class_name CharacterPreview
extends Control
## Isolated portrait renderer. It owns a CharacterVisual, never a playable Hero.
## Reparenting preserves this viewport, the model, yaw and animation state.

const VisualScript = preload("res://scripts/character_visual.gd")
const RENDER_SIZE: Vector2i = Vector2i(320,320)
const UPDATE_INTERVAL: float = 1.0/30.0
const MOUSE_GUARD_MSEC: int = 250
const BODY_CAMERA_SIZE: float = 2.9
const ATTACK_CAMERA_SIZE: float = 5.3
const FIRE_ATTACK_CAMERA_SIZE: float = 6.0

var preview_viewport: SubViewport
var preview_model: CharacterVisual
var preview_camera: Camera3D
var preview_active: bool = false
var preview_yaw: float = 0.0
var animation_mode: String = "idle"
var touch_id: int = -1
var mouse_dragging: bool = false
var render_request_count: int = 0
var visual_tick_count: int = 0
var _requested_active: bool = false
var _application_focused: bool = true
var _update_elapsed: float = 0.0
var _last_pointer: Vector2 = Vector2.ZERO
var _ignore_mouse_until: int = 0
var _next_attack: int = 0
var _weapon_tier: int = 0
var _armor_tier: int = 0
var _upgrade: int = 0
var _sword_flame_requested: bool = false
var _frame_style: StyleBoxFlat

func _enter_tree() -> void:
	# _ready runs once. Parking and reattaching the same Control must not
	# allocate another world or dispose resources used by its viewport texture.
	if is_node_ready():
		call_deferred("_sync_activity")

func _ready() -> void:
	if name.is_empty() or str(name).begins_with("@"):
		name = "CharacterPreview"
	custom_minimum_size = Vector2(250,264)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	clip_contents = true
	_frame_style = StyleBoxFlat.new()
	_frame_style.bg_color = Color("11272e")
	_frame_style.border_color = Color("526655")
	_frame_style.set_border_width_all(1)
	_frame_style.set_corner_radius_all(10)
	resized.connect(queue_redraw)
	_build_preview()
	_sync_activity()

func _exit_tree() -> void:
	preview_active = false
	cancel_preview_drag()
	_update_elapsed = 0.0
	set_process(false)
	if is_instance_valid(preview_viewport):
		preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if is_instance_valid(preview_model):
		preview_model.set_sword_flame(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_node_ready():
			_sync_activity()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_application_focused = false
		_sync_activity()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_application_focused = true
		_sync_activity()

func _draw() -> void:
	if _frame_style != null:
		draw_style_box(_frame_style,Rect2(Vector2.ZERO,size))

func _build_preview() -> void:
	preview_viewport = SubViewport.new()
	preview_viewport.name = "PreviewViewport"
	preview_viewport.size = RENDER_SIZE
	preview_viewport.own_world_3d = true
	preview_viewport.transparent_bg = true
	preview_viewport.gui_disable_input = true
	preview_viewport.physics_object_picking = false
	preview_viewport.msaa_3d = Viewport.MSAA_DISABLED
	preview_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	preview_viewport.positional_shadow_atlas_size = 0
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(preview_viewport)
	var stage: Node3D = Node3D.new()
	stage.name = "PreviewStage"
	preview_viewport.add_child(stage)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0,0,0,0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bfccd1")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	stage.add_child(world_environment)
	var key: DirectionalLight3D = DirectionalLight3D.new()
	key.name = "PreviewKey"
	key.light_color = Color("ffe6bd")
	key.light_energy = 1.15
	key.shadow_enabled = false
	key.rotation_degrees = Vector3(-38,-145,0)
	stage.add_child(key)
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.name = "PreviewFill"
	fill.light_color = Color("a3d4e7")
	fill.light_energy = 0.55
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-24,28,0)
	stage.add_child(fill)
	var pedestal: MeshInstance3D = MeshInstance3D.new()
	pedestal.name = "PreviewPedestal"
	var disk: CylinderMesh = CylinderMesh.new()
	disk.top_radius = 0.65
	disk.bottom_radius = 0.69
	disk.height = 0.045
	disk.radial_segments = 32
	pedestal.mesh = disk
	var disk_material: StandardMaterial3D = StandardMaterial3D.new()
	disk_material.albedo_color = Color("263b3e")
	disk_material.roughness = 0.9
	pedestal.material_override = disk_material
	pedestal.position.y = -0.025
	pedestal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.add_child(pedestal)
	preview_model = VisualScript.new()
	preview_model.name = "PreviewModel"
	stage.add_child(preview_model)
	preview_model.set_equipment(_weapon_tier,_armor_tier,_upgrade)
	preview_model.rotation.y = deg_to_rad(preview_yaw)
	preview_model.tick(0.0,0.0)
	preview_camera = Camera3D.new()
	preview_camera.name = "PreviewCamera"
	preview_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	preview_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	preview_camera.size = BODY_CAMERA_SIZE
	preview_camera.near = 0.05
	preview_camera.far = 20.0
	preview_camera.position = Vector3(0,1.35,-6)
	stage.add_child(preview_camera)
	preview_camera.look_at(Vector3(0,1.20,0),Vector3.UP)
	preview_camera.current = true
	var portrait: TextureRect = TextureRect.new()
	portrait.name = "PreviewPortrait"
	portrait.texture = preview_viewport.get_texture()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = 3
	portrait.offset_top = 3
	portrait.offset_right = -3
	portrait.offset_bottom = -3
	add_child(portrait)

func set_equipment(weapon_tier: int, armor_tier: int, upgrade: int = 0) -> void:
	_weapon_tier = clampi(weapon_tier,0,3)
	_armor_tier = clampi(armor_tier,0,3)
	_upgrade = clampi(upgrade,0,6)
	if is_instance_valid(preview_model):
		preview_model.set_equipment(_weapon_tier,_armor_tier,_upgrade)

func set_preview_active(active: bool) -> void:
	_requested_active = active
	_sync_activity()

func set_sword_flame(burning: bool) -> void:
	_sword_flame_requested = burning
	if is_instance_valid(preview_model):
		preview_model.set_sword_flame(burning and preview_active)
	update_framing(0.0)

func _sync_activity() -> void:
	var active: bool = _requested_active and _application_focused and is_inside_tree() and is_visible_in_tree()
	if not active:
		cancel_preview_drag()
	set_process(active)
	if active == preview_active:
		return
	preview_active = active
	_update_elapsed = 0.0
	if is_instance_valid(preview_model):
		preview_model.set_sword_flame(_sword_flame_requested and active)
	if is_instance_valid(preview_viewport):
		if active:
			_request_render()
		else:
			preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _process(delta: float) -> void:
	if not preview_active or not is_visible_in_tree():
		return
	_update_elapsed += delta
	if _update_elapsed < UPDATE_INTERVAL:
		return
	var step: float = minf(_update_elapsed,0.10)
	_update_elapsed = fmod(_update_elapsed,UPDATE_INTERVAL)
	preview_model.tick(step,1.0 if animation_mode == "run" else 0.0)
	preview_model.rotation.y = deg_to_rad(preview_yaw)
	update_framing(step)
	visual_tick_count += 1
	_request_render()

func _request_render() -> void:
	if not preview_active or not is_instance_valid(preview_viewport):
		return
	# UPDATE_ONCE is reset by the renderer. ALWAYS/WHEN_VISIBLE would render
	# at the main viewport's frame rate even with a 30 Hz animation clock.
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	render_request_count += 1

func set_preview_yaw(degrees: float) -> void:
	if not is_finite(degrees):
		return
	preview_yaw = wrapf(degrees,-180.0,180.0)
	if is_instance_valid(preview_model):
		preview_model.rotation.y = deg_to_rad(preview_yaw)

func get_preview_yaw() -> float:
	return preview_yaw

func rotate_preview(degrees: float) -> void:
	set_preview_yaw(preview_yaw+degrees)

func reset_view() -> void:
	set_preview_yaw(0.0)

func set_animation(mode: String) -> void:
	if mode not in ["idle","run"]:
		return
	animation_mode = mode
	if is_instance_valid(preview_model):
		preview_model.attack_elapsed = -1.0

func play_preview_attack() -> void:
	if not preview_active or not is_instance_valid(preview_model) or preview_model.is_attacking():
		return
	animation_mode = "idle"
	preview_model.start_attack(_next_attack,false)
	_next_attack = (_next_attack+1)%4
	update_framing(0.0)

func update_framing(delta: float) -> void:
	if not is_instance_valid(preview_camera) or not is_instance_valid(preview_model):
		return
	# Keep the resting warrior large. A cut can swing the long third-tier
	# blade far outside the silhouette, so widen immediately before its first
	# rendered frame and return gently only once the full motion has ended.
	var target: float = BODY_CAMERA_SIZE
	if preview_model.is_attacking():
		target = FIRE_ATTACK_CAMERA_SIZE if _sword_flame_requested else ATTACK_CAMERA_SIZE
	if target > preview_camera.size:
		preview_camera.size = target
	elif delta > 0.0:
		preview_camera.size = lerpf(preview_camera.size,target,1.0-exp(-delta*5.0))

func cancel_preview_drag() -> void:
	if touch_id >= 0:
		_ignore_mouse_until = Time.get_ticks_msec()+MOUSE_GUARD_MSEC
	touch_id = -1
	mouse_dragging = false
	_last_pointer = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not preview_active or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.canceled:
			if event.index == touch_id:
				cancel_preview_drag()
				get_viewport().set_input_as_handled()
			return
		if event.pressed:
			if touch_id < 0 and not mouse_dragging and get_global_rect().has_point(event.position):
				touch_id = event.index
				_last_pointer = event.position
				_ignore_mouse_until = Time.get_ticks_msec()+MOUSE_GUARD_MSEC
				get_viewport().set_input_as_handled()
		elif event.index == touch_id:
			cancel_preview_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			_rotate_from_pointer(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device < 0 or touch_id >= 0 or Time.get_ticks_msec() < _ignore_mouse_until:
			return
		if event.pressed:
			if not mouse_dragging and get_global_rect().has_point(event.position):
				mouse_dragging = true
				_last_pointer = event.position
				get_viewport().set_input_as_handled()
		elif mouse_dragging:
			cancel_preview_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_dragging:
		if event.device < 0 or touch_id >= 0 or Time.get_ticks_msec() < _ignore_mouse_until:
			return
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
			cancel_preview_drag()
			return
		_rotate_from_pointer(event.position)
		get_viewport().set_input_as_handled()

func _rotate_from_pointer(point: Vector2) -> void:
	var distance: float = point.x-_last_pointer.x
	_last_pointer = point
	rotate_preview(distance*180.0/maxf(size.x,1.0))

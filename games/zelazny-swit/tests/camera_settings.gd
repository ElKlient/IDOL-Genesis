extends SceneTree
## Isolated camera geometry, real movement/UI and independent preference persistence.
var game: Node3D
var state: Node
var checks: int = 0
var failures: int = 0
var capture_directory: String = ""
var legacy_save: PackedByteArray

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _run() -> void:
	var expected_root: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--test-data-root="):
			expected_root = arg.trim_prefix("--test-data-root=").trim_suffix("/")
		if arg.begins_with("--capture-dir="):
			capture_directory = arg.trim_prefix("--capture-dir=")
	if not "--test-isolated" in OS.get_cmdline_user_args() or expected_root.is_empty() or not expected_root.is_absolute_path() or not OS.get_user_data_dir().begins_with(expected_root + "/"):
		push_error("Refusing camera fixtures outside explicit disposable XDG_DATA_HOME/--test-data-root and --test-isolated.")
		quit(2)
		return
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	_check(not state.save_enabled,"camera regression disables character save writes")
	# This valid older-format character save belongs only to the disposable fixture.
	var legacy: Dictionary = {"version":1,"gold":4321,"level":3,"xp":24,"hp":180,"potions":7,"kills":2,"quest_claimed":false,"bought_weapon":true,"upgraded_any":true,"weapon_uid":7,"armor_uid":0,"items":[{"id":"iron_sword","uid":7,"upgrade":2}],"audio_enabled":false}
	_write_text(state.SAVE_PATH,JSON.stringify(legacy))
	legacy_save = FileAccess.get_file_as_bytes(state.SAVE_PATH)
	await _preferences()
	var scene: PackedScene = load("res://main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.8).timeout
	var initial: Dictionary = game.get_camera_settings()
	_check(_defaults(initial),"real scene starts with closer zoom 1.35, pitch 48 and yaw zero")
	var old_camera: Camera3D = Camera3D.new()
	old_camera.fov = 48.0
	old_camera.near = 0.2
	old_camera.far = 190.0
	game.add_child(old_camera)
	old_camera.global_position = game.hero.global_position+Vector3(0,16,13)
	old_camera.look_at(game.hero.global_position+Vector3(0,0.6,-1.5),Vector3.UP)
	await _frames(2)
	var old_height: float = _hero_height(old_camera)
	var default_height: float = _hero_height(game.camera)
	print("CAMERA GEOMETRY: old_height_px=%.2f default_height_px=%.2f larger_percent=%.2f" % [old_height,default_height,(default_height/old_height-1.0)*100.0])
	_check(default_height > old_height*1.32,"default camera projects a warrior at least 32 percent larger than the previous fixed camera")
	await _main_persistence()
	game.set_camera_settings(1.0,48.0,0.0)
	await create_timer(0.8).timeout
	var distant_height: float = _hero_height(game.camera)
	game.set_camera_settings(1.85,48.0,0.0)
	await create_timer(0.8).timeout
	var close_height: float = _hero_height(game.camera)
	_check(close_height > distant_height*1.5,"full zoom range visibly enlarges projected warrior height")
	await _collision_regression()
	game.set_camera_settings(999.0,-999.0,999.0)
	await _frames(3)
	var clamped: Dictionary = game.get_camera_settings()
	_check(is_equal_approx(clamped.zoom,1.85) and is_equal_approx(clamped.pitch,38.0) and is_equal_approx(clamped.yaw,180.0),"main camera API clamps zoom, low pitch and yaw to supported ranges")
	game.set_camera_settings(-999.0,999.0,-999.0)
	await _frames(3)
	clamped = game.get_camera_settings()
	_check(is_equal_approx(clamped.zoom,1.0) and is_equal_approx(clamped.pitch,65.0) and is_equal_approx(clamped.yaw,-180.0),"main camera API clamps the opposite zoom, pitch and yaw bounds")
	game.reset_camera_settings()
	_check(_defaults(game.get_camera_settings()),"main reset restores all three camera defaults")
	# Freeze only AI; use the real hero, physics floor, joystick and orbit camera.
	for enemy: Node3D in game.enemies:
		enemy.set_physics_process(false)
	for yaw: float in [0.0,90.0,-90.0,180.0]:
		await _movement_at_yaw(yaw,old_camera)
	game.hero.reset_to(game.world.spawn_position)
	game.reset_camera_settings()
	await create_timer(0.8).timeout
	await _capture("camera-default-1280x720")
	game.hud.open_panel("camera")
	await _frames(5)
	var zoom_slider: HSlider = game.hud.modal.find_child("CameraZoom",true,false)
	var pitch_slider: HSlider = game.hud.modal.find_child("CameraPitch",true,false)
	var yaw_slider: HSlider = game.hud.modal.find_child("CameraYaw",true,false)
	_check(zoom_slider != null and pitch_slider != null and yaw_slider != null,"camera panel exposes all three named touch sliders")
	if zoom_slider != null and pitch_slider != null and yaw_slider != null:
		var slider_id: int = zoom_slider.get_instance_id()
		await _click_at(zoom_slider.get_global_rect().position+Vector2(zoom_slider.size.x*0.82,zoom_slider.size.y*0.5))
		_check(zoom_slider.value > 1.35 and is_equal_approx(game.get_camera_settings().zoom,zoom_slider.value),"actual zoom slider pointer input updates live camera preference")
		await _click_at(pitch_slider.get_global_rect().position+Vector2(pitch_slider.size.x*0.85,pitch_slider.size.y*0.5))
		_check(pitch_slider.value > 48.0 and is_equal_approx(game.get_camera_settings().pitch,pitch_slider.value),"actual pitch slider pointer input updates live camera preference")
		await _click_at(yaw_slider.get_global_rect().position+Vector2(yaw_slider.size.x*0.75,yaw_slider.size.y*0.5))
		_check(yaw_slider.value > 20.0 and is_equal_approx(game.get_camera_settings().yaw,yaw_slider.value),"actual orbit slider pointer input updates live camera preference")
		_check(is_instance_valid(zoom_slider) and zoom_slider.get_instance_id() == slider_id,"live preview does not rebuild the slider tree during interaction")
	var reset: Button = _button(game.hud.modal,"PRZYWRÓĆ DOMYŚLNE")
	_check(reset != null,"camera panel exposes explicit restore-defaults button")
	if reset != null:
		await _click_at(reset.get_global_rect().get_center())
	_check(_defaults(game.get_camera_settings()),"actual reset button restores the default camera preview")
	await create_timer(0.8).timeout
	await _panel_geometry("1280x720")
	root.size = Vector2i(1600,720)
	await _frames(5)
	await _panel_geometry("1600x720")
	_check(FileAccess.get_file_as_bytes(state.SAVE_PATH) == legacy_save,"camera settings, reloads, UI and captures leave legacy character save bytes unchanged")
	_check(not root.get_node("Diagnostics").is_network_enabled(),"camera test remains isolated from telemetry networking")
	game.queue_free()
	await _frames(3)
	await create_timer(0.25).timeout
	print("CAMERA SETTINGS RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _preferences() -> void:
	var script: Script = load("res://scripts/camera_preferences.gd")
	var preferences: RefCounted = script.new()
	_check(not preferences.save_enabled and _defaults(preferences.as_dictionary()),"separate camera preferences start at defaults with persistence disabled in isolated mode")
	var existed: bool = FileAccess.file_exists(preferences.SETTINGS_PATH)
	var before: PackedByteArray = FileAccess.get_file_as_bytes(preferences.SETTINGS_PATH) if existed else PackedByteArray()
	preferences.set_values(1.65,60.0,-95.0)
	_check(not preferences.save_settings() and FileAccess.file_exists(preferences.SETTINGS_PATH) == existed and (not existed or FileAccess.get_file_as_bytes(preferences.SETTINGS_PATH) == before),"disabled isolated preferences do not create or overwrite camera settings")
	preferences.save_enabled = true
	_check(preferences.save_settings(),"explicit disposable-directory camera preference save succeeds")
	var reloaded: RefCounted = script.new()
	reloaded.save_enabled = true
	reloaded.load_settings()
	var values: Dictionary = reloaded.as_dictionary()
	_check(is_equal_approx(values.zoom,1.65) and is_equal_approx(values.pitch,60.0) and is_equal_approx(values.yaw,-95.0),"independent camera preference file reloads zoom, pitch and orbit exactly")
	_check(not FileAccess.file_exists(preferences.SETTINGS_PATH+".tmp"),"atomic preference save leaves no temporary file")
	reloaded.set_values("invalid",NAN,INF)
	_check(_defaults(reloaded.as_dictionary()),"non-numeric and non-finite camera values fall back to safe defaults")
	reloaded.set_values(-999.0,999.0,999.0)
	values = reloaded.as_dictionary()
	_check(is_equal_approx(values.zoom,1.0) and is_equal_approx(values.pitch,65.0) and is_equal_approx(values.yaw,180.0),"persisted preference model independently enforces all numeric bounds")
	_write_text(preferences.SETTINGS_PATH,"x".repeat(preferences.MAX_FILE_BYTES+1))
	reloaded.load_settings()
	_check(_defaults(reloaded.as_dictionary()),"oversized preference file safely loads defaults")
	preferences.reset_defaults()
	preferences.save_settings()
	_check(FileAccess.get_file_as_bytes(state.SAVE_PATH) == legacy_save,"camera preference persistence never modifies legacy character data")

func _movement_at_yaw(yaw: float, snapshot: Camera3D) -> void:
	for direction: Vector2 in [Vector2.UP,Vector2.RIGHT]:
		game.hero.reset_to(Vector3(0,0,2))
		game.set_camera_settings(1.35,48.0,yaw)
		await create_timer(0.65).timeout
		snapshot.fov = game.camera.fov
		snapshot.global_transform = game.camera.global_transform
		var before_world: Vector3 = game.hero.global_position
		var before_screen: Vector2 = snapshot.unproject_position(before_world+Vector3.UP)
		_stick(direction)
		await create_timer(0.32).timeout
		_release_stick()
		var after_screen: Vector2 = snapshot.unproject_position(game.hero.global_position+Vector3.UP)
		var delta: Vector2 = after_screen-before_screen
		var screen_correct: bool = delta.y < -10.0 and absf(delta.x) < absf(delta.y)*0.35 if direction == Vector2.UP else delta.x > 10.0 and absf(delta.y) < absf(delta.x)*0.35
		_check(screen_correct and before_world.distance_to(game.hero.global_position) > 0.6,"actual joystick moves screen-%s at camera orbit %.0f degrees" % ["up" if direction == Vector2.UP else "right",yaw])

func _main_persistence() -> void:
	# Only this explicitly guarded disposable directory permits the real main
	# controller to exercise its normal debounced persistence hook.
	game.camera_preferences.save_enabled = true
	game.set_camera_settings(1.55,54.0,-35.0)
	game.set_camera_settings(1.65,57.0,-70.0)
	await create_timer(0.65).timeout
	var script: Script = load("res://scripts/camera_preferences.gd")
	var reloaded: RefCounted = script.new()
	reloaded.save_enabled = true
	reloaded.load_settings()
	var values: Dictionary = reloaded.as_dictionary()
	_check(is_equal_approx(values.zoom,1.65) and is_equal_approx(values.pitch,57.0) and is_equal_approx(values.yaw,-70.0) and not game.camera_settings_dirty,"real main debounce persists the last live camera settings for the next launch")
	_check(FileAccess.get_file_as_bytes(state.SAVE_PATH) == legacy_save,"real main camera persistence leaves the existing character save unchanged")
	game.camera_preferences.save_enabled = false
	game.reset_camera_settings()

func _collision_regression() -> void:
	game.hero.reset_to(Vector3(0,0,2))
	game.set_camera_settings(1.0,48.0,0.0)
	await create_timer(0.8).timeout
	var original_length: float = game.camera_arm.get_hit_length()
	var obstacle: StaticBody3D = StaticBody3D.new()
	obstacle.collision_layer = 1
	obstacle.collision_mask = 0
	var collider: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(4,4,0.6)
	collider.shape = shape
	obstacle.add_child(collider)
	game.add_child(obstacle)
	obstacle.global_transform = game.camera_arm.global_transform
	obstacle.global_position = game.camera_arm.global_position+game.camera_arm.global_basis.z*6.0
	for _index: int in range(8):
		await physics_frame
	var blocked_length: float = game.camera_arm.get_hit_length()
	var camera_in_box: bool = AABB(-shape.size*0.5,shape.size).has_point(obstacle.to_local(game.camera.global_position))
	_check(original_length > 10.0 and blocked_length < 6.5 and blocked_length < original_length-3.0,"temporary wall between camera focus and desired endpoint shortens the real spring arm")
	_check(not camera_in_box and game.camera.global_position.distance_to(game.camera_arm.global_position) < 6.5,"camera eye remains in front of the temporary wall instead of clipping inside it")
	obstacle.queue_free()
	for _index: int in range(8):
		await physics_frame
	_check(game.camera_arm.get_hit_length() > original_length*0.9,"removing the wall restores the camera spring-arm distance")

func _panel_geometry(label: String) -> void:
	var panel_rect: Rect2 = game.hud.modal.get_global_rect()
	var hero_screen: Vector2 = game.camera.unproject_position(game.hero.global_position+Vector3.UP)
	var viewport: Rect2 = root.get_visible_rect()
	_check(viewport.encloses(panel_rect) and not panel_rect.has_point(hero_screen) and hero_screen.x < panel_rect.position.x,"camera panel fits %s and leaves the larger warrior visible for live preview" % label)
	await _capture("camera-panel-"+label)

func _hero_height(camera: Camera3D) -> float:
	var feet: Vector2 = camera.unproject_position(game.hero.global_position)
	var head: Vector2 = camera.unproject_position(game.hero.global_position+Vector3(0,1.9,0))
	return absf(feet.y-head.y)

func _capture(filename: String) -> void:
	if capture_directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(capture_directory)
	game.hud.toast_timer = 0.0
	game.hud.toast_panel.hide()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image.save_png(capture_directory.path_join(filename+".png")) == OK,"actual OpenGL capture saved: "+filename)

func _stick(direction: Vector2) -> void:
	var joystick: Control = game.hud.joystick
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 42
	event.pressed = true
	event.position = joystick.global_position+joystick.size*0.5+direction*joystick.size.x*0.34
	Input.parse_input_event(event)

func _release_stick() -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 42
	event.pressed = false
	Input.parse_input_event(event)

func _click_at(point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	for pressed: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		Input.parse_input_event(event)
		await process_frame
	await _frames(3)

func _button(node: Node, text: String) -> Button:
	if node is Button and node.text == text and node.is_visible_in_tree():
		return node
	for child: Node in node.get_children():
		var found: Button = _button(child,text)
		if found != null:
			return found
	return null

func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame

func _defaults(values: Dictionary) -> bool:
	return is_equal_approx(float(values.zoom),1.35) and is_equal_approx(float(values.pitch),48.0) and is_equal_approx(float(values.yaw),0.0)

func _write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()

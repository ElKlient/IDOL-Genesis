extends SceneTree
const Timing = preload("res://scripts/attack_timing.gd")
## Actual fire-skill/HUD/orbit input regression, with isolated real enemy bodies.
const EnemyScript = preload("res://scripts/enemy.gd")
var game: Node3D
var state: Node
var fixtures: Array[Node3D] = []
var hits: Array[int] = [0,0,0]
var last_amount: int = 0
var last_critical: bool = false
var pad_presses: int = 0
var checks: int = 0
var failures: int = 0
var capture_dir: String = ""

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool,label: String) -> void:
	checks += 1
	if ok:
		print("PASS: "+label)
	else:
		failures += 1
		push_error("FAIL: "+label)

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		push_error("Supply --test-isolated; never run fire QA against a player's save.")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	var save_exists: bool = FileAccess.file_exists(state.SAVE_PATH)
	var save_before: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if save_exists else PackedByteArray()
	_check(not state.save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"fire/orbit QA disables character saving and diagnostic networking")
	state.new_game()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for existing: Node3D in game.enemies:
		existing.set_physics_process(false)
	await _frames(4)
	game.set_camera_settings(2.5,38,145)
	state.buy("dawn_sword")
	var sword_uid: int = int(state.inventory.back().uid)
	state.find_item(sword_uid).upgrade = 5
	state.equip(sword_uid)
	state.buy("dawn_armor")
	state.equip(int(state.inventory.back().uid))
	var permanent_attack: int = state.attack_power()
	for index: int in range(3):
		var enemy: Node3D = EnemyScript.new()
		enemy.setup(0,game.hero)
		game.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.max_hp = 10000
		enemy.hp = 10000
		enemy.position = [Vector3(0,0,0),Vector3(2.5,0,0),Vector3(8,0,0)][index]
		enemy.damaged.connect(func(amount: int,critical: bool) -> void:
			hits[index] += 1
			if index == 0:
				last_amount = amount
				last_critical = critical
		)
		fixtures.append(enemy)
		game.enemies.append(enemy)
	_place_hero()
	await _frames(4)
	_check(root.get_visible_rect().encloses(game.hud.camera_pad.get_global_rect()) and root.get_visible_rect().encloses(game.hud.fire_pad.get_global_rect()) and not game.hud.camera_pad.get_global_rect().intersects(game.hud.fire_pad.get_global_rect()),"new camera area and fire button fit landscape without overlapping each other")
	# Slow only the rendered windup so first-time shader compilation cannot
	# skip the pose being inspected; headless timing stays at real speed.
	if DisplayServer.get_name() != "headless":
		Engine.time_scale = 0.1
	var point: Vector2 = game.hud.fire_pad.get_global_rect().get_center()
	_touch(point,true,3)
	await process_frame
	_touch(point,false,3)
	await _frames(2)
	_check(game.fire_skill_cooldown > 19 and game._fire_action_time > 0.8 and game.hero.attack_locked_time > 0.8 and game.hero.visual.fire_slam_attack,"actual fire touch button starts a planted two-handed slam and a twenty-second cooldown")
	var serial: int = game._attack_serial
	var where: Vector3 = game.hero.position
	game.hud.joystick.vector = Vector2.RIGHT
	game.request_attack()
	game.use_skill()
	game.use_fire_skill()
	await create_timer(0.18).timeout
	_check(hits == [0,0,0] and game.fire_buff_time == 0 and _effect_count() == 0,"windup deals no early damage, creates no impact and grants no early flame buff")
	_check(game._attack_serial == serial and game.skill_cooldown == 0 and game.hero.position.distance_to(where) < 0.025,"slam locks normal attacks, Wir stali, retriggering and movement during its windup")
	await _capture("fire-01-windup")
	Engine.time_scale = 1.0
	game.hud.joystick.vector = Vector2.ZERO
	await create_timer(0.42).timeout
	_check(hits == [1,1,0] and last_amount == int(state.attack_power()*1.65)+10,"one contact hits both enemies inside the four-meter impact while leaving the distant enemy untouched")
	_check(game.fire_buff_time > 11 and game.hero.visual.sword_burning and game.hero.visual.sword_fire.is_burning(),"contact ignites the actual sword and begins its twelve-second buff")
	_check(_effect_count() == 1 and game.hud.fire_status_text.text.begins_with("OGIEŃ"),"one bounded impact effect and the HUD report the active fire state")
	await _capture("fire-02-impact")
	var fire_node_count: int = _descendants(game.hero.visual.sword_fire)
	_check(fire_node_count <= 6,"burning blade uses a bounded shared-mesh effect instead of spawning per-frame nodes")
	await create_timer(1.10).timeout
	_check(hits == [1,1,0] and _effect_count() == 0 and game._fire_action_time == 0 and game.hero.attack_locked_time == 0,"slam hits each enemy only once, its impact cleans itself up and action lock expires")
	await _capture("fire-03-burning-blade")
	_place_hero()
	game.attack_cooldown = 0
	game.combo = 0
	game.request_attack()
	await create_timer(Timing.contact_time(0)+0.08).timeout
	var minimum: int = int((state.attack_power()-2)*1.3)
	var maximum: int = int((state.attack_power()+3)*1.3)
	if last_critical:
		minimum = int(minimum*1.65)
		maximum = int(maximum*1.65)
	_check(hits[0] == 2 and last_amount >= minimum and last_amount <= maximum,"real ordinary cut receives the thirty-percent fire bonus before its possible critical multiplier")
	var before_hits: Array[int] = hits.duplicate()
	game.use_fire_skill()
	await create_timer(0.55).timeout
	_check(hits == before_hits and game.fire_skill_cooldown > 16,"active cooldown rejects a second fire cast without another impact or hit")
	game.hud.open_panel("inventory")
	await _frames(6)
	var preview: Control = game.hud.character_preview
	_check(preview.preview_model.sword_burning and preview.preview_model.sword_fire.is_burning(),"inventory portrait mirrors the live flaming sword")
	await _capture("fire-04-inventory-flame")
	game.hud.close_panel()
	await _frames(4)
	_check(not preview.preview_model.sword_fire.is_processing() and not preview.preview_model.sword_fire.is_burning(),"hidden inventory switches off its sword flame processing")
	game.hud.open_panel("inventory")
	await _frames(4)
	_check(preview.preview_model.sword_fire.is_burning(),"reopening inventory restores the flame while the buff remains active")
	game.hud.close_panel()
	await _frames(4)
	await _orbit_inputs()
	# Touch ownership also has to survive Android's synthetic mouse event stream.
	var attack_pad: Control = game.hud.attack_pad
	attack_pad.pressed.connect(func() -> void: pad_presses += 1)
	point = attack_pad.get_global_rect().get_center()
	_touch(point,true,8)
	await process_frame
	var synthetic := InputEventMouseButton.new()
	synthetic.device = -1
	synthetic.button_index = MOUSE_BUTTON_LEFT
	synthetic.position = point
	synthetic.pressed = true
	Input.parse_input_event(synthetic)
	await process_frame
	_check(attack_pad.finger == 8 and attack_pad.is_down and pad_presses == 1,"attack pad owns the real touch index and ignores a duplicate synthetic mouse press")
	_touch(point,false,8)
	await _frames(3)
	_check(attack_pad.finger == -999 and not attack_pad.is_down and not game.hud.attack_held,"real attack-touch release clears the held attack without a stuck synthetic mouse")
	# Use the actual twelve-second expiry rather than manually clearing the buff.
	var deadline: int = Time.get_ticks_msec()+13000
	while game.fire_buff_time > 0 and Time.get_ticks_msec() < deadline:
		await physics_frame
	_check(game.fire_buff_time == 0 and not game.hero.visual.sword_burning and not game.hero.visual.sword_fire.is_processing(),"the real twelve-second expiry removes the buff and stops live flame processing")
	_check(state.attack_power() == permanent_attack and game.hero.visual.upgrade_level == 5 and game.hero.visual.blade_material.emission_enabled,"flame expiry preserves the equipped upgraded sword and its normal upgrade material")
	game.hud.open_panel("inventory")
	await _frames(4)
	_check(not preview.preview_model.sword_burning and not preview.preview_model.sword_fire.is_processing(),"expired buff stays extinguished after reopening the portrait")
	game.hud.close_panel()
	await _frames(3)
	# Controlled reset of cooldowns enables independent cancellation cases without
	# shortening the production twenty-second cooldown or changing save state.
	game.fire_skill_cooldown = 0
	game.attack_cooldown = 0
	_place_hero()
	if DisplayServer.get_name() != "headless":
		Engine.time_scale = 0.1
	_key(KEY_F)
	await _frames(2)
	_check(game._fire_action_time > 0.8,"physical F key invokes the same slam path as the touch button")
	Engine.time_scale = 1.0
	before_hits = hits.duplicate()
	game.hud.open_panel("inventory")
	game.hud.close_panel()
	await create_timer(0.60).timeout
	_check(hits == before_hits and game.fire_buff_time == 0 and _effect_count() == 0 and not game.hero.visual.fire_slam_attack,"even same-frame modal open/close cancels pending slam damage, buff and effect")
	_check(game.fire_skill_cooldown > 19 and game.hero.attack_locked_time == 0,"interrupting the slam preserves spent cooldown while releasing its movement lock")
	game.fire_skill_cooldown = 0
	game.attack_cooldown = 0
	game.use_fire_skill()
	await _frames(3)
	game.hero.dead = true
	await create_timer(0.60).timeout
	_check(hits == before_hits and game.fire_buff_time == 0 and _effect_count() == 0 and game.hero.attack_locked_time == 0,"death during windup cancels every delayed impact and releases its lock")
	game.hero.reset_to(Vector3(0,0,1.7))
	game.fire_skill_cooldown = 0
	game.hud.open_panel("inventory")
	await _frames(3)
	serial = game._attack_serial
	_key(KEY_F)
	game.use_fire_skill()
	await _frames(3)
	_check(game.fire_skill_cooldown == 0 and game._attack_serial == serial,"open inventory rejects both F and direct fire requests")
	game.hud.close_panel()
	await _frames(3)
	# A slam supersedes a normal cut already waiting for contact.
	game.fire_skill_cooldown = 0
	game.attack_cooldown = 0
	_place_hero()
	before_hits = hits.duplicate()
	game.request_attack()
	game.use_fire_skill()
	await create_timer(0.28).timeout
	_check(hits == before_hits,"starting the slam invalidates an older pending ordinary contact")
	await create_timer(0.35).timeout
	_check(hits[0] == before_hits[0]+1 and game.fire_buff_time > 11,"superseding a normal cut leaves exactly the new slam contact and buff")
	game.hero.dead = true
	await _frames(4)
	_check(game.fire_buff_time == 0 and not game.hero.visual.sword_burning,"death after a successful impact immediately removes the live sword buff")
	game.hero.reset_to(Vector3(0,0,1.7))
	await create_timer(1.2).timeout
	_check(_descendants(game.hero.visual.sword_fire) == fire_node_count and _effect_count() == 0,"repeated cast, cancellation and expiry leave no accumulating flame nodes")
	_check(FileAccess.file_exists(state.SAVE_PATH) == save_exists and (not save_exists or FileAccess.get_file_as_bytes(state.SAVE_PATH) == save_before),"fire, equipment and camera QA leave any existing character save unchanged")
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("FIRE SKILL RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _orbit_inputs() -> void:
	game.hero.reset_to(Vector3(0,0,4))
	game.set_camera_settings(1.85,48,0)
	await _frames(3)
	var pad: Control = game.hud.camera_pad
	var point: Vector2 = pad.get_global_rect().get_center()
	var settings: Dictionary = game.get_camera_settings()
	var serial: int = game._attack_serial
	var target: Node3D = game.target
	var previous_fixture_position: Vector3 = fixtures[2].position
	fixtures[2].position = game.camera.project_position(point,5.0)-Vector3.UP
	game._pick_target(point)
	var ray_fixture_valid: bool = game.target == fixtures[2]
	game._set_target(target)
	_mouse(point,true,-1)
	_mouse(point,false,-1)
	await process_frame
	_check(ray_fixture_valid and game.target == target,"a synthetic mouse companion cannot select an enemy positioned behind the camera control")
	fixtures[2].position = previous_fixture_position
	_mouse(point,true)
	await process_frame
	_motion(point+Vector2(60,20),Vector2(60,20))
	await process_frame
	_mouse(point+Vector2(60,20),false)
	await _frames(3)
	var changed: Dictionary = game.get_camera_settings()
	_check(absf(changed.yaw-settings.yaw) > 10 and changed.pitch > settings.pitch and is_equal_approx(changed.zoom,settings.zoom),"real mouse drag in camera field rotates yaw and pitch while preserving zoom")
	var start: Vector3 = game.hero.position
	var stick: Control = game.hud.joystick
	var stick_point: Vector2 = stick.get_global_rect().get_center()+Vector2(45,0)
	_touch(stick_point,true,1)
	_touch(point,true,2)
	await process_frame
	_touch(point,true,6)
	var yaw: float = game.get_camera_settings().yaw
	_drag(point+Vector2(50,-20),6)
	await process_frame
	_check(pad.finger == 2 and is_equal_approx(game.get_camera_settings().yaw,yaw),"another camera-area finger cannot steal an active gesture")
	_drag(point+Vector2(50,-20),2)
	await create_timer(0.30).timeout
	_check(game.hero.position.distance_to(start) > 0.5 and absf(game.get_camera_settings().yaw-yaw) > 8 and stick.finger == 1 and pad.finger == 2,"left joystick movement and right camera orbit work simultaneously with independent fingers")
	_touch(stick_point,false,1)
	_touch(point,false,2,true)
	_touch(point,false,6)
	await _frames(3)
	_check(pad.finger == -1 and not pad.mouse_dragging and game._attack_serial == serial and game.target == target,"camera cancel releases its pointer without attack or world-target click-through")
	_touch(point,true,4)
	await process_frame
	game.hud.open_panel("inventory")
	await _frames(3)
	settings = game.get_camera_settings()
	_drag(point+Vector2(120,120),4)
	game.orbit_camera(Vector2(80,80))
	await process_frame
	_check(pad.finger == -1 and not pad.enabled and game.get_camera_settings() == settings,"opening a modal releases camera ownership and rejects further orbit input")
	game.hud.close_panel()
	await _frames(3)
	game.orbit_camera(Vector2(0,10000))
	_check(is_equal_approx(game.get_camera_settings().pitch,65),"camera orbit clamps the upper pitch limit")
	game.orbit_camera(Vector2(10000,-10000))
	settings = game.get_camera_settings()
	_check(is_equal_approx(settings.pitch,38) and settings.yaw >= -180 and settings.yaw <= 180 and not game.camera_preferences.save_enabled,"orbit clamps lower pitch, wraps yaw and keeps preference writes disabled in isolated QA")
	game.set_camera_settings(2.5,38,145)
	_place_hero()

func _place_hero() -> void:
	game.hero.reset_to(Vector3(0,0,1.7))
	game.hero.face_direction(Vector3.FORWARD)
	game._set_target(fixtures[0])

func _effect_count() -> int:
	var count: int = 0
	for child: Node in game.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("fire_impact.gd") and not child.is_queued_for_deletion():
			count += 1
	return count

func _descendants(node: Node) -> int:
	var count: int = node.get_child_count()
	for child: Node in node.get_children():
		count += _descendants(child)
	return count

func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame

func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)

func _mouse(point: Vector2,pressed: bool,device_id: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.device = device_id
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = point
	event.global_position = point
	event.pressed = pressed
	Input.parse_input_event(event)

func _motion(point: Vector2,relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)

func _touch(point: Vector2,pressed: bool,index: int,canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)

func _drag(point: Vector2,index: int) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	Input.parse_input_event(event)

func _capture(filename: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	game.hud.toast_timer = 0.0
	game.hud.toast_panel.hide()
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(capture_dir.path_join(filename+".png")) == OK,"saved actual fire render "+filename)

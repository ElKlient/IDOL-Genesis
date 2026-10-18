extends SceneTree
## Actual inventory renderer/input regression. No player-save writes or telemetry.
var game: Node3D
var state: Node
var preview: Control
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
		push_error("Supply --test-isolated; never run preview QA against a player's save.")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	var save_exists: bool = FileAccess.file_exists(state.SAVE_PATH)
	var save_before: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if save_exists else PackedByteArray()
	_check(not state.save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"preview QA disables player saving and diagnostic networking")
	state.new_game()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _frames(4)
	game.hud.open_panel("inventory")
	await _frames(5)
	preview = game.hud.character_preview
	if not is_instance_valid(preview):
		_check(false,"inventory creates its live preview")
		quit(1)
		return
	var instance: int = preview.get_instance_id()
	var viewport_id: int = preview.preview_viewport.get_instance_id()
	_check(preview.preview_active and preview.preview_viewport.own_world_3d and preview.preview_model != game.hero.visual,"inventory renders an independent animated character instead of moving the playable hero")
	_check(preview.preview_viewport.size == Vector2i(512,512) and preview.preview_viewport.msaa_3d == Viewport.MSAA_DISABLED,"portrait uses the bounded 512-square renderer without MSAA allocation")
	var ticks: int = preview.visual_tick_count
	var renders: int = preview.render_request_count
	await create_timer(0.55).timeout
	_check(preview.visual_tick_count > ticks and preview.visual_tick_count <= ticks+20 and preview.render_request_count-renders <= 20,"visible preview animates and requests rendering at at most 30 Hz")
	var serial: int = game._attack_serial
	var hero_position: Vector3 = game.hero.position
	var point: Vector2 = preview.get_global_rect().get_center()
	var yaw: float = preview.preview_yaw
	_mouse(point,true)
	await process_frame
	_motion(point+Vector2(70,0),Vector2(70,0),true)
	await process_frame
	_mouse(point+Vector2(70,0),false)
	await _frames(3)
	_check(absf(wrapf(preview.preview_yaw-yaw,-180,180)) > 15 and not preview.mouse_dragging,"real mouse drag rotates the inventory model and releases outside its initial point")
	_touch(point,true,4)
	await process_frame
	yaw = preview.preview_yaw
	_touch(point,true,5)
	_drag(point+Vector2(40,0),5)
	await process_frame
	_check(preview.touch_id == 4 and is_equal_approx(preview.preview_yaw,yaw),"a second touch cannot steal the model's active rotation finger")
	_drag(point+Vector2(35,0),4)
	await process_frame
	var touch_yaw: float = preview.preview_yaw
	_mouse(point,true,-1)
	_motion(point+Vector2(100,0),Vector2(100,0),true,-1)
	_mouse(point,false,-1)
	await process_frame
	_check(absf(wrapf(touch_yaw-yaw,-180,180)) > 5 and is_equal_approx(preview.preview_yaw,touch_yaw),"real touch rotates once while emulated mouse events cannot double its movement")
	_touch(point,false,4,true)
	await process_frame
	_check(preview.touch_id == -1 and not preview.mouse_dragging,"cancelled touch releases the preview rotation gesture")
	_check(game._attack_serial == serial and game.hero.position.distance_to(hero_position) < 0.02 and not game.hud.attack_held,"preview gestures stay inside the modal and cannot attack or move the live hero")
	await create_timer(0.28).timeout
	await _click("PreviewRun")
	await create_timer(0.35).timeout
	_check(preview.animation_mode == "run" and preview.preview_model.locomotion_blend > 0.5,"actual BIEG button drives the model's running animation")
	await _click("PreviewIdle")
	await create_timer(0.20).timeout
	_check(preview.animation_mode == "idle","actual POSTÓJ button returns to idle")
	await _click("PreviewAttack")
	_check(preview.preview_model.is_attacking(),"actual CIOS button starts an attack in the portrait")
	await create_timer(0.7).timeout
	await _click("PreviewRotateRight")
	_check(not is_equal_approx(preview.preview_yaw,touch_yaw),"rotation button turns the same live model")
	await _click("PreviewReset")
	_check(is_zero_approx(preview.preview_yaw),"RESET button restores the front view")
	preview.set_preview_yaw(63)
	state.buy("dawn_sword")
	var sword_uid: int = int(state.inventory.back().uid)
	state.find_item(sword_uid).upgrade = 5
	state.equip(sword_uid)
	state.buy("dawn_armor")
	state.equip(int(state.inventory.back().uid))
	await _frames(6)
	_check(game.hud.character_preview.get_instance_id() == instance and preview.preview_viewport.get_instance_id() == viewport_id and is_equal_approx(preview.preview_yaw,63),"equipping and rebuilding cards preserve the portrait, viewport and chosen yaw")
	_check(preview.preview_model.weapon_tier == 3 and preview.preview_model.armor_tier == 3 and preview.preview_model.upgrade_level == 5,"portrait immediately mirrors the equipped third armor, sword and upgrade level")
	for width: int in [1280,1600]:
		root.size = Vector2i(width,720)
		await _frames(6)
		var visible: Rect2 = root.get_visible_rect()
		_check(visible.encloses(game.hud.modal.get_global_rect()) and game.hud.modal.get_global_rect().encloses(preview.get_global_rect()),"inventory and portrait fit landscape viewport %d x 720" % width)
		preview.set_preview_yaw(0)
		await create_timer(0.15).timeout
		await _capture("inventory-live-%dx720" % width)
	# The same large sword/armor must remain inside the portrait through a full
	# rotation and through every contact pose. Rigid mesh vertices avoid empty
	# AABB corners around a curved blade; warrior_model.gd also skins the body.
	preview.set_process(false)
	preview.preview_model.attack_elapsed = -1
	var framed: bool = true
	for angle: int in range(0,360,30):
		preview.set_preview_yaw(angle)
		preview.preview_model.tick(0,0)
		framed = framed and _model_framed()
	_check(framed,"full tier-three equipment fits the portrait throughout a full 360-degree rotation")
	for attack: int in range(4):
		var full_swing_framed: bool = true
		for angle: int in range(0,360,45):
			preview.set_preview_yaw(angle)
			for sample: int in range(11):
				preview.preview_model.attack_elapsed = -1
				preview.preview_model.tick(1,0)
				preview.preview_model.start_attack(attack,false)
				preview.preview_model.tick(preview.preview_model.attack_duration*float(sample)/10.0,0)
				preview.update_framing(0)
				full_swing_framed = full_swing_framed and _model_framed()
		_check(full_swing_framed,"portrait frames the entire swing %d at eleven animation times and eight viewing angles" % (attack+1))
		preview.preview_model.tick(1,0)
	preview.set_process(true)
	for cycle: int in range(8):
		game.hud.open_panel("settings")
		await _frames(3)
		game.hud.open_panel("inventory")
		await _frames(3)
	_check(game.hud.character_preview.get_instance_id() == instance and preview.preview_viewport.get_instance_id() == viewport_id and _preview_count(game) == 1,"repeated panel switches retain exactly one character preview and one viewport")
	_touch(preview.get_global_rect().get_center(),true,7)
	await process_frame
	game.hud.close_panel()
	await _frames(4)
	ticks = preview.visual_tick_count
	renders = preview.render_request_count
	await create_timer(0.30).timeout
	_check(not preview.preview_active and preview.touch_id == -1 and not preview.is_processing() and preview.preview_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,"closing inventory cancels touch and disables the portrait's process and renderer")
	_check(preview.visual_tick_count == ticks and preview.render_request_count == renders,"hidden portrait performs no animation ticks or render requests")
	_check(FileAccess.file_exists(state.SAVE_PATH) == save_exists and (not save_exists or FileAccess.get_file_as_bytes(state.SAVE_PATH) == save_before),"preview, equipment and modal QA preserve any existing player-save bytes")
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("CHARACTER PREVIEW RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _model_framed() -> bool:
	var model: Node3D = preview.preview_model
	var camera: Camera3D = preview.preview_camera
	var viewport_rect: Rect2 = Rect2(Vector2(1,1),Vector2(preview.preview_viewport.size)-Vector2(2,2))
	for part: Node in model.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree() or part.mesh == null:
			continue
		if part.skin == null:
			for surface: int in range(part.mesh.get_surface_count()):
				var arrays: Array = part.mesh.surface_get_arrays(surface)
				for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
					var p: Vector3 = part.to_global(vertex)
					if camera.is_position_behind(p) or not viewport_rect.has_point(camera.unproject_position(p)):
						print("PORTRAIT FRAME outside: ",part.name," at ",camera.unproject_position(p))
						return false
		else:
			var bounds: AABB = part.get_aabb()
			for corner: int in range(8):
				var p: Vector3 = part.to_global(bounds.get_endpoint(corner))
				if camera.is_position_behind(p) or not viewport_rect.has_point(camera.unproject_position(p)):
					print("PORTRAIT FRAME outside: ",part.name," at ",camera.unproject_position(p))
					return false
	return true

func _preview_count(node: Node) -> int:
	var count: int = 1 if node.get_script() != null and node.get_script().resource_path.ends_with("character_preview.gd") else 0
	for child: Node in node.get_children():
		count += _preview_count(child)
	return count

func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame

func _click(node_name: String) -> void:
	var button: Button = game.hud.modal.find_child(node_name,true,false)
	_check(is_instance_valid(button) and button.is_visible_in_tree(),"inventory exposes button "+node_name)
	if not is_instance_valid(button):
		return
	var point: Vector2 = button.get_global_rect().get_center()
	_motion(point)
	_mouse(point,true)
	await process_frame
	_mouse(point,false)
	await _frames(4)

func _mouse(point: Vector2,pressed: bool,device_id: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.device = device_id
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = point
	event.global_position = point
	event.pressed = pressed
	Input.parse_input_event(event)

func _motion(point: Vector2,relative: Vector2 = Vector2.ZERO,held: bool = false,device_id: int = 0) -> void:
	var event := InputEventMouseMotion.new()
	event.device = device_id
	event.position = point
	event.global_position = point
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
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
	_check(root.get_texture().get_image().save_png(capture_dir.path_join(filename+".png")) == OK,"saved real rendered portrait "+filename)

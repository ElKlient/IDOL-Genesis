extends SceneTree
## Actual game screenshots; isolated demonstration equipment, no save/network.
var game: Node3D
var output: String = ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			output = arg.trim_prefix("--capture-dir=")
	if output.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,720)
	var state: Node = root.get_node("GameState")
	state.new_game()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for enemy: Node in game.enemies:
		enemy.set_physics_process(false)
	state.buy("dawn_sword")
	state.equip(int(state.inventory.back().uid))
	state.buy("dawn_armor")
	state.equip(int(state.inventory.back().uid))
	game.set_camera_settings(2.10,38.0,155.0)
	game.hero.reset_to(Vector3(.6,0,3.0))
	await _shot("valley-village-0.2.2")
	game.hero.reset_to(Vector3(-1,0,-25.0))
	game.set_camera_settings(1.75,38.0,125.0)
	await _shot("valley-forest-0.2.2")
	game.hero.reset_to(Vector3(-13.6,0,-22.3))
	game.set_camera_settings(1.55,40.0,-40.0)
	await _shot("valley-pond-0.2.2")
	game.hero.reset_to(Vector3(0,0,3.0))
	game.set_camera_settings(2.5,38.0,155.0)
	game.hero.visual.set_sword_flame(true)
	await _shot("valley-warrior-0.2.2")
	game.queue_free()
	await process_frame
	quit()

func _shot(filename: String) -> void:
	await create_timer(.6).timeout
	game.hud.toast_timer = 0.0
	game.hud.toast_panel.hide()
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(output.path_join(filename+".png"))
	if result != OK:
		push_error("Could not save graphics capture: "+filename)
	print("CAPTURE "+filename)

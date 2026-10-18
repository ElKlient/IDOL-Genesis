extends SceneTree
## Render screenshots with a real display (or Xvfb), never --headless.
## godot --path . --script res://tests/capture_preview.gd -- --test-isolated --capture-dir=/tmp/preview
var game: Node3D
var state: Node
var output_dir: String = ""

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		push_error("Refusing screenshot setup without --test-isolated.")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			output_dir = arg.trim_prefix("--capture-dir=")
	if output_dir.is_empty():
		push_error("Supply --capture-dir=/absolute/output/path")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	state = root.get_node("GameState")
	state.new_game()
	var scene: PackedScene = load("res://main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(1.2).timeout
	await _shot("01-village")
	game.hero.reset_to(game.world.npc_positions.merchant + Vector3(0,0,1.4))
	await create_timer(0.8).timeout
	game.interact()
	game.hud._select_catalog("iron_sword")
	await create_timer(0.25).timeout
	await _shot("02-merchant")
	game._close_modal()
	state.buy("hunter_sword")
	state.equip(int(state.inventory.back().uid))
	state.upgrade_item(state.weapon_uid)
	state.buy("guard_armor")
	state.equip(int(state.inventory.back().uid))
	game.hud.selected_uid = state.weapon_uid
	game.hero.reset_to(game.world.npc_positions.blacksmith + Vector3(0,0,1.4))
	await create_timer(0.8).timeout
	game.interact()
	await create_timer(0.25).timeout
	await _shot("03-blacksmith")
	game._close_modal()
	game.hud.open_panel("inventory")
	await create_timer(0.25).timeout
	await _shot("04-inventory")
	game._close_modal()
	var victim: Node3D = game.enemies[0]
	for enemy: Node3D in game.enemies:
		if enemy.kind == 0:
			victim = enemy
			break
	game.hero.reset_to(victim.position + Vector3(0,0,2.0))
	game._set_target(victim)
	await create_timer(0.8).timeout
	game.request_attack()
	await create_timer(0.12).timeout
	await _shot("05-combat")
	game.hero.reset_to(game.world.spawn_position)
	game._set_target(null)
	root.size = Vector2i(1600,720)
	await create_timer(0.8).timeout
	await _shot("06-wide-village")
	print("CAPTURE RESULT: saved village, merchant, blacksmith, inventory, combat and wide-phone previews to " + output_dir)
	game.queue_free()
	await process_frame
	quit()

func _shot(filename: String) -> void:
	game.hud.toast_timer = 0.0
	game.hud.toast_panel.hide()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png(output_dir.path_join(filename + ".png"))
	if result != OK:
		push_error("Screenshot failed: %s (%d)" % [filename,result])
	else:
		print("CAPTURE: " + filename)

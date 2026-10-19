extends SceneTree
## Actual controller, hit timers, audio and player physics at fixed 30 FPS.
## Only enemy AI is stopped. Isolated state prevents saves and diagnostics.
var game: Node3D
var output: String = ""
var hits: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): output = arg.trim_prefix("--capture-dir=")
	if output.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960,540)
	var state: Node = root.get_node("GameState")
	state.new_game()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for enemy: Node3D in game.enemies: enemy.set_physics_process(false)
	state.buy("iron_sword")
	state.equip(int(state.inventory.back().uid))
	state.buy("leather_armor")
	state.equip(int(state.inventory.back().uid))
	game.hero.reset_to(Vector3(0,0,3))
	game.hud.hide()
	game.camera.reparent(game)
	game.camera.fov = 36.0
	var focus: Vector3 = game.hero.position+Vector3(0,1.1,0)
	game.camera.position = focus+Vector3(4.7,2.7,-5.7)
	game.camera.look_at(focus)
	var victim: Node3D = game.enemies[0]
	victim.hp = 100000
	victim.max_hp = 100000
	victim.position = game.hero.position+Vector3(0,0,-1.7)
	victim.damaged.connect(func(_amount: int,_critical: bool) -> void: hits += 1)
	game._set_target(victim)
	var overlay: CanvasLayer = CanvasLayer.new()
	root.add_child(overlay)
	var title: Label = Label.new()
	title.position = Vector2(20,18)
	title.add_theme_font_size_override("font_size",25)
	title.add_theme_color_override("font_color",Color("ffe1a3"))
	title.add_theme_constant_override("outline_size",5)
	overlay.add_child(title)
	for speed: int in [100,150]:
		state.attack_speed_bonus = float(speed-100)
		game.combo = 0
		game.combo_time = 0.0
		var accepted: int = 0
		var phase_hits: int = hits
		for frame: int in range(210):
			title.text = ("RYTM BAZOWY · 100%" if speed == 100 else "PRÓBA BONUSU +50% · 150%")+"   |   CIOS %d / 4" % accepted
			if frame >= 15 and accepted < 4:
				var before: int = game._attack_serial
				game.request_attack()
				if game._attack_serial != before: accepted += 1
			await process_frame
			if frame == 30 or frame == 68:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("rhythm-%d-%03d.png" % [speed,frame]))
			if accepted == 4 and game.attack_cooldown <= 0.0 and not game.hero.visual.is_attacking():
				for tail: int in range(12): await process_frame
				break
		print("RHYTHM capture speed=%d accepted=%d hits=%d" % [speed,accepted,hits-phase_hits])
		if accepted != 4 or hits-phase_hits != 4:
			quit(1)
			return
	state.attack_speed_bonus = 0.0
	game.queue_free()
	overlay.queue_free()
	await process_frame
	print("CAPTURE ATTACK RHYTHM RESULT: actual controller, 4 hits at 100 and 4 hits at 150, 30 FPS")
	quit()

extends SceneTree
## Real game assets, fixed 60 Hz demonstration. No AI, rewards or networking.
## --write-movie /tmp/stance.avi --fixed-fps 60 -- --test-isolated --capture-dir=/tmp/stance
var game: Node3D
var output: String = ""

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
	root.size = Vector2i(1280,720)
	var state: Node = root.get_node("GameState")
	state.new_game()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.set_process(false)
	game.hero.set_physics_process(false)
	for enemy: Node in game.enemies: enemy.set_physics_process(false)
	state.buy("iron_sword")
	state.equip(int(state.inventory.back().uid))
	state.buy("leather_armor")
	state.equip(int(state.inventory.back().uid))
	game.hero.reset_to(Vector3(0,0,3))
	game.hud.hide()
	game.camera.reparent(game)
	game.camera.fov = 35.0
	if "--guard-review" in OS.get_cmdline_user_args() or "--guard-motion" in OS.get_cmdline_user_args():
		await _guard_review(state)
		return
	for frame: int in range(900):
		var time: float = frame/60.0
		var yaw: float = 150.0
		if time >= 2.0 and time < 4.0: yaw = 85.0
		elif time >= 4.0 and time < 6.0: yaw = 0.0
		var focus: Vector3 = game.hero.position+Vector3(0,1.0,0)
		game.camera.position = focus+Vector3(sin(deg_to_rad(yaw))*5.3,1.2,cos(deg_to_rad(yaw))*5.3)
		game.camera.look_at(focus)
		var moving: float = 1.0 if time >= 6.0 and time < 7.4 else 0.0
		if frame in [450,510,570,634]: game.hero.visual.start_attack([450,510,570,634].find(frame))
		if frame == 730: game.hero.visual.start_fire_slam()
		if frame == 810:
			game.hud.show()
			game.hud.open_panel("inventory")
		if frame < 810: game.hero.visual.tick(1.0/60.0,moving)
		await process_frame
		if frame in [90,210,330,470,668,850]:
			await RenderingServer.frame_post_draw
			var result: Error = root.get_texture().get_image().save_png(output.path_join("stance-%03d.png" % frame))
			if result != OK: push_error("Stance capture failed")
	print("CAPTURE STANCE RESULT: 15 seconds, front/side/back, run, four cuts, fire slam, inventory portrait")
	game.queue_free()
	await process_frame
	quit()

func _guard_review(state: Node) -> void:
	# Fast actual-world stills for the raised guard, including the largest set.
	state.buy("dawn_sword")
	state.equip(int(state.inventory.back().uid))
	state.buy("dawn_armor")
	state.equip(int(state.inventory.back().uid))
	game.hero.visual.tick(1.0,0.0)
	if "--guard-motion" in OS.get_cmdline_user_args():
		# Short 30-Hz timing review; actual assets and unchanged game lighting.
		root.size = Vector2i(640,360)
		var focus: Vector3 = game.hero.position+Vector3(0,1.15,0)
		game.camera.position = focus+Vector3(2.65,1.2,-4.59)
		game.camera.look_at(focus)
		for frame: int in range(90):
			if frame == 18: game.hero.visual.start_attack(1)
			if frame == 50: game.hero.visual.start_attack(3)
			game.hero.visual.tick(1.0/30.0,0.0)
			await process_frame
		print("CAPTURE GUARD MOTION RESULT: 3 seconds at 30 Hz, second cut, finisher and guard")
		game.queue_free()
		await process_frame
		quit()
		return
	for view: String in ["front","side","gameplay","inventory"]:
		var focus: Vector3 = game.hero.position+Vector3(0,1.15,0)
		var offset: Vector3 = Vector3(2.65,1.2,-4.59)
		if view == "side": offset = Vector3(5.3,1.2,0)
		elif view == "gameplay": offset = Vector3(0,5.8,-5.8)
		game.camera.position = focus+offset
		game.camera.look_at(focus)
		if view == "inventory":
			game.hud.show()
			game.hud.open_panel("inventory")
		for frame: int in range(4):
			game.hero.visual.tick(1.0/60.0,0.0)
			await process_frame
		await RenderingServer.frame_post_draw
		var result: Error = root.get_texture().get_image().save_png(output.path_join("guard-"+view+".png"))
		if result != OK: push_error("Guard capture failed")
	print("CAPTURE GUARD RESULT: actual tier-three front, side, elevated gameplay view and inventory")
	game.queue_free()
	await process_frame
	quit()

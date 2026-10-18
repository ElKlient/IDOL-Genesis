extends SceneTree
## Real main attack path, enemy physics and camera regression. No player save/network writes.
const EnemyScript = preload("res://scripts/enemy.gd")
var game: Node3D
var enemy: CharacterBody3D
var state: Node
var checks: int = 0
var failures: int = 0
var hits: int = 0
var deaths: int = 0
var enemy_attacks: int = 0
var capture_dir: String = ""

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		push_error("Refusing combat test without --test-isolated.")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	var save_exists: bool = FileAccess.file_exists(state.SAVE_PATH)
	var save_before: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if save_exists else PackedByteArray()
	_check(not state.save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"combat regression disables player saving and diagnostic networking")
	state.new_game()
	var scene: PackedScene = load("res://main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	for other: Node3D in game.enemies:
		other.set_physics_process(false)
	# Independent real enemy fixture avoids production respawn timers. Existing
	# integration.gd covers full spawned-enemy reward/respawn signal wiring.
	enemy = EnemyScript.new()
	enemy.setup(0,game.hero)
	game.add_child(enemy)
	game.enemies.append(enemy)
	enemy.max_hp = 10000
	enemy.hp = 10000
	enemy.damaged.connect(func(_amount: int,_critical: bool) -> void: hits += 1)
	enemy.struck_player.connect(func(_amount: int) -> void: enemy_attacks += 1)
	enemy.defeated.connect(func(dead_enemy: Node3D) -> void:
		deaths += 1
		state.gain_reward(dead_enemy.reward_gold,dead_enemy.reward_xp)
	)
	_place_enemy()
	await _physics(3)
	for step: int in range(1,5):
		await _cooldown()
		var hp_before: int = enemy.hp
		var hits_before: int = hits
		var position_before: Vector3 = enemy.position
		game.request_attack()
		_check(game.combo == step and game.hero.visual.combo_index == step-1,"combo step %d selects its distinct animation index" % step)
		var serial: int = game._attack_serial
		var cooldown: float = game.attack_cooldown
		game.request_attack()
		_check(game._attack_serial == serial and game.combo == step and game.attack_cooldown == cooldown,"cooldown rejects duplicate request for combo step %d" % step)
		await _physics(3)
		_check(hits == hits_before and enemy.hp == hp_before,"combo step %d does not damage before sword contact" % step)
		await _wait_hits(hits_before+1)
		_check(hits == hits_before+1 and enemy.hp < hp_before,"combo step %d deals exactly one real contact hit" % step)
		if step < 4:
			_check(enemy._knockback_velocity.length() < 0.001 and enemy.position.distance_to(position_before) < 0.05,"combo step %d causes no finisher impulse" % step)
		else:
			var speed: float = enemy._knockback_velocity.length()
			_check(speed > 6.0 and enemy._stagger_time > 0.25,"fourth hit applies the finisher impulse and stagger")
			enemy._clock = 20.0
			await _physics(6)
			_check(enemy._knockback_velocity.length() < speed and enemy.position.distance_to(position_before) > 0.2,"finisher moves the real body while its impulse decays")
			await _physics(30)
			_check(enemy._knockback_velocity.length() < 0.01 and enemy._stagger_time <= 0.0,"finisher impulse and stagger expire naturally")
	await create_timer(1.25).timeout
	_check(game.combo == 0,"combo resets after the real 1.2-second inactivity timeout")
	_place_enemy()
	game.request_attack()
	_check(game.combo == 1,"attack after timeout restarts at the first strike")
	await _wait_hits(hits+1)
	await _cooldown()
	# Range is checked at contact, not only when attack input is accepted.
	var before_hits: int = hits
	var before_hp: int = enemy.hp
	game.request_attack()
	enemy.position.z = -6.0
	enemy._spawn = enemy.position
	await create_timer(0.3).timeout
	_check(hits == before_hits and enemy.hp == before_hp,"moving out of range during windup prevents damage")
	await _cooldown()
	_place_enemy()
	game.request_attack()
	game.hud.open_panel("inventory")
	await _physics(2)
	var blocked_serial: int = game._attack_serial
	game.request_attack()
	_check(game._attack_serial == blocked_serial and game.combo == 0,"modal blocks new attacks and resets the active combo")
	game.hud.close_panel()
	await create_timer(0.3).timeout
	_check(hits == before_hits and enemy.hp == before_hp,"closing a modal does not revive its cancelled pending hit")
	await _cooldown()
	game.hero.dead = true
	game.request_attack()
	_check(game._attack_serial == blocked_serial,"dead warrior cannot start a new attack")
	game.hero.dead = false
	# Direct enemy physics tests isolate interruption and wall collision.
	_place_enemy()
	enemy._mode = EnemyScript.Mode.WINDUP
	enemy._clock = 0.4
	enemy._warning_ring.show()
	var before_enemy_attacks: int = enemy_attacks
	enemy.apply_knockback(Vector3.RIGHT,7.5)
	_check(enemy._mode == EnemyScript.Mode.RECOVER and not enemy._warning_ring.visible and enemy._stagger_time > 0.0,"knockback immediately interrupts enemy WINDUP and hides its attack warning")
	enemy._clock = 20.0
	await _physics(24)
	_check(enemy_attacks == before_enemy_attacks,"interrupted enemy windup emits no delayed player damage")
	_place_enemy()
	var wall: StaticBody3D = StaticBody3D.new()
	wall.position = Vector3(1.4,1.5,0)
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collider: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.4,3,5)
	collider.shape = box
	wall.add_child(collider)
	game.add_child(wall)
	await _physics(2)
	enemy.apply_knockback(Vector3.RIGHT,7.5)
	enemy._clock = 20.0
	await _physics(30)
	_check(enemy.position.x > 0.3 and enemy.position.x < 0.91,"real collision solver stops knockback before the wall instead of teleporting through it")
	_check(enemy._knockback_velocity.length() < 0.01,"wall collision discards the blocked impulse")
	wall.queue_free()
	await process_frame
	# Only one defeat signal may pay rewards, even with additional damage/push calls.
	_place_enemy()
	var gold_before: int = state.gold
	var xp_before: int = state.xp
	enemy.take_damage(enemy.hp+1)
	enemy.take_damage(1000)
	enemy.apply_knockback(Vector3.FORWARD,7.5)
	_check(deaths == 1 and state.gold == gold_before+enemy.reward_gold and state.xp == xp_before+enemy.reward_xp,"dead enemy emits one defeat and awards its reward once")
	_check(enemy._knockback_velocity == Vector3.ZERO and enemy._stagger_time == 0.0,"dead enemy rejects impulses and retains no stagger")
	var dead_hits: int = hits
	game.request_attack()
	await create_timer(0.35).timeout
	_check(hits == dead_hits and deaths == 1 and state.gold == gold_before+enemy.reward_gold,"normal attack cannot hit a dead target or duplicate its reward")
	game.enemies.erase(enemy)
	game._set_target(null)
	enemy.queue_free()
	await _camera_follow()
	await _visual_poses()
	_check(FileAccess.file_exists(state.SAVE_PATH) == save_exists and (not save_exists or FileAccess.get_file_as_bytes(state.SAVE_PATH) == save_before),"combat regression leaves existing player save bytes unchanged")
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("COMBAT COMBO RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _place_enemy() -> void:
	enemy.position = Vector3.ZERO
	enemy._spawn = enemy.position
	enemy.velocity = Vector3.ZERO
	enemy._knockback_velocity = Vector3.ZERO
	enemy._stagger_time = 0.0
	enemy._mode = EnemyScript.Mode.RECOVER
	enemy._clock = 20.0
	game.hero.reset_to(Vector3(0,0,1.7))
	game._set_target(enemy)

func _wait_hits(expected: int) -> void:
	var started: int = Time.get_ticks_msec()
	while hits < expected and Time.get_ticks_msec()-started < 2000:
		await physics_frame

func _cooldown() -> void:
	while game.attack_cooldown > 0.0:
		await physics_frame

func _physics(count: int) -> void:
	for _index: int in range(count):
		await physics_frame

func _camera_follow() -> void:
	game.hero.reset_to(Vector3(0,0,5))
	game.hud.joystick.vector = Vector2.RIGHT
	await create_timer(0.25).timeout
	await create_timer(0.0).timeout
	_check(game.camera_pivot.position.distance_to(game.hero.position+game.CAMERA_FOCUS) < 0.001,"camera focus follows current moving hero without interpolation lag")
	game.hud.joystick.vector = Vector2.ZERO
	await create_timer(0.25).timeout
	_check(game.camera_pivot.position.distance_to(game.hero.position+game.CAMERA_FOCUS) < 0.001,"camera retains its exact focus offset after movement stops")
	game.hero.reset_to(Vector3(2,0,4))
	await create_timer(0.0).timeout
	_check(game.camera_pivot.position.distance_to(game.hero.position+game.CAMERA_FOCUS) < 0.001,"camera follows a teleport on the next update without trailing")

func _visual_poses() -> void:
	game.hero.set_physics_process(false)
	game.hero.reset_to(Vector3(0,0,2))
	game.hero.face_direction(Vector3.FORWARD)
	game.hero.visual.rotation.y = 0.0
	game.set_camera_settings(2.5,38.0,145.0)
	state.buy("hunter_sword")
	state.equip(int(state.inventory.back().uid))
	state.buy("dawn_armor")
	state.equip(int(state.inventory.back().uid))
	await _physics(3)
	await process_frame
	var visual: Node3D = game.hero.visual
	visual.start_attack(0,true)
	visual.tick(0.68,0.0)
	visual.start_attack(0,false)
	visual.tick(0.04,0.0)
	_check(absf(wrapf(visual.body.rotation.y,-PI,PI)) < 0.2,"normal strike after a full skill spin does not interpolate backwards around a full turn")
	visual.attack_elapsed = -1.0
	visual.tick(0.0,0.0)
	var idle_position: Vector3 = visual.body.position
	var idle_rotation: Vector3 = visual.torso.rotation
	visual.tick(0.5,0.0)
	var breath_changes: bool = visual.body.position.distance_to(idle_position) > 0.0001 or visual.torso.rotation.distance_to(idle_rotation) > 0.0001
	visual.tick(12.0,0.0)
	_check(breath_changes and visual.body.position.length() < 0.03 and visual.torso.rotation.length() < 0.1,"idle breath changes the resting pose while remaining bounded without accumulated drift")
	await _capture("00-idle")
	var poses: Array[String] = []
	for index: int in range(4):
		visual.start_attack(index,false)
		visual.tick(0.16 if index < 3 else 0.25,0.0)
		_check(visual.combo_index == index,"visual contact sample retains strike index %d" % (index+1))
		var tip: Vector3 = visual.to_local(visual.sword.to_global(Vector3(0,-1.2,0)))
		_check(tip.z < -0.8 and tip.y > 0.35,"strike %d places the actual blade in front of the warrior above ground" % (index+1))
		poses.append("%s|%s|%s" % [visual.body.rotation,visual.right_arm.rotation,visual.sword.rotation])
		await _capture("0%d-strike-%d" % [index+1,index+1])
		visual.tick(1.0,0.0)
		_check(not visual.is_attacking(),"strike %d recovers to idle after its duration" % (index+1))
	var unique: Dictionary = {}
	for pose: String in poses:
		unique[pose] = true
	_check(unique.size() == 4,"four contact poses produce distinct body, arm and sword transforms")

func _capture(name: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	game.hud.toast_timer = 0.0
	game.hud.toast_panel.hide()
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(capture_dir.path_join(name+".png")) == OK,"actual OpenGL pose capture saved: "+name)

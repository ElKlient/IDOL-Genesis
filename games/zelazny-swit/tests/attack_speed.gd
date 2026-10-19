extends SceneTree
## Real controller, timer, audio and visual clocks. Isolated from saves/network.
const Timing = preload("res://scripts/attack_timing.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

class AudioProbe extends Node:
	var swings: Array[Dictionary] = []
	var contacts: Array[int] = []
	var event_order: int = 0
	func play_cut_swing(step: int) -> void:
		event_order += 1
		swings.append({"step":step,"at":Engine.get_physics_frames(),"order":event_order})
	func play_cut_hit(step: int,_boss: bool,_critical: bool) -> void:
		contacts.append(step)
	func play_sfx(_name: String) -> void:
		pass

var checks: int = 0
var failures: int = 0
var game: Node3D
var state: Node
var enemy: CharacterBody3D
var audio_probe: AudioProbe
var hits: Array[Dictionary] = []

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
		push_error("Supply --test-isolated; attack speed QA never writes player data.")
		quit(2)
		return
	state = root.get_node("GameState")
	var save_exists: bool = FileAccess.file_exists(state.SAVE_PATH)
	var save_before: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if save_exists else PackedByteArray()
	_check(not state.save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"attack-speed QA disables player saving and diagnostic networking")
	state.new_game()
	_check(state.attack_speed() == 100.0,"existing equipment starts at the authored 100 attack speed")
	state.attack_speed_bonus = 25.0
	state.equipped("weapon")["attack_speed_bonus"] = 30.0
	state.buy("leather_armor")
	state.equip(int(state.inventory.back().uid))
	state.equipped("armor")["attack_speed_bonus"] = 20.0
	_check(state.attack_speed() == 175.0,"runtime, weapon and armor speed contributions add through the real stat API")
	state.attack_speed_bonus = 1000.0
	_check(state.attack_speed() == 200.0,"oversized positive speed is capped before playback")
	state.attack_speed_bonus = -1000.0
	_check(state.attack_speed() == 50.0,"negative speed is bounded before playback")
	state.attack_speed_bonus = NAN
	_check(state.attack_speed() == 100.0 and Timing.rate_from_speed(NAN) == 1.0,"non-finite speed safely restores ordinary playback")
	state.new_game()
	_check(state.attack_speed_bonus == 0.0 and state.attack_speed() == 100.0,"new adventure clears transient and fixture equipment bonuses")
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for other: Node3D in game.enemies:
		other.set_physics_process(false)
	enemy = EnemyScript.new()
	enemy.setup(0,game.hero)
	game.add_child(enemy)
	game.enemies.append(enemy)
	enemy.set_physics_process(false)
	enemy.max_hp = 100000
	enemy.hp = enemy.max_hp
	enemy.damaged.connect(func(amount: int,_critical: bool) -> void:
		audio_probe.event_order += 1
		hits.append({"at":Engine.get_physics_frames(),"amount":amount,"order":audio_probe.event_order,"visual_time":float(game.hero.visual.attack_elapsed)})
	)
	game.audio.queue_free()
	audio_probe = AudioProbe.new()
	game.audio = audio_probe
	game.add_child(audio_probe)
	# Resource construction can occupy the first process frame. Start probes
	# after that frame; timestamps below use simulated physics time so host
	# scheduling and startup catch-up are not mistaken for attack-speed bugs.
	await create_timer(0.25).timeout
	await _physics(3)
	for speed: int in [100,125,150,200]:
		for cut: int in range(4):
			await _one_attack(speed,cut)
	await _next_attack_uses_new_speed()
	for speed: int in [100,125,150,200]:
		for mode: int in range(4):
			await _cancel_attack(speed,mode)
	await _held_series()
	game.hud.open_panel("inventory")
	await _physics(3)
	var preview: Control = game.hud.character_preview
	state.attack_speed_bonus = 50.0
	preview.play_preview_attack()
	_check(preview.preview_model.is_attacking() and is_equal_approx(float(preview.preview_model.attack_rate),1.5),"inventory CIOS uses the same current attack-speed stat")
	state.attack_speed_bonus = 100.0
	_check(is_equal_approx(float(preview.preview_model.attack_rate),1.5),"changing speed leaves an already playing portrait cut on its accepted rate")
	game.hud.close_panel()
	state.attack_speed_bonus = 0.0
	_check(FileAccess.file_exists(state.SAVE_PATH) == save_exists and (not save_exists or FileAccess.get_file_as_bytes(state.SAVE_PATH) == save_before),"speed, cancellation, held input and preview tests preserve existing player-save bytes")
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("ATTACK SPEED RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _prepare(cut: int,speed: int) -> void:
	game._attack_serial += 1
	game.attack_cooldown = 0.0
	game.combo = cut
	game.combo_time = 5.0
	game.respawning = false
	game.hud.attack_held = false
	game.hero.reset_to(Vector3(0,0,1.7))
	game.hero.visual.attack_elapsed = -1.0
	game.hero.visual.contact_pause(0.0)
	game.hero.visual.tick(0.0,0.0)
	enemy.position = Vector3.ZERO
	enemy._spawn = enemy.position
	enemy._knockback_velocity = Vector3.ZERO
	enemy._stagger_time = 0.0
	game._set_target(enemy)
	state.attack_speed_bonus = float(speed-100)
	hits.clear()
	audio_probe.swings.clear()
	audio_probe.contacts.clear()
	audio_probe.event_order = 0

func _one_attack(speed: int,cut: int) -> void:
	_prepare(cut,speed)
	var rate: float = float(speed)/100.0
	var contact: float = Timing.contact_time(cut,rate)
	var started: int = Engine.get_physics_frames()
	var serial: int = game._attack_serial
	game.request_attack()
	serial += 1
	_check(game._attack_serial == serial and game.combo == cut+1 and is_equal_approx(float(game.hero.visual.attack_rate),rate),"%d speed cut %d accepts one shared playback snapshot" % [speed,cut+1])
	_check(is_equal_approx(game.attack_cooldown,Timing.cooldown(cut,rate)),"%d speed cut %d reserves recovery and contact-pause time" % [speed,cut+1])
	state.attack_speed_bonus = 100.0 if speed < 200 else 0.0
	game.request_attack()
	await _physics(maxi(1,floori(contact*0.60*float(Engine.physics_ticks_per_second))))
	_check(hits.is_empty() and game._attack_serial == serial and is_equal_approx(float(game.hero.visual.attack_rate),rate),"%d speed cut %d keeps anticipation, rejects restart and freezes its rate" % [speed,cut+1])
	await _wait_hits(1,1.0)
	var elapsed: float = float(int(hits[0].at)-started)/float(Engine.physics_ticks_per_second) if not hits.is_empty() else INF
	var swing_elapsed: float = float(int(audio_probe.swings[0].at)-started)/float(Engine.physics_ticks_per_second) if not audio_probe.swings.is_empty() else INF
	var frame_tolerance: float = 2.0/float(Engine.physics_ticks_per_second)+0.002
	_check(hits.size() == 1 and absf(elapsed-contact) < frame_tolerance,"%d speed cut %d deals its single hit at the scaled contact" % [speed,cut+1])
	_check(audio_probe.swings.size() == 1 and int(audio_probe.swings[0].step) == cut+1 and absf(swing_elapsed-Timing.swing_time(cut,rate)) < frame_tolerance and not hits.is_empty() and int(audio_probe.swings[0].order) < int(hits[0].order),"%d speed cut %d emits one accelerating-blade whoosh before contact" % [speed,cut+1])
	_check(not hits.is_empty() and absf(float(hits[0].visual_time)-contact) < frame_tolerance,"%d speed cut %d visual reaches the authored contact with the real hit" % [speed,cut+1])
	var cooldown: float = game.attack_cooldown
	game.attack_cooldown = 0.0
	game.request_attack()
	_check(game._attack_serial == serial,"%d speed cut %d recovery cannot be interrupted by another ordinary request" % [speed,cut+1])
	game.attack_cooldown = cooldown
	await _wait_ready()
	_check(hits.size() == 1 and audio_probe.contacts == [cut+1] and audio_probe.swings.size() == 1,"%d speed cut %d completes with no duplicate hit or sound" % [speed,cut+1])
	var cycle: float = float(Engine.get_physics_frames()-started)/float(Engine.physics_ticks_per_second)
	_check(absf(cycle-Timing.cooldown(cut,rate)) < frame_tolerance,"%d speed cut %d accelerates the complete recoverable cycle" % [speed,cut+1])
	print("SPEED speed=%d cut=%d contact=%.3fs swing=%.3fs cycle=%.3fs" % [speed,cut+1,elapsed,swing_elapsed,cycle])

func _next_attack_uses_new_speed() -> void:
	_prepare(0,100)
	game.request_attack()
	state.attack_speed_bonus = 100.0
	await _wait_ready()
	game.request_attack()
	_check(game.combo == 2 and is_equal_approx(float(game.hero.visual.attack_rate),2.0) and is_equal_approx(game.attack_cooldown,Timing.cooldown(1,2.0)),"speed gained during a cut is first applied to the next accepted combo step")
	game.hud.open_panel("settings")
	game.hud.close_panel()
	await _physics(ceili((Timing.contact_time(1,2.0)+0.10)*float(Engine.physics_ticks_per_second)))

func _cancel_attack(speed: int,mode: int) -> void:
	_prepare(mode,speed)
	var contact: float = Timing.contact_time(mode,float(speed)/100.0)
	game.request_attack()
	await _physics(maxi(1,floori(contact*0.25*float(Engine.physics_ticks_per_second))))
	match mode:
		0: game._attack_serial += 1
		1:
			game.hud.open_panel("settings")
			game.hud.close_panel()
		2: game.hero.dead = true
		3: game.respawning = true
	await _physics(ceili((contact+0.10)*float(Engine.physics_ticks_per_second)))
	if not hits.is_empty() or not audio_probe.swings.is_empty():
		print("CANCEL DETAIL speed=%d mode=%d hits=%s swings=%s" % [speed,mode,str(hits),str(audio_probe.swings)])
	_check(hits.is_empty() and audio_probe.swings.is_empty() and audio_probe.contacts.is_empty(),"%d speed cut %d cancellation suppresses its pending contact and whoosh" % [speed,mode+1])
	game.hero.dead = false
	game.respawning = false

func _held_series() -> void:
	_prepare(0,200)
	game.hud.attack_held = true
	var started: int = Engine.get_physics_frames()
	while hits.size() < 4 and Engine.get_physics_frames()-started < ceili(4.0*float(Engine.physics_ticks_per_second)):
		await physics_frame
	game.hud.attack_held = false
	await _wait_ready()
	print("HELD SERIES contacts=%s swings=%s" % [str(audio_probe.contacts),str(audio_probe.swings)])
	_check(hits.size() == 4 and audio_probe.contacts == [1,2,3,4],"held attack at 200 speed advances through all four real contacts exactly once")
	var correctly_ordered: bool = audio_probe.swings.size() == 4
	for index: int in range(audio_probe.swings.size()):
		correctly_ordered = correctly_ordered and int(audio_probe.swings[index].step) == index+1
	_check(correctly_ordered,"held attack preserves four ordered whooshes while speeding up the entire cycle")

func _wait_hits(expected: int,timeout: float) -> void:
	var started: int = Engine.get_physics_frames()
	while hits.size() < expected and Engine.get_physics_frames()-started < ceili(timeout*float(Engine.physics_ticks_per_second)):
		await physics_frame

func _wait_ready() -> void:
	var started: int = Engine.get_physics_frames()
	while (game.attack_cooldown > 0.0 or game.hero.visual.is_attacking()) and Engine.get_physics_frames()-started < ceili(3.0*float(Engine.physics_ticks_per_second)):
		await physics_frame
	_check(game.attack_cooldown <= 0.0 and not game.hero.visual.is_attacking(),"accepted cut completes its visual recovery within bounded time")

func _physics(count: int) -> void:
	for _frame: int in range(count):
		await physics_frame

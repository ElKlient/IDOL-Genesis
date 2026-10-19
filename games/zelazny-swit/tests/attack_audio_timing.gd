extends SceneTree
const Timing = preload("res://scripts/attack_timing.gd")
class AudioProbe extends Node:
	var swings: Array[int] = []
	func play_cut_swing(step: int) -> void:
		swings.append(step)
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool,label: String) -> void:
	checks += 1
	if ok:
		print("PASS: "+label)
	else:
		failures += 1
		push_error(label)
func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		quit(2)
		return
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.hero.set_physics_process(false)
	for enemy: Node3D in game.enemies:
		enemy.set_physics_process(false)
	game.audio.queue_free()
	game.audio = AudioProbe.new()
	game.add_child(game.audio)
	game._attack_serial = 5
	game._swing_after_windup(1,5)
	_check(game.audio.swings.is_empty(),"whoosh is not emitted at anticipation start")
	await create_timer(Timing.swing_time(0)+0.06).timeout
	_check(game.audio.swings == [1],"ordinary whoosh emitted once during acceleration")
	game._swing_after_windup(4,5)
	await create_timer(Timing.swing_time(0)-0.04).timeout
	_check(game.audio.swings == [1],"heavy whoosh waits beyond ordinary windup")
	await create_timer(Timing.swing_time(3)-Timing.swing_time(0)+0.10).timeout
	_check(game.audio.swings == [1,4],"heavy whoosh emitted once")
	game.audio.swings.clear()
	game._swing_after_windup(1,5)
	game._attack_serial = 6
	await create_timer(Timing.swing_time(0)+0.06).timeout
	_check(game.audio.swings.is_empty(),"serial cancellation suppresses pending whoosh")
	game._swing_after_windup(1,6)
	game.hud.modal_open = true
	await create_timer(Timing.swing_time(0)+0.06).timeout
	_check(game.audio.swings.is_empty(),"modal suppresses pending whoosh")
	game.hud.modal_open = false
	game._swing_after_windup(1,6)
	game.hero.dead = true
	await create_timer(Timing.swing_time(0)+0.06).timeout
	_check(game.audio.swings.is_empty(),"death suppresses pending whoosh")
	game.hero.dead = false
	game._swing_after_windup(1,6)
	game.respawning = true
	await create_timer(Timing.swing_time(0)+0.06).timeout
	_check(game.audio.swings.is_empty(),"respawn suppresses pending whoosh")
	game.queue_free()
	await process_frame
	print("Attack audio timing: %d/%d passed" % [checks-failures,checks])
	quit(0 if failures==0 else 1)

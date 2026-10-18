extends SceneTree
## Opposing/side joystick movement must not rotate a committed ordinary cut.
const HeroScript = preload("res://scripts/player.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS: "+label)
	else:
		failures += 1
		push_error("FAIL: "+label)

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		quit(2)
		return
	_check(not root.get_node("GameState").save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"isolated facing probe disables save/network")
	var hero := HeroScript.new()
	root.add_child(hero)
	hero.set_physics_process(false)
	for step: int in range(4):
		hero.move_input = Vector2.ZERO
		hero.velocity = Vector3.ZERO
		hero.face_direction(Vector3.FORWARD)
		hero.play_attack(step)
		var start := hero.position
		var stable: bool = true
		for frame: int in range(12):
			hero.move_input = Vector2(1,0) if frame < 6 else Vector2(0,1)
			hero._physics_process(1.0/60.0)
			stable = stable and hero.facing.distance_to(Vector3.FORWARD)<0.0001 and absf(hero.visual.rotation.y)<0.0001
		_check(stable,"cut %d keeps facing despite side/opposite joystick" % (step+1))
		_check(Vector2(hero.position.x-start.x,hero.position.z-start.z).length()>0.03,"cut %d retains reduced movement" % (step+1))
		for frame: int in range(70):
			hero._physics_process(1.0/60.0)
		_check(not hero.visual.is_attacking() and hero.facing.distance_to(Vector3.BACK)<0.0001,"cut %d restores steering after recovery" % (step+1))
	hero.queue_free()
	await process_frame
	print("Attack facing: %d/%d passed" % [checks-failures,checks])
	quit(0 if failures==0 else 1)

extends SceneTree
## Samples real sword transforms at 120 Hz. Isolated: no saves or network.
const Visual = preload("res://scripts/character_visual.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool,label: String) -> void:
	checks += 1
	if ok: print("PASS: "+label)
	else:
		failures += 1
		push_error("FAIL: "+label)
func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		quit(2)
		return
	_check(not root.get_node("GameState").save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"animation QA disables saving and telemetry")
	var actor: Node3D = Visual.new()
	root.add_child(actor)
	for tier: int in range(4):
		actor.set_equipment(tier,tier,0,0)
		for cut: int in range(4):
			actor.tick(1.0,0.0)
			actor.start_attack(cut)
			var last_tip: Vector3 = actor.sword.to_global(Vector3(0,-1.205,0))
			var last_axis: Vector3 = -actor.sword.global_basis.y.normalized()
			var last_rotation: Quaternion = actor.sword.global_basis.orthonormalized().get_rotation_quaternion()
			var max_roll_step: float = 0.0
			var max_jump: float = 0.0
			var max_angle: float = 0.0
			var finite: bool = true
			var max_grip: float = 0.0
			var minimum_tip: float = 100.0
			for frame: int in range(80):
				actor.tick(1.0/120.0,0.0)
				var tip: Vector3 = actor.sword.to_global(Vector3(0,-1.205,0))
				var axis: Vector3 = -actor.sword.global_basis.y.normalized()
				var rotation: Quaternion = actor.sword.global_basis.orthonormalized().get_rotation_quaternion()
				max_roll_step = maxf(max_roll_step,rad_to_deg(last_rotation.angle_to(rotation)))
				last_rotation = rotation
				finite = finite and tip.is_finite() and axis.is_finite()
				max_jump = maxf(max_jump,tip.distance_to(last_tip))
				max_angle = maxf(max_angle,rad_to_deg(axis.angle_to(last_axis)))
				minimum_tip = minf(minimum_tip,tip.y)
				if cut == 3 and actor.attack_elapsed >= 0.14 and actor.attack_elapsed <= 0.37:
					max_grip = maxf(max_grip,actor.left_wrist.global_position.distance_to(actor.sword.to_global(Vector3(0,-0.14,0))))
				last_tip = tip
				last_axis = axis
			print("ARC tier=%d cut=%d tip_step=%.4fm axis_step=%.2fdeg tip_floor=%.3fm grip=%.4fm basis_step=%.2fdeg" % [tier,cut+1,max_jump,max_angle,minimum_tip,max_grip,max_roll_step])
			_check(finite,"tier %d cut %d finite blade transforms" % [tier,cut+1])
			_check(max_jump/actor.sword.scale.y < 0.40 and max_angle < 18.0,"tier %d cut %d has no 120-Hz blade snap" % [tier,cut+1])
			_check(minimum_tip > -0.04,"tier %d cut %d blade avoids floor" % [tier,cut+1])
			_check(max_roll_step < 20.0,"tier %d cut %d blade roll stays continuous" % [tier,cut+1])
			if cut == 3: _check(max_grip < 0.015,"tier %d finisher support hand remains on hilt" % tier)
	actor.queue_free()
	await process_frame
	print("ANIMATION CONTINUITY RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

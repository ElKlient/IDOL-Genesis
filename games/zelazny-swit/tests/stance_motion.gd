extends SceneTree
## Actual control geometry over time; requires isolated state, no networking.
const Visual = preload("res://scripts/character_visual.gd")
const MotionProfile = preload("res://scripts/weapon_motion_profile.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _tip(actor: Node3D) -> Vector3:
	return actor.to_local(actor.sword.to_global(Vector3(0,-1.205,0)))

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		quit(2)
		return
	_check(not root.get_node("GameState").save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"stance QA isolates saves and telemetry")
	var actor: Node3D = Visual.new()
	root.add_child(actor)
	for tier: int in range(4):
		actor.set_equipment(tier,tier,0,0)
		actor.tick(1.0,0.0)
		var first_head: Vector3 = actor.to_local(actor.head.global_position)
		var left_anchor: Vector3 = actor.to_local(actor.left_ankle.global_position)
		var right_anchor: Vector3 = actor.to_local(actor.right_ankle.global_position)
		var largest_motion: float = 0.0
		var foot_drift: float = 0.0
		var min_clearance: float = 100.0
		var max_forward: float = -1.0
		var minimum_up: float = 1.0
		var minimum_camera_up: float = 1.0
		var finite: bool = true
		for frame: int in range(1440):
			actor.tick(1.0/120.0,0.0)
			var point: Vector3 = actor.to_local(actor.head.global_position)
			var direction: Vector3 = -actor.sword.global_basis.y.normalized()
			largest_motion = maxf(largest_motion,point.distance_to(first_head))
			foot_drift = maxf(foot_drift,actor.to_local(actor.left_ankle.global_position).distance_to(left_anchor))
			foot_drift = maxf(foot_drift,actor.to_local(actor.right_ankle.global_position).distance_to(right_anchor))
			min_clearance = minf(min_clearance,_tip(actor).y)
			max_forward = maxf(max_forward,direction.dot(Vector3.FORWARD))
			minimum_up = minf(minimum_up,direction.y)
			# A 45-degree elevated front camera can cancel equal upward and
			# forward components, making an apparently raised blade look flat.
			minimum_camera_up = minf(minimum_camera_up,direction.dot(Vector3(0,1,1).normalized()))
			finite = finite and point.is_finite() and direction.is_finite()
		print("STANCE tier=%d head_motion=%.4fm boot_drift=%.5fm blade_floor=%.3fm forward_dot=%.3f blade_y=%.3f" % [tier,largest_motion,foot_drift,min_clearance,max_forward,minimum_up])
		_check(finite,"tier %d finite idle geometry" % tier)
		_check(largest_motion > 0.002 and largest_motion < 0.065,"tier %d visible bounded breathing and weight shift" % tier)
		_check(foot_drift < 0.002,"tier %d planted boots over twelve seconds" % tier)
		_check(max_forward < cos(deg_to_rad(25.0)) and minimum_up > 0.45 and minimum_camera_up > 0.20,"tier %d raised guard stays upward in the elevated front view" % tier)
		_check(min_clearance > 0.10,"tier %d relaxed sword clears ground by ten centimetres" % tier)
		# Real start/recovery at 120 Hz, including running-to-idle and tier changes.
		for phase: int in range(6):
			if phase % 2 == 1:
				for frame: int in range(60): actor.tick(1.0/120.0,1.0)
			if phase < 4: actor.start_attack(phase)
			elif phase == 4: actor.start_fire_slam()
			else: actor.start_attack(0,true)
			var previous: Vector3 = _tip(actor)
			var finite_motion: bool = true
			var recovery_step: float = 0.0
			var recovery_approach: float = 0.0
			var endpoint_step: float = 0.0
			var duration: float = actor.attack_duration
			for frame: int in range(150):
				actor.tick(1.0/120.0,1.0 if frame < 20 and phase < 4 else 0.0)
				var point: Vector3 = _tip(actor)
				finite_motion = finite_motion and point.is_finite()
				if frame/120.0 > duration*0.90: recovery_step = maxf(recovery_step,point.distance_to(previous))
				if frame/120.0 > duration*0.70: recovery_approach = maxf(recovery_approach,point.distance_to(previous))
				if frame/120.0 >= duration: endpoint_step = maxf(endpoint_step,point.distance_to(previous))
				previous = point
			print("RECOVERY tier=%d action=%d return_step=%.4fm late_step=%.4fm endpoint=%.4fm" % [tier,phase,recovery_approach,recovery_step,endpoint_step])
			# Returning blade may still move quickly, but must decelerate near
			# completion. A completed action must join the live guard smoothly.
			# The spin is still intentionally rotating at 70% completion; only
			# ordinary/slam recovery is already in its slow return at that point.
			_check(finite_motion and (phase == 5 or recovery_approach < 0.20) and recovery_step < 0.08 and endpoint_step < 0.025,"tier %d action %d decelerates and joins live guard continuously" % [tier,phase])
		actor.tick(120.0,0.0)
		_check(actor.position == Vector3.ZERO and actor.body.position.length() < 0.08,"tier %d no accumulated root drift" % tier)
	var original_profile: Resource = actor.motion_profile
	var custom_profile: Resource = MotionProfile.new()
	custom_profile.carry_direction = Vector3(0.75,-0.5,-0.42)
	actor.tick(0.0,0.0)
	var original_axis: Vector3 = -actor.sword.global_basis.y.normalized()
	_check(actor.set_motion_profile(custom_profile),"valid custom weapon posture accepted")
	actor.tick(0.0,0.0)
	var custom_axis: Vector3 = -actor.sword.global_basis.y.normalized()
	_check(original_axis.angle_to(custom_axis) > 0.25,"custom posture changes actual carried blade orientation")
	var invalid_profile: Resource = MotionProfile.new()
	invalid_profile.carry_direction = Vector3.ZERO
	_check(not actor.set_motion_profile(invalid_profile) and actor.motion_profile == custom_profile,"zero-length weapon direction rejected without replacing active posture")
	_check(not actor.set_motion_profile(Resource.new()),"unrelated resources rejected")
	invalid_profile.carry_direction = Vector3.DOWN
	invalid_profile.breathing_blade_sway = Vector3.ONE
	_check(not actor.set_motion_profile(invalid_profile),"oversized breathing sway rejected before it can invert carried blade")
	actor.start_attack(0)
	_check(not actor.set_motion_profile(original_profile) and actor.motion_profile == custom_profile,"profile change during cut rejected without mutating active grip")
	actor.tick(1.0,0.0)
	_check(actor.set_motion_profile(original_profile),"original sword posture restored")
	actor.queue_free()
	await process_frame
	print("STANCE MOTION RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

extends SceneTree
## Independent bounded-impact and local contact-pause regression. Never sends diagnostics.
const HitEffectScript = preload("res://scripts/hit_effect.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const VisualScript = preload("res://scripts/character_visual.gd")
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
		push_error("FAIL: "+label)

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		push_error("Supply --test-isolated for impact QA.")
		quit(2)
		return
	var state: Node = root.get_node("GameState")
	_check(not state.save_enabled and not root.get_node("Diagnostics").is_network_enabled(), "impact QA disables player-save writes and diagnostic networking")
	var stage := Node3D.new()
	root.add_child(stage)
	var effects: Array[Node3D] = []
	for index: int in range(HitEffectScript.MAX_ACTIVE+1):
		var effect: Node3D = HitEffectScript.new()
		stage.add_child(effect)
		effects.append(effect)
	await process_frame
	_check(HitEffectScript.active_count == 0, "untriggered contact effects stay inactive")
	var ready: bool = true
	for effect: Node3D in effects:
		ready = ready and not effect.visible and not effect.is_processing() and effect.get_child_count() == 3
		for child: Node in effect.get_children():
			ready = ready and child is MultiMeshInstance3D and child.multimesh.instance_count <= 12
	_check(ready, "each dormant contact uses exactly three bounded batches and no animation processing")
	var accepted: int = 0
	for index: int in range(effects.size()):
		if effects[index].trigger(Vector3(index*0.1,0.8,0),Vector3.FORWARD,index%2==0,index%3==0,index%4==0):
			accepted += 1
	_check(accepted == HitEffectScript.MAX_ACTIVE and HitEffectScript.active_count == HitEffectScript.MAX_ACTIVE and not effects.back().running, "simultaneous contact effects enforce the eight-effect cap")
	var first: Node3D = effects[0]
	var ids: Array[int] = []
	for child: Node in first.get_children():
		ids.append(child.get_instance_id())
	var retriggered: bool = true
	for index: int in range(100):
		retriggered = retriggered and first.trigger(Vector3(0,0.8,0),Vector3.RIGHT,index%2==0)
		first._process(0.01)
	var same: bool = true
	for index: int in range(ids.size()):
		same = same and first.get_child(index).get_instance_id() == ids[index]
	_check(retriggered and same and first.get_child_count() == 3 and HitEffectScript.active_count == HitEffectScript.MAX_ACTIVE, "one hundred retriggers reuse the same three batches without incrementing the active count")
	var transforms_valid: bool = true
	for effect: Node3D in effects:
		if not effect.running:
			continue
		effect._process(0.07)
		for batch: MultiMeshInstance3D in effect.get_children():
			for index: int in range(batch.multimesh.instance_count):
				var transform: Transform3D = batch.multimesh.get_instance_transform(index)
				transforms_valid = transforms_valid and transform.is_finite() and transform.origin.length() < 4.0 and transform.basis.get_scale().length() < 5.0
	_check(transforms_valid, "all actual spark, flash and dust instance transforms stay finite and spatially bounded")
	var position_before: Vector3 = first.global_position
	stage.position = Vector3(8,3,-4)
	_check(first.is_set_as_top_level() and first.global_position.is_equal_approx(position_before), "contact flashes remain anchored in world space while their owning actor moves")
	for effect: Node3D in effects:
		effect._process(HitEffectScript.LIFETIME+0.01)
	var stopped: bool = HitEffectScript.active_count == 0
	for effect: Node3D in effects:
		stopped = stopped and not effect.running and not effect.visible and not effect.is_processing()
	_check(stopped, "every contact naturally expires, hides and stops processing with an exact zero active count")
	_check(not first.trigger(Vector3(INF,0,0),Vector3.FORWARD) and not first.trigger(Vector3.ZERO,Vector3(NAN,0,0)) and HitEffectScript.active_count == 0, "invalid contact coordinates are rejected without consuming the global effect budget")
	first.trigger(Vector3(0,0.8,0),Vector3.FORWARD)
	first.queue_free()
	await process_frame
	_check(HitEffectScript.active_count == 0, "freeing a currently active contact returns its budget slot")
	stage.queue_free()
	await process_frame
	var fixture := Node3D.new()
	root.add_child(fixture)
	var hero := CharacterBody3D.new()
	fixture.add_child(hero)
	var enemy: CharacterBody3D = EnemyScript.new()
	enemy.setup(0,hero)
	fixture.add_child(enemy)
	enemy.set_physics_process(false)
	var health: int = enemy.hp
	enemy.take_damage(3,false,Vector3.RIGHT,1)
	enemy._tick_visual(0.06)
	var flinched: bool = absf(enemy._visual.position.x)+absf(enemy._visual.position.z)+absf(enemy._visual.rotation.x)+absf(enemy._visual.rotation.z) > 0.01
	_check(enemy.hp == health-3 and flinched and enemy.position == Vector3.ZERO, "a directional hit changes the enemy's local reaction pose and deals damage exactly once")
	enemy._tick_visual(1.0)
	_check(absf(enemy._visual.position.x)+absf(enemy._visual.position.z)+absf(enemy._visual.rotation.x)+absf(enemy._visual.rotation.z) < 0.0001, "enemy contact reaction returns exactly to its neutral translation and tilt")
	var visual: Node3D = VisualScript.new()
	fixture.add_child(visual)
	await process_frame
	visual.start_attack(0,false)
	visual.tick(0.16,0.0)
	var elapsed: float = visual.attack_elapsed
	var time_scale: float = Engine.time_scale
	visual.contact_pause(0.028)
	visual.tick(0.02,0.0)
	_check(is_equal_approx(visual.attack_elapsed,elapsed) and Engine.time_scale == time_scale, "contact pause holds only the pose clock while global simulation time remains unchanged")
	visual.tick(0.03,0.0)
	_check(visual.attack_elapsed > elapsed, "contact animation resumes after the bounded local hold")
	visual.contact_pause(0.05)
	visual.cancel_fire_slam()
	_check(is_zero_approx(visual._contact_hold), "cancellation clears a pending visual contact hold")
	visual.contact_pause(INF)
	_check(is_zero_approx(visual._contact_hold), "nonfinite contact pauses cannot freeze the actor")
	fixture.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	_check(HitEffectScript.active_count == 0, "scene disposal leaves no active impact budget or orphaned effect processing")
	print("IMPACT HD RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

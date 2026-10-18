class_name WildEnemy
extends CharacterBody3D
## Small independent state machine: roam, chase, visible windup, recover and leash.
signal struck_player(amount: int)
signal defeated(enemy: Node3D)
signal damaged(amount: int, critical: bool)

enum Mode { ROAM, CHASE, WINDUP, RECOVER, RETURN }
var hero: CharacterBody3D
var frozen: bool = false
var kind: int = 0
var display_name: String = "Leśny wilk"
var level: int = 1
var max_hp: int = 70
var hp: int = 70
var reward_gold: int = 90
var reward_xp: int = 35
var _damage: int = 12
var _speed: float = 2.6
var _spawn: Vector3
var _mode: Mode = Mode.ROAM
var _clock: float = 1.0
var _roam_goal: Vector3
var _rng := RandomNumberGenerator.new()
var _visual: Node3D
var _head: Node3D
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _parts: Array[MeshInstance3D] = []
var _target_ring: MeshInstance3D
var _warning_ring: MeshInstance3D
var _health_root: Node3D
var _health_fill: MeshInstance3D
var _name_label: Label3D
var _flash_mat: StandardMaterial3D
var _phase: float = 0.0
var _flash: float = 0.0
var _damage_visibility: float = 0.0
var _targeted: bool = false
var _dying: bool = false
var _death_time: float = 0.0
var _attack_lunge: float = 0.0

func setup(type: int, target: CharacterBody3D) -> void:
	kind = clampi(type, 0, 2)
	hero = target
	match kind:
		0:
			display_name = "Leśny wilk"
			level = 1
			max_hp = 70
			reward_gold = 115
			reward_xp = 35
			_damage = 11
			_speed = 2.65
		1:
			display_name = "Rozjuszony dzik"
			level = 2
			max_hp = 130
			reward_gold = 190
			reward_xp = 60
			_damage = 16
			_speed = 2.35
		2:
			display_name = "Strażnik Korzeni"
			level = 4
			max_hp = 320
			reward_gold = 450
			reward_xp = 145
			_damage = 25
			_speed = 1.85
	hp = max_hp

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_spawn = global_position
	_roam_goal = _spawn
	_rng.randomize()
	_clock = _rng.randf_range(1.0, 3.0)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.55 if kind == 2 else 0.40
	shape.height = 2.55 if kind == 2 else 1.1
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	add_child(collision)
	_visual = Node3D.new()
	add_child(_visual)
	_visual.rotation.y = _rng.randf_range(-PI, PI)
	_flash_mat = _mat(Color(1.0, 0.62, 0.40, 0.76))
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if kind == 2:
		_build_guardian()
	else:
		_build_animal()
	_target_ring = _ring(0.72 if kind < 2 else 1.0, Color(1.0, 0.79, 0.23, 0.85), 0.018)
	_target_ring.visible = false
	_warning_ring = _ring(0.92 if kind < 2 else 1.23, Color(1.0, 0.19, 0.07, 0.72), 0.028)
	_warning_ring.visible = false
	_make_health_bar()

func _mat(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.metallic = metallic
	return material

func _part(parent: Node3D, mesh: Mesh, pos: Vector3, material: Material, size_scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = mesh
	result.material_override = material
	result.position = pos
	result.scale = size_scale
	parent.add_child(result)
	_parts.append(result)
	return result

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _part(parent, mesh, pos, mat)

func _ellipsoid(parent: Node3D, pos: Vector3, size_scale: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return _part(parent, mesh, pos, mat, size_scale)

func _cone(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 5
	return _part(parent, mesh, pos, mat)

func _segment(parent: Node3D, start: Vector3, end: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.75
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 6
	var result: MeshInstance3D = _part(parent, mesh, (start + end) * 0.5, mat)
	result.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return result

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var result := Node3D.new()
	result.position = pos
	parent.add_child(result)
	return result

func _build_animal() -> void:
	var fur: StandardMaterial3D = _mat(Color("607077") if kind == 0 else Color("684b3d"))
	var pale: StandardMaterial3D = _mat(Color("b7bcaf") if kind == 0 else Color("97806a"))
	var dark: StandardMaterial3D = _mat(Color("26343b") if kind == 0 else Color("372e29"))
	var ivory: StandardMaterial3D = _mat(Color("e9dabc"))
	var eye: StandardMaterial3D = _mat(Color("ffc34a"))
	eye.emission_enabled = true
	eye.emission = Color("e99825")
	eye.emission_energy_multiplier = 1.2
	if kind == 0:
		_ellipsoid(_visual, Vector3(0, 0.77, 0.05), Vector3(0.72, 0.70, 1.45), fur)
		_ellipsoid(_visual, Vector3(0, 0.66, -0.17), Vector3(0.52, 0.49, 0.89), pale)
		_ellipsoid(_visual, Vector3(0, 0.91, -0.45), Vector3(0.66, 0.68, 0.61), fur)
		_head = _pivot(_visual, Vector3(0, 1.01, -0.63))
		_ellipsoid(_head, Vector3.ZERO, Vector3(0.50, 0.48, 0.56), fur)
		_ellipsoid(_head, Vector3(0, -0.08, -0.31), Vector3(0.29, 0.23, 0.46), pale)
		_ellipsoid(_head, Vector3(0, -0.055, -0.53), Vector3(0.20, 0.15, 0.13), dark)
		for side: int in [-1, 1]:
			var ear: MeshInstance3D = _cone(_head, Vector3(side * 0.17, 0.30, 0.03), 0.13, 0.34, fur)
			ear.rotation.z = side * -0.16
			_ellipsoid(_head, Vector3(side * 0.219, 0.055, -0.14), Vector3(0.052, 0.065, 0.09), eye)
			_cone(_head, Vector3(side * 0.10, -0.19, -0.30), 0.025, 0.10, ivory).rotation.z = PI
		_segment(_visual, Vector3(0, 0.89, 0.58), Vector3(0, 0.73, 1.13), 0.13, fur)
		_segment(_visual, Vector3(0, 0.73, 1.13), Vector3(0, 0.92, 1.40), 0.085, pale)
	else:
		_ellipsoid(_visual, Vector3(0, 0.76, 0.02), Vector3(1.05, 0.92, 1.50), fur)
		_ellipsoid(_visual, Vector3(0, 0.98, -0.35), Vector3(0.91, 0.94, 0.96), fur)
		_head = _pivot(_visual, Vector3(0, 0.83, -0.70))
		_ellipsoid(_head, Vector3.ZERO, Vector3(0.75, 0.66, 0.77), fur)
		_ellipsoid(_head, Vector3(0, -0.10, -0.43), Vector3(0.44, 0.33, 0.26), pale)
		for side: int in [-1, 1]:
			_ellipsoid(_head, Vector3(side * 0.105, -0.085, -0.555), Vector3(0.08, 0.09, 0.025), dark)
			_ellipsoid(_head, Vector3(side * 0.322, 0.10, -0.17), Vector3(0.07, 0.075, 0.08), eye)
			var ear: MeshInstance3D = _cone(_head, Vector3(side * 0.29, 0.34, 0.06), 0.17, 0.25, dark)
			ear.rotation.z = side * -0.55
			var tusk: MeshInstance3D = _cone(_head, Vector3(side * 0.25, -0.02, -0.40), 0.06, 0.33, ivory)
			tusk.rotation = Vector3(-0.50, 0, side * -0.3)
		for z: float in [-0.38, -0.13, 0.12, 0.37, 0.58]:
			_cone(_visual, Vector3(0, 1.26, z), 0.09, 0.20, dark)
		_segment(_visual, Vector3(0, 0.90, 0.65), Vector3(0.16, 0.93, 0.92), 0.045, dark)
	for row: int in [0, 1]:
		for side: int in [-1, 1]:
			var leg: Node3D = _pivot(_visual, Vector3(side * (0.29 if kind == 0 else 0.36), 0.61, -0.42 if row == 0 else 0.45))
			_segment(leg, Vector3.ZERO, Vector3(0, -0.29, 0.03), 0.085 if kind == 0 else 0.12, fur)
			_segment(leg, Vector3(0, -0.25, 0.03), Vector3(0, -0.51, -0.05), 0.06 if kind == 0 else 0.08, pale)
			_box(leg, Vector3(0.16, 0.13, 0.25), Vector3(0, -0.52, -0.10), dark)
			_legs.append(leg)

func _build_guardian() -> void:
	var stone: StandardMaterial3D = _mat(Color("586474"), 0.18)
	var edge: StandardMaterial3D = _mat(Color("7b8490"), 0.15)
	var dark: StandardMaterial3D = _mat(Color("303540"))
	var crystal: StandardMaterial3D = _mat(Color("b65bd8"), 0.25)
	crystal.emission_enabled = true
	crystal.emission = Color("bd42eb")
	crystal.emission_energy_multiplier = 1.8
	_box(_visual, Vector3(1.03, 0.82, 0.62), Vector3(0, 1.76, 0), stone).rotation.z = 0.04
	_box(_visual, Vector3(0.65, 0.34, 0.49), Vector3(0, 1.18, 0), dark)
	var heart: MeshInstance3D = _box(_visual, Vector3(0.28, 0.28, 0.10), Vector3(0, 1.83, -0.36), crystal)
	heart.rotation.z = PI / 4
	_box(_visual, Vector3(0.06, 0.51, 0.05), Vector3(-0.27, 1.77, -0.34), crystal).rotation.z = -0.24
	_box(_visual, Vector3(0.07, 0.38, 0.05), Vector3(0.27, 1.69, -0.34), crystal).rotation.z = 0.38
	_head = _pivot(_visual, Vector3(0, 2.38, -0.03))
	_box(_head, Vector3(0.55, 0.58, 0.48), Vector3.ZERO, edge).rotation.z = -0.08
	_box(_head, Vector3(0.43, 0.10, 0.07), Vector3(0, 0.03, -0.27), dark)
	for side: int in [-1, 1]:
		_box(_head, Vector3(0.12, 0.065, 0.025), Vector3(side * 0.135, 0.03, -0.315), crystal)
		var horn: MeshInstance3D = _cone(_head, Vector3(side * 0.23, 0.38, 0.03), 0.12, 0.38, stone)
		horn.rotation.z = side * -0.35
		var arm: Node3D = _pivot(_visual, Vector3(side * 0.72, 1.98, 0))
		_box(arm, Vector3(0.48, 0.43, 0.53), Vector3.ZERO, edge).rotation.z = side * 0.18
		_segment(arm, Vector3(0, -0.10, 0), Vector3(side * 0.08, -0.48, 0), 0.17, dark)
		_box(arm, Vector3(0.44, 0.56, 0.49), Vector3(side * 0.09, -0.62, -0.02), stone).rotation.z = side * -0.1
		_box(arm, Vector3(0.43, 0.33, 0.46), Vector3(side * 0.1, -0.98, -0.05), edge)
		_box(arm, Vector3(0.08, 0.32, 0.04), Vector3(side * 0.09, -0.61, -0.28), crystal)
		_cone(arm, Vector3(side * 0.10, 0.33, 0), 0.14, 0.43, crystal).rotation.z = side * -0.35
		_arms.append(arm)
		var leg: Node3D = _pivot(_visual, Vector3(side * 0.29, 1.14, 0))
		_box(leg, Vector3(0.39, 0.46, 0.41), Vector3(0, -0.24, 0), stone)
		_box(leg, Vector3(0.42, 0.40, 0.46), Vector3(0, -0.68, 0), edge)
		_box(leg, Vector3(0.47, 0.27, 0.64), Vector3(0, -0.99, -0.11), dark)
		_legs.append(leg)

func _ring(radius: float, color: Color, y: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.045
	mesh.outer_radius = radius
	mesh.rings = 24
	mesh.ring_segments = 4
	node.mesh = mesh
	var mat: StandardMaterial3D = _mat(color)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override = mat
	node.position.y = y
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _make_health_bar() -> void:
	_health_root = Node3D.new()
	_health_root.position.y = 3.05 if kind == 2 else 1.65
	add_child(_health_root)
	var back := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.28, 0.095)
	back.mesh = quad
	var back_mat: StandardMaterial3D = _mat(Color("19252d"))
	back_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	back_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	back.material_override = back_mat
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_health_root.add_child(back)
	_health_fill = MeshInstance3D.new()
	var front := QuadMesh.new()
	front.size = Vector2(1.20, 0.055)
	_health_fill.mesh = front
	var red: StandardMaterial3D = _mat(Color("ef6655"))
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	red.no_depth_test = true
	_health_fill.material_override = red
	_health_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_health_root.add_child(_health_fill)
	_name_label = Label3D.new()
	_name_label.text = "%s · %d" % [display_name, level]
	_name_label.font_size = 28
	_name_label.pixel_size = 0.008
	_name_label.position.y = 0.23
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.modulate = Color("f1e6cf")
	_name_label.outline_modulate = Color("222c35")
	_name_label.outline_size = 8
	_health_root.add_child(_name_label)
	_health_root.visible = false

func _physics_process(delta: float) -> void:
	if _dying:
		_death_time += delta
		_visual.rotation.z = move_toward(_visual.rotation.z, -1.35, delta * 3.0)
		_visual.position.y = -maxf(0.0, _death_time - 0.4) * 0.38
		if _death_time > 1.15:
			queue_free()
		return
	_tick_visual(delta)
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.5
	if frozen or not is_instance_valid(hero):
		velocity.x = 0.0
		velocity.z = 0.0
		if _mode == Mode.WINDUP:
			_mode = Mode.RECOVER
			_clock = 0.55
		_warning_ring.visible = false
		move_and_slide()
		return
	var hero_dead: bool = bool(hero.get("dead"))
	var hero_offset: Vector3 = hero.global_position - global_position
	hero_offset.y = 0.0
	var distance: float = hero_offset.length()
	var spawn_distance: float = Vector2(global_position.x - _spawn.x, global_position.z - _spawn.z).length()
	if hero_dead or spawn_distance > 15.0 or hero.global_position.distance_to(_spawn) > 19.0:
		_mode = Mode.RETURN
		_warning_ring.visible = false
	var direction := Vector3.ZERO
	_clock -= delta
	match _mode:
		Mode.ROAM:
			if distance < 6.7 and not hero_dead:
				_mode = Mode.CHASE
			elif _clock <= 0.0:
				_clock = _rng.randf_range(2.5, 5.0)
				_roam_goal = _spawn + Vector3(_rng.randf_range(-2.4, 2.4), 0, _rng.randf_range(-2.4, 2.4))
			else:
				var roam_offset: Vector3 = _roam_goal - global_position
				roam_offset.y = 0.0
				if roam_offset.length() > 0.3:
					direction = roam_offset.normalized() * 0.35
		Mode.CHASE:
			if distance > 1.6:
				direction = hero_offset.normalized()
			else:
				_mode = Mode.WINDUP
				_clock = 0.60 if kind == 2 else 0.43
				_warning_ring.visible = true
		Mode.WINDUP:
			_face(hero_offset, delta * 5.0)
			if _clock <= 0.0:
				_warning_ring.visible = false
				_attack_lunge = 1.0
				if distance < (2.15 if kind < 2 else 2.45) and not hero_dead:
					struck_player.emit(_damage)
				_mode = Mode.RECOVER
				_clock = 1.05 if kind < 2 else 1.5
		Mode.RECOVER:
			if _clock <= 0.0:
				_mode = Mode.CHASE
		Mode.RETURN:
			var home: Vector3 = _spawn - global_position
			home.y = 0.0
			if home.length() < 0.5:
				hp = max_hp
				_update_health()
				_mode = Mode.ROAM
				_clock = 2.5
				_roam_goal = _spawn
			else:
				direction = home.normalized() * 0.85
	velocity.x = move_toward(velocity.x, direction.x * _speed, delta * 10.0)
	velocity.z = move_toward(velocity.z, direction.z * _speed, delta * 10.0)
	if direction.length_squared() > 0.01:
		_face(direction, delta * 7.0)
	move_and_slide()

func _face(direction: Vector3, weight: float) -> void:
	if direction.length_squared() > 0.01:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-direction.x, -direction.z), minf(1.0, weight))

func _tick_visual(delta: float) -> void:
	var movement: float = Vector2(velocity.x, velocity.z).length() / _speed
	_phase += delta * (9.0 if movement > 0.05 else 2.0)
	for i: int in range(_legs.size()):
		var side_phase: float = 0.0 if i % 3 == 0 else PI
		_legs[i].rotation.x = sin(_phase + side_phase) * 0.64 * movement
	for i: int in range(_arms.size()):
		_arms[i].rotation.x = sin(_phase + i * PI) * 0.35 * movement
	_visual.position.y = absf(sin(_phase)) * movement * 0.04
	_head.rotation.x = sin(_phase * 0.4) * 0.045
	if _mode == Mode.WINDUP:
		_head.rotation.x = -0.22
		_warning_ring.scale = Vector3.ONE * (1.0 + sin(_clock * 16.0) * 0.08)
		for arm: Node3D in _arms:
			arm.rotation.x = -0.7
	if _attack_lunge > 0.0:
		_attack_lunge = maxf(0, _attack_lunge - delta * 4.0)
		_head.rotation.x = 0.45 * _attack_lunge
		for arm: Node3D in _arms:
			arm.rotation.x = 1.1 * _attack_lunge
		_visual.position.y += sin(_attack_lunge * PI) * 0.10
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			for part: MeshInstance3D in _parts:
				part.material_overlay = null
	_damage_visibility = maxf(0.0, _damage_visibility - delta)
	_health_root.visible = _targeted or _damage_visibility > 0.0

func take_damage(amount: int, critical: bool = false) -> void:
	if _dying or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	_flash = 0.13
	_damage_visibility = 5.0
	for part: MeshInstance3D in _parts:
		part.material_overlay = _flash_mat
	_update_health()
	_hit_sparks(critical)
	damaged.emit(amount, critical)
	if hp <= 0:
		_dying = true
		velocity = Vector3.ZERO
		_health_root.visible = false
		_target_ring.visible = false
		_warning_ring.visible = false
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		defeated.emit(self)
	else:
		if _mode == Mode.ROAM:
			_mode = Mode.CHASE

func _update_health() -> void:
	if is_instance_valid(_health_fill):
		var ratio: float = float(hp) / max_hp
		_health_fill.scale.x = ratio
		_health_fill.position.x = (ratio - 1.0) * 0.60

func _hit_sparks(critical: bool) -> void:
	var mat: StandardMaterial3D = _mat(Color("ffe9a5") if critical else Color("ffd275"))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i: int in range(6 if critical else 4):
		var spark := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.07, 0.07, 0.18)
		spark.mesh = box
		spark.material_override = mat
		spark.position = Vector3(0, 1.5 if kind == 2 else 0.8, 0)
		spark.rotation = Vector3(_rng.randf() * PI, _rng.randf() * PI, 0)
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(spark)
		var end: Vector3 = spark.position + Vector3(_rng.randf_range(-0.7, 0.7), _rng.randf_range(0.2, 0.8), _rng.randf_range(-0.7, 0.7))
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(spark, "position", end, 0.28)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.28)
		tween.chain().tween_callback(spark.queue_free)

func is_alive() -> bool:
	return hp > 0 and not _dying

func set_targeted(value: bool) -> void:
	_targeted = value
	if is_instance_valid(_target_ring):
		_target_ring.visible = value and not _dying

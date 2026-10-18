class_name CharacterVisual
extends Node3D
## Original low-poly warrior assembled from small mobile-friendly primitives.

var body: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var head: Node3D
var sword: Node3D
var slash: MeshInstance3D
var spin_ring: MeshInstance3D
var armor_material: StandardMaterial3D
var trim_material: StandardMaterial3D
var blade_material: StandardMaterial3D
var cloth_material: StandardMaterial3D
var glow_material: StandardMaterial3D
var slash_material: StandardMaterial3D
var skin_material: StandardMaterial3D
var advanced_weapon: Node3D
var dawn_weapon: Node3D
var advanced_armor: Node3D
var dawn_armor: Node3D
var mesh_parts: Array[MeshInstance3D] = []
var flash_material: StandardMaterial3D
var walk_phase: float = 0.0
var attack_elapsed: float = -1.0
var attack_duration: float = 0.45
var combo_index: int = 0
var skill_attack: bool = false
var flash_time: float = 0.0
var weapon_tier: int = 0
var armor_tier: int = 0
var upgrade_level: int = 0

func _ready() -> void:
	_build()
	set_equipment(weapon_tier, armor_tier, upgrade_level)

func _material(color: Color, metallic: float = 0.0, roughness: float = 0.7) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	part.position = pos
	part.rotation = rot
	parent.add_child(part)
	mesh_parts.append(part)
	return part

func _sphere(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 4
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	part.position = pos
	parent.add_child(part)
	mesh_parts.append(part)
	return part

func _cylinder(parent: Node3D, top: float, bottom: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 6
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	part.position = pos
	part.rotation = rot
	parent.add_child(part)
	mesh_parts.append(part)
	return part

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	return pivot

func _build() -> void:
	armor_material = _material(Color("657a88"), 0.55, 0.4)
	trim_material = _material(Color("b4a471"), 0.65, 0.36)
	blade_material = _material(Color("c9d9de"), 0.75, 0.24)
	cloth_material = _material(Color("304d65"))
	skin_material = _material(Color("c49471"))
	var leather: StandardMaterial3D = _material(Color("392f28"))
	var dark: StandardMaterial3D = _material(Color("1c262b"), 0.25)
	glow_material = _material(Color("51c8f2"))
	glow_material.emission_enabled = true
	glow_material.emission = Color("35c6ff")
	glow_material.emission_energy_multiplier = 1.5
	flash_material = _material(Color(1.0, 0.86, 0.69, 0.7))
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	body = _pivot(self, Vector3.ZERO)
	# Breastplate, rear cape, layered waist and diagonal baldric.
	_box(body, Vector3(0.73, 0.58, 0.40), Vector3(0, 1.31, 0), armor_material)
	_box(body, Vector3(0.58, 0.11, 0.43), Vector3(0, 1.02, 0), leather)
	_box(body, Vector3(0.15, 0.13, 0.05), Vector3(0, 1.02, -0.235), trim_material)
	_box(body, Vector3(0.10, 0.61, 0.05), Vector3(0, 1.32, -0.23), leather, Vector3(0, 0, -0.58))
	_box(body, Vector3(0.18, 0.19, 0.06), Vector3(0, 1.39, -0.27), trim_material, Vector3(0, 0, PI / 4))
	_box(body, Vector3(0.29, 0.30, 0.13), Vector3(-0.19, 0.85, -0.17), armor_material, Vector3(0, 0, -0.11))
	_box(body, Vector3(0.29, 0.30, 0.13), Vector3(0.19, 0.85, -0.17), armor_material, Vector3(0, 0, 0.11))
	_box(body, Vector3(0.67, 0.70, 0.045), Vector3(0, 1.02, 0.24), cloth_material, Vector3(-0.16, 0, 0))
	# Neck, angular enclosed helm, nose guard and glowing eye slit.
	_cylinder(body, 0.12, 0.12, 0.18, Vector3(0, 1.64, 0), skin_material)
	head = _pivot(body, Vector3(0, 1.77, 0))
	_sphere(head, 0.245, 0.47, Vector3.ZERO, armor_material)
	_box(head, Vector3(0.39, 0.075, 0.055), Vector3(0, 0.015, -0.217), dark)
	_box(head, Vector3(0.31, 0.025, 0.014), Vector3(0, 0.019, -0.25), glow_material)
	_box(head, Vector3(0.055, 0.24, 0.07), Vector3(0, -0.025, -0.251), trim_material)
	_box(head, Vector3(0.06, 0.32, 0.34), Vector3(0, 0.18, 0.02), trim_material)
	_box(head, Vector3(0.055, 0.25, 0.24), Vector3(0, 0.36, 0.07), cloth_material, Vector3(0.38, 0, 0))
	for side: int in [-1, 1]:
		var arm: Node3D = _pivot(body, Vector3(side * 0.48, 1.47, 0))
		_sphere(arm, 0.235, 0.28, Vector3(side * 0.015, 0.01, 0), armor_material)
		_box(arm, Vector3(0.31, 0.07, 0.36), Vector3(side * 0.015, 0.10, 0), trim_material)
		_cylinder(arm, 0.115, 0.10, 0.31, Vector3(0, -0.20, 0), cloth_material)
		_box(arm, Vector3(0.23, 0.29, 0.25), Vector3(0, -0.44, -0.005), armor_material)
		_sphere(arm, 0.105, 0.18, Vector3(0, -0.62, 0), leather)
		var leg: Node3D = _pivot(body, Vector3(side * 0.20, 0.90, 0))
		_cylinder(leg, 0.135, 0.11, 0.40, Vector3(0, -0.20, 0), cloth_material)
		_box(leg, Vector3(0.25, 0.29, 0.27), Vector3(0, -0.52, 0), armor_material)
		_box(leg, Vector3(0.28, 0.19, 0.43), Vector3(0, -0.76, -0.09), leather)
		_box(leg, Vector3(0.25, 0.08, 0.18), Vector3(0, -0.66, -0.12), trim_material)
		if side < 0:
			left_arm = arm
			left_leg = leg
		else:
			right_arm = arm
			right_leg = leg
	sword = _pivot(right_arm, Vector3(0, -0.64, -0.015))
	sword.rotation = Vector3(0.94, 0, -0.12)
	_cylinder(sword, 0.045, 0.045, 0.23, Vector3(0, -0.08, 0), leather)
	_sphere(sword, 0.075, 0.105, Vector3(0, 0.055, 0), trim_material)
	_box(sword, Vector3(0.40, 0.07, 0.12), Vector3(0, -0.21, 0), trim_material)
	_box(sword, Vector3(0.145, 0.77, 0.053), Vector3(0, -0.62, 0), blade_material)
	_box(sword, Vector3(0.025, 0.63, 0.062), Vector3(0, -0.60, 0), trim_material)
	_cylinder(sword, 0.0, 0.084, 0.20, Vector3(0, -1.105, 0), blade_material, Vector3(0, 0, PI))
	_sphere(sword, 0.056, 0.08, Vector3(0, -0.21, -0.067), glow_material)
	advanced_weapon = _pivot(sword, Vector3.ZERO)
	for side: int in [-1, 1]:
		_box(advanced_weapon, Vector3(0.28, 0.07, 0.12), Vector3(side * 0.25, -0.25, 0), trim_material, Vector3(0, 0, side * -0.5))
	dawn_weapon = _pivot(sword, Vector3.ZERO)
	_box(dawn_weapon, Vector3(0.25, 0.06, 0.075), Vector3(0, -0.43, 0), trim_material)
	_box(dawn_weapon, Vector3(0.07, 0.16, 0.085), Vector3(0, -0.35, -0.045), glow_material, Vector3(0, 0, PI / 4))
	for side: int in [-1, 1]:
		_cylinder(dawn_weapon, 0.0, 0.06, 0.25, Vector3(side * 0.37, -0.22, 0), trim_material, Vector3(0, 0, side * -PI / 2))
	advanced_armor = _pivot(body, Vector3.ZERO)
	for side: int in [-1, 1]:
		_box(advanced_armor, Vector3(0.18, 0.10, 0.42), Vector3(side * 0.59, 1.55, 0.02), armor_material, Vector3(0, 0, side * -0.35))
		_box(advanced_armor, Vector3(0.06, 0.36, 0.04), Vector3(side * 0.26, 1.32, -0.23), trim_material)
	dawn_armor = _pivot(body, Vector3.ZERO)
	for side: int in [-1, 1]:
		_cylinder(dawn_armor, 0.0, 0.09, 0.30, Vector3(side * 0.55, 1.72, 0.08), trim_material, Vector3(0, 0, side * -0.42))
		_box(dawn_armor, Vector3(0.13, 0.39, 0.045), Vector3(side * 0.20, 0.85, -0.25), trim_material, Vector3(0, 0, side * 0.12))
	# Broad transparent ribbons communicate attacks clearly from the camera.
	slash_material = _material(Color(1.0, 0.84, 0.36, 0.65))
	slash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	slash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	slash_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	slash_material.emission_enabled = true
	slash_material.emission = Color(1.0, 0.56, 0.15)
	slash = MeshInstance3D.new()
	slash.mesh = _arc_mesh(1.05, 1.75, 1.7, 18)
	slash.material_override = slash_material
	slash.position.y = 1.02
	slash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	slash.visible = false
	add_child(slash)
	spin_ring = MeshInstance3D.new()
	spin_ring.mesh = _arc_mesh(1.0, 2.30, TAU, 40)
	spin_ring.material_override = slash_material
	spin_ring.position.y = 0.65
	spin_ring.visible = false
	spin_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spin_ring)

func _arc_mesh(inner: float, outer: float, angle: float, segments: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for i: int in range(segments):
		var a: float = -angle * 0.5 + angle * float(i) / segments
		var b: float = -angle * 0.5 + angle * float(i + 1) / segments
		var p0 := Vector3(sin(a) * inner, 0, -cos(a) * inner)
		var p1 := Vector3(sin(a) * outer, 0, -cos(a) * outer)
		var p2 := Vector3(sin(b) * outer, 0, -cos(b) * outer)
		var p3 := Vector3(sin(b) * inner, 0, -cos(b) * inner)
		for v: Vector3 in [p0, p2, p1, p0, p3, p2]:
			verts.append(v)
			normals.append(Vector3.UP)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

func set_equipment(new_weapon_tier: int, new_armor_tier: int, upgrade: int = 0) -> void:
	weapon_tier = clampi(new_weapon_tier, 0, 3)
	armor_tier = clampi(new_armor_tier, 0, 3)
	upgrade_level = upgrade
	if not is_instance_valid(armor_material):
		return
	var armor_colors: Array[Color] = [Color("726553"), Color("8d6b4b"), Color("477b98"), Color("47394d")]
	var trim_colors: Array[Color] = [Color("918979"), Color("b29d71"), Color("b8d9e2"), Color("d4a34f")]
	var cloth_colors: Array[Color] = [Color("3d504c"), Color("3c484e"), Color("153956"), Color("831d2e")]
	var blade_colors: Array[Color] = [Color("9da7a9"), Color("c6d4d8"), Color("96d9eb"), Color("f4b56c")]
	armor_material.albedo_color = armor_colors[armor_tier]
	trim_material.albedo_color = trim_colors[armor_tier]
	cloth_material.albedo_color = cloth_colors[armor_tier]
	blade_material.albedo_color = blade_colors[weapon_tier]
	blade_material.emission_enabled = upgrade_level > 0 or weapon_tier == 3
	blade_material.emission = blade_colors[weapon_tier]
	blade_material.emission_energy_multiplier = minf(0.18 * upgrade_level + weapon_tier * 0.13, 1.25)
	sword.scale = Vector3.ONE * (0.84 + weapon_tier * 0.10)
	advanced_weapon.visible = weapon_tier >= 2
	dawn_weapon.visible = weapon_tier == 3
	advanced_armor.visible = armor_tier >= 2
	dawn_armor.visible = armor_tier == 3
	glow_material.emission = [Color("75abb3"), Color("36c8ff"), Color("55e1ff"), Color("ff6544")][weapon_tier]

func start_attack(combo: int = 0, skill: bool = false) -> void:
	combo_index = combo % 3
	skill_attack = skill
	attack_elapsed = 0.0
	attack_duration = 0.68 if skill else 0.46

func is_attacking() -> bool:
	return attack_elapsed >= 0.0

func hit_flash() -> void:
	flash_time = 0.17
	for part: MeshInstance3D in mesh_parts:
		part.material_overlay = flash_material

func tick(delta: float, moving: float) -> void:
	if body == null:
		return
	walk_phase += delta * (9.5 if moving > 0.05 else 2.4)
	var stride: float = sin(walk_phase) * 0.65 * moving
	left_leg.rotation.x = stride
	right_leg.rotation.x = -stride
	left_arm.rotation = Vector3(-stride * 0.6, 0, 0.08)
	right_arm.rotation = Vector3(stride * 0.5, 0, -0.08)
	body.position.y = absf(sin(walk_phase)) * 0.065 * moving + sin(walk_phase * 0.5) * 0.012
	body.rotation = Vector3.ZERO
	head.rotation.y = sin(walk_phase * 0.35) * 0.04
	slash.visible = false
	spin_ring.visible = false
	if attack_elapsed >= 0.0:
		attack_elapsed += delta
		var t: float = clampf(attack_elapsed / attack_duration, 0.0, 1.0)
		if skill_attack:
			body.rotation.y = t * TAU * 1.5
			right_arm.rotation = Vector3(1.3, -0.4, -0.7)
			left_arm.rotation = Vector3(0.5, 0.3, 0.55)
			spin_ring.visible = t > 0.18 and t < 0.88
			spin_ring.rotation.y = -t * TAU
			spin_ring.scale = Vector3.ONE * (0.7 + 0.4 * sin(t * PI))
			slash_material.albedo_color = Color(0.48, 0.85, 1.0, sin(t * PI) * 0.65)
		elif combo_index == 2:
			var swing: float = sin(t * PI)
			right_arm.rotation = Vector3(-0.6 + 2.8 * swing, -0.25, -0.3)
			left_arm.rotation.x = 1.0 * swing
			body.rotation.x = -0.12 + swing * 0.27
			slash.visible = t > 0.28 and t < 0.80
			slash.rotation = Vector3(0, 0, -0.8)
			slash_material.albedo_color = Color(1.0, 0.83, 0.32, sin(t * PI) * 0.6)
		else:
			var sign_value: float = 1.0 if combo_index == 0 else -1.0
			var swing: float = sin(t * PI)
			right_arm.rotation = Vector3(1.2 * swing, -sign_value * (t * 2.5 - 1.2), -0.55 * swing)
			body.rotation.y = sign_value * (0.45 - t * 0.9) * swing
			left_arm.rotation.x = swing * 0.7
			slash.visible = t > 0.24 and t < 0.85
			slash.rotation = Vector3(0.08 * sign_value, sign_value * (t - 0.5), sign_value * 0.10)
			slash_material.albedo_color = Color(1.0, 0.83, 0.32, sin(t * PI) * 0.58)
		if t >= 1.0:
			attack_elapsed = -1.0
	if flash_time > 0.0:
		flash_time -= delta
		if flash_time <= 0.0:
			for part: MeshInstance3D in mesh_parts:
				part.material_overlay = null

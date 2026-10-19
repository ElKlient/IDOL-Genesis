class_name WarriorModel
extends Node3D
## Imported, continuously skinned warrior. The procedural rig remains the single
## animation authority for both the playable actor and the inventory portrait.

const BODY_PATH: String = "res://assets/warrior/warrior.glb"
const WEAPONS_PATH: String = "res://assets/warrior/weapons.glb"
var skeleton: Skeleton3D
var model_root: Node3D
var weapon_root: Node3D
var mesh_parts: Array[MeshInstance3D] = []
var armor_variants: Dictionary = {}
var weapon_variants: Dictionary = {}
var materials: Array[StandardMaterial3D] = []
var load_succeeded: bool = false
var _material_copies: Dictionary = {}
var _material_defaults: Dictionary = {}
var _controls: Dictionary = {}
var _corrections: Dictionary = {}
var _bone_order: Array[int] = []
var _desired: Array[Transform3D] = []
var _selected_weapon: int = 0

func load_model() -> bool:
	var resource: Resource = load(BODY_PATH)
	if not resource is PackedScene:
		push_error("Warrior model is unavailable: "+BODY_PATH)
		return false
	model_root = (resource as PackedScene).instantiate() as Node3D
	if model_root == null:
		push_error("Warrior model must have a 3D scene root.")
		return false
	model_root.name = "WarriorBody"
	add_child(model_root)
	for node: Node in model_root.find_children("*","Skeleton3D",true,false):
		skeleton = node as Skeleton3D
		break
	if skeleton == null:
		push_error("Warrior model has no Skeleton3D.")
		return false
	for tier: int in range(4):
		armor_variants[tier] = _variant(model_root,"Armor%d" % tier)
		if armor_variants[tier] == null:
			push_error("Warrior model is missing Armor%d." % tier)
			return false
	_collect_meshes(model_root)
	_bone_order.resize(skeleton.get_bone_count())
	_desired.resize(skeleton.get_bone_count())
	for index: int in range(skeleton.get_bone_count()):
		_bone_order[index] = index
	_bone_order.sort_custom(func(a: int,b: int) -> bool: return _depth(a) < _depth(b))
	load_succeeded = true
	return true

func attach_weapons(parent: Node3D) -> void:
	var resource: Resource = load(WEAPONS_PATH)
	if not resource is PackedScene:
		load_succeeded = false
		push_error("Warrior weapons are unavailable: "+WEAPONS_PATH)
		return
	weapon_root = (resource as PackedScene).instantiate() as Node3D
	if weapon_root == null:
		load_succeeded = false
		return
	weapon_root.name = "WarriorWeapons"
	parent.add_child(weapon_root)
	for tier: int in range(4):
		weapon_variants[tier] = _variant(weapon_root,"Weapon%d" % tier)
		if weapon_variants[tier] == null:
			load_succeeded = false
			push_error("Warrior weapons are missing Weapon%d." % tier)
			return
	_collect_meshes(weapon_root,"weapon")

func _variant(scene: Node,node_name: String) -> Node3D:
	if scene.name == node_name:
		return scene as Node3D
	var exact: Node = scene.find_child(node_name,true,false)
	if exact != null:
		return exact as Node3D
	# glTF exporters can retain a mesh/object suffix on a joined object.
	for child: Node in scene.find_children(node_name+"*","Node3D",true,false):
		return child as Node3D
	return null

func _collect_meshes(scene: Node,equipment_kind: String = "armor") -> void:
	var candidates: Array[Node] = scene.find_children("*","MeshInstance3D",true,false)
	if scene is MeshInstance3D:
		candidates.push_front(scene)
	for node: Node in candidates:
		var part: MeshInstance3D = node as MeshInstance3D
		if part.mesh == null:
			continue
		# Mesh resources stay shared; only small mutable materials are copied,
		# once per actor, so a portrait cannot tint the player's equipment.
		for surface: int in range(part.mesh.get_surface_count()):
			var original: Material = part.get_active_material(surface)
			if original == null:
				continue
			var key: int = original.get_instance_id()
			if not _material_copies.has(key):
				var copy: Material = original.duplicate() as Material
				_material_copies[key] = copy
				if copy is StandardMaterial3D:
					materials.append(copy)
					_material_defaults[copy.get_instance_id()] = {"roughness":copy.roughness,"emission_energy":copy.emission_energy_multiplier,"equipment_kind":equipment_kind}
			part.set_surface_override_material(surface,_material_copies[key])
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# Layer 2 receives the village's bounded character-only soft fill. Keep
		# layer 1 as well for normal cameras, sun shadows and the inventory world.
		part.layers = 3
		mesh_parts.append(part)

func _depth(index: int) -> int:
	var result: int = 0
	var parent: int = skeleton.get_bone_parent(index)
	while parent >= 0:
		result += 1
		parent = skeleton.get_bone_parent(parent)
	return result

func get_joint_position(bone_name: String) -> Vector3:
	var index: int = skeleton.find_bone(bone_name) if skeleton != null else -1
	if index < 0:
		return Vector3.ZERO
	return (global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_rest(index)).origin

func bind_controls(controls: Dictionary) -> void:
	_controls.clear()
	_corrections.clear()
	if skeleton == null:
		return
	for bone_name: String in controls:
		var index: int = skeleton.find_bone(bone_name)
		var proxy: Node3D = controls[bone_name] as Node3D
		if index < 0 or proxy == null:
			continue
		_controls[index] = proxy
		_corrections[index] = proxy.global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_rest(index)
	sync_pose()

func sync_pose() -> void:
	if skeleton == null or _controls.is_empty():
		return
	var inverse_skeleton: Transform3D = skeleton.global_transform.affine_inverse()
	for index: int in _bone_order:
		var parent: int = skeleton.get_bone_parent(index)
		var desired: Transform3D
		if _controls.has(index):
			var proxy: Node3D = _controls[index]
			desired = inverse_skeleton*proxy.global_transform*(_corrections[index] as Transform3D)
		else:
			desired = skeleton.get_bone_rest(index)
			if parent >= 0:
				desired = _desired[parent]*desired
		_desired[index] = desired
		var local_pose: Transform3D = desired if parent < 0 else _desired[parent].affine_inverse()*desired
		# Skeleton3D pose is the full parent-local transform, not a delta
		# multiplied by rest. Applying rest twice stretches the entire skin.
		skeleton.set_bone_pose_position(index,local_pose.origin)
		skeleton.set_bone_pose_rotation(index,local_pose.basis.orthonormalized().get_rotation_quaternion())
		skeleton.set_bone_pose_scale(index,local_pose.basis.get_scale())

func set_equipment(weapon_tier: int,armor_tier: int,upgrade: int,armor_upgrade: int = 0) -> StandardMaterial3D:
	_selected_weapon = clampi(weapon_tier,0,3)
	for tier: int in armor_variants:
		var variant: Node3D = armor_variants[tier]
		if variant != null:
			variant.visible = tier == 0 or tier == armor_tier
	for tier: int in weapon_variants:
		var variant: Node3D = weapon_variants[tier]
		if variant != null:
			variant.visible = tier == _selected_weapon
	var selected_blade: StandardMaterial3D
	for material: StandardMaterial3D in materials:
		var defaults: Dictionary = _material_defaults.get(material.get_instance_id(),{})
		if material.resource_name.begins_with("Blade"):
			var grade: int = clampi(upgrade,0,6)
			var hues: Array[Color] = [Color("d8e7e7"),Color("ffca85"),Color("94dfcb"),Color("ff9d63")]
			# The atlas restricts emission to a honed edge and recessed engraving.
			# The opaque steel still receives ordinary scene light and reflections.
			material.emission_enabled = grade > 0 or weapon_tier == 3
			material.emission = hues[clampi(weapon_tier,0,3)]
			material.emission_energy_multiplier = 0.045*grade+0.008*grade*grade+(0.10 if weapon_tier == 3 else 0.0)
			material.roughness = float(defaults.get("roughness",1.0))*(1.0-0.025*grade)
		elif material.resource_name.begins_with("EquipmentAtlas"):
			var grade: int = clampi(upgrade if str(defaults.get("equipment_kind","armor")) == "weapon" else armor_upgrade,0,6)
			material.roughness = float(defaults.get("roughness",1.0))*(1.0-0.018*grade)
			material.emission_energy_multiplier = float(defaults.get("emission_energy",1.0))*(1.0+0.045*grade)
	var selected: Node3D = weapon_variants.get(_selected_weapon) as Node3D
	if selected != null:
		var candidates: Array[Node] = selected.find_children("*","MeshInstance3D",true,false)
		if selected is MeshInstance3D:
			candidates.push_front(selected)
		for node: Node in candidates:
			var mesh: MeshInstance3D = node as MeshInstance3D
			for surface: int in range(mesh.mesh.get_surface_count()):
				var material: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
				if material != null and material.resource_name.begins_with("Blade"):
					selected_blade = material
					break
	return selected_blade

func get_render_stats() -> Dictionary:
	var triangles: int = 0
	var surfaces: int = 0
	var meshes: int = 0
	var all_triangles: int = 0
	var skin_count: int = 0
	var active_materials: Dictionary = {}
	for part: MeshInstance3D in mesh_parts:
		if part.skin != null:
			skin_count += 1
		for surface: int in range(part.mesh.get_surface_count()):
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var count: int = int(float(indices.size() if not indices.is_empty() else vertices.size())/3.0)
			all_triangles += count
			if part.is_visible_in_tree():
				triangles += count
				surfaces += 1
				var material: Material = part.get_active_material(surface)
				if material != null:
					active_materials[material.get_instance_id()] = true
		if part.is_visible_in_tree():
			meshes += 1
	return {"visible_triangles":triangles,"visible_surfaces":surfaces,"visible_meshes":meshes,"all_triangles":all_triangles,"material_count":active_materials.size(),"bone_count":skeleton.get_bone_count() if skeleton != null else 0,"skin_count":skin_count}

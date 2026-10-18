class_name CharacterVisual
extends Node3D
## Original armored human using a continuous imported skin and a procedural rig.

const WarriorModelScript = preload("res://scripts/warrior_model.gd")
const SwordFireScript = preload("res://scripts/sword_fire_effect.gd")
const FIRE_SLAM_DURATION: float = 1.0
const FIRE_SLAM_CONTACT: float = 0.48
const POSE_CHANNELS: Array[String] = ["root","offset","hips","torso","right_arm","right_forearm","wrist","left_arm","left_forearm","left_leg","right_leg","left_knee","right_knee"]
const FINISHER_GRIP_TRACK: Array = [
	{"time":0.0,"target":Vector3(0.10,1.34,-0.25),"angle":Vector3(1.4,0,0)},
	{"time":0.16,"target":Vector3(0.10,1.62,-0.20),"angle":Vector3(3.0,0,0)},
	{"time":0.25,"target":Vector3(0.02,1.50,-0.22),"angle":Vector3(1.18,0,0)},
	{"time":0.36,"target":Vector3(-0.10,1.45,-0.20),"angle":Vector3(0.95,0,0)},
	{"time":0.49,"target":Vector3(0.16,1.32,-0.32),"angle":Vector3(1.5,0,0)},
	{"time":0.62,"target":Vector3(0.23,1.24,-0.28),"angle":Vector3(1.75,0,0)}
]

var body: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var head: Node3D
var hips: Node3D
var torso: Node3D
var left_forearm: Node3D
var right_forearm: Node3D
var left_knee: Node3D
var right_knee: Node3D
var right_wrist: Node3D
var left_wrist: Node3D
var left_ankle: Node3D
var right_ankle: Node3D
var _left_ankle_rest: Vector3
var _right_ankle_rest: Vector3
var model: WarriorModel
var cape: MeshInstance3D
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
var idle_phase: float = 0.0
var locomotion_blend: float = 0.0
var _combat_tracks: Array = []
var _attack_origin: Dictionary = {}
var attack_elapsed: float = -1.0
var attack_duration: float = 0.45
var combo_index: int = 0
var skill_attack: bool = false
var fire_slam_attack: bool = false
var sword_fire: Node3D
var sword_burning: bool = false
var _fire_slam_track: Array = []
var flash_time: float = 0.0
var weapon_tier: int = 0
var armor_tier: int = 0
var upgrade_level: int = 0
var armor_upgrade_level: int = 0
var presentation_active: bool = false
var presentation_phase: float = 0.0
var _presentation_blend: float = 0.0
var _contact_hold: float = 0.0
var _locomotion_pose: Dictionary = {}

func _ready() -> void:
	_build()
	set_equipment(weapon_tier, armor_tier, upgrade_level, armor_upgrade_level)
	set_sword_flame(sword_burning)

func _material(color: Color, metallic: float = 0.0, roughness: float = 0.7) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	return pivot

func _build() -> void:
	flash_material = _material(Color(1.0,0.86,0.69,0.7))
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	model = WarriorModelScript.new()
	model.name = "WarriorModel"
	# The skinned renderer is a sibling of the control root. Skinning already
	# contains body motion, so parenting it below body would apply it twice.
	add_child(model)
	if not model.load_model():
		return
	body = _pivot(self,Vector3.ZERO)
	hips = _joint_pivot(body,"pelvis")
	torso = _joint_pivot(hips,"spine_03")
	head = _joint_pivot(torso,"Head")
	left_arm = _joint_pivot(torso,"upperarm_l")
	right_arm = _joint_pivot(torso,"upperarm_r")
	left_forearm = _joint_pivot(left_arm,"lowerarm_l")
	right_forearm = _joint_pivot(right_arm,"lowerarm_r")
	left_wrist = _joint_pivot(left_forearm,"hand_l")
	right_wrist = _joint_pivot(right_forearm,"hand_r")
	left_leg = _joint_pivot(hips,"thigh_l")
	right_leg = _joint_pivot(hips,"thigh_r")
	left_knee = _joint_pivot(left_leg,"calf_l")
	right_knee = _joint_pivot(right_leg,"calf_r")
	left_ankle = _joint_pivot(left_knee,"foot_l")
	right_ankle = _joint_pivot(right_knee,"foot_r")
	_left_ankle_rest = to_local(left_ankle.global_position)
	_right_ankle_rest = to_local(right_ankle.global_position)
	# Kept as a control handle for the public animation API. The new authored
	# cloth is skinned to the pelvis/chest rather than a rigid box cape.
	cape = MeshInstance3D.new()
	cape.name = "ClothControl"
	torso.add_child(cape)
	sword = _pivot(right_wrist,Vector3.ZERO)
	sword.name = "SwordGrip"
	sword.rotation = Vector3(0.94,0,-0.12)
	model.attach_weapons(sword)
	mesh_parts.assign(model.mesh_parts)
	# Keep the public material API available to callers. Actual equipment
	# colors belong to the imported armor sets, never to the human skin.
	armor_material = _material(Color("657a88"),0.55,0.4)
	trim_material = _material(Color("b4a471"),0.65,0.36)
	blade_material = _material(Color("c9d9de"),0.75,0.24)
	cloth_material = _material(Color("304d65"))
	skin_material = _material(Color("c49471"))
	glow_material = _material(Color("51c8f2"))
	advanced_weapon = Node3D.new()
	dawn_weapon = Node3D.new()
	advanced_armor = Node3D.new()
	dawn_armor = Node3D.new()
	for handle: Node3D in [advanced_weapon,dawn_weapon,advanced_armor,dawn_armor]:
		add_child(handle)
	sword_fire = SwordFireScript.new()
	sword_fire.name = "SwordFire"
	sword.add_child(sword_fire)
	slash_material = _material(Color(1.0,0.84,0.36,0.65))
	slash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	slash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	slash_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	slash_material.emission_enabled = true
	slash_material.emission = Color(1.0,0.56,0.15)
	slash = MeshInstance3D.new()
	slash.mesh = _arc_mesh(1.05,1.75,1.7,18)
	slash.material_override = slash_material
	slash.position.y = 1.02
	slash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	slash.visible = false
	add_child(slash)
	spin_ring = MeshInstance3D.new()
	spin_ring.mesh = _arc_mesh(1.0,2.30,TAU,40)
	spin_ring.material_override = slash_material
	spin_ring.position.y = 0.65
	spin_ring.visible = false
	spin_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spin_ring)
	model.bind_controls({"root":body,"pelvis":hips,"spine_03":torso,"Head":head,
		"upperarm_l":left_arm,"upperarm_r":right_arm,
		"lowerarm_l":left_forearm,"lowerarm_r":right_forearm,
		"hand_l":left_wrist,"hand_r":right_wrist,
		"thigh_l":left_leg,"thigh_r":right_leg,
		"calf_l":left_knee,"calf_r":right_knee,
		"foot_l":left_ankle,"foot_r":right_ankle})
	_build_combat_tracks()

func _joint_pivot(parent: Node3D,bone_name: String) -> Node3D:
	var joint: Node3D = _pivot(parent,Vector3.ZERO)
	joint.name = bone_name+"Control"
	joint.global_position = model.to_global(model.get_joint_position(bone_name))
	return joint

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

func set_equipment(new_weapon_tier: int,new_armor_tier: int,upgrade: int = 0,new_armor_upgrade: int = 0) -> void:
	weapon_tier = clampi(new_weapon_tier,0,3)
	armor_tier = clampi(new_armor_tier,0,3)
	upgrade_level = upgrade
	armor_upgrade_level = new_armor_upgrade
	if not is_instance_valid(model) or not model.load_succeeded or not is_instance_valid(sword):
		return
	var selected_blade: StandardMaterial3D = model.set_equipment(weapon_tier,armor_tier,upgrade_level,armor_upgrade_level)
	if selected_blade != null:
		blade_material = selected_blade
	sword.scale = Vector3.ONE*(0.84+weapon_tier*0.10)
	advanced_weapon.visible = weapon_tier >= 2
	dawn_weapon.visible = weapon_tier == 3
	advanced_armor.visible = armor_tier >= 2
	dawn_armor.visible = armor_tier == 3

func start_attack(combo: int = 0, skill: bool = false) -> void:
	_contact_hold = 0.0
	presentation_active = false
	_presentation_blend = 0.0
	fire_slam_attack = false
	combo_index = posmod(combo, 4)
	skill_attack = skill
	attack_elapsed = 0.0
	attack_duration = 0.68 if skill else (0.62 if combo_index == 3 else 0.46)
	if is_instance_valid(torso):
		_attack_origin = _capture_pose()

func start_fire_slam() -> void:
	_contact_hold = 0.0
	presentation_active = false
	_presentation_blend = 0.0
	skill_attack = false
	fire_slam_attack = true
	attack_elapsed = 0.0
	attack_duration = FIRE_SLAM_DURATION
	locomotion_blend = 0.0
	if is_instance_valid(torso):
		_attack_origin = _capture_pose()

func cancel_fire_slam() -> void:
	_contact_hold = 0.0
	if not fire_slam_attack:
		return
	fire_slam_attack = false
	attack_elapsed = -1.0
	if is_instance_valid(torso):
		tick(0.0,0.0)

func set_sword_flame(burning: bool) -> void:
	sword_burning = burning
	if is_instance_valid(sword_fire):
		sword_fire.set_burning(burning)

func is_attacking() -> bool:
	return attack_elapsed >= 0.0

func contact_pause(seconds: float) -> void:
	# Only the visible pose pauses. Physics, input, enemy timers and the real
	# damage/cooldown clocks keep advancing normally.
	if not is_finite(seconds) or seconds <= 0.0:
		_contact_hold = 0.0
	elif is_attacking():
		_contact_hold = maxf(_contact_hold,clampf(seconds,0.0,0.05))

func set_presentation_pose(enabled: bool) -> void:
	# A preview-only inspection stance; this never starts an attack or skill.
	presentation_active = enabled
	if enabled:
		presentation_phase = 0.0

func hit_flash() -> void:
	flash_time = 0.17
	for part: MeshInstance3D in mesh_parts:
		part.material_overlay = flash_material

func _angles(degrees: Vector3) -> Vector3:
	return degrees * (PI / 180.0)

func _keyframe(at: float, overrides: Dictionary = {}) -> Dictionary:
	var pose: Dictionary = {
		"time":at,"root":Vector3.ZERO,"offset":Vector3.ZERO,
		"hips":Vector3(0,2,0),"torso":Vector3(-2,-2,0),
		"right_arm":Vector3(12,-9,7),"right_forearm":Vector3(59,0,0),
		"wrist":Vector3(-3,0,9),"left_arm":Vector3(-5,0,5),
		"left_forearm":Vector3(20,0,0),"left_leg":Vector3.ZERO,
		"right_leg":Vector3.ZERO,"left_knee":Vector3(-3,0,0),"right_knee":Vector3(-3,0,0)
	}
	pose.merge(overrides,true)
	for key: String in ["root","hips","torso","right_arm","right_forearm","wrist","left_arm","left_forearm","left_leg","right_leg","left_knee","right_knee"]:
		pose[key] = _angles(pose[key])
	return pose

func _build_combat_tracks() -> void:
	# All ordinary cuts meet their contact key at .16 s; the planted fourth
	# strike loads longer and releases at .25 s, matching main's actual hit.
	_combat_tracks = [
		[
			_keyframe(0.0),
			_keyframe(0.04,{"hips":Vector3(0,-9,-1),"torso":Vector3(-3,-8,-2),"right_arm":Vector3(22,-25,8),"right_forearm":Vector3(53,0,0),"left_arm":Vector3(12,8,12),"left_forearm":Vector3(36,0,0),"offset":Vector3(0,-0.022,0.012)}),
			_keyframe(0.095,{"hips":Vector3(0,-14,-3),"torso":Vector3(-5,-24,-5),"right_arm":Vector3(50,-65,26),"right_forearm":Vector3(62,0,0),"wrist":Vector3(-35,-15,4),"left_arm":Vector3(28,20,15),"left_forearm":Vector3(42,0,0)}),
			_keyframe(0.16,{"hips":Vector3(0,12,1),"torso":Vector3(7,20,9),"right_arm":Vector3(16,-19,-9),"right_forearm":Vector3(31,0,0),"wrist":Vector3(-36,-22,-31),"left_arm":Vector3(20,-20,16),"left_forearm":Vector3(48,0,0),"offset":Vector3(-0.015,-0.015,-0.055)}),
			_keyframe(0.255,{"hips":Vector3(0,17,2),"torso":Vector3(9,28,8),"right_arm":Vector3(48,40,-14),"right_forearm":Vector3(28,0,0),"wrist":Vector3(-35,-8,-25),"left_arm":Vector3(5,-30,22),"left_forearm":Vector3(38,0,0),"offset":Vector3(-0.025,-0.01,-0.04)}),
			_keyframe(0.46)
		],
		[
			_keyframe(0.0),
			_keyframe(0.04,{"hips":Vector3(0,8,1),"torso":Vector3(0,7,2),"right_arm":Vector3(29,27,-10),"right_forearm":Vector3(61,0,0),"wrist":Vector3(-18,4,-9),"left_arm":Vector3(12,-8,16),"left_forearm":Vector3(35,0,0),"offset":Vector3(0,-0.022,0.01)}),
			_keyframe(0.09,{"hips":Vector3(0,12,2),"torso":Vector3(2,25,5),"right_arm":Vector3(58,70,-12),"right_forearm":Vector3(60,0,0),"wrist":Vector3(-47,12,-30),"left_arm":Vector3(20,-20,18),"left_forearm":Vector3(50,0,0)}),
			_keyframe(0.16,{"hips":Vector3(0,-12,-2),"torso":Vector3(0,-23,-7),"right_arm":Vector3(77,27,-14),"right_forearm":Vector3(5,0,0),"wrist":Vector3(-52,19,26),"left_arm":Vector3(12,22,23),"left_forearm":Vector3(48,0,0),"offset":Vector3(0.02,-0.012,-0.065)}),
			_keyframe(0.25,{"hips":Vector3(0,-20,-3),"torso":Vector3(-4,-30,-6),"right_arm":Vector3(67,-40,40),"right_forearm":Vector3(26,0,0),"wrist":Vector3(-44,12,22),"left_arm":Vector3(0,30,28),"left_forearm":Vector3(35,0,0),"offset":Vector3(0.02,0,-0.035)}),
			_keyframe(0.46)
		],
		[
			_keyframe(0.0),
			_keyframe(0.045,{"hips":Vector3(-2,-3,0),"torso":Vector3(-7,-3,-1),"right_arm":Vector3(64,-11,3),"right_forearm":Vector3(67,0,0),"wrist":Vector3(-22,0,-3),"left_arm":Vector3(22,8,10),"left_forearm":Vector3(46,0,0),"offset":Vector3(0,-0.028,0.005)}),
			_keyframe(0.105,{"hips":Vector3(0,-5,0),"torso":Vector3(-11,-9,-4),"right_arm":Vector3(146,-12,12),"right_forearm":Vector3(63,0,0),"wrist":Vector3(-42,0,-6),"left_arm":Vector3(63,16,11),"left_forearm":Vector3(64,0,0),"left_knee":Vector3(-7,0,0),"right_knee":Vector3(-9,0,0),"offset":Vector3(0,-0.018,0.015)}),
			_keyframe(0.16,{"hips":Vector3(5,6,0),"torso":Vector3(15,9,3),"right_arm":Vector3(24,-10,-19),"right_forearm":Vector3(41,0,0),"wrist":Vector3(-75,8,28),"left_arm":Vector3(37,-10,20),"left_forearm":Vector3(48,0,0),"left_leg":Vector3(8,0,0),"right_leg":Vector3(-7,0,0),"offset":Vector3(0,-0.035,-0.085)}),
			_keyframe(0.245,{"hips":Vector3(7,9,0),"torso":Vector3(18,12,3),"right_arm":Vector3(5,16,-7),"right_forearm":Vector3(18,0,0),"wrist":Vector3(-38,0,8),"left_arm":Vector3(18,-15,24),"left_forearm":Vector3(30,0,0),"offset":Vector3(0,-0.025,-0.065)}),
			_keyframe(0.46)
		],
		[
			_keyframe(0.0),
			_keyframe(0.055,{"hips":Vector3(-2,-12,-2),"torso":Vector3(-3,-8,-3),"right_arm":Vector3(25,-28,6),"right_forearm":Vector3(65,0,0),"wrist":Vector3(-15,-4,-2),"left_arm":Vector3(19,14,13),"left_forearm":Vector3(49,0,0),"offset":Vector3(0.015,-0.055,0.025)}),
			_keyframe(0.16,{"hips":Vector3(-2,-24,-5),"torso":Vector3(-7,-35,-7),"right_arm":Vector3(48,-85,45),"right_forearm":Vector3(77,0,0),"wrist":Vector3(-45,-10,-6),"left_arm":Vector3(41,30,14),"left_forearm":Vector3(69,0,0),"left_leg":Vector3(8,-5,-2),"right_leg":Vector3(-9,6,2),"left_knee":Vector3(-12,0,0),"right_knee":Vector3(-14,0,0),"offset":Vector3(0.035,-0.10,0.045)}),
			_keyframe(0.25,{"hips":Vector3(4,18,4),"torso":Vector3(8,31,8),"right_arm":Vector3(0,-32,-21),"right_forearm":Vector3(45,0,0),"wrist":Vector3(-16,-12,13),"left_arm":Vector3(25,-28,28),"left_forearm":Vector3(43,0,0),"left_leg":Vector3(13,2,-2),"right_leg":Vector3(-10,8,2),"left_knee":Vector3(-8,0,0),"right_knee":Vector3(-12,0,0),"offset":Vector3(-0.015,-0.105,-0.14)}),
			_keyframe(0.36,{"hips":Vector3(3,28,4),"torso":Vector3(11,44,10),"right_arm":Vector3(45,22,16),"right_forearm":Vector3(22,0,0),"wrist":Vector3(-35,0,-25),"left_arm":Vector3(-3,-38,35),"left_forearm":Vector3(35,0,0),"left_leg":Vector3(10,3,-2),"right_leg":Vector3(-9,8,2),"offset":Vector3(-0.025,-0.085,-0.105)}),
			_keyframe(0.49,{"hips":Vector3(0,12,1),"torso":Vector3(3,17,3),"right_arm":Vector3(28,38,-6),"right_forearm":Vector3(31,0,0),"wrist":Vector3(-14,0,-3),"left_forearm":Vector3(20,0,0),"offset":Vector3(0,0,-0.025)}),
			_keyframe(0.62)
		]
	]
	# Original two-handed ignition: gather, raise, plant, and recover. The
	# hand targets below keep the palms on one hilt throughout the strike.
	_fire_slam_track = [
		_keyframe(0.0),
		_keyframe(0.18,{"hips":Vector3(-3,0,0),"torso":Vector3(-12,0,0),"left_leg":Vector3(6,-4,-4),"right_leg":Vector3(-7,4,4),"left_knee":Vector3(-12,0,0),"right_knee":Vector3(-15,0,0),"offset":Vector3(0,-0.035,0.025)}),
		_keyframe(0.35,{"hips":Vector3(-5,0,0),"torso":Vector3(-17,0,0),"left_leg":Vector3(7,-4,-4),"right_leg":Vector3(-8,4,4),"left_knee":Vector3(-14,0,0),"right_knee":Vector3(-17,0,0),"offset":Vector3(0,-0.045,0.035)}),
		_keyframe(0.39,{"hips":Vector3(-3,0,0),"torso":Vector3(-11,0,0),"left_leg":Vector3(7,-4,-4),"right_leg":Vector3(-8,4,4),"left_knee":Vector3(-14,0,0),"right_knee":Vector3(-17,0,0),"offset":Vector3(0,-0.045,0.02)}),
		_keyframe(FIRE_SLAM_CONTACT,{"hips":Vector3(6,0,0),"torso":Vector3(-26,0,0),"left_leg":Vector3(14,-4,-4),"right_leg":Vector3(-11,4,4),"left_knee":Vector3(-20,0,0),"right_knee":Vector3(-25,0,0),"offset":Vector3(0,-0.075,-0.045)}),
		_keyframe(0.60,{"hips":Vector3(5,0,0),"torso":Vector3(-22,0,0),"left_leg":Vector3(12,-4,-3),"right_leg":Vector3(-10,4,3),"left_knee":Vector3(-17,0,0),"right_knee":Vector3(-21,0,0),"offset":Vector3(0,-0.06,-0.035)}),
		_keyframe(0.82,{"hips":Vector3(1,0,0),"torso":Vector3(-5,0,0),"left_knee":Vector3(-7,0,0),"right_knee":Vector3(-9,0,0),"offset":Vector3(0,-0.015,-0.01)}),
		_keyframe(FIRE_SLAM_DURATION)
	]

func _capture_pose() -> Dictionary:
	# A completed full skill turn is the neutral orientation, not a request
	# for the next cut to unwind 360 degrees back through its first key.
	var root_rotation: Vector3 = Vector3(wrapf(body.rotation.x,-PI,PI),wrapf(body.rotation.y,-PI,PI),wrapf(body.rotation.z,-PI,PI))
	return {"root":root_rotation,"offset":body.position,"hips":hips.rotation,"torso":torso.rotation,"right_arm":right_arm.rotation,"right_forearm":right_forearm.rotation,"wrist":right_wrist.rotation,"left_arm":left_arm.rotation,"left_forearm":left_forearm.rotation,"left_leg":left_leg.rotation,"right_leg":right_leg.rotation,"left_knee":left_knee.rotation,"right_knee":right_knee.rotation}

func _track_key(track: Array,index: int) -> Dictionary:
	var result: Dictionary = track[index]
	if index == 0 and not _attack_origin.is_empty():
		result = result.duplicate()
		result.merge(_attack_origin,true)
	elif index == track.size()-1 and not _locomotion_pose.is_empty():
		# Recover to the current breathing/running pose rather than a frozen
		# neutral key which would snap on the first locomotion frame.
		result = result.duplicate()
		result.merge(_locomotion_pose,true)
	return result

func _pose_tangent(before: Dictionary,current: Dictionary,after: Dictionary,key: String) -> Vector3:
	var first_time: float = maxf(float(current.time)-float(before.time),0.001)
	var next_time: float = maxf(float(after.time)-float(current.time),0.001)
	var incoming: Vector3 = ((current[key] as Vector3)-(before[key] as Vector3))/first_time
	var outgoing: Vector3 = ((after[key] as Vector3)-(current[key] as Vector3))/next_time
	var tangent := Vector3.ZERO
	# Monotone Hermite interpolation keeps a continuous velocity through a
	# contact key while avoiding overshoot at the weapon's extremes.
	for axis: int in range(3):
		if incoming[axis]*outgoing[axis] > 0.0:
			var average: float = (incoming[axis]*next_time+outgoing[axis]*first_time)/(first_time+next_time)
			tangent[axis] = signf(average)*minf(absf(average),3.0*minf(absf(incoming[axis]),absf(outgoing[axis])))
	return tangent

func _interpolated(first: Vector3,second: Vector3,start_tangent: Vector3,end_tangent: Vector3,weight: float,duration: float) -> Vector3:
	var square: float = weight*weight
	var cube: float = square*weight
	return first*(2.0*cube-3.0*square+1.0)+start_tangent*duration*(cube-2.0*square+weight)+second*(-2.0*cube+3.0*square)+end_tangent*duration*(cube-square)

func _apply_cut_pose() -> void:
	var track: Array = _combat_tracks[combo_index]
	_apply_track_pose(track)
	# The pelvis and chest can load into a cut without dragging both boots
	# across the floor. Moving attacks retain the running legs underneath.
	var moving_stance: float = clampf(locomotion_blend*2.0,0.0,1.0)
	var stance: float = sin(clampf(attack_elapsed/attack_duration,0.0,1.0)*PI)
	var left_target: Vector3 = _stance_foot(true)
	var right_target: Vector3 = _stance_foot(false)
	if combo_index == 3:
		left_target += Vector3(-0.035,0.0,-0.09)*stance
		right_target += Vector3(0.035,0.0,0.055)*stance
	left_target = left_target.lerp(_running_foot(_left_ankle_rest,walk_phase),moving_stance)
	right_target = right_target.lerp(_running_foot(_right_ankle_rest,walk_phase+PI),moving_stance)
	var left_pitch: float = clampf(sin(walk_phase-0.8)*0.24,-0.18,0.24)*locomotion_blend
	var right_pitch: float = clampf(sin(walk_phase+PI-0.8)*0.24,-0.18,0.24)*locomotion_blend
	_plant_feet(left_target,right_target,1.0,left_pitch,right_pitch)
	if combo_index == 3:
		_apply_finisher_grip()

func _apply_finisher_grip() -> void:
	# The final cut uses the spare hand and the whole loaded stance. A real
	# hilt target makes the power stroke read as a deliberate two-hand action.
	var grip_weight: float = minf(smoothstep(0.035,0.14,attack_elapsed),1.0-smoothstep(0.37,0.56,attack_elapsed))
	if grip_weight <= 0.0:
		return
	var segment: int = FINISHER_GRIP_TRACK.size()-2
	for index: int in range(1,FINISHER_GRIP_TRACK.size()):
		if attack_elapsed <= float(FINISHER_GRIP_TRACK[index].time):
			segment = index-1
			break
	var first: Dictionary = FINISHER_GRIP_TRACK[segment]
	var second: Dictionary = FINISHER_GRIP_TRACK[segment+1]
	var before: Dictionary = FINISHER_GRIP_TRACK[maxi(segment-1,0)]
	var after: Dictionary = FINISHER_GRIP_TRACK[mini(segment+2,FINISHER_GRIP_TRACK.size()-1)]
	var duration: float = maxf(float(second.time)-float(first.time),0.001)
	var alpha: float = clampf((attack_elapsed-float(first.time))/duration,0.0,1.0)
	var target: Vector3 = Vector3.ZERO
	var angle: float = 0.0
	for channel: String in ["target","angle"]:
		var start_tangent: Vector3 = Vector3.ZERO if segment == 0 else _pose_tangent(before,first,second,channel)
		var end_tangent: Vector3 = Vector3.ZERO if segment+1 == FINISHER_GRIP_TRACK.size()-1 else _pose_tangent(first,second,after,channel)
		var value: Vector3 = _interpolated(first[channel],second[channel],start_tangent,end_tangent,alpha,duration)
		if channel == "target":
			target = value
		else:
			angle = value.x
	_solve_arm(right_arm,right_forearm,to_global(target),1.0,grip_weight)
	var blade_basis: Basis = global_basis.orthonormalized()*Basis.from_euler(Vector3(angle,0.0,0.0))
	var wrist_basis: Basis = blade_basis*sword.basis.orthonormalized().inverse()
	right_wrist.global_basis = Basis(right_wrist.global_basis.get_rotation_quaternion().slerp(wrist_basis.get_rotation_quaternion(),grip_weight))
	_solve_arm(left_arm,left_forearm,sword.to_global(Vector3(0.0,-0.14,0.0)),-1.0,grip_weight)
	left_wrist.global_basis = Basis(left_wrist.global_basis.get_rotation_quaternion().slerp(right_wrist.global_basis.get_rotation_quaternion(),grip_weight))

func _apply_track_pose(track: Array) -> void:
	var segment: int = track.size()-2
	for index: int in range(1,track.size()):
		if attack_elapsed <= float(track[index].time):
			segment = index-1
			break
	var previous: Dictionary = _track_key(track,segment)
	var following: Dictionary = _track_key(track,segment+1)
	var duration: float = maxf(float(following.time)-float(previous.time),0.001)
	var alpha: float = clampf((attack_elapsed-float(previous.time))/duration,0,1)
	var before: Dictionary = _track_key(track,maxi(segment-1,0))
	var after: Dictionary = _track_key(track,mini(segment+2,track.size()-1))
	var pose: Dictionary = {}
	for channel: String in POSE_CHANNELS:
		var start_tangent: Vector3 = Vector3.ZERO if segment == 0 else _pose_tangent(before,previous,following,channel)
		var end_tangent: Vector3 = Vector3.ZERO if segment+1 == track.size()-1 else _pose_tangent(previous,following,after,channel)
		pose[channel] = _interpolated(previous[channel],following[channel],start_tangent,end_tangent,alpha,duration)
	body.position = pose.offset
	body.rotation = pose.root
	hips.rotation = pose.hips
	torso.rotation = pose.torso
	right_arm.rotation = pose.right_arm
	right_forearm.rotation = pose.right_forearm
	right_wrist.rotation = pose.wrist
	left_arm.rotation = pose.left_arm
	left_forearm.rotation = pose.left_forearm
	var stance_weight: float = 1.0-clampf(locomotion_blend*2.0,0,1)
	left_leg.rotation = left_leg.rotation.lerp(pose.left_leg,stance_weight)
	right_leg.rotation = right_leg.rotation.lerp(pose.right_leg,stance_weight)
	left_knee.rotation = left_knee.rotation.lerp(pose.left_knee,stance_weight)
	right_knee.rotation = right_knee.rotation.lerp(pose.right_knee,stance_weight)
	head.rotation = Vector3(-torso.rotation.x*0.35,-torso.rotation.y*0.38,-torso.rotation.z*0.25)

func _apply_fire_slam_pose() -> void:
	_apply_track_pose(_fire_slam_track)
	# A shorter starter blade needs a deeper planted stance. Bend the knees
	# while lowering the pelvis so both human hands can reach the same hilt
	# without stretching either forearm or leaving the point above ground.
	var plant_weight: float = minf(clampf((attack_elapsed-0.35)/0.13,0.0,1.0),clampf((0.82-attack_elapsed)/0.22,0.0,1.0))
	plant_weight = plant_weight*plant_weight*(3.0-2.0*plant_weight)
	var crouch_weight: float = float(3-weapon_tier)/3.0*plant_weight
	body.position.y -= 0.24*crouch_weight
	left_leg.rotation.x = lerpf(left_leg.rotation.x,0.63,crouch_weight)
	right_leg.rotation.x = lerpf(right_leg.rotation.x,0.63,crouch_weight)
	left_knee.rotation.x = lerpf(left_knee.rotation.x,-1.24,crouch_weight)
	right_knee.rotation.x = lerpf(right_knee.rotation.x,-1.24,crouch_weight)
	var impact_height: float = 0.07+1.205*sword.scale.y*cos(0.12)
	var keys: Array = [
		[0.0,Vector3(0.0,1.36,-0.30),1.05],
		[0.18,Vector3(-0.06,1.70,-0.20),3.25],
		[0.35,Vector3(-0.06,1.75,-0.10),3.48],
		[0.39,Vector3(-0.06,1.75,-0.10),3.42],
		[FIRE_SLAM_CONTACT,Vector3(0.0,impact_height,-0.32),0.12],
		[0.60,Vector3(0.0,impact_height+0.025,-0.31),0.16],
		[0.82,Vector3(0.0,1.40,-0.28),0.95],
		[FIRE_SLAM_DURATION,Vector3(0.22,1.30,-0.37),0.94]
	]
	var first: Array = keys[0]
	var second: Array = keys.back()
	for i: int in range(1,keys.size()):
		second = keys[i]
		if attack_elapsed <= float(second[0]):
			first = keys[i-1]
			break
	var alpha: float = clampf((attack_elapsed-float(first[0]))/maxf(float(second[0])-float(first[0]),0.001),0.0,1.0)
	alpha = alpha*alpha*(3.0-2.0*alpha)
	var wrist_target: Vector3 = (first[1] as Vector3).lerp(second[1],alpha)
	var sword_angle: float = lerpf(float(first[2]),float(second[2]),alpha)
	var grip_weight: float = minf(clampf(attack_elapsed/0.12,0.0,1.0),clampf((FIRE_SLAM_DURATION-attack_elapsed)/0.15,0.0,1.0))
	grip_weight = grip_weight*grip_weight*(3.0-2.0*grip_weight)
	_solve_arm(right_arm,right_forearm,to_global(wrist_target),1.0,grip_weight)
	var blade_basis: Basis = global_basis.orthonormalized()*Basis.from_euler(Vector3(sword_angle,0.0,0.0))
	var wrist_basis: Basis = blade_basis*sword.basis.orthonormalized().inverse()
	right_wrist.global_basis = Basis(right_wrist.global_basis.get_rotation_quaternion().slerp(wrist_basis.get_rotation_quaternion(),grip_weight))
	# The second palm grips the lower handle, above the crossguard. It is
	# solved against the actual sword transform, including equipment scale.
	_solve_arm(left_arm,left_forearm,sword.to_global(Vector3(0,-0.14,0)),-1.0,grip_weight)
	left_wrist.global_basis = Basis(left_wrist.global_basis.get_rotation_quaternion().slerp(right_wrist.global_basis.get_rotation_quaternion(),grip_weight))
	# Plant the boots while the body settles into the impact. This is the
	# same analytical two-bone solve as the arms, with knees bending forward.
	var knee_pole: Vector3 = global_basis.orthonormalized()*Vector3(0,0,-1)
	_solve_limb(left_leg,left_knee,left_ankle.position,to_global(_left_ankle_rest),knee_pole,plant_weight)
	_solve_limb(right_leg,right_knee,right_ankle.position,to_global(_right_ankle_rest),knee_pole,plant_weight)
	left_ankle.global_basis = Basis(left_ankle.global_basis.get_rotation_quaternion().slerp(global_basis.orthonormalized().get_rotation_quaternion(),plant_weight))
	right_ankle.global_basis = Basis(right_ankle.global_basis.get_rotation_quaternion().slerp(global_basis.orthonormalized().get_rotation_quaternion(),plant_weight))

func _solve_arm(upper: Node3D,lower: Node3D,target: Vector3,side: float,weight: float) -> void:
	var hand_offset: Vector3 = right_wrist.position if lower == right_forearm else left_wrist.position
	var pole: Vector3 = global_basis.orthonormalized()*Vector3(side,0.12,0.24)
	_solve_limb(upper,lower,hand_offset,target,pole,weight)

func _solve_limb(upper: Node3D,lower: Node3D,end_offset: Vector3,target: Vector3,pole: Vector3,weight: float) -> void:
	var shoulder: Vector3 = upper.global_position
	var upper_length: float = lower.position.length()
	var lower_length: float = end_offset.length()
	var delta: Vector3 = target-shoulder
	var distance: float = clampf(delta.length(),absf(upper_length-lower_length)+0.001,upper_length+lower_length-0.001)
	var direction: Vector3 = delta.normalized() if delta.length_squared() > 0.00001 else Vector3.DOWN
	var bend: Vector3 = pole-direction*pole.dot(direction)
	if bend.length_squared() < 0.00001:
		bend = direction.cross(Vector3.FORWARD)
	bend = bend.normalized()
	var along: float = (upper_length*upper_length-lower_length*lower_length+distance*distance)/(2.0*distance)
	var perpendicular: float = sqrt(maxf(0.0,upper_length*upper_length-along*along))
	var elbow: Vector3 = shoulder+direction*along+bend*perpendicular
	var upper_basis: Basis = Basis(Quaternion(lower.position.normalized(),(elbow-shoulder).normalized()))
	upper.global_basis = Basis(upper.global_basis.get_rotation_quaternion().slerp(upper_basis.get_rotation_quaternion(),weight))
	var reachable_hand: Vector3 = shoulder+direction*distance
	var lower_basis: Basis = Basis(Quaternion(end_offset.normalized(),(reachable_hand-lower.global_position).normalized()))
	lower.global_basis = Basis(lower.global_basis.get_rotation_quaternion().slerp(lower_basis.get_rotation_quaternion(),weight))

func _plant_feet(left_target: Vector3,right_target: Vector3,weight: float,left_pitch: float = 0.0,right_pitch: float = 0.0) -> void:
	if weight <= 0.0:
		return
	var frame: Basis = global_basis.orthonormalized()
	var pole: Vector3 = frame*Vector3(0.0,0.0,-1.0)
	_solve_limb(left_leg,left_knee,left_ankle.position,to_global(left_target),pole,weight)
	_solve_limb(right_leg,right_knee,right_ankle.position,to_global(right_target),pole,weight)
	var left_basis: Basis = frame*Basis(Vector3.RIGHT,left_pitch)
	var right_basis: Basis = frame*Basis(Vector3.RIGHT,right_pitch)
	left_ankle.global_basis = Basis(left_ankle.global_basis.get_rotation_quaternion().slerp(left_basis.get_rotation_quaternion(),weight))
	right_ankle.global_basis = Basis(right_ankle.global_basis.get_rotation_quaternion().slerp(right_basis.get_rotation_quaternion(),weight))

func _running_foot(rest: Vector3,phase: float) -> Vector3:
	var cycle: float = fposmod(phase/TAU,1.0)
	var target: Vector3 = rest
	var stride: float = 0.43
	if cycle < 0.57:
		# During support the boot moves backwards relative to the moving body,
		# then the raised foot returns forward along a short rounded arc.
		target.z += lerpf(-stride,stride,cycle/0.57)
	else:
		var swing: float = (cycle-0.57)/0.43
		var eased: float = swing*swing*(3.0-2.0*swing)
		target.z += lerpf(stride,-stride,eased)
		target.y += sin(swing*PI)*0.27
	var stance: Vector3 = _stance_foot(rest.x < 0.0)
	return stance.lerp(target,locomotion_blend)

func _stance_foot(left: bool) -> Vector3:
	return (_left_ankle_rest+Vector3(-0.065,0.0,-0.055)) if left else (_right_ankle_rest+Vector3(0.065,0.0,0.055))

func _apply_presentation_pose(delta: float) -> void:
	presentation_phase += delta
	var rise: float = smoothstep(0.0,0.75,presentation_phase)*_presentation_blend
	var display: float = (0.5+0.5*sin(presentation_phase*0.6))*0.13
	var inspecting: float = 0.5-0.5*cos(presentation_phase*0.55)
	body.position.y -= 0.012*rise
	hips.rotation.y = lerp_angle(hips.rotation.y,-0.13,rise)
	torso.rotation.y = lerp_angle(torso.rotation.y,0.25,rise)
	right_arm.rotation = right_arm.rotation.lerp(Vector3(0.25,-0.05,0.18),rise)
	right_forearm.rotation = right_forearm.rotation.lerp(Vector3(0.78+display,0.0,0.0),rise)
	right_wrist.rotation = right_wrist.rotation.lerp(Vector3(-0.20,-0.25,0.08+sin(presentation_phase*0.7)*0.03),rise)
	left_arm.rotation = left_arm.rotation.lerp(Vector3(0.18,0.12,0.15),rise)
	left_forearm.rotation = left_forearm.rotation.lerp(Vector3(0.82,0.0,0.0),rise)
	head.rotation.y = (-0.13-0.12*inspecting)*rise
	head.rotation.x = (-0.06-0.04*inspecting)*rise
	_plant_feet(_stance_foot(true),_stance_foot(false),1.0)

func tick(delta: float, moving: float) -> void:
	if not is_instance_valid(torso):
		return
	idle_phase += delta
	var moving_target: float = clampf(moving,0.0,1.0)
	_presentation_blend = move_toward(_presentation_blend,1.0 if presentation_active else 0.0,delta*5.0)
	# Blend the gait, but keep the camera and world transform fully direct.
	locomotion_blend = move_toward(locomotion_blend,moving_target,delta*(5.5 if moving_target > locomotion_blend else 7.0))
	walk_phase += delta*lerpf(2.8,10.6,locomotion_blend)
	var step: float = sin(walk_phase)
	var passing: float = cos(walk_phase)
	var breath: float = sin(idle_phase*TAU/3.7)
	var weight_shift: float = sin(idle_phase*TAU/5.2)
	var resting: float = 1.0-locomotion_blend
	body.position = Vector3(weight_shift*0.007*resting,(-0.045+0.018*cos(walk_phase*2.0))*locomotion_blend+(-0.020+breath*0.005)*resting,0.0)
	body.rotation = Vector3(-0.018*locomotion_blend,-0.11*resting,0.0)
	hips.rotation = Vector3(-0.025*locomotion_blend,0.035*resting+step*0.055*locomotion_blend,step*0.025*locomotion_blend+weight_shift*0.010*resting)
	torso.rotation = Vector3(-0.032-0.040*locomotion_blend+breath*0.009*resting,-hips.rotation.y*0.8+weight_shift*0.008*resting,-hips.rotation.z*0.6)
	left_leg.rotation = Vector3(step*0.48*locomotion_blend,0.025,-0.012*resting)
	right_leg.rotation = Vector3(-step*0.48*locomotion_blend,-0.025,0.012*resting)
	left_knee.rotation = Vector3(-0.045-maxf(0.0,passing)*0.90*locomotion_blend,0.0,0.0)
	right_knee.rotation = Vector3(-0.045-maxf(0.0,-passing)*0.90*locomotion_blend,0.0,0.0)
	# The sword arm carries its weight near the ribs instead of swinging like
	# an empty hand. The free arm counters the leading hip with a soft elbow.
	left_arm.rotation = Vector3(-0.10-step*0.43*locomotion_blend,0.025,0.095+weight_shift*0.010*resting)
	right_arm.rotation = Vector3(0.20+step*0.10*locomotion_blend,-0.15,0.12)
	left_forearm.rotation = Vector3(0.34+0.30*locomotion_blend+maxf(0.0,step)*0.12*locomotion_blend+breath*0.016*resting,0.0,0.0)
	right_forearm.rotation = Vector3(0.88-0.10*locomotion_blend+maxf(0.0,-step)*0.10*locomotion_blend+breath*0.014*resting,0.0,0.0)
	right_wrist.rotation = Vector3(-0.06-0.05*locomotion_blend,-0.25,0.16+step*0.018*locomotion_blend)
	left_wrist.rotation = Vector3(0.0,0.0,breath*0.008*resting)
	left_ankle.rotation = Vector3.ZERO
	right_ankle.rotation = Vector3.ZERO
	head.rotation = Vector3(-torso.rotation.x*0.55,sin(idle_phase*0.47)*0.018*resting,-hips.rotation.z*0.65)
	cape.rotation.x = -0.16+0.035*sin(walk_phase-0.6)*locomotion_blend+breath*0.012*resting
	cape.rotation.z = -hips.rotation.z*0.35
	var left_pitch: float = clampf(sin(walk_phase-0.8)*0.24,-0.18,0.24)*locomotion_blend
	var right_pitch: float = clampf(sin(walk_phase+PI-0.8)*0.24,-0.18,0.24)*locomotion_blend
	_plant_feet(_running_foot(_left_ankle_rest,walk_phase),_running_foot(_right_ankle_rest,walk_phase+PI),1.0,left_pitch,right_pitch)
	if _presentation_blend > 0.0 and attack_elapsed < 0.0 and locomotion_blend < 0.01:
		_apply_presentation_pose(delta)
	_locomotion_pose = _capture_pose()
	slash.visible = false
	spin_ring.visible = false
	if attack_elapsed >= 0.0:
		var advance: float = delta
		if _contact_hold > 0.0:
			var held: float = minf(_contact_hold,advance)
			_contact_hold -= held
			advance -= held
		attack_elapsed = minf(attack_elapsed+advance,attack_duration)
		var t: float = attack_elapsed/attack_duration
		if fire_slam_attack:
			_apply_fire_slam_pose()
		elif skill_attack:
			var spin: float = clampf((t-0.12)/0.76,0,1)
			spin = spin*spin*(3.0-2.0*spin)
			var readiness: float = minf(smoothstep(0.0,0.18,t),1.0-smoothstep(0.82,1.0,t))
			var return_weight: float = smoothstep(0.75,1.0,t)
			var starting_yaw: float = float((_attack_origin.get("root",Vector3.ZERO) as Vector3).y)
			body.rotation.y = spin*TAU+lerp_angle(starting_yaw,(_locomotion_pose.root as Vector3).y,return_weight)
			body.position.y -= sin(t*PI)*0.025
			hips.rotation = hips.rotation.lerp(Vector3(-0.06,0.0,0.0),readiness)
			torso.rotation = torso.rotation.lerp(Vector3(-0.07,-0.06,0.0),readiness)
			var spin_channels: Dictionary = {"right_arm":Vector3(0.50,-0.55,1.12),"right_forearm":Vector3(0.30,0,0),"wrist":Vector3(-0.40,0,0),"left_arm":Vector3(0.28,0.30,-0.78),"left_forearm":Vector3(0.40,0,0)}
			for channel: String in spin_channels:
				var origin: Vector3 = _attack_origin.get(channel,_locomotion_pose[channel])
				var recovery: Vector3 = origin.lerp(_locomotion_pose[channel],return_weight)
				var value: Vector3 = recovery.lerp(spin_channels[channel],readiness)
				match channel:
					"right_arm": right_arm.rotation = value
					"right_forearm": right_forearm.rotation = value
					"wrist": right_wrist.rotation = value
					"left_arm": left_arm.rotation = value
					"left_forearm": left_forearm.rotation = value
			left_knee.rotation.x -= sin(t*PI)*0.22
			right_knee.rotation.x -= sin(t*PI)*0.12
			head.rotation.y = -torso.rotation.y*0.4
			spin_ring.visible = t > 0.18 and t < 0.88
			spin_ring.rotation.y = -t*TAU
			spin_ring.scale = Vector3.ONE*(0.7+0.4*sin(t*PI))
			slash_material.albedo_color = Color(0.48,0.85,1.0,sin(t*PI)*0.65)
		else:
			_apply_cut_pose()
		if t >= 1.0:
			attack_elapsed = -1.0
			fire_slam_attack = false
	if flash_time > 0.0:
		flash_time -= delta
		if flash_time <= 0.0:
			for part: MeshInstance3D in mesh_parts:
				part.material_overlay = null

	if is_instance_valid(model):
		model.sync_pose()

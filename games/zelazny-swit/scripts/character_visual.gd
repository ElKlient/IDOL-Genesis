class_name CharacterVisual
extends Node3D
## Original armored human using a continuous imported skin and a procedural rig.

const WarriorModelScript = preload("res://scripts/warrior_model.gd")
const SwordFireScript = preload("res://scripts/sword_fire_effect.gd")
const MotionProfileScript = preload("res://scripts/weapon_motion_profile.gd")
const DEFAULT_MOTION_PROFILE = preload("res://assets/warrior/sword_motion.tres")
const Timing = preload("res://scripts/attack_timing.gd")
const FIRE_SLAM_DURATION: float = 1.0
const FIRE_SLAM_CONTACT: float = 0.48
const POSE_CHANNELS: Array[String] = ["root","offset","hips","torso","right_arm","right_forearm","wrist","left_arm","left_forearm","left_leg","right_leg","left_knee","right_knee"]
# Hilt positions are in character space; blade directions are unit-independent.
# One coherent path drives the hand AND blade, rather than unrelated shoulder,
# elbow and wrist rotations fighting each other. These are authored phases,
# with contact at .42 for the cuts and .49 for the two-handed finisher.
# _cut_sample_time maps the shared real damage time onto that exact marker.
const BLADE_CUT_TRACKS: Array = [
	[
		[0.0,Vector3(0.25,1.25,-0.28),Vector3(0.18,0.42,-0.89)],
		[0.24,Vector3(0.44,1.42,0.02),Vector3(0.76,0.62,0.18)],
		[0.31,Vector3(0.40,1.46,-0.16),Vector3(0.81,0.24,-0.54)],
		[0.42,Vector3(0.15,1.31,-0.51),Vector3(-0.30,-0.23,-0.93)],
		[0.52,Vector3(-0.13,1.10,-0.37),Vector3(-0.82,-0.52,-0.24)],
		[0.88,Vector3(0.18,1.14,-0.24),Vector3(-0.12,-0.18,-0.98)],
		[1.0,Vector3(0.25,1.25,-0.28),Vector3(0.18,0.42,-0.89)]
	],
	[
		[0.0,Vector3(0.25,1.25,-0.28),Vector3(0.18,0.42,-0.89)],
		[0.24,Vector3(-0.10,1.13,-0.29),Vector3(-0.82,-0.29,-0.49)],
		[0.31,Vector3(-0.06,1.22,-0.42),Vector3(-0.62,-0.10,-0.78)],
		[0.42,Vector3(0.18,1.35,-0.51),Vector3(0.36,0.15,-0.92)],
		[0.59,Vector3(0.43,1.48,-0.22),Vector3(0.83,0.45,-0.33)],
		[0.80,Vector3(0.41,1.25,-0.18),Vector3(0.54,0.24,-0.81)],
		[1.0,Vector3(0.25,1.25,-0.28),Vector3(0.18,0.42,-0.89)]
	],
	[
		[0.0,Vector3(0.25,1.25,-0.28),Vector3(0.18,0.42,-0.89)],
		[0.24,Vector3(0.29,1.57,-0.16),Vector3(0.29,0.93,-0.22)],
		[0.31,Vector3(0.23,1.60,-0.24),Vector3(0.18,0.78,-0.60)],
		[0.42,Vector3(0.10,1.29,-0.51),Vector3(-0.12,-0.30,-0.95)],
		[0.59,Vector3(-0.02,1.09,-0.39),Vector3(-0.25,-0.67,-0.70)],
		[0.80,Vector3(0.21,1.12,-0.24),Vector3(0.12,-0.24,-0.96)],
		[1.0,Vector3(0.25,1.25,-0.28),Vector3(0.18,0.42,-0.89)]
	],
	[
		[0.0,Vector3(0.25,1.25,-0.28),Vector3(0.18,0.42,-0.89)],
		[0.23,Vector3(0.10,1.48,-0.25),Vector3(0.12,0.88,-0.46)],
		[0.35,Vector3(0.07,1.64,-0.18),Vector3(0.10,0.96,-0.26)],
		[0.40,Vector3(0.06,1.60,-0.29),Vector3(0.06,0.69,-0.72)],
		[0.49,Vector3(0.03,1.30,-0.53),Vector3(0.0,-0.22,-0.98)],
		[0.64,Vector3(-0.04,1.07,-0.43),Vector3(-0.10,-0.68,-0.73)],
		[0.82,Vector3(0.05,1.15,-0.34),Vector3(0.0,-0.25,-0.97)],
		[1.0,Vector3(0.25,1.25,-0.28),Vector3(0.18,0.42,-0.89)]
	]
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
var motion_profile: Resource = DEFAULT_MOTION_PROFILE
var locomotion_blend: float = 0.0
var _combat_tracks: Array = []
var _attack_origin: Dictionary = {}
var attack_elapsed: float = -1.0
var attack_duration: float = 0.82
var attack_rate: float = 1.0
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
var _attack_blade_origin: Transform3D = Transform3D.IDENTITY
var _guard_blade: Transform3D = Transform3D.IDENTITY

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

func set_motion_profile(profile: Resource) -> bool:
	# Shared by live actor and portrait. Grip presentation can be authored for
	# another class without coupling it to inventory or damage timing. Its
	# attack clips and support-hand rig still need their own authored motion.
	if is_attacking() or not profile is MotionProfileScript or not profile.valid():
		return false
	motion_profile = profile
	return true

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

func start_attack(combo: int = 0, skill: bool = false, rate: float = 1.0) -> void:
	if is_instance_valid(sword):
		_attack_blade_origin = global_transform.affine_inverse()*sword.global_transform
	_contact_hold = 0.0
	presentation_active = false
	_presentation_blend = 0.0
	fire_slam_attack = false
	combo_index = posmod(combo, 4)
	skill_attack = skill
	# Snapshot once: a bonus changing during an already accepted attack must
	# never move its blade/contact schedule partway through the animation.
	attack_rate = 1.0 if skill else Timing.safe_rate(rate)
	attack_elapsed = 0.0
	attack_duration = 0.68 if skill else Timing.duration(combo_index,attack_rate)
	if is_instance_valid(torso):
		_attack_origin = _capture_pose()

func start_fire_slam() -> void:
	if is_instance_valid(sword):
		_attack_blade_origin = global_transform.affine_inverse()*sword.global_transform
	_contact_hold = 0.0
	presentation_active = false
	_presentation_blend = 0.0
	skill_attack = false
	fire_slam_attack = true
	attack_rate = 1.0
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
		var maximum_hold: float = 0.05 if skill_attack or fire_slam_attack else 0.05/attack_rate
		_contact_hold = maxf(_contact_hold,clampf(seconds,0.0,maximum_hold))

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
		"right_arm":Vector3(12,-9,7),"right_forearm":Vector3(51,0,0),
		"wrist":Vector3(-3,0,9),"left_arm":Vector3(-5,0,5),
		"left_forearm":Vector3(20,0,0),"left_leg":Vector3.ZERO,
		"right_leg":Vector3.ZERO,"left_knee":Vector3(-3,0,0),"right_knee":Vector3(-3,0,0)
	}
	pose.merge(overrides,true)
	for key: String in ["root","hips","torso","right_arm","right_forearm","wrist","left_arm","left_forearm","left_leg","right_leg","left_knee","right_knee"]:
		pose[key] = _angles(pose[key])
	return pose

func _build_combat_tracks() -> void:
	# Hips load first, then the chest and blade release into the shared
	# contact marker. The longer gather and follow-through communicate mass
	# without adding geometry, effects, or a second independent attack clock.
	_combat_tracks = [
		[
			_keyframe(0),
			_keyframe(0.18,{"hips":Vector3(0,-10,0),"torso":Vector3(0,-3,-1),"offset":Vector3(-0.012,-0.022,0.014),"left_arm":Vector3(6,-4,11),"left_forearm":Vector3(43,0,0)}),
			_keyframe(0.29,{"hips":Vector3(0,-6,0),"torso":Vector3(-2,-17,-2),"offset":Vector3(-0.010,-0.030,0.004),"left_arm":Vector3(9,-3,10),"left_forearm":Vector3(48,0,0)}),
			_keyframe(0.42,{"hips":Vector3(0,12,0),"torso":Vector3(3,14,1),"offset":Vector3(0.018,-0.040,-0.055),"left_arm":Vector3(8,2,13),"left_forearm":Vector3(45,0,0)}),
			_keyframe(0.52,{"hips":Vector3(0,15,0),"torso":Vector3(5,19,2),"offset":Vector3(0.025,-0.030,-0.055),"left_arm":Vector3(5,3,15),"left_forearm":Vector3(38,0,0)}),
			_keyframe(0.88,{"hips":Vector3(0,6,0),"torso":Vector3(1,7,1),"offset":Vector3(0.010,-0.026,-0.020),"left_arm":Vector3(2,0,10),"left_forearm":Vector3(30,0,0)}),
			_keyframe(1.0)
		],
		[
			_keyframe(0),
			_keyframe(0.18,{"hips":Vector3(0,10,0),"torso":Vector3(1,5,1),"offset":Vector3(0.012,-0.025,0.010),"left_arm":Vector3(7,3,12),"left_forearm":Vector3(44,0,0)}),
			_keyframe(0.29,{"hips":Vector3(0,6,0),"torso":Vector3(0,17,2),"offset":Vector3(0.010,-0.032,0.0),"left_arm":Vector3(9,3,11),"left_forearm":Vector3(48,0,0)}),
			_keyframe(0.42,{"hips":Vector3(0,-12,0),"torso":Vector3(2,-14,-1),"offset":Vector3(-0.015,-0.040,-0.055),"left_arm":Vector3(8,-2,14),"left_forearm":Vector3(43,0,0)}),
			_keyframe(0.59,{"hips":Vector3(0,-15,0),"torso":Vector3(-2,-18,-2),"offset":Vector3(-0.022,-0.032,-0.045),"left_arm":Vector3(5,-3,15),"left_forearm":Vector3(36,0,0)}),
			_keyframe(0.80,{"hips":Vector3(0,-5,0),"torso":Vector3(0,-7,-1),"offset":Vector3(-0.008,-0.025,-0.020),"left_arm":Vector3(2,0,10),"left_forearm":Vector3(30,0,0)}),
			_keyframe(1.0)
		],
		[
			_keyframe(0),
			_keyframe(0.18,{"hips":Vector3(0,-7,0),"torso":Vector3(-7,-4,-1),"offset":Vector3(-0.006,-0.032,0.020),"left_arm":Vector3(7,-2,10),"left_forearm":Vector3(42,0,0)}),
			_keyframe(0.29,{"hips":Vector3(0,-1,0),"torso":Vector3(-10,-5,0),"offset":Vector3(0,-0.024,0.008),"left_arm":Vector3(9,0,10),"left_forearm":Vector3(47,0,0)}),
			_keyframe(0.42,{"hips":Vector3(0,7,0),"torso":Vector3(9,11,0),"offset":Vector3(0.008,-0.050,-0.065),"left_arm":Vector3(8,1,12),"left_forearm":Vector3(45,0,0)}),
			_keyframe(0.59,{"hips":Vector3(0,9,0),"torso":Vector3(13,12,1),"offset":Vector3(0.010,-0.055,-0.050),"left_arm":Vector3(5,2,14),"left_forearm":Vector3(39,0,0)}),
			_keyframe(0.80,{"hips":Vector3(0,4,0),"torso":Vector3(4,5,0),"offset":Vector3(0,-0.030,-0.020),"left_arm":Vector3(2,0,10),"left_forearm":Vector3(30,0,0)}),
			_keyframe(1.0)
		],
		[
			_keyframe(0),
			_keyframe(0.18,{"hips":Vector3(0,-7,0),"torso":Vector3(-5,-4,0),"offset":Vector3(0,-0.045,0.025),"left_arm":Vector3(8,0,9),"left_forearm":Vector3(48,0,0)}),
			_keyframe(0.35,{"hips":Vector3(0,-8,0),"torso":Vector3(-11,-12,0),"offset":Vector3(0,-0.072,0.018),"left_arm":Vector3(8,0,9),"left_forearm":Vector3(48,0,0)}),
			_keyframe(0.40,{"hips":Vector3(0,2,0),"torso":Vector3(-6,-8,0),"offset":Vector3(0,-0.072,-0.008),"left_arm":Vector3(8,0,9),"left_forearm":Vector3(48,0,0)}),
			_keyframe(0.49,{"hips":Vector3(0,10,0),"torso":Vector3(12,11,0),"offset":Vector3(0,-0.085,-0.090),"left_arm":Vector3(8,0,9),"left_forearm":Vector3(48,0,0)}),
			_keyframe(0.64,{"hips":Vector3(0,13,0),"torso":Vector3(16,17,0),"offset":Vector3(0,-0.072,-0.070),"left_arm":Vector3(8,0,9),"left_forearm":Vector3(48,0,0)}),
			_keyframe(0.82,{"hips":Vector3(0,5,0),"torso":Vector3(4,7,0),"offset":Vector3(0,-0.035,-0.030),"left_arm":Vector3(4,0,10),"left_forearm":Vector3(36,0,0)}),
			_keyframe(1.0)
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

func _cut_sample_time() -> float:
	# Keep the poses independent from the controller's real-second schedule.
	# The same snapshotted rate drives both clocks, and this map ensures that
	# the authored contact key is reached on the shared actual damage time.
	var phase: float = clampf(attack_elapsed/attack_duration,0.0,1.0)
	var live_contact: float = Timing.contact_time(combo_index,attack_rate)/attack_duration
	var authored_contact: float = 0.49 if combo_index == 3 else 0.42
	if phase <= live_contact:
		return phase*authored_contact/live_contact
	return authored_contact+(phase-live_contact)*(1.0-authored_contact)/(1.0-live_contact)

func _apply_cut_pose() -> void:
	var track: Array = _combat_tracks[combo_index]
	_apply_track_pose(track,_cut_sample_time())
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
	_apply_blade_cut()

func _blade_key(track: Array,index: int) -> Dictionary:
	var key: Array = track[index]
	var target: Vector3 = key[1]
	var direction: Vector3 = (key[2] as Vector3).normalized()
	if index == 0:
		target = _attack_blade_origin.origin
		direction = -_attack_blade_origin.basis.y.normalized()
	elif index == track.size()-1:
		target = _guard_blade.origin
		direction = -_guard_blade.basis.y.normalized()
	var orientation := Quaternion(Vector3.DOWN,direction)
	if index == 0:
		orientation = _attack_blade_origin.basis.orthonormalized().get_rotation_quaternion()
	elif index == track.size()-1:
		orientation = _guard_blade.basis.orthonormalized().get_rotation_quaternion()
	elif index == track.size()-2:
		# Recovery belongs to the equipped weapon's current guard, not the
		# historical lowered carry baked into these attack keys. Arrive near
		# that live guard early so the final segment merely settles the sword,
		# rather than whipping a lowered blade up in the last tenth of a cut.
		# The wide first diagonal has the longest angular return. Spread that
		# return across .52–.88 instead of whipping it up in a short middle
		# segment; the final fraction only settles an almost recovered guard.
		target = target.lerp(_guard_blade.origin,0.85 if combo_index == 0 else 0.74)
		orientation = orientation.slerp(_guard_blade.basis.orthonormalized().get_rotation_quaternion(),0.90 if combo_index == 0 else 0.72)
		direction = -(Basis(orientation).y)
	return {"time":key[0],"target":target,"direction":direction,"orientation":orientation}

func _apply_blade_cut() -> void:
	var track: Array = BLADE_CUT_TRACKS[combo_index]
	var sample_time: float = _cut_sample_time()
	var segment: int = track.size()-2
	for index: int in range(1,track.size()):
		if sample_time <= float(track[index][0]):
			segment = index-1
			break
	var first: Dictionary = _blade_key(track,segment)
	var second: Dictionary = _blade_key(track,segment+1)
	var before: Dictionary = _blade_key(track,maxi(segment-1,0))
	var after: Dictionary = _blade_key(track,mini(segment+2,track.size()-1))
	var duration: float = maxf(float(second.time)-float(first.time),0.001)
	var alpha: float = clampf((sample_time-float(first.time))/duration,0.0,1.0)
	var start_tangent: Vector3 = Vector3.ZERO if segment == 0 else _pose_tangent(before,first,second,"target")
	var end_tangent: Vector3 = Vector3.ZERO if segment+1 == track.size()-1 else _pose_tangent(first,second,after,"target")
	var target: Vector3 = _interpolated(first.target,second.target,start_tangent,end_tangent,alpha,duration)
	# Spherical interpolation keeps blade length and its plane stable. Euler
	# wrist keys could otherwise roll the edge through the arm or full turns.
	var first_rotation: Quaternion = first.orientation
	var second_rotation: Quaternion = second.orientation
	# Preserve the incoming recovery speed, then ease the angular velocity to
	# zero at the live guard. A plain linear slerp stopped the wrist abruptly
	# even though the hilt's Hermite path already settled smoothly.
	var rotation_alpha: float = alpha
	if segment+1 == track.size()-1:
		rotation_alpha = alpha+alpha*alpha-alpha*alpha*alpha
	var blade_rotation: Quaternion = first_rotation.slerp(second_rotation,rotation_alpha)
	var frame: Basis = global_basis.orthonormalized()
	var blade_basis: Basis = frame*Basis(blade_rotation)
	var hand_target: Vector3 = to_global(target)
	if combo_index == 3:
		# A shared hilt must be reachable by BOTH arms. Project its position
		# into their reach intersection instead of silently stretching/clamping
		# the support arm away from the weapon at the bottom of the stroke.
		var unconstrained_target: Vector3 = hand_target
		var hilt_constraint: float = _finisher_grip_weight()
		var support_offset: Vector3 = blade_basis*(Vector3(0.0,-0.14,0.0)*sword.scale)
		var right_reach: float = right_forearm.position.length()+right_wrist.position.length()-0.012
		var left_reach: float = left_forearm.position.length()+left_wrist.position.length()-0.012
		for iteration: int in range(6):
			var right_delta: Vector3 = hand_target-right_arm.global_position
			if right_delta.length() > right_reach:
				hand_target = right_arm.global_position+right_delta.normalized()*right_reach
			var left_delta: Vector3 = hand_target+support_offset-left_arm.global_position
			if left_delta.length() > left_reach:
				hand_target = left_arm.global_position+left_delta.normalized()*left_reach-support_offset
		hand_target = unconstrained_target.lerp(hand_target,hilt_constraint)
	_solve_cut_arm(right_arm,right_forearm,hand_target,1.0,1.0)
	right_wrist.global_basis = blade_basis*sword.basis.orthonormalized().inverse()
	if combo_index == 3:
		_apply_finisher_grip()

func _apply_finisher_grip() -> void:
	# The support hand joins the actual lower hilt before the power stroke,
	# stays attached through contact, then releases naturally on recovery.
	var grip_weight: float = _finisher_grip_weight()
	if grip_weight <= 0.0:
		return
	_solve_cut_arm(left_arm,left_forearm,sword.to_global(Vector3(0.0,-0.14,0.0)),-1.0,grip_weight)
	left_wrist.global_basis = Basis(left_wrist.global_basis.get_rotation_quaternion().slerp(right_wrist.global_basis.get_rotation_quaternion(),grip_weight))

func _finisher_grip_weight() -> float:
	var phase: float = _cut_sample_time()
	return minf(smoothstep(0.06,0.20,phase),1.0-smoothstep(0.66,0.87,phase))

func _apply_track_pose(track: Array, sample_time: float = -1.0) -> void:
	# Ordinary tracks use normalized phases; the fire slam keeps its authored
	# absolute seconds and calls this without a phase override.
	if sample_time < 0.0:
		sample_time = attack_elapsed
	var segment: int = track.size()-2
	for index: int in range(1,track.size()):
		if sample_time <= float(track[index].time):
			segment = index-1
			break
	var previous: Dictionary = _track_key(track,segment)
	var following: Dictionary = _track_key(track,segment+1)
	var duration: float = maxf(float(following.time)-float(previous.time),0.001)
	var alpha: float = clampf((sample_time-float(previous.time))/duration,0,1)
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
		[0.82,_guard_blade.origin+Vector3(-0.02,0.06,-0.025),0.95],
		[FIRE_SLAM_DURATION,_guard_blade.origin,0.94]
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
	var first_rotation: Quaternion = Basis.from_euler(Vector3(float(first[2]),0,0)).get_rotation_quaternion()
	var second_rotation: Quaternion = Basis.from_euler(Vector3(float(second[2]),0,0)).get_rotation_quaternion()
	if float(first[0]) == 0.0:
		wrist_target = _attack_blade_origin.origin.lerp(second[1],alpha)
		first_rotation = _attack_blade_origin.basis.orthonormalized().get_rotation_quaternion()
	var guard_rotation: Quaternion = _guard_blade.basis.orthonormalized().get_rotation_quaternion()
	if float(first[0]) >= 0.82:
		first_rotation = guard_rotation
	if float(second[0]) >= 0.82:
		second_rotation = guard_rotation
	var grip_weight: float = minf(clampf(attack_elapsed/0.12,0.0,1.0),clampf((FIRE_SLAM_DURATION-attack_elapsed)/0.15,0.0,1.0))
	grip_weight = grip_weight*grip_weight*(3.0-2.0*grip_weight)
	# Solve the right palm throughout recovery against the live guard. Blending
	# old Euler arm keys into a new low carry caused a late wrist flip; explicit
	# hilt position and full blade orientation keep the same endpoint contract
	# as the ordinary cuts while the support hand can release independently.
	_solve_cut_arm(right_arm,right_forearm,to_global(wrist_target),1.0,1.0)
	var blade_basis: Basis = global_basis.orthonormalized()*Basis(first_rotation.slerp(second_rotation,alpha))
	var wrist_basis: Basis = blade_basis*sword.basis.orthonormalized().inverse()
	right_wrist.global_basis = wrist_basis
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

func _solve_cut_arm(upper: Node3D,lower: Node3D,target: Vector3,side: float,weight: float) -> void:
	var hand_offset: Vector3 = right_wrist.position if lower == right_forearm else left_wrist.position
	# Low, outside elbows carry the weapon close to the ribs. The small rear
	# component avoids folding the elbow across the chest on a forward grip.
	var pole: Vector3 = global_basis.orthonormalized()*Vector3(side*0.65,-0.35,0.18)
	_solve_limb(upper,lower,hand_offset,target,pole,weight)

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
	# A small lead with the unarmed side gives the sword room beside the hip.
	# These anchors remain fixed throughout breathing; pelvis motion is solved
	# against the planted boots rather than making the entire person float.
	return (_left_ankle_rest+Vector3(-0.075,0.0,-0.085)) if left else (_right_ankle_rest+Vector3(0.075,0.0,0.070))

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
	var breath: float = sin(idle_phase*TAU/3.9)
	var shoulder_breath: float = sin(idle_phase*TAU/3.9-0.32)
	var weight_shift: float = sin(idle_phase*TAU/6.4)
	var resting: float = 1.0-locomotion_blend
	body.position = Vector3((0.010+weight_shift*0.013)*resting,(-0.045+0.018*cos(walk_phase*2.0))*locomotion_blend+(-0.024+breath*0.004)*resting,0.0)
	body.rotation = Vector3(-0.018*locomotion_blend,-0.14*resting,0.0)
	hips.rotation = Vector3(-0.025*locomotion_blend,(0.055+weight_shift*0.010)*resting+step*0.055*locomotion_blend,step*0.025*locomotion_blend+(0.008+weight_shift*0.014)*resting)
	# Expansion is expressed as a small chest lift and delayed shoulder settle,
	# not by scaling armor or translating the feet. The longer weight cycle
	# prevents the idle from reading as a synchronized mechanical oscillation.
	torso.rotation = Vector3(-0.020-0.052*locomotion_blend+breath*0.018*resting,-hips.rotation.y*0.8+weight_shift*0.011*resting,-hips.rotation.z*0.72)
	left_leg.rotation = Vector3(step*0.48*locomotion_blend,0.025,-0.012*resting)
	right_leg.rotation = Vector3(-step*0.48*locomotion_blend,-0.025,0.012*resting)
	left_knee.rotation = Vector3(-0.045-maxf(0.0,passing)*0.90*locomotion_blend,0.0,0.0)
	right_knee.rotation = Vector3(-0.045-maxf(0.0,-passing)*0.90*locomotion_blend,0.0,0.0)
	# The sword arm carries its weight near the ribs instead of swinging like
	# an empty hand. The free arm counters the leading hip with a soft elbow.
	left_arm.rotation = Vector3(-0.055-step*0.43*locomotion_blend+shoulder_breath*0.010*resting,0.025,0.075+weight_shift*0.013*resting)
	right_arm.rotation = Vector3(0.20+step*0.10*locomotion_blend,-0.15,0.12)
	left_forearm.rotation = Vector3(0.27+0.37*locomotion_blend+maxf(0.0,step)*0.12*locomotion_blend+shoulder_breath*0.023*resting,0.0,0.0)
	right_forearm.rotation = Vector3(0.88-0.10*locomotion_blend+maxf(0.0,-step)*0.10*locomotion_blend+breath*0.014*resting,0.0,0.0)
	right_wrist.rotation = Vector3(-0.06-0.05*locomotion_blend,-0.25,0.16+step*0.018*locomotion_blend)
	left_wrist.rotation = Vector3(0.0,0.0,breath*0.008*resting)
	left_ankle.rotation = Vector3.ZERO
	right_ankle.rotation = Vector3.ZERO
	head.rotation = Vector3(-torso.rotation.x*0.65,-torso.rotation.y*0.40+sin(idle_phase*0.39)*0.024*resting,-hips.rotation.z*0.75)
	cape.rotation.x = -0.16+0.035*sin(walk_phase-0.6)*locomotion_blend+breath*0.012*resting
	cape.rotation.z = -hips.rotation.z*0.35
	var left_pitch: float = clampf(sin(walk_phase-0.8)*0.24,-0.18,0.24)*locomotion_blend
	var right_pitch: float = clampf(sin(walk_phase+PI-0.8)*0.24,-0.18,0.24)*locomotion_blend
	_plant_feet(_running_foot(_left_ankle_rest,walk_phase),_running_foot(_right_ankle_rest,walk_phase+PI),1.0,left_pitch,right_pitch)
	# The profile places the palm and blade in the weapon's authored guard.
	# Its own slight lag behind the chest and contained running swing keep
	# the current raised guard responsive without fixing the hand in space.
	var carry_target: Vector3 = motion_profile.carry_target
	var breathing_offset: Vector3 = motion_profile.breathing_offset
	carry_target += (Vector3(weight_shift*0.007,0,0)+breathing_offset*Vector3(weight_shift,shoulder_breath,-breath))*resting
	carry_target += (motion_profile.run_offset+Vector3(step*0.012,step*0.020,passing*0.025))*locomotion_blend
	var carry_direction: Vector3 = (motion_profile.carry_direction.normalized()+motion_profile.breathing_blade_sway*shoulder_breath*resting+Vector3(0,.10,step*.035)*locomotion_blend).normalized()
	# Follow the body's weight and yaw as a held object, with a tiny delayed
	# forearm roll. Arm IK still keeps the palm exactly on the weapon socket.
	carry_target = body.transform*carry_target
	carry_direction = body.basis*carry_direction
	_solve_cut_arm(right_arm,right_forearm,to_global(carry_target),1.0,1.0)
	var carry_roll: float = deg_to_rad(motion_profile.carry_roll_degrees)+(shoulder_breath*0.018+weight_shift*0.010)*resting+step*0.014*locomotion_blend
	var carry_basis: Basis = global_basis.orthonormalized()*Basis(Quaternion(Vector3.DOWN,carry_direction))*Basis(Vector3.DOWN,carry_roll)
	right_wrist.global_basis = carry_basis*sword.basis.orthonormalized().inverse()
	if _presentation_blend > 0.0 and attack_elapsed < 0.0 and locomotion_blend < 0.01:
		_apply_presentation_pose(delta)
	_guard_blade = global_transform.affine_inverse()*sword.global_transform
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
			# Release the extended spin guard over the last third of the move;
			# compressing this into the final .12 s snapped the long blade down
			# toward the new low carry despite ending at the right transform.
			var readiness: float = minf(smoothstep(0.0,0.18,t),1.0-smoothstep(0.65,1.0,t))
			var return_weight: float = smoothstep(0.65,1.0,t)
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

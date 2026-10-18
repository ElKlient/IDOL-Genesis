class_name Hero
extends CharacterBody3D

const VisualScript = preload("res://scripts/character_visual.gd")
const MOVE_SPEED: float = 5.0
var move_input: Vector2 = Vector2.ZERO
var dead: bool = false
var facing: Vector3 = Vector3(0, 0, -1)
var visual: CharacterVisual
var _weapon_tier: int = 0
var _armor_tier: int = 0
var _upgrade: int = 0
var _armor_upgrade: int = 0
var _death_angle: float = 0.0
var attack_locked_time: float = 0.0
var _sword_burning: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CapsuleShape3D.new()
	shape.radius = 0.37
	shape.height = 1.8
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.90
	add_child(collider)
	visual = VisualScript.new()
	visual.weapon_tier = _weapon_tier
	visual.armor_tier = _armor_tier
	visual.upgrade_level = _upgrade
	visual.armor_upgrade_level = _armor_upgrade
	add_child(visual)
	visual.set_sword_flame(_sword_burning)
	var shadow := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = 0.57
	disk.bottom_radius = 0.57
	disk.height = 0.006
	disk.radial_segments = 24
	shadow.mesh = disk
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.06, 0.07, 0.24)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = mat
	shadow.position.y = 0.012
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

func _physics_process(delta: float) -> void:
	var planted: bool = attack_locked_time > 0.0
	attack_locked_time = maxf(0.0, attack_locked_time - delta)
	var requested := Vector3(move_input.x, 0.0, move_input.y)
	if requested.length() > 1.0:
		requested = requested.normalized()
	if dead or planted:
		requested = Vector3.ZERO
	if dead:
		cancel_fire_slam()
		set_sword_flame(false)
		if is_instance_valid(visual) and visual.has_method("contact_pause"):
			visual.call("contact_pause",0.0)
	var speed: float = MOVE_SPEED
	if is_instance_valid(visual) and visual.is_attacking():
		speed *= 0.52
	velocity.x = 0.0 if planted else move_toward(velocity.x, requested.x * speed, delta * 24.0)
	velocity.z = 0.0 if planted else move_toward(velocity.z, requested.z * speed, delta * 24.0)
	if not is_on_floor():
		velocity.y -= delta * 22.0
	else:
		velocity.y = -0.5
	# Keep the selected strike direction through an ordinary cut. Movement can
	# still slide at the existing reduced speed, but cannot spin the whole
	# sword arc away from its target while the damage timer is pending.
	var cutting: bool = is_instance_valid(visual) and visual.is_attacking() and not visual.skill_attack and not visual.fire_slam_attack
	if requested.length_squared() > 0.02 and not cutting:
		facing = requested.normalized()
	move_and_slide()
	if is_instance_valid(visual):
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), minf(1.0, delta * 15.0))
		visual.tick(delta, Vector2(velocity.x, velocity.z).length() / MOVE_SPEED)
		_death_angle = move_toward(_death_angle, -PI * 0.48 if dead else 0.0, delta * 3.3)
		visual.rotation.z = _death_angle

func play_attack(combo: int = 0, skill: bool = false) -> void:
	if not dead and attack_locked_time <= 0.0 and is_instance_valid(visual):
		visual.start_attack(combo, skill)

func play_fire_slam() -> void:
	if dead or not is_instance_valid(visual):
		return
	attack_locked_time = maxf(attack_locked_time, 1.0)
	move_input = Vector2.ZERO
	velocity.x = 0.0
	velocity.z = 0.0
	visual.start_fire_slam()

func cancel_fire_slam() -> void:
	attack_locked_time = 0.0
	if is_instance_valid(visual):
		visual.cancel_fire_slam()

func set_sword_flame(burning: bool) -> void:
	_sword_burning = burning
	if is_instance_valid(visual):
		visual.set_sword_flame(burning)

func set_equipment(weapon_tier: int, armor_tier: int, upgrade: int = 0, armor_upgrade: int = 0) -> void:
	_weapon_tier = weapon_tier
	_armor_tier = armor_tier
	_upgrade = upgrade
	_armor_upgrade = armor_upgrade
	if is_instance_valid(visual):
		visual.set_equipment(weapon_tier, armor_tier, upgrade, armor_upgrade)

func receive_hit() -> void:
	if is_instance_valid(visual):
		visual.hit_flash()

func confirm_contact(heavy: bool = false) -> void:
	# This only holds the visual pose for a few milliseconds. Input, movement,
	# AI, damage contacts, timers and skill cooldowns keep normal simulation time.
	if not dead and is_instance_valid(visual) and visual.has_method("contact_pause"):
		visual.call("contact_pause",0.042 if heavy else 0.028)

func reset_to(pos: Vector3) -> void:
	cancel_fire_slam()
	set_sword_flame(false)
	global_position = pos
	velocity = Vector3.ZERO
	move_input = Vector2.ZERO
	dead = false
	_death_angle = 0.0
	if is_instance_valid(visual):
		visual.rotation.z = 0.0
		if visual.has_method("contact_pause"):
			visual.call("contact_pause",0.0)

func face_direction(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	facing = flat.normalized()
	if is_instance_valid(visual):
		visual.rotation.y = atan2(-facing.x, -facing.z)

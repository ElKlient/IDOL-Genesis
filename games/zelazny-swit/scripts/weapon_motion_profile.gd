class_name WeaponMotionProfile
extends Resource
## Shared presentation data. A future class supplies a profile and its own
## attack tracks to the same skeletal animation interface; this resource never
## changes hit timing, damage, inventory or the player's saved equipment.

@export var profile_id: StringName = &"sword_one_hand"
@export var carry_target: Vector3 = Vector3(.35,1.20,-.18)
@export var carry_direction: Vector3 = Vector3(.38,.84,-.40)
@export_range(-180.0,180.0,.1) var carry_roll_degrees: float = 0.0
@export var run_offset: Vector3 = Vector3(0,.035,-.035)
@export var breathing_offset: Vector3 = Vector3(0,.009,.006)
@export var breathing_blade_sway: Vector3 = Vector3(.015,0,0)

func valid() -> bool:
	# A normalized base direction plus the bounded built-in running offset and
	# this sway cannot cancel to zero before constructing the wrist quaternion.
	return carry_target.is_finite() and carry_direction.is_finite() and carry_direction.length_squared() > .01 and is_finite(carry_roll_degrees) and run_offset.is_finite() and breathing_offset.is_finite() and breathing_blade_sway.is_finite() and breathing_blade_sway.length() <= .25

class_name AttackTiming
extends RefCounted
## Original sword-combo timing. All ordinary-attack consumers use one snapshot.
## Values are authored seconds at 100 attack speed; skills have separate clocks.
const DURATIONS: Array[float] = [0.82,0.86,0.92,1.14]
const CONTACTS: Array[float] = [0.34,0.36,0.38,0.56]
const SWINGS: Array[float] = [0.24,0.26,0.28,0.44]

static func rate_from_speed(speed: float) -> float:
	return clampf(speed,50.0,200.0)/100.0 if is_finite(speed) else 1.0

static func safe_rate(rate: float) -> float:
	return clampf(rate,0.5,2.0) if is_finite(rate) else 1.0

static func duration(combo: int,rate: float = 1.0) -> float:
	return DURATIONS[posmod(combo,4)]/safe_rate(rate)

static func contact_time(combo: int,rate: float = 1.0) -> float:
	return CONTACTS[posmod(combo,4)]/safe_rate(rate)

static func swing_time(combo: int,rate: float = 1.0) -> float:
	return SWINGS[posmod(combo,4)]/safe_rate(rate)

static func contact_hold(combo: int,rate: float = 1.0) -> float:
	return (0.042 if posmod(combo,4) == 3 else 0.028)/safe_rate(rate)

static func cooldown(combo: int,rate: float = 1.0) -> float:
	# Reserve the confirmed-hit pose hold and a short frame-boundary margin.
	return duration(combo,rate)+contact_hold(combo,rate)+0.02/safe_rate(rate)

static func combo_grace(rate: float = 1.0) -> float:
	return 1.2/safe_rate(rate)

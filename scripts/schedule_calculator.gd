extends RefCounted

enum DayState { NONE, WORK, HOME, REST, VACATION }
const WEEKDAY_NAMES := ["poniedziałek", "wtorek", "środa", "czwartek", "piątek", "sobota", "niedziela"]

var mode: String = "preset"
var start_day_index: int = 0
var work_days: int = 14
var home_days: int = 7
var rest_every_work_days: int = 6
var fixed_start_weekday: int = -1
var custom_pattern: Array[int] = []
var last_error: String = ""


func configure_empty() -> bool:
	mode = "none"
	fixed_start_weekday = -1
	last_error = ""
	return true


func configure_preset(
	start_date_text: String,
	work_units: int,
	home_units: int,
	unit: String,
	use_weekly_rest: bool,
	fixed_weekday: int = -1
) -> bool:
	var parsed := parse_date(start_date_text)
	if parsed.is_empty():
		last_error = "Podaj datę w formacie RRRR-MM-DD."
		return false

	var multiplier := 7 if unit == "weeks" else 1
	mode = "preset"
	work_days = maxi(1, work_units * multiplier)
	home_days = maxi(1, home_units * multiplier)
	rest_every_work_days = 6 if use_weekly_rest else 0
	fixed_start_weekday = _clean_fixed_weekday(fixed_weekday)
	custom_pattern.clear()
	var parsed_day_index := day_index_from_date(int(parsed["year"]), int(parsed["month"]), int(parsed["day"]))
	start_day_index = _aligned_start_day_index(parsed_day_index)
	last_error = ""
	return true


func configure_custom(start_date_text: String, pattern: Array[int], fixed_weekday: int = -1) -> bool:
	var parsed := parse_date(start_date_text)
	if parsed.is_empty():
		last_error = "Podaj datę w formacie RRRR-MM-DD."
		return false
	if pattern.is_empty():
		last_error = "Własny cykl musi mieć przynajmniej jeden dzień."
		return false

	custom_pattern.clear()
	for state in pattern:
		var clean_state: int = clampi(int(state), DayState.NONE, DayState.VACATION)
		custom_pattern.append(clean_state)

	mode = "custom"
	fixed_start_weekday = _clean_fixed_weekday(fixed_weekday)
	var parsed_day_index := day_index_from_date(int(parsed["year"]), int(parsed["month"]), int(parsed["day"]))
	start_day_index = _aligned_start_day_index(parsed_day_index)
	last_error = ""
	return true


func get_state_for_day(day_index: int) -> int:
	if mode == "none":
		return DayState.NONE

	if mode == "custom":
		var custom_pattern_days: int = maxi(1, custom_pattern.size())
		var custom_cycle_days: int = get_cycle_days()
		var custom_offset := positive_mod(day_index - start_day_index, custom_cycle_days)
		if custom_offset >= custom_pattern_days:
			return DayState.HOME
		return int(custom_pattern[custom_offset])

	var base_cycle_days: int = maxi(1, work_days + home_days)
	var cycle_days: int = get_cycle_days()
	var offset := positive_mod(day_index - start_day_index, cycle_days)
	if offset >= base_cycle_days:
		return DayState.HOME

	if offset < work_days:
		return DayState.REST if _is_rest_day_in_work_block(offset) else DayState.WORK

	return DayState.HOME


func count_month(year: int, month: int) -> Dictionary:
	var result := _empty_counts()
	var days := days_in_month(year, month)

	for day in range(1, days + 1):
		_add_state_to_counts(result, get_state_for_day(day_index_from_date(year, month, day)))

	return result


func count_months(start_year: int, start_month: int, month_count: int) -> Dictionary:
	var result := _empty_counts()
	var year := start_year
	var month := start_month

	for _i in range(month_count):
		var month_counts := count_month(year, month)
		result["none"] += int(month_counts["none"])
		result["work"] += int(month_counts["work"])
		result["home"] += int(month_counts["home"])
		result["rest"] += int(month_counts["rest"])
		result["vacation"] += int(month_counts["vacation"])

		month += 1
		if month > 12:
			month = 1
			year += 1

	return result


func days_until_next_change(day_index: int) -> int:
	var state := get_state_for_day(day_index)
	var cycle_days: int = maxi(1, get_cycle_days())

	for offset in range(1, cycle_days + 1):
		if get_state_for_day(day_index + offset) != state:
			return offset

	return 0


func get_cycle_days() -> int:
	if mode == "custom":
		return _effective_cycle_days(custom_pattern.size())
	return _effective_cycle_days(work_days + home_days)


func cycle_label() -> String:
	if mode == "none":
		return "brak ustawionego systemu"
	if mode == "custom":
		return "własny cykl: %d dni%s" % [get_cycle_days(), _fixed_start_label()]
	return "%d dni pracy / %d dni domu%s" % [work_days, home_days, _fixed_start_label()]


func _clean_fixed_weekday(weekday: int) -> int:
	return weekday if weekday >= 0 and weekday <= 6 else -1


func _aligned_start_day_index(day_index: int) -> int:
	if fixed_start_weekday < 0:
		return day_index

	var shift_days := positive_mod(fixed_start_weekday - weekday_monday_first(day_index), 7)
	return day_index + shift_days


func _effective_cycle_days(base_cycle_days: int) -> int:
	var cycle_days := maxi(1, base_cycle_days)
	if fixed_start_weekday < 0:
		return cycle_days

	var next_weekday := weekday_monday_first(start_day_index + cycle_days)
	var extra_home_days := positive_mod(fixed_start_weekday - next_weekday, 7)
	return cycle_days + extra_home_days


func _fixed_start_label() -> String:
	if fixed_start_weekday < 0:
		return ""
	return ", stały start: %s" % WEEKDAY_NAMES[fixed_start_weekday]


func _is_rest_day_in_work_block(work_offset: int) -> bool:
	if rest_every_work_days <= 0:
		return false
	if work_offset < rest_every_work_days:
		return false
	if work_offset >= work_days - 1:
		return false
	return positive_mod(work_offset + 1, rest_every_work_days + 1) == 0


func _empty_counts() -> Dictionary:
	return {
		"none": 0,
		"work": 0,
		"home": 0,
		"rest": 0,
		"vacation": 0,
	}


func _add_state_to_counts(counts: Dictionary, state: int) -> void:
	match state:
		DayState.NONE:
			counts["none"] += 1
		DayState.WORK:
			counts["work"] += 1
		DayState.REST:
			counts["rest"] += 1
		DayState.VACATION:
			counts["vacation"] += 1
		_:
			counts["home"] += 1


static func parse_date(text: String) -> Dictionary:
	var parts := text.strip_edges().split("-")
	if parts.size() != 3:
		return {}

	if not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return {}

	var year := parts[0].to_int()
	var month := parts[1].to_int()
	var day := parts[2].to_int()

	if year < 1970 or year > 2200:
		return {}
	if month < 1 or month > 12:
		return {}
	if day < 1 or day > days_in_month(year, month):
		return {}

	return {
		"year": year,
		"month": month,
		"day": day,
	}


static func day_index_from_date(year: int, month: int, day: int) -> int:
	var unix_time: int = int(Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": 0,
		"minute": 0,
		"second": 0,
	}))
	return int(floor(float(unix_time) / 86400.0))


static func weekday_monday_first(day_index: int) -> int:
	return positive_mod(day_index + 3, 7)


static func month_start_weekday_monday(year: int, month: int) -> int:
	return weekday_monday_first(day_index_from_date(year, month, 1))


static func days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if is_leap_year(year) else 28
	return 30


static func is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or year % 400 == 0


static func positive_mod(value: int, modulo: int) -> int:
	var result := value % modulo
	if result < 0:
		result += modulo
	return result

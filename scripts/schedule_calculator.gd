extends RefCounted

enum DayState { WORK, HOME, TRAVEL, REST }

var mode: String = "preset"
var start_day_index: int = 0
var work_days: int = 14
var home_days: int = 7
var commute_before_days: int = 1
var commute_after_days: int = 1
var rest_every_work_days: int = 6
var custom_pattern: Array[int] = []
var last_error: String = ""


func configure_preset(
	start_date_text: String,
	work_units: int,
	home_units: int,
	unit: String,
	commute_before: int,
	commute_after: int,
	use_weekly_rest: bool
) -> bool:
	var parsed := parse_date(start_date_text)
	if parsed.is_empty():
		last_error = "Podaj datę w formacie RRRR-MM-DD."
		return false

	var multiplier := 7 if unit == "weeks" else 1
	mode = "preset"
	work_days = max(1, work_units * multiplier)
	home_days = max(1, home_units * multiplier)
	commute_before_days = max(0, commute_before)
	commute_after_days = max(0, commute_after)
	rest_every_work_days = 6 if use_weekly_rest else 0
	custom_pattern.clear()
	start_day_index = day_index_from_date(int(parsed["year"]), int(parsed["month"]), int(parsed["day"]))
	last_error = ""
	return true


func configure_custom(start_date_text: String, pattern: Array[int]) -> bool:
	var parsed := parse_date(start_date_text)
	if parsed.is_empty():
		last_error = "Podaj datę w formacie RRRR-MM-DD."
		return false
	if pattern.is_empty():
		last_error = "Własny cykl musi mieć przynajmniej jeden dzień."
		return false

	custom_pattern.clear()
	for state in pattern:
		var clean_state := clampi(int(state), DayState.WORK, DayState.REST)
		custom_pattern.append(clean_state)

	mode = "custom"
	start_day_index = day_index_from_date(int(parsed["year"]), int(parsed["month"]), int(parsed["day"]))
	last_error = ""
	return true


func get_state_for_day(day_index: int) -> int:
	if mode == "custom":
		var custom_cycle_days := max(1, custom_pattern.size())
		var custom_offset := positive_mod(day_index - start_day_index, custom_cycle_days)
		return int(custom_pattern[custom_offset])

	var cycle_days := max(1, work_days + home_days)
	var offset := positive_mod(day_index - start_day_index, cycle_days)

	if offset < work_days:
		return DayState.REST if _is_rest_day_in_work_block(offset) else DayState.WORK

	var home_offset := offset - work_days
	if home_offset < commute_after_days:
		return DayState.TRAVEL
	if home_offset >= home_days - commute_before_days:
		return DayState.TRAVEL
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
		result["work"] += int(month_counts["work"])
		result["home"] += int(month_counts["home"])
		result["travel"] += int(month_counts["travel"])
		result["rest"] += int(month_counts["rest"])

		month += 1
		if month > 12:
			month = 1
			year += 1

	return result


func days_until_next_change(day_index: int) -> int:
	var state := get_state_for_day(day_index)
	var cycle_days := max(1, get_cycle_days())

	for offset in range(1, cycle_days + 1):
		if get_state_for_day(day_index + offset) != state:
			return offset

	return 0


func get_cycle_days() -> int:
	if mode == "custom":
		return max(1, custom_pattern.size())
	return max(1, work_days + home_days)


func cycle_label() -> String:
	if mode == "custom":
		return "własny cykl: %d dni" % get_cycle_days()
	return "%d dni wyjazdu / %d dni domu" % [work_days, home_days]


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
		"work": 0,
		"home": 0,
		"travel": 0,
		"rest": 0,
	}


func _add_state_to_counts(counts: Dictionary, state: int) -> void:
	match state:
		DayState.WORK:
			counts["work"] += 1
		DayState.TRAVEL:
			counts["travel"] += 1
		DayState.REST:
			counts["rest"] += 1
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
	var unix_time := Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": 0,
		"minute": 0,
		"second": 0,
	})
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

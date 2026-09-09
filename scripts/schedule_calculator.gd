extends RefCounted

enum DayState { WORK, HOME }

var start_day_index: int = 0
var work_days: int = 14
var home_days: int = 7
var starts_with_work: bool = true
var last_error: String = ""


func configure(start_date_text: String, work_units: int, home_units: int, unit: String, start_with_work: bool = true) -> bool:
	var parsed := parse_date(start_date_text)
	if parsed.is_empty():
		last_error = "Podaj date w formacie RRRR-MM-DD."
		return false

	var multiplier := 7 if unit == "weeks" else 1
	work_days = max(1, work_units * multiplier)
	home_days = max(1, home_units * multiplier)
	starts_with_work = start_with_work
	start_day_index = day_index_from_date(parsed["year"], parsed["month"], parsed["day"])
	last_error = ""
	return true


func get_state_for_day(day_index: int) -> int:
	var cycle_days := work_days + home_days
	var offset := positive_mod(day_index - start_day_index, cycle_days)

	if starts_with_work:
		return DayState.WORK if offset < work_days else DayState.HOME

	return DayState.HOME if offset < home_days else DayState.WORK


func count_month(year: int, month: int) -> Dictionary:
	var result := {
		"work": 0,
		"home": 0,
	}
	var days := days_in_month(year, month)

	for day in range(1, days + 1):
		var state := get_state_for_day(day_index_from_date(year, month, day))
		if state == DayState.WORK:
			result["work"] += 1
		else:
			result["home"] += 1

	return result


func days_until_next_change(day_index: int) -> int:
	var state := get_state_for_day(day_index)
	var cycle_days := work_days + home_days

	for offset in range(1, cycle_days + 1):
		if get_state_for_day(day_index + offset) != state:
			return offset

	return 0


func cycle_label() -> String:
	return "%d dni praca / %d dni dom" % [work_days, home_days]


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

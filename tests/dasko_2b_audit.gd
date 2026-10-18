extends SceneTree

const Main = preload("res://scripts/main.gd")
const Calculator = preload("res://scripts/schedule_calculator.gd")

var passed := 0
var failed := 0
var app


func _initialize() -> void:
	if OS.get_name() != "Linux" or not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/driver-calendar-audit-"):
		printerr("Use isolated /tmp/driver-calendar-audit-* XDG_DATA_HOME on Linux.")
		quit(2)
		return
	_run.call_deferred()


func check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
	print("%s | %s" % ["PASS" if condition else "FAIL", label])


func settle() -> void:
	for _frame in range(6):
		await process_frame


func day_index(text: String) -> int:
	var date := Calculator.parse_date(text)
	return Calculator.day_index_from_date(date.year, date.month, date.day)


func check_interval(calc, first: String, last: String, state: int) -> void:
	var matches := true
	for index in range(day_index(first), day_index(last) + 1):
		if calc.get_state_for_day(index) != state:
			matches = false
	check("%s through %s = %s" % [first, last, state], matches)


func _run() -> void:
	print("ENGINE | %s" % Engine.get_version_info().string)
	var calc = Calculator.new()
	var pattern: Array[int] = Calculator.dasko_2b_pattern()
	check("Exactly six weeks, not a repeated three-week approximation", pattern.size() == 42)
	check("42 days contain 24 work, 3 rest and 15 home days", pattern.count(1) == 24 and pattern.count(3) == 3 and pattern.count(2) == 15)
	check("Pattern has no empty days or holiday-derived days", not pattern.has(0) and not pattern.has(4))
	check("Preset configures through the existing custom-cycle mechanism", calc.configure_custom(Calculator.DASKO_2B_START_DATE, pattern))
	check("Thursday reference date and exact 42-day period", Calculator.weekday_monday_first(calc.start_day_index) == 3 and calc.get_cycle_days() == 42)
	check("Preset identifies itself in the existing summary", calc.cycle_label() == "DASKO 2B: 42 dni")
	# Independent transcription of the printed option 2 / variant B table.
	var expected := "WWW" + "R" + "WWWWWW" + "R" + "WWW" + "HHHHHHH" + "WWWWWW" + "R" + "WWWWWW" + "HHHHHHHH"
	var encoded := ""
	for state in pattern:
		encoded += {1: "W", 2: "H", 3: "R"}[state]
	check("Every block matches the printed variant B, in order", encoded == expected)
	var repeats := true
	for cycle in range(-100, 101):
		for offset in range(42):
			if calc.get_state_for_day(calc.start_day_index + cycle * 42 + offset) != pattern[offset]:
				repeats = false
	check("Repeats unchanged before and after anchor for 201 cycles", repeats)
	var weekdays_match := true
	for cycle in range(-100, 101):
		var start: int = calc.start_day_index + cycle * 42
		if Calculator.weekday_monday_first(start) != 3 or Calculator.weekday_monday_first(start + 21) != 3:
			weekdays_match = false
		if Calculator.weekday_monday_first(start + 3) != 6 or Calculator.weekday_monday_first(start + 10) != 6 or Calculator.weekday_monday_first(start + 27) != 2:
			weekdays_match = false
	check("Work legs start Thursdays; rests stay Sunday, Sunday, Wednesday", weekdays_match)
	check_interval(calc, "2026-10-08", "2026-10-13", 1)
	check_interval(calc, "2026-10-14", "2026-10-14", 3)
	check_interval(calc, "2026-10-15", "2026-10-20", 1)
	check_interval(calc, "2026-10-21", "2026-10-28", 2)
	check_interval(calc, "2026-10-29", "2026-10-31", 1)
	check_interval(calc, "2026-11-01", "2026-11-01", 3)
	check_interval(calc, "2026-11-02", "2026-11-07", 1)
	check_interval(calc, "2026-11-08", "2026-11-08", 3)
	check_interval(calc, "2026-11-09", "2026-11-11", 1)
	check_interval(calc, "2026-11-12", "2026-11-18", 2)
	check_interval(calc, "2026-11-19", "2026-11-24", 1)
	check_interval(calc, "2026-11-25", "2026-11-25", 3)
	check_interval(calc, "2026-11-26", "2026-12-01", 1)
	check_interval(calc, "2026-12-02", "2026-12-09", 2)
	check_interval(calc, "2026-12-10", "2026-12-12", 1)
	check_interval(calc, "2026-12-13", "2026-12-13", 3)
	check_interval(calc, "2026-12-14", "2026-12-19", 1)
	check_interval(calc, "2026-12-20", "2026-12-20", 3)
	check_interval(calc, "2026-12-21", "2026-12-23", 1)
	check_interval(calc, "2026-12-24", "2026-12-30", 2)
	check_interval(calc, "2026-12-31", "2027-01-05", 1)
	check_interval(calc, "2027-01-06", "2027-01-06", 3)
	check_interval(calc, "2027-01-07", "2027-01-12", 1)
	check("2028 leap day is a normal offset within the 42-day cycle", calc.get_state_for_day(day_index("2028-02-29")) == pattern[Calculator.positive_mod(day_index("2028-02-29") - calc.start_day_index, 42)])

	root.size = Vector2i(720, 1280)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.gui_embed_subwindows = true
	app = Main.new()
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	var before_empty: Dictionary = app._calendar_state_snapshot().duplicate(true)
	check("One separate, large button is connected", app.dasko_2b_button.text == "DASKO 2B" and app.dasko_2b_button.custom_minimum_size.y >= 62 and not app.dasko_2b_button.pressed.get_connections().is_empty())
	app.manual_overrides = {"2026-11-01": 2, "2026-11-09": 3, "2026-11-02": 0, "2026-12-25": 4}
	app.notes = {"2026-11-01": "Keep this note"}
	app.worked_seconds_by_day = {"2026-11-01": 61200}
	app.fixed_start_toggle.set_pressed_no_signal(true)
	app._set_option_selected(app.fixed_start_option, 6)
	app.weekly_rest_toggle.set_pressed_no_signal(true)
	app.cycle_pending_apply = true
	app.main_view_saved = true
	app.current_year = 2027
	app.current_month = 2
	app._accept_calendar_page()
	app._set_option_selected(app.range_option, 1)
	app.work_start_unix = int(Time.get_unix_time_from_system()) - 3600
	app.work_start_day_key = "2026-11-01"
	var live_start: int = app.work_start_unix
	var before_apply: Dictionary = app._calendar_state_snapshot().duplicate(true)
	app.dasko_2b_button.pressed.emit()
	await settle()
	check("Button immediately applies the preset without a second Apply", not app.cycle_pending_apply and app.calculator.custom_pattern == pattern and app.calculator.get_cycle_days() == 42)
	check("Generic rest insertion and weekday alignment cannot distort this preset", not app.weekly_rest_toggle.button_pressed and not app.fixed_start_toggle.button_pressed and app.calculator.fixed_start_weekday == -1)
	check("Old manual schedule does not mask the preset; vacation is retained", app.manual_overrides == {"2026-12-25": 4} and app._visual_state_for_day(day_index("2026-11-01"), "2026-11-01") == 3)
	check("Notes, hours and running work are untouched", app.notes == before_apply.notes and app.worked_seconds_by_day == before_apply.worked_seconds_by_day and app.work_start_unix == live_start)
	check("Current page, range and panel mode remain unchanged", app.current_year == 2027 and app.current_month == 2 and app.range_option.selected == 1 and app.main_view_saved)
	check("Click can be undone", app.undo_available)
	app._undo_last_action()
	check("Undo restores the whole previous schedule", app._calendar_state_snapshot() == before_apply)
	app._apply_dasko_2b_system()
	var applied: Dictionary = app._calendar_state_snapshot().duplicate(true)
	app.custom_pattern.clear()
	app.start_input.text = ""
	app._set_option_selected(app.schedule_option, 0)
	app._load_settings_from_disk()
	app._apply_settings()
	check("Disk round-trip restores pattern, phase and period", app._calendar_state_snapshot() == applied and app.calculator.get_cycle_days() == 42 and app.calculator.get_state_for_day(day_index("2026-12-23")) == 1)
	app._on_save_profile_pressed()
	var saved: Dictionary = app.saved_profiles["1"].duplicate(true)
	app.selected_profile_index = 2
	app._on_load_profile_pressed()
	check("Another profile stays empty and does not alter DASKO profile", app.calculator.mode == "none" and app.saved_profiles["1"] == saved)
	app.selected_profile_index = 1
	app._on_load_profile_pressed()
	check("Profile reload restores DASKO 2B without stopping work", app.calculator.get_cycle_days() == 42 and app.calculator.custom_pattern == pattern and app.work_start_unix == live_start)
	app._reset_calendar_settings(false, true)
	app._undo_calendar_reset()
	check("Undo reset also restores DASKO 2B", app.calculator.custom_pattern == pattern and app.calculator.get_cycle_days() == 42)
	app._enter_calendar_only_mode()
	check("Calendar-only mode hides the button with other options", not app.dasko_2b_button.is_visible_in_tree())
	app._exit_calendar_only_mode()
	check("Show options makes the button available again", app.dasko_2b_button.is_visible_in_tree())
	app._restore_calendar_state(before_empty)
	# Legacy settings controls are deliberately kept outside the scene tree.
	for control_name in ["settings_panel", "schedule_option", "system_work_spin", "system_home_spin", "start_input", "fixed_start_toggle", "fixed_start_option", "weekly_rest_toggle", "custom_panel", "custom_length_spin", "error_label"]:
		var control = app.get(control_name)
		if is_instance_valid(control) and control.get_parent() == null:
			control.free()
	app.free()
	await settle()
	print("RESULT | %d PASS | %d FAIL" % [passed, failed])
	quit(1 if failed > 0 else 0)

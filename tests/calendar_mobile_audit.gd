extends SceneTree

const Main = preload("res://scripts/main.gd")
const Calculator = preload("res://scripts/schedule_calculator.gd")
var app
var passed := 0
var failed := 0


func _initialize() -> void:
	if OS.get_name() != "Linux" or not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/driver-calendar-audit-"):
		printerr("Use isolated /tmp/driver-calendar-audit-* XDG_DATA_HOME on Linux.")
		quit(2)
		return
	_run.call_deferred()


func check(label: String, condition: bool) -> void:
	if condition: passed += 1
	else: failed += 1
	print("%s | %s" % ["PASS" if condition else "FAIL", label])


func settle() -> void:
	for _i in range(6): await process_frame


func tile(day: int) -> Button:
	for target in app.day_touch_targets:
		if target.year == 2026 and target.month == 9 and target.day == day:
			return target.button
	return null


func hours(day: int) -> Label:
	return tile(day).find_child("WorkedHours", true, false) as Label


func hours_fit(day: int) -> bool:
	var label := hours(day)
	if label == null: return false
	var text_width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	print("HOURS LAYOUT | tile=%s label=%s text_width=%s" % [tile(day).get_global_rect(), label.get_global_rect(), text_width])
	return tile(day).get_global_rect().encloses(label.get_global_rect()) and text_width <= label.size.x and label.get_global_rect().end.y <= tile(day).get_global_rect().end.y - 9


func _run() -> void:
	for path in [Main.SETTINGS_PATH, Main.SETTINGS_BACKUP_PATH, Main.SETTINGS_TEMP_PATH]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	root.size = Vector2i(720, 1280)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.gui_embed_subwindows = true
	app = Main.new()
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.current_year = 2026
	app.current_month = 9
	app._accept_calendar_page()
	app._save_and_close_main_view()
	app._select_day(2026, 9, 24)
	app._open_manual_hours_dialog()
	app.manual_hours_spin.get_line_edit().text = "13"
	app.manual_minutes_spin.get_line_edit().text = "30"
	app._confirm_add_manual_hours()
	app.manual_hours_dialog.hide()
	app.manual_overrides["2026-09-24"] = Calculator.DayState.WORK
	app.manual_overrides["2026-09-25"] = Calculator.DayState.WORK
	app.notes["2026-09-25"] = "Zmiana przez północ"
	app._on_start_work_pressed()
	app.work_start_unix = int(Time.get_unix_time_from_system()) - 13 * 3600 - 15 * 60 - 47
	app.work_start_day_key = "2026-09-25"
	app._confirm_end_work()
	await settle()
	var recorded: int = app.worked_seconds_by_day["2026-09-25"]
	check("Finished shift appears as 13:15 on its start date", hours(25) != null and hours(25).text == "13:15")
	check("Recorded time retains seconds", recorded >= 47747 and recorded <= 47749)
	check("Manual entry appears as 13:30 on selected day", hours(24) != null and hours(24).text == "13:30" and app.worked_seconds_by_day["2026-09-24"] == 48600)
	check("Time labels fit tiles above accent stripe", hours_fit(24) and hours_fit(25))
	app._save_worked_seconds_for_day(app.work_start_unix, 20) # No active start: must not add.
	check("Invalid start cannot add hours", app.worked_seconds_by_day["2026-09-25"] == recorded)
	app._add_worked_seconds_for_day_key("2026-09-25", 20)
	app._rebuild_calendar()
	await settle()
	check("Seconds accumulate across entries into the next minute", hours(25).text == "13:16" and app.worked_seconds_by_day["2026-09-25"] == recorded + 20)
	check("Whole and short durations keep minute format", app._format_worked_hours_tile(13 * 3600) == "13:00" and app._format_worked_hours_tile(65) == "0:01" and app._format_worked_hours_tile(30) == "0:00")
	app._on_toggle_work_hours_pressed()
	await settle()
	check("Hide hours only hides labels", hours(24) == null and app.worked_seconds_by_day["2026-09-24"] == 48600)
	app._on_toggle_work_hours_pressed()
	app._apply_range_selection(3, 0)
	await settle()
	check("Time labels also fit the year overview", hours_fit(24) and hours_fit(25))
	app._apply_range_selection(0, 0)
	app._select_day(2026, 9, 25)
	app.clear_day_hours_key = "2026-09-25"
	app._confirm_clear_selected_day_hours()
	await settle()
	check("Clearing one day removes its time only", hours(25) == null and hours(24).text == "13:30" and not app.worked_seconds_by_day.has("2026-09-25"))
	print("RESULT | passed=%d failed=%d" % [passed, failed])
	app.queue_free()
	await settle()
	quit(0 if failed == 0 else 1)

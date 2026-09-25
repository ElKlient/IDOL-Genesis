extends SceneTree

const Main = preload("res://scripts/main.gd")
const Calculator = preload("res://scripts/schedule_calculator.gd")

var app
var baseline: Dictionary
var passed := 0
var failed := 0


func _initialize() -> void:
	# The application writes user:// during these scenarios. Never use real saves.
	var data_home := OS.get_environment("XDG_DATA_HOME")
	if OS.get_name() != "Linux" or not data_home.begins_with("/tmp/driver-calendar-audit-"):
		printerr("Set XDG_DATA_HOME=/tmp/driver-calendar-audit-<unique-name> on Linux.")
		quit(2)
		return
	_run.call_deferred()


func _check(label: String, condition: bool, evidence: String = "") -> void:
	if condition:
		passed += 1
	else:
		failed += 1
	print("%s | %s | %s" % ["PASS" if condition else "FAIL", label, evidence])


func _settle() -> void:
	for _frame in range(5):
		await process_frame


func _clean() -> void:
	app._restore_calendar_state(baseline.duplicate(true))
	app.saved_profiles.clear()
	app.profile_count = 3
	app.selected_profile_index = 1
	app._refresh_profile_options()
	app._set_profile_panel_visible(false)
	app.undo_available = false
	app.reset_undo_available = false
	app.undo_snapshot.clear()
	app.reset_undo_snapshot.clear()
	app._update_undo_buttons()


func _capture(name: String) -> void:
	await _settle()
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var path := "user://%s.png" % name
	var error := picture.save_png(path)
	print("SCREENSHOT | %s | %s" % [ProjectSettings.globalize_path(path), error])


func _run() -> void:
	print("ENGINE | %s | display=%s" % [Engine.get_version_info().string, DisplayServer.get_name()])
	print("ISOLATED_DATA | %s" % OS.get_user_data_dir())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Main.SETTINGS_PATH))
	root.size = Vector2i(720, 1280)
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.gui_embed_subwindows = true
	app = Main.new()
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _settle()
	baseline = app._calendar_state_snapshot().duplicate(true)
	_check("Application boots with empty calendar", app.calculator.mode == "none")
	await _capture("01-first-launch")
	var overlap: Rect2 = app.profile_button.get_global_rect().intersection(app.return_today_button.get_global_rect())
	_check("Profile and today buttons do not overlap", not overlap.has_area(), str(overlap))
	print("LAYOUT | viewport=%s calendar=%s options=%s day_tools=%s" % [root.size, app.calendar_root.get_global_rect(), app.options_root.get_global_rect(), app.day_tools_panel.get_global_rect()])
	app._set_profile_panel_visible(true)
	await _capture("02-profiles")
	app._set_profile_panel_visible(false)

	var calc = Calculator.new()
	_check("Leap day accepted", not Calculator.parse_date("2028-02-29").is_empty())
	_check("Invalid leap day rejected", Calculator.parse_date("2027-02-29").is_empty())
	var pattern: Array[int] = [1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2]
	calc.configure_custom("2026-12-25", pattern)
	var start := Calculator.day_index_from_date(2026, 12, 25)
	_check("6+24h+6+8 cycle repeats across years", calc.get_state_for_day(start + 6) == 3 and calc.get_state_for_day(start + 7) == 1 and calc.get_state_for_day(start + 13) == 2 and calc.get_state_for_day(start + 21) == 1 and calc.get_state_for_day(start + 21 * 150) == 1)
	calc.configure_preset("2026-09-25", 14, 7, "days", false)
	_check("2/1 cycle boundaries", calc.get_state_for_day(calc.start_day_index + 13) == 1 and calc.get_state_for_day(calc.start_day_index + 14) == 2 and calc.get_state_for_day(calc.start_day_index + 21) == 1)
	calc.configure_custom("2026-09-25", pattern, 4)
	_check("Fixed Friday cycle start remains Friday", Calculator.weekday_monday_first(calc.start_day_index + calc.get_cycle_days()) == 4)

	_clean()
	app.main_view_saved = true
	app._select_day(2026, 9, 25)
	app._set_selected_day_state(Calculator.DayState.WORK)
	_check("Single-day edit stays on selected day", app.manual_overrides == {"2026-09-25": 1} and app.calculator.mode == "none")
	app._select_day(2026, 9, 25)
	app._open_manual_hours_dialog()
	app.manual_hours_spin.get_line_edit().text = "8"
	app.manual_minutes_spin.get_line_edit().text = "30"
	app._select_day(2026, 9, 26)
	app._confirm_add_manual_hours()
	app.manual_hours_dialog.hide()
	_check("Manual hours retain dialog date", app.worked_seconds_by_day == {"2026-09-25": 30600}, str(app.worked_seconds_by_day))
	_check("Monthly hours total is correct", app._worked_seconds_for_month(2026, 9) == 30600)
	app.notes["2026-09-25"] = "Audit note"
	app._on_save_profile_pressed()
	app.worked_seconds_by_day["2026-09-25"] = 60
	app.notes.clear()
	app._on_load_profile_pressed()
	_check("Saved profile restores hours and notes", app.worked_seconds_by_day.get("2026-09-25", 0) == 30600 and app.notes.get("2026-09-25", "") == "Audit note")
	app.selected_profile_index = 2
	app._on_load_profile_pressed()
	_check("Empty profile has no previous hours", app.worked_seconds_by_day.is_empty(), str(app.worked_seconds_by_day))

	_clean()
	app.notes["2026-09-25"] = "Reset recovery"
	app.worked_seconds_by_day["2026-09-25"] = 28800
	app._reset_calendar_settings()
	app._undo_calendar_reset()
	_check("Undo reset recovers notes and hours", app.notes.get("2026-09-25", "") == "Reset recovery" and app.worked_seconds_by_day.get("2026-09-25", 0) == 28800)
	app._on_save_profile_pressed()
	app.work_start_unix = int(Time.get_unix_time_from_system()) - 3600
	var stored_start: int = app.work_start_unix
	app._save_settings_to_disk()
	app.worked_seconds_by_day.clear()
	app.notes.clear()
	app.saved_profiles.clear()
	app.work_start_unix = 0
	app._load_settings_from_disk()
	_check("Disk roundtrip restores data and active timer", app.worked_seconds_by_day.get("2026-09-25", 0) == 28800 and app.notes.get("2026-09-25", "") == "Reset recovery" and app.saved_profiles.has("1") and app.work_start_unix == stored_start)

	_clean()
	app.work_start_unix = int(Time.get_unix_time_from_system()) - 8 * 3600
	var original_start: int = app.work_start_unix
	app._on_start_work_pressed()
	_check("Second start preserves active shift", app.work_start_unix == original_start, "lost_seconds=%d" % (app.work_start_unix - original_start))
	_clean()
	app.work_start_unix = int(Time.get_unix_time_from_system()) - 8 * 3600
	app._on_save_profile_pressed()
	app._confirm_end_work()
	app._on_load_profile_pressed()
	_check("Loading a profile does not resurrect completed shift", app.work_start_unix == 0, "start_unix=%d hours=%s" % [app.work_start_unix, app.worked_seconds_by_day])

	_clean()
	app.pause_start_unix = int(Time.get_unix_time_from_system()) - 3 * 3600
	var original_pause: int = app.pause_start_unix
	app._on_start_pause_pressed()
	_check("Second pause start preserves elapsed rest", app.pause_start_unix == original_pause, "lost_seconds=%d" % (app.pause_start_unix - original_pause))

	_clean()
	var night_start: int = int(Time.get_unix_time_from_datetime_string("2026-09-30T22:00:00")) - app._system_utc_offset_seconds()
	app._save_worked_seconds_for_day(night_start, 8 * 3600)
	print("OBSERVATION | Sep30 22:00-Oct01 06:00 | %s | September=%s October=%s" % [app.worked_seconds_by_day, app._worked_seconds_for_month(2026, 9), app._worked_seconds_for_month(2026, 10)])

	_clean()
	app._save_and_close_main_view()
	app._enter_calendar_only_mode()
	_check("Today shortcut remains available in calendar-only mode", app.return_today_button.is_visible_in_tree())
	await _capture("03-calendar-only")
	app._exit_calendar_only_mode()
	app.main_scroll.scroll_horizontal = 50
	app.calendar_scroll.scroll_horizontal = 50
	app._lock_horizontal_scroll()
	_check("Horizontal scroll stays locked", app.main_scroll.scroll_horizontal == 0 and app.calendar_scroll.scroll_horizontal == 0)
	var year_before: int = app.current_year
	var month_before: int = app.current_month
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2(350, 450)
	touch.pressed = true
	Input.parse_input_event(touch)
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(150, 450)
	drag.relative = Vector2(-200, 0)
	Input.parse_input_event(drag)
	touch = InputEventScreenTouch.new()
	touch.position = Vector2(150, 450)
	touch.pressed = false
	Input.parse_input_event(touch)
	await _settle()
	_check("Synthetic horizontal swipe does not change month", app.current_year == year_before and app.current_month == month_before)

	_clean()
	app.work_start_unix = int(Time.get_unix_time_from_system()) - 8 * 3600
	app._on_pause_selected(1)
	app._update_work_timer()
	print("OBSERVATION | selected 11h pause | %s" % app.rest_after_work_label.text.replace("\n", " / "))
	await _capture("04-timer")
	app._apply_range_selection(3, 0)
	await _settle()
	_check("Year view enables vertical scrolling", app.calendar_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO)
	await _capture("05-year")

	_clean()
	app.current_year = 2026
	app.current_month = 8
	app._accept_calendar_page()
	app._rebuild_calendar()
	await _settle()
	_check("Six-row month leaves room for Apply button", app.main_scroll.size.y >= app.settings_toggle_button.size.y, "options_viewport_height=%s button_height=%s" % [app.main_scroll.size.y, app.settings_toggle_button.size.y])
	app._open_day_actions(2026, 8, 31)
	await _settle()
	print("LAYOUT | day_dialog=%s root=%s" % [app.day_action_dialog.size, root.size])
	_check("Day actions dialog fits portrait viewport", app.day_action_dialog.size.y <= root.size.y, "dialog_height=%s viewport_height=%s" % [app.day_action_dialog.size.y, root.size.y])
	app.day_action_dialog.hide()

	_clean()
	var config_path := ProjectSettings.globalize_path(Main.SETTINGS_PATH)
	DirAccess.remove_absolute(config_path)
	var directory_error := DirAccess.make_dir_absolute(config_path)
	if directory_error != OK:
		printerr("Cannot create isolated save-failure fixture: %d" % directory_error)
		quit(2)
		return
	app._on_save_profile_pressed()
	_check("Save failure is not reported as success", not app.profile_status_label.text.begins_with("Zapisano"), app.profile_status_label.text)
	DirAccess.remove_absolute(config_path)

	print("RESULT | passed=%d failed=%d" % [passed, failed])
	# Legacy settings controls are intentionally outside the scene tree in main.gd.
	for control_name in ["settings_panel", "schedule_option", "system_work_spin", "system_home_spin", "start_input", "fixed_start_toggle", "fixed_start_option", "weekly_rest_toggle", "custom_panel", "custom_length_spin", "error_label"]:
		var control = app.get(control_name)
		if is_instance_valid(control) and control.get_parent() == null:
			control.free()
	app.free()
	await process_frame
	quit(1 if failed > 0 else 0)

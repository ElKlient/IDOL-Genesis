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


func swipe(position: Vector2, delta: Vector2) -> void:
	# ScrollContainer consumes the mouse events Godot emulates from touch.
	var hover := InputEventMouseMotion.new()
	hover.position = position
	hover.global_position = position
	Input.parse_input_event(hover)
	var touch := InputEventMouseButton.new()
	touch.position = position
	touch.global_position = position
	touch.button_index = MOUSE_BUTTON_LEFT
	touch.button_mask = MOUSE_BUTTON_MASK_LEFT
	touch.pressed = true
	Input.parse_input_event(touch)
	await process_frame
	for step in range(1, 7):
		var drag := InputEventMouseMotion.new()
		drag.button_mask = MOUSE_BUTTON_MASK_LEFT
		drag.position = position + delta * step / 6.0
		drag.global_position = drag.position
		drag.relative = delta / 6.0
		Input.parse_input_event(drag)
		await process_frame
	touch = InputEventMouseButton.new()
	touch.button_index = MOUSE_BUTTON_LEFT
	touch.position = position + delta
	touch.global_position = touch.position
	Input.parse_input_event(touch)
	await settle()


func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://%s.png" % name)
	print("SCREENSHOT | %s" % ProjectSettings.globalize_path("user://%s.png" % name))


func _run() -> void:
	for path in [Main.SETTINGS_PATH, Main.SETTINGS_BACKUP_PATH, Main.SETTINGS_TEMP_PATH]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	root.size = Vector2i(720, 1280)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.gui_embed_subwindows = true
	print("TOUCHSCREEN | %s" % DisplayServer.is_touchscreen_available())
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
	await capture("mobile-hours")
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
	app.main_scroll.scroll_vertical = 0
	await settle()
	var calendar_top: float = app.calendar_root.global_position.y
	var tools_top: float = app.day_tools_panel.global_position.y
	var header_position: Vector2 = app.header_bar.global_position
	await swipe(tile(10).get_global_rect().get_center(), Vector2(0, -220))
	check("Finger swipe on calendar scrolls the whole page", app.main_scroll.scroll_vertical > 50 and app.calendar_root.global_position.y < calendar_top and app.day_tools_panel.global_position.y < tools_top)
	check("Calendar and tools move together", is_equal_approx(calendar_top - app.calendar_root.global_position.y, tools_top - app.day_tools_panel.global_position.y))
	check("Scrolling keeps header fixed and scrollbars hidden", app.header_bar.global_position == header_position and not app.main_scroll.get_v_scroll_bar().visible and not app.main_scroll.get_h_scroll_bar().visible)
	check("Vertical swipe does not open a day or change month", not app.day_action_dialog.visible and app.current_year == 2026 and app.current_month == 9)
	# Stop inertia and leave room below the work button for the next gesture.
	app.main_scroll.scroll_vertical = 0
	app.main_scroll.ensure_control_visible(app.start_work_button)
	await settle()
	check("Work buttons can be reached by scrolling", app.main_scroll.get_global_rect().encloses(app.start_work_button.get_global_rect()))
	var scroll_before: int = app.main_scroll.scroll_vertical
	await swipe(app.start_work_button.get_global_rect().get_center(), Vector2(0, -100))
	check("Swiping on a work button scrolls without starting a shift", app.main_scroll.scroll_vertical > scroll_before and app.work_start_unix == 0)
	await capture("mobile-tools")
	app.main_scroll.scroll_vertical = 0
	await settle()
	await swipe(tile(10).get_global_rect().get_center(), Vector2(-100, 0))
	check("Horizontal swipe stays blocked", app.main_scroll.scroll_horizontal == 0 and app.current_year == 2026 and app.current_month == 9)
	app._enter_calendar_only_mode()
	await settle()
	check("Calendar-only mode preserves calendar and hides tools", app.main_scroll.is_visible_in_tree() and not app.day_tools_panel.is_visible_in_tree() and app.return_today_button.is_visible_in_tree())
	app._apply_range_selection(3, 0)
	await settle()
	var overview_button: Button = app.day_touch_targets[10].button
	await swipe(overview_button.get_global_rect().get_center(), Vector2(0, -150))
	check("Year overview supports vertical finger scrolling", app.main_scroll.scroll_vertical > 0 and app._range_months() == 12 and not app.main_scroll.get_v_scroll_bar().visible)
	print("RESULT | passed=%d failed=%d" % [passed, failed])
	# The legacy settings controls deliberately live outside the tree.
	for control_name in ["settings_panel", "schedule_option", "system_work_spin", "system_home_spin", "start_input", "fixed_start_toggle", "fixed_start_option", "weekly_rest_toggle", "custom_panel", "custom_length_spin", "error_label"]:
		var control = app.get(control_name)
		if is_instance_valid(control) and control.get_parent() == null: control.free()
	app.free()
	await settle()
	quit(0 if failed == 0 else 1)

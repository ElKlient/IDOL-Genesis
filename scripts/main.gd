extends Control

const ScheduleCalculator = preload("res://scripts/schedule_calculator.gd")

const MONTH_NAMES := [
	"Styczeń",
	"Luty",
	"Marzec",
	"Kwiecień",
	"Maj",
	"Czerwiec",
	"Lipiec",
	"Sierpień",
	"Wrzesień",
	"Październik",
	"Listopad",
	"Grudzień",
]
const WEEKDAY_NAMES := ["Pon", "Wt", "Śr", "Czw", "Pt", "Sob", "Nd"]

const COLOR_BG := Color(0.055, 0.065, 0.07)
const COLOR_PANEL := Color(0.105, 0.125, 0.135)
const COLOR_PANEL_SOFT := Color(0.145, 0.165, 0.175)
const COLOR_TEXT := Color(0.91, 0.93, 0.91)
const COLOR_TEXT_MUTED := Color(0.66, 0.70, 0.68)
const COLOR_WORK := Color(0.58, 0.20, 0.22)
const COLOR_HOME := Color(0.18, 0.43, 0.29)
const COLOR_TRAVEL := Color(0.78, 0.61, 0.28)
const COLOR_REST := Color(0.60, 0.48, 0.26)
const COLOR_TODAY := Color(0.95, 0.78, 0.34)
const COLOR_NOTE := Color(0.58, 0.72, 0.90)

var calculator := ScheduleCalculator.new()
var current_year: int
var current_month: int
var today_day_index: int

var months_box: VBoxContainer
var summary_label: Label
var start_input: LineEdit
var schedule_option: OptionButton
var range_option: OptionButton
var commute_before_spin: SpinBox
var commute_after_spin: SpinBox
var weekly_rest_toggle: CheckButton
var custom_panel: PanelContainer
var custom_length_spin: SpinBox
var custom_buttons_grid: GridContainer
var error_label: Label
var work_status_label: Label
var pause_option: OptionButton
var pause_result_label: Label
var note_dialog: ConfirmationDialog
var note_edit: TextEdit

var custom_pattern: Array[int] = []
var notes: Dictionary = {}
var selected_note_key: String = ""
var work_start_unix: int = 0
var work_end_unix: int = 0


func _ready() -> void:
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	today_day_index = ScheduleCalculator.day_index_from_date(int(now["year"]), int(now["month"]), int(now["day"]))

	_reset_custom_pattern(21)
	_build_ui()
	_apply_settings()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = COLOR_BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margins := MarginContainer.new()
	margins.set_anchors_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 18)
	margins.add_theme_constant_override("margin_right", 18)
	margins.add_theme_constant_override("margin_top", 18)
	margins.add_theme_constant_override("margin_bottom", 18)
	add_child(margins)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margins.add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 16)
	scroll.add_child(root)

	var title := _make_label("Kalendarz Kierowcy", 34, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var subtitle := _make_label("Plan pracy, domu, dojazdów i pauz", 18, COLOR_TEXT_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)

	root.add_child(_build_settings_panel())
	root.add_child(_build_day_tools_panel())
	root.add_child(_build_navigation_panel())

	summary_label = _make_label("", 18, COLOR_TEXT_MUTED)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(summary_label)

	root.add_child(_build_legend())

	months_box = VBoxContainer.new()
	months_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	months_box.add_theme_constant_override("separation", 18)
	root.add_child(months_box)

	_build_note_dialog()


func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	box.add_child(_make_section_label("Jakim systemem jeździsz?"))

	schedule_option = OptionButton.new()
	schedule_option.add_item("2 na 1")
	schedule_option.add_item("2 na 2")
	schedule_option.add_item("3 na 1")
	schedule_option.add_item("3 na 2")
	schedule_option.add_item("4 na 1")
	schedule_option.add_item("6 dni + 24h pauzy + 6 dni")
	schedule_option.add_item("Inne - własny cykl")
	schedule_option.selected = 0
	schedule_option.item_selected.connect(_on_schedule_selected)
	box.add_child(schedule_option)

	box.add_child(_make_section_label("Kiedy zaczynasz pracę?"))

	start_input = LineEdit.new()
	start_input.placeholder_text = "RRRR-MM-DD, np. 2026-09-14"
	start_input.text = "%04d-%02d-%02d" % [current_year, current_month, now_day()]
	start_input.text_submitted.connect(func(_text: String) -> void: _apply_settings())
	box.add_child(start_input)

	var travel_grid := GridContainer.new()
	travel_grid.columns = 2
	travel_grid.add_theme_constant_override("h_separation", 10)
	travel_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(travel_grid)

	commute_before_spin = _make_spin(0, 7, 1)
	travel_grid.add_child(_field_stack("Dojazd przed pracą", commute_before_spin))

	commute_after_spin = _make_spin(0, 7, 1)
	travel_grid.add_child(_field_stack("Zjazd po pracy", commute_after_spin))

	weekly_rest_toggle = CheckButton.new()
	weekly_rest_toggle.text = "Pauza 24h co 6 dni pracy"
	weekly_rest_toggle.button_pressed = true
	box.add_child(weekly_rest_toggle)

	custom_panel = _build_custom_cycle_panel()
	custom_panel.visible = false
	box.add_child(custom_panel)

	var apply_button := Button.new()
	apply_button.text = "Przelicz grafik"
	apply_button.custom_minimum_size = Vector2(0, 58)
	apply_button.pressed.connect(_apply_settings)
	box.add_child(apply_button)

	error_label = _make_label("", 18, Color(1.0, 0.56, 0.48))
	error_label.visible = false
	box.add_child(error_label)

	return panel


func _build_custom_cycle_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL_SOFT, 8))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	box.add_child(_make_label("Własny cykl: klikaj dni i ustaw powtarzalność", 17, COLOR_TEXT))

	custom_length_spin = _make_spin(1, 56, 21)
	custom_length_spin.value_changed.connect(_on_custom_length_changed)
	box.add_child(_field_stack("Długość cyklu w dniach", custom_length_spin))

	custom_buttons_grid = GridContainer.new()
	custom_buttons_grid.columns = 7
	custom_buttons_grid.add_theme_constant_override("h_separation", 6)
	custom_buttons_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(custom_buttons_grid)

	_rebuild_custom_buttons()
	return panel


func _build_day_tools_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	box.add_child(_make_section_label("Dzień kierowcy"))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	var start_button := Button.new()
	start_button.text = "Rozpocząłem pracę"
	start_button.custom_minimum_size = Vector2(0, 54)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.pressed.connect(_on_start_work_pressed)
	buttons.add_child(start_button)

	var end_button := Button.new()
	end_button.text = "Zakończyłem pracę"
	end_button.custom_minimum_size = Vector2(0, 54)
	end_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end_button.pressed.connect(_on_end_work_pressed)
	buttons.add_child(end_button)

	var pause_row := HBoxContainer.new()
	pause_row.add_theme_constant_override("separation", 8)
	box.add_child(pause_row)

	pause_option = OptionButton.new()
	pause_option.add_item("9h")
	pause_option.add_item("11h")
	pause_option.add_item("24h")
	pause_option.selected = 0
	pause_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_option.item_selected.connect(func(_index: int) -> void: _update_pause_result())
	pause_row.add_child(pause_option)

	var pause_button := Button.new()
	pause_button.text = "Policz pauzę"
	pause_button.custom_minimum_size = Vector2(0, 54)
	pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_button.pressed.connect(_update_pause_result)
	pause_row.add_child(pause_button)

	work_status_label = _make_label("Najpierw kliknij rozpoczęcie pracy.", 17, COLOR_TEXT_MUTED)
	work_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(work_status_label)

	pause_result_label = _make_label("", 18, COLOR_TEXT)
	pause_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pause_result_label)

	return panel


func _build_navigation_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	range_option = OptionButton.new()
	range_option.add_item("Pokaż miesiąc")
	range_option.add_item("Pokaż kwartał")
	range_option.add_item("Pokaż 4 miesiące")
	range_option.add_item("Pokaż cały rok")
	range_option.selected = 0
	range_option.item_selected.connect(func(_index: int) -> void: _rebuild_calendar())
	box.add_child(range_option)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	box.add_child(nav)

	var previous_year_button := _make_nav_button("<< Rok")
	previous_year_button.pressed.connect(_on_previous_year)
	nav.add_child(previous_year_button)

	var previous_button := _make_nav_button("< Mies.")
	previous_button.pressed.connect(_on_previous_month)
	nav.add_child(previous_button)

	var next_button := _make_nav_button("Mies. >")
	next_button.pressed.connect(_on_next_month)
	nav.add_child(next_button)

	var next_year_button := _make_nav_button("Rok >>")
	next_year_button.pressed.connect(_on_next_year)
	nav.add_child(next_year_button)

	return panel


func _build_legend() -> HBoxContainer:
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 8)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_child(_legend_item(COLOR_WORK, "Praca"))
	legend.add_child(_legend_item(COLOR_HOME, "Dom"))
	legend.add_child(_legend_item(COLOR_TRAVEL, "Jazda"))
	legend.add_child(_legend_item(COLOR_REST, "24h"))
	return legend


func _build_note_dialog() -> void:
	note_dialog = ConfirmationDialog.new()
	note_dialog.title = "Notatka"
	note_dialog.confirmed.connect(_save_note)
	add_child(note_dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	note_dialog.add_child(margin)

	note_edit = TextEdit.new()
	note_edit.placeholder_text = "Wpisz notatkę do tego dnia..."
	note_edit.custom_minimum_size = Vector2(620, 260)
	margin.add_child(note_edit)


func _apply_settings() -> void:
	var ok := false
	if _is_custom_schedule():
		ok = calculator.configure_custom(start_input.text, custom_pattern)
	else:
		var preset := _preset_for_index(schedule_option.selected)
		ok = calculator.configure_preset(
			start_input.text,
			int(preset["work"]),
			int(preset["home"]),
			String(preset["unit"]),
			int(commute_before_spin.value),
			int(commute_after_spin.value),
			weekly_rest_toggle.button_pressed
		)

	error_label.visible = not ok
	error_label.text = calculator.last_error

	if ok:
		_rebuild_calendar()


func _rebuild_calendar() -> void:
	if months_box == null:
		return

	for child in months_box.get_children():
		child.queue_free()

	var month_count := _range_months()
	var counts := calculator.count_months(current_year, current_month, month_count)
	var today_state := calculator.get_state_for_day(today_day_index)
	var change_days := calculator.days_until_next_change(today_day_index)
	summary_label.text = "Okres: praca %d, dom %d, jazda %d, pauza 24h %d. Dzisiaj: %s. Zmiana za %d dni. System: %s." % [
		int(counts["work"]),
		int(counts["home"]),
		int(counts["travel"]),
		int(counts["rest"]),
		_state_name(today_state),
		change_days,
		calculator.cycle_label(),
	]

	var year := current_year
	var month := current_month
	for _i in range(month_count):
		months_box.add_child(_make_month_section(year, month))
		month += 1
		if month > 12:
			month = 1
			year += 1


func _make_month_section(year: int, month: int) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 8)

	var title := _make_label("%s %d" % [MONTH_NAMES[month - 1], year], 25, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	section.add_child(grid)

	for weekday in WEEKDAY_NAMES:
		grid.add_child(_make_weekday_label(weekday))

	var first_offset := ScheduleCalculator.month_start_weekday_monday(year, month)
	var days_current := ScheduleCalculator.days_in_month(year, month)

	for cell_index in range(42):
		var date := _date_for_month_cell(year, month, cell_index, first_offset, days_current)
		var date_year := int(date["year"])
		var date_month := int(date["month"])
		var date_day := int(date["day"])
		var day_index := ScheduleCalculator.day_index_from_date(date_year, date_month, date_day)
		var state := calculator.get_state_for_day(day_index)
		var in_month := date_month == month
		grid.add_child(_make_day_cell(date_year, date_month, date_day, in_month, state, day_index == today_day_index))

	return section


func _make_day_cell(year: int, month: int, day: int, in_month: bool, state: int, is_today: bool) -> Button:
	var key := _date_key(year, month, day)
	var button := Button.new()
	button.text = _day_cell_text(day, state, notes.has(key))
	button.custom_minimum_size = Vector2(0, _day_cell_height())
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 16 if _range_months() > 4 else 18)
	button.add_theme_color_override("font_color", COLOR_TEXT if in_month else COLOR_TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _button_style(_state_color(state), is_today, in_month, 0.0))
	button.add_theme_stylebox_override("hover", _button_style(_state_color(state).lightened(0.08), is_today, in_month, 0.0))
	button.add_theme_stylebox_override("pressed", _button_style(_state_color(state).darkened(0.08), is_today, in_month, 0.0))
	button.add_theme_stylebox_override("focus", _button_style(_state_color(state), true, in_month, 0.0))
	button.pressed.connect(func() -> void: _open_note_editor(year, month, day))
	return button


func _day_cell_text(day: int, state: int, has_note: bool) -> String:
	var text := "%d\n%s" % [day, _state_short_name(state)]
	if has_note:
		text += "\n*"
	return text


func _date_for_month_cell(year: int, month: int, cell_index: int, first_offset: int, days_current: int) -> Dictionary:
	var day_number := cell_index - first_offset + 1
	var result_year := year
	var result_month := month
	var result_day := day_number

	if day_number < 1:
		var previous := _previous_month(year, month)
		result_year = int(previous["year"])
		result_month = int(previous["month"])
		result_day = ScheduleCalculator.days_in_month(result_year, result_month) + day_number
	elif day_number > days_current:
		var next := _next_month(year, month)
		result_year = int(next["year"])
		result_month = int(next["month"])
		result_day = day_number - days_current

	return {
		"year": result_year,
		"month": result_month,
		"day": result_day,
	}


func _on_schedule_selected(_index: int) -> void:
	custom_panel.visible = _is_custom_schedule()
	_apply_settings()


func _on_custom_length_changed(value: float) -> void:
	_reset_custom_pattern(int(value))
	_rebuild_custom_buttons()
	_apply_settings()


func _cycle_custom_day(index: int) -> void:
	var state := int(custom_pattern[index])
	match state:
		ScheduleCalculator.DayState.WORK:
			custom_pattern[index] = ScheduleCalculator.DayState.REST
		ScheduleCalculator.DayState.REST:
			custom_pattern[index] = ScheduleCalculator.DayState.TRAVEL
		ScheduleCalculator.DayState.TRAVEL:
			custom_pattern[index] = ScheduleCalculator.DayState.HOME
		_:
			custom_pattern[index] = ScheduleCalculator.DayState.WORK

	_rebuild_custom_buttons()
	_apply_settings()


func _rebuild_custom_buttons() -> void:
	if custom_buttons_grid == null:
		return

	for child in custom_buttons_grid.get_children():
		child.queue_free()

	for index in range(custom_pattern.size()):
		var state := int(custom_pattern[index])
		var button := Button.new()
		button.text = "%d\n%s" % [index + 1, _state_short_name(state)]
		button.custom_minimum_size = Vector2(0, 56)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", _button_style(_state_color(state), false, true, 0.0))
		button.add_theme_stylebox_override("hover", _button_style(_state_color(state).lightened(0.08), false, true, 0.0))
		button.add_theme_stylebox_override("pressed", _button_style(_state_color(state).darkened(0.08), false, true, 0.0))
		button.pressed.connect(func() -> void: _cycle_custom_day(index))
		custom_buttons_grid.add_child(button)


func _reset_custom_pattern(days: int) -> void:
	custom_pattern.clear()
	for index in range(max(1, days)):
		if index < 6:
			custom_pattern.append(ScheduleCalculator.DayState.WORK)
		elif index == 6:
			custom_pattern.append(ScheduleCalculator.DayState.REST)
		elif index < 13:
			custom_pattern.append(ScheduleCalculator.DayState.WORK)
		elif index == 13:
			custom_pattern.append(ScheduleCalculator.DayState.TRAVEL)
		elif index == days - 1:
			custom_pattern.append(ScheduleCalculator.DayState.TRAVEL)
		else:
			custom_pattern.append(ScheduleCalculator.DayState.HOME)


func _on_start_work_pressed() -> void:
	work_start_unix = int(Time.get_unix_time_from_system())
	work_end_unix = 0
	work_status_label.text = "Start pracy: %s" % _format_unix_time(work_start_unix)
	pause_result_label.text = ""


func _on_end_work_pressed() -> void:
	if work_start_unix <= 0:
		work_status_label.text = "Najpierw kliknij rozpoczęcie pracy."
		return

	work_end_unix = int(Time.get_unix_time_from_system())
	var worked_seconds := max(0, work_end_unix - work_start_unix)
	work_status_label.text = "Praca trwała: %s. Koniec: %s" % [
		_format_duration(worked_seconds),
		_format_unix_time(work_end_unix),
	]
	_update_pause_result()


func _update_pause_result() -> void:
	if pause_result_label == null:
		return
	if work_end_unix <= 0:
		pause_result_label.text = "Po zakończeniu pracy pokażę dokładną godzinę końca pauzy."
		return

	var pause_hours := _selected_pause_hours()
	var pause_end_unix := work_end_unix + pause_hours * 3600
	pause_result_label.text = "Pauza %dh kończy się: %s" % [
		pause_hours,
		_format_unix_time(pause_end_unix),
	]


func _open_note_editor(year: int, month: int, day: int) -> void:
	selected_note_key = _date_key(year, month, day)
	note_dialog.title = "Notatka: %s" % selected_note_key
	note_edit.text = String(notes.get(selected_note_key, ""))
	note_dialog.popup_centered()


func _save_note() -> void:
	var text := note_edit.text.strip_edges()
	if text.is_empty():
		notes.erase(selected_note_key)
	else:
		notes[selected_note_key] = text
	_rebuild_calendar()


func _preset_for_index(index: int) -> Dictionary:
	match index:
		0:
			return {"work": 2, "home": 1, "unit": "weeks"}
		1:
			return {"work": 2, "home": 2, "unit": "weeks"}
		2:
			return {"work": 3, "home": 1, "unit": "weeks"}
		3:
			return {"work": 3, "home": 2, "unit": "weeks"}
		4:
			return {"work": 4, "home": 1, "unit": "weeks"}
		5:
			return {"work": 13, "home": 8, "unit": "days"}
	return {"work": 2, "home": 1, "unit": "weeks"}


func _is_custom_schedule() -> bool:
	return schedule_option != null and schedule_option.selected == schedule_option.get_item_count() - 1


func _range_months() -> int:
	if range_option == null:
		return 1

	match range_option.selected:
		1:
			return 3
		2:
			return 4
		3:
			return 12
	return 1


func _day_cell_height() -> int:
	return 54 if _range_months() > 4 else 68


func _selected_pause_hours() -> int:
	match pause_option.selected:
		1:
			return 11
		2:
			return 24
	return 9


func _state_name(state: int) -> String:
	match state:
		ScheduleCalculator.DayState.WORK:
			return "praca"
		ScheduleCalculator.DayState.TRAVEL:
			return "jazda do/z pracy"
		ScheduleCalculator.DayState.REST:
			return "pauza 24h"
	return "dom"


func _state_short_name(state: int) -> String:
	match state:
		ScheduleCalculator.DayState.WORK:
			return "Praca"
		ScheduleCalculator.DayState.TRAVEL:
			return "Jazda"
		ScheduleCalculator.DayState.REST:
			return "24h"
	return "Dom"


func _state_color(state: int) -> Color:
	match state:
		ScheduleCalculator.DayState.WORK:
			return COLOR_WORK
		ScheduleCalculator.DayState.TRAVEL:
			return COLOR_TRAVEL
		ScheduleCalculator.DayState.REST:
			return COLOR_REST
	return COLOR_HOME


func _make_spin(min_value: int, max_value: int, value: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.value = value
	spin.custom_minimum_size = Vector2(0, 52)
	spin.value_changed.connect(func(_value: float) -> void: _apply_settings())
	return spin


func _field_stack(label_text: String, field: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := _make_label(label_text, 15, COLOR_TEXT_MUTED)
	box.add_child(label)

	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(field)
	return box


func _make_section_label(text: String) -> Label:
	return _make_label(text, 19, COLOR_TEXT)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_nav_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _make_weekday_label(text: String) -> Label:
	var label := _make_label(text, 14, COLOR_TEXT_MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(0, 28)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _legend_item(color: Color, text: String) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 4)

	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(16, 16)
	item.add_child(swatch)

	item.add_child(_make_label(text, 14, COLOR_TEXT_MUTED))
	return item


func _button_style(color: Color, is_today: bool, in_month: bool, _extra_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color if in_month else color.darkened(0.45)
	style.set_corner_radius_all(7)
	style.set_border_width_all(2 if is_today else 0)
	style.border_color = COLOR_TODAY
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _format_duration(seconds: int) -> String:
	var hours := int(seconds / 3600)
	var minutes := int((seconds % 3600) / 60)
	return "%dh %02dmin" % [hours, minutes]


func _format_unix_time(unix_time: int) -> String:
	var date := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d %02d:%02d" % [
		int(date["year"]),
		int(date["month"]),
		int(date["day"]),
		int(date["hour"]),
		int(date["minute"]),
	]


func _date_key(year: int, month: int, day: int) -> String:
	return "%04d-%02d-%02d" % [year, month, day]


func _on_previous_month() -> void:
	var previous := _previous_month(current_year, current_month)
	current_year = int(previous["year"])
	current_month = int(previous["month"])
	_rebuild_calendar()


func _on_previous_year() -> void:
	current_year -= 1
	_rebuild_calendar()


func _on_next_month() -> void:
	var next := _next_month(current_year, current_month)
	current_year = int(next["year"])
	current_month = int(next["month"])
	_rebuild_calendar()


func _on_next_year() -> void:
	current_year += 1
	_rebuild_calendar()


func _previous_month(year: int, month: int) -> Dictionary:
	month -= 1
	if month < 1:
		month = 12
		year -= 1
	return {"year": year, "month": month}


func _next_month(year: int, month: int) -> Dictionary:
	month += 1
	if month > 12:
		month = 1
		year += 1
	return {"year": year, "month": month}


func now_day() -> int:
	return int(Time.get_datetime_dict_from_system()["day"])

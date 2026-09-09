extends Control

const BackgroundArt = preload("res://scripts/background_art.gd")
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
const WEEKDAY_SHORT_TILE := ["pon", "wt", "śr", "czw", "pt", "sob", "nd"]

const COLOR_PANEL := Color(0.075, 0.090, 0.092, 0.76)
const COLOR_PANEL_SOFT := Color(0.110, 0.125, 0.122, 0.72)
const COLOR_TILE_EMPTY := Color(0.90, 0.93, 0.88, 0.18)
const COLOR_TILE_EMPTY_OUTSIDE := Color(0.90, 0.93, 0.88, 0.08)
const COLOR_TEXT := Color(0.94, 0.955, 0.925)
const COLOR_TEXT_MUTED := Color(0.76, 0.80, 0.77)
const COLOR_TEXT_DIM := Color(0.54, 0.58, 0.55)
const COLOR_WORK := Color(0.60, 0.28, 0.30, 0.82)
const COLOR_HOME := Color(0.30, 0.54, 0.38, 0.82)
const COLOR_TRAVEL := Color(0.73, 0.58, 0.30, 0.84)
const COLOR_REST := Color(0.62, 0.50, 0.27, 0.84)
const COLOR_TODAY := Color(0.92, 0.72, 0.38)
const PORTRAIT_WIDTH := 640

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
var error_label: Label
var work_status_label: Label
var pause_option: OptionButton
var pause_result_label: Label
var day_action_dialog: AcceptDialog
var note_dialog: ConfirmationDialog
var note_edit: TextEdit

var custom_pattern: Array[int] = []
var manual_overrides: Dictionary = {}
var notes: Dictionary = {}
var selected_day_key: String = ""
var selected_day_index: int = 0
var selected_day_year: int = 0
var selected_day_month: int = 0
var selected_day_number: int = 0
var selected_note_key: String = ""
var work_start_unix: int = 0
var work_end_unix: int = 0


func _ready() -> void:
	_force_portrait()

	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	today_day_index = ScheduleCalculator.day_index_from_date(int(now["year"]), int(now["month"]), int(now["day"]))

	_reset_custom_pattern(21)
	_build_ui()
	_apply_settings()


func _force_portrait() -> void:
	ProjectSettings.set_setting("display/window/handheld/orientation", DisplayServer.SCREEN_PORTRAIT)
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	DisplayServer.window_set_size(Vector2i(720, 1280))


func _build_ui() -> void:
	var background := BackgroundArt.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scrim := ColorRect.new()
	scrim.color = Color(0.0, 0.0, 0.0, 0.16)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 18)
	safe_margin.add_theme_constant_override("margin_right", 18)
	safe_margin.add_theme_constant_override("margin_top", 18)
	safe_margin.add_theme_constant_override("margin_bottom", 20)
	add_child(safe_margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe_margin.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(PORTRAIT_WIDTH, 0)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_theme_constant_override("separation", 18)
	center.add_child(root)

	var title := _make_label("Kalendarz Kierowcy", 30, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var subtitle := _make_label("Pusty grafik. Kliknij dzień i układaj cykl.", 20, COLOR_TEXT_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)

	root.add_child(_build_navigation_panel())

	summary_label = _make_label("", 21, COLOR_TEXT)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(summary_label)

	months_box = VBoxContainer.new()
	months_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	months_box.add_theme_constant_override("separation", 26)
	root.add_child(months_box)

	root.add_child(_build_legend())
	root.add_child(_build_settings_panel())
	root.add_child(_build_day_tools_panel())

	_build_day_action_dialog()
	_build_note_dialog()


func _build_settings_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	box.add_child(_make_section_label("Jakim systemem jeździsz?"))

	schedule_option = OptionButton.new()
	schedule_option.add_item("Wybierz system...")
	schedule_option.add_item("2 na 1")
	schedule_option.add_item("2 na 2")
	schedule_option.add_item("3 na 1")
	schedule_option.add_item("3 na 2")
	schedule_option.add_item("4 na 1")
	schedule_option.add_item("6 dni + 24h pauzy + 6 dni")
	schedule_option.add_item("Inne - własny cykl")
	schedule_option.selected = 0
	schedule_option.item_selected.connect(_on_schedule_selected)
	_prepare_control(schedule_option, 23, 64)
	box.add_child(schedule_option)

	box.add_child(_make_section_label("Dzień pierwszy pracy albo cyklu"))

	start_input = LineEdit.new()
	start_input.placeholder_text = "Kliknij dzień w kalendarzu albo wpisz RRRR-MM-DD"
	start_input.text_submitted.connect(func(_text: String) -> void: _apply_settings())
	_prepare_control(start_input, 21, 62)
	box.add_child(start_input)

	var travel_grid := GridContainer.new()
	travel_grid.columns = 2
	travel_grid.add_theme_constant_override("h_separation", 10)
	travel_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(travel_grid)

	commute_before_spin = _make_spin(0, 7, 1)
	travel_grid.add_child(_field_stack("Dojazd przed", commute_before_spin))

	commute_after_spin = _make_spin(0, 7, 1)
	travel_grid.add_child(_field_stack("Zjazd po", commute_after_spin))

	weekly_rest_toggle = CheckButton.new()
	weekly_rest_toggle.text = "Pauza 24h co 6 dni pracy"
	weekly_rest_toggle.button_pressed = true
	weekly_rest_toggle.toggled.connect(func(_enabled: bool) -> void: _apply_settings())
	_prepare_control(weekly_rest_toggle, 20, 56)
	box.add_child(weekly_rest_toggle)

	custom_panel = _build_custom_cycle_panel()
	custom_panel.visible = false
	box.add_child(custom_panel)

	var apply_button := Button.new()
	apply_button.text = "Przelicz grafik"
	apply_button.pressed.connect(_apply_settings)
	_prepare_control(apply_button, 22, 62)
	box.add_child(apply_button)

	error_label = _make_label("", 18, Color(0.95, 0.58, 0.52))
	error_label.visible = false
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(error_label)

	return panel


func _build_custom_cycle_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL_SOFT, 8))

	var box := _panel_box(panel, 10)
	box.add_child(_make_label("Własny cykl: wybierz długość, potem klikaj dni w kalendarzu.", 18, COLOR_TEXT))

	custom_length_spin = _make_spin(1, 56, 21)
	custom_length_spin.value_changed.connect(_on_custom_length_changed)
	box.add_child(_field_stack("Długość powtarzalnego cyklu", custom_length_spin))

	return panel


func _build_navigation_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	box.add_child(nav)

	var previous_button := _make_nav_button("<")
	previous_button.pressed.connect(_on_previous_month)
	nav.add_child(previous_button)

	range_option = OptionButton.new()
	range_option.add_item("Miesiąc")
	range_option.add_item("Kwartał")
	range_option.add_item("4 mies.")
	range_option.add_item("Rok")
	range_option.selected = 0
	range_option.item_selected.connect(func(_index: int) -> void: _rebuild_calendar())
	_prepare_control(range_option, 22, 60)
	nav.add_child(range_option)

	var next_button := _make_nav_button(">")
	next_button.pressed.connect(_on_next_month)
	nav.add_child(next_button)

	var year_buttons := HBoxContainer.new()
	year_buttons.add_theme_constant_override("separation", 8)
	box.add_child(year_buttons)

	var previous_year_button := _make_nav_button("<< rok")
	previous_year_button.pressed.connect(_on_previous_year)
	year_buttons.add_child(previous_year_button)

	var next_year_button := _make_nav_button("rok >>")
	next_year_button.pressed.connect(_on_next_year)
	year_buttons.add_child(next_year_button)

	return panel


func _build_day_tools_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	box.add_child(_make_section_label("Dzień pracy i pauza"))

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	var start_button := Button.new()
	start_button.text = "Rozpocząłem pracę"
	start_button.pressed.connect(_on_start_work_pressed)
	_prepare_control(start_button, 21, 58)
	buttons.add_child(start_button)

	var end_button := Button.new()
	end_button.text = "Zakończyłem pracę"
	end_button.pressed.connect(_on_end_work_pressed)
	_prepare_control(end_button, 21, 58)
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
	_prepare_control(pause_option, 20, 56)
	pause_row.add_child(pause_option)

	var pause_button := Button.new()
	pause_button.text = "Policz pauzę"
	pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_button.pressed.connect(_update_pause_result)
	_prepare_control(pause_button, 20, 56)
	pause_row.add_child(pause_button)

	work_status_label = _make_label("Tu później aplikacja policzy czas pracy.", 18, COLOR_TEXT_MUTED)
	work_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(work_status_label)

	pause_result_label = _make_label("", 19, COLOR_TEXT)
	pause_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pause_result_label)

	return panel


func _build_legend() -> HBoxContainer:
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 9)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_child(_legend_item(COLOR_WORK, "Praca"))
	legend.add_child(_legend_item(COLOR_HOME, "Dom"))
	legend.add_child(_legend_item(COLOR_TRAVEL, "Jazda"))
	legend.add_child(_legend_item(COLOR_REST, "24h"))
	return legend


func _build_day_action_dialog() -> void:
	day_action_dialog = AcceptDialog.new()
	day_action_dialog.title = "Wybierz dzień"
	day_action_dialog.exclusive = false
	day_action_dialog.min_size = Vector2i(640, 650)
	add_child(day_action_dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	day_action_dialog.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var set_travel := _action_button("Ten dzień = wyjazd / zjazd")
	set_travel.pressed.connect(_set_selected_day_state.bind(ScheduleCalculator.DayState.TRAVEL))
	box.add_child(set_travel)

	var set_work := _action_button("Ten dzień = praca")
	set_work.pressed.connect(_set_selected_day_state.bind(ScheduleCalculator.DayState.WORK))
	box.add_child(set_work)

	var set_rest := _action_button("Ten dzień = pauza 24h")
	set_rest.pressed.connect(_set_selected_day_state.bind(ScheduleCalculator.DayState.REST))
	box.add_child(set_rest)

	var set_home := _action_button("Ten dzień = dom")
	set_home.pressed.connect(_set_selected_day_state.bind(ScheduleCalculator.DayState.HOME))
	box.add_child(set_home)

	var clear_day := _action_button("Wyczyść ten dzień")
	clear_day.pressed.connect(_set_selected_day_state.bind(ScheduleCalculator.DayState.NONE))
	box.add_child(clear_day)

	var note_button := _action_button("Dodaj notatkę")
	note_button.pressed.connect(_open_note_from_action_dialog)
	box.add_child(note_button)


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
	note_edit.custom_minimum_size = Vector2(600, 260)
	note_edit.add_theme_font_size_override("font_size", 20)
	margin.add_child(note_edit)


func _apply_settings() -> void:
	var ok := true

	if schedule_option.selected == 0:
		ok = calculator.configure_empty()
	elif _is_custom_schedule():
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
	var counts := _count_visible_months(current_year, current_month, month_count)

	if _calendar_is_empty():
		summary_label.text = "Kalendarz jest pusty. Kliknij dzień i wybierz, czym jest: wyjazd, praca, pauza 24h albo dom."
	else:
		var today_state := _visual_state_for_day(today_day_index, _date_key_from_day_index(today_day_index))
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
	section.add_theme_constant_override("separation", 14)

	var title := _make_label("%s %d" % [MONTH_NAMES[month - 1], year], 31 if _range_months() == 1 else 27, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	section.add_child(grid)

	var first_offset := ScheduleCalculator.month_start_weekday_monday(year, month)
	var days_current := ScheduleCalculator.days_in_month(year, month)

	for cell_index in range(42):
		var date := _date_for_month_cell(year, month, cell_index, first_offset, days_current)
		var date_year := int(date["year"])
		var date_month := int(date["month"])
		var date_day := int(date["day"])
		var day_index := ScheduleCalculator.day_index_from_date(date_year, date_month, date_day)
		var key := _date_key(date_year, date_month, date_day)
		var state := _visual_state_for_day(day_index, key)
		var in_month := date_month == month
		grid.add_child(_make_day_cell(date_year, date_month, date_day, day_index, in_month, state, day_index == today_day_index))

	return section


func _make_day_cell(year: int, month: int, day: int, day_index: int, in_month: bool, state: int, is_today: bool) -> Button:
	var key := _date_key(year, month, day)
	var button := Button.new()
	button.text = _day_cell_text(day, day_index, state, notes.has(key))
	button.custom_minimum_size = Vector2(0, _day_cell_height())
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", _day_cell_font_size())
	button.add_theme_color_override("font_color", COLOR_TEXT if in_month else COLOR_TEXT_DIM)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _tile_style(_state_color(state, in_month), is_today))
	button.add_theme_stylebox_override("hover", _tile_style(_state_color(state, in_month).lightened(0.08), is_today))
	button.add_theme_stylebox_override("pressed", _tile_style(_state_color(state, in_month).darkened(0.09), is_today))
	button.add_theme_stylebox_override("focus", _tile_style(_state_color(state, in_month), true))
	button.pressed.connect(_open_day_actions.bind(year, month, day))
	return button


func _day_cell_text(day: int, day_index: int, state: int, has_note: bool) -> String:
	var weekday := _weekday_short_for_day_index(day_index)
	var state_name := _state_short_name(state)
	var text := "%d\n%s" % [day, weekday]
	if not state_name.is_empty():
		text += "\n%s" % state_name
	if has_note:
		text += "\nnot."
	return text


func _open_day_actions(year: int, month: int, day: int) -> void:
	selected_day_year = year
	selected_day_month = month
	selected_day_number = day
	selected_day_key = _date_key(year, month, day)
	selected_day_index = ScheduleCalculator.day_index_from_date(year, month, day)
	day_action_dialog.title = selected_day_key
	day_action_dialog.popup_centered()


func _set_selected_day_state(state: int) -> void:
	if _is_preset_schedule():
		if state == ScheduleCalculator.DayState.WORK:
			start_input.text = selected_day_key
			manual_overrides.clear()
			_apply_settings()
		elif state == ScheduleCalculator.DayState.NONE:
			manual_overrides.erase(selected_day_key)
			_rebuild_calendar()
		else:
			manual_overrides[selected_day_key] = state
			_rebuild_calendar()
	else:
		_ensure_custom_mode_for_selected_day()
		var offset := ScheduleCalculator.positive_mod(selected_day_index - calculator.start_day_index, custom_pattern.size())
		custom_pattern[offset] = state
		_apply_settings()

	day_action_dialog.hide()


func _ensure_custom_mode_for_selected_day() -> void:
	if not _is_custom_schedule():
		schedule_option.selected = schedule_option.get_item_count() - 1
		custom_panel.visible = true

	if start_input.text.strip_edges().is_empty() or ScheduleCalculator.parse_date(start_input.text).is_empty():
		start_input.text = selected_day_key

	calculator.configure_custom(start_input.text, custom_pattern)


func _open_note_from_action_dialog() -> void:
	day_action_dialog.hide()
	_open_note_editor(selected_day_key)


func _open_note_editor(day_key: String) -> void:
	selected_note_key = day_key
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


func _on_schedule_selected(_index: int) -> void:
	custom_panel.visible = _is_custom_schedule()
	if schedule_option.selected == 0:
		start_input.text = ""
		manual_overrides.clear()
	_apply_settings()


func _on_custom_length_changed(value: float) -> void:
	_resize_custom_pattern(int(value))
	_apply_settings()


func _reset_custom_pattern(days: int) -> void:
	custom_pattern.clear()
	for _index in range(max(1, days)):
		custom_pattern.append(ScheduleCalculator.DayState.NONE)


func _resize_custom_pattern(days: int) -> void:
	var old_pattern := custom_pattern.duplicate()
	_reset_custom_pattern(days)
	for index in range(min(old_pattern.size(), custom_pattern.size())):
		custom_pattern[index] = int(old_pattern[index])


func _visual_state_for_day(day_index: int, key: String) -> int:
	if manual_overrides.has(key):
		return int(manual_overrides[key])
	return calculator.get_state_for_day(day_index)


func _count_visible_months(start_year: int, start_month: int, month_count: int) -> Dictionary:
	var result := {
		"none": 0,
		"work": 0,
		"home": 0,
		"travel": 0,
		"rest": 0,
	}
	var year := start_year
	var month := start_month

	for _i in range(month_count):
		var days := ScheduleCalculator.days_in_month(year, month)
		for day in range(1, days + 1):
			var day_index := ScheduleCalculator.day_index_from_date(year, month, day)
			var key := _date_key(year, month, day)
			var state := _visual_state_for_day(day_index, key)
			match state:
				ScheduleCalculator.DayState.WORK:
					result["work"] += 1
				ScheduleCalculator.DayState.HOME:
					result["home"] += 1
				ScheduleCalculator.DayState.TRAVEL:
					result["travel"] += 1
				ScheduleCalculator.DayState.REST:
					result["rest"] += 1
				_:
					result["none"] += 1

		month += 1
		if month > 12:
			month = 1
			year += 1

	return result


func _calendar_is_empty() -> bool:
	if not manual_overrides.is_empty():
		return false
	if calculator.mode != "none" and calculator.mode != "custom":
		return false
	for state in custom_pattern:
		if int(state) != ScheduleCalculator.DayState.NONE:
			return false
	return true


func _preset_for_index(index: int) -> Dictionary:
	match index:
		1:
			return {"work": 2, "home": 1, "unit": "weeks"}
		2:
			return {"work": 2, "home": 2, "unit": "weeks"}
		3:
			return {"work": 3, "home": 1, "unit": "weeks"}
		4:
			return {"work": 3, "home": 2, "unit": "weeks"}
		5:
			return {"work": 4, "home": 1, "unit": "weeks"}
		6:
			return {"work": 13, "home": 8, "unit": "days"}
	return {"work": 2, "home": 1, "unit": "weeks"}


func _is_preset_schedule() -> bool:
	return schedule_option != null and schedule_option.selected > 0 and not _is_custom_schedule()


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
	match _range_months():
		12:
			return 58
		3, 4:
			return 68
	return 82


func _day_cell_font_size() -> int:
	match _range_months():
		12:
			return 15
		3, 4:
			return 17
	return 20


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
		ScheduleCalculator.DayState.HOME:
			return "dom"
		ScheduleCalculator.DayState.TRAVEL:
			return "jazda do/z pracy"
		ScheduleCalculator.DayState.REST:
			return "pauza 24h"
	return "pusty dzień"


func _state_short_name(state: int) -> String:
	match state:
		ScheduleCalculator.DayState.WORK:
			return "Praca"
		ScheduleCalculator.DayState.HOME:
			return "Dom"
		ScheduleCalculator.DayState.TRAVEL:
			return "Jazda"
		ScheduleCalculator.DayState.REST:
			return "24h"
	return ""


func _state_color(state: int, in_month: bool = true) -> Color:
	if not in_month:
		return COLOR_TILE_EMPTY_OUTSIDE

	match state:
		ScheduleCalculator.DayState.WORK:
			return COLOR_WORK
		ScheduleCalculator.DayState.HOME:
			return COLOR_HOME
		ScheduleCalculator.DayState.TRAVEL:
			return COLOR_TRAVEL
		ScheduleCalculator.DayState.REST:
			return COLOR_REST
	return COLOR_TILE_EMPTY


func _weekday_short_for_day_index(day_index: int) -> String:
	return WEEKDAY_SHORT_TILE[ScheduleCalculator.weekday_monday_first(day_index)]


func _make_spin(min_value: int, max_value: int, value: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.value = value
	spin.value_changed.connect(func(_value: float) -> void: _apply_settings())
	_prepare_control(spin, 20, 56)
	return spin


func _field_stack(label_text: String, field: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := _make_label(label_text, 17, COLOR_TEXT_MUTED)
	box.add_child(label)

	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(field)
	return box


func _make_section_label(text: String) -> Label:
	var label := _make_label(text, 21, COLOR_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_nav_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prepare_control(button, 22, 58)
	return button


func _action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	_prepare_control(button, 21, 66)
	return button


func _prepare_control(control: Control, font_size: int, min_height: int) -> void:
	control.custom_minimum_size.y = min_height
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size", font_size)
	if control is Button or control is OptionButton or control is LineEdit or control is SpinBox:
		control.add_theme_stylebox_override("normal", _control_style(Color(0.90, 0.94, 0.90, 0.13)))
		control.add_theme_stylebox_override("hover", _control_style(Color(0.90, 0.94, 0.90, 0.18)))
		control.add_theme_stylebox_override("pressed", _control_style(Color(0.90, 0.94, 0.90, 0.09)))
		control.add_theme_stylebox_override("focus", _control_style(Color(0.92, 0.72, 0.38, 0.18), true))
		control.add_theme_color_override("font_color", COLOR_TEXT)
		control.add_theme_color_override("font_hover_color", COLOR_TEXT)
		control.add_theme_color_override("font_pressed_color", COLOR_TEXT)
		control.add_theme_color_override("font_focus_color", COLOR_TEXT)
		control.add_theme_color_override("font_placeholder_color", COLOR_TEXT_DIM)


func _legend_item(color: Color, text: String) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 4)

	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(16, 16)
	item.add_child(swatch)

	item.add_child(_make_label(text, 15, COLOR_TEXT_MUTED))
	return item


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, 8))
	return panel


func _panel_box(panel: PanelContainer, margin_size: int = 14) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", margin_size)
	margin.add_theme_constant_override("margin_right", margin_size)
	margin.add_theme_constant_override("margin_top", margin_size)
	margin.add_theme_constant_override("margin_bottom", margin_size)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	margin.add_child(box)
	return box


func _tile_style(color: Color, is_today: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.set_border_width_all(2 if is_today else 1)
	style.border_color = COLOR_TODAY if is_today else Color(1.0, 1.0, 1.0, 0.13)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 1.0, 1.0, 0.10)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _control_style(color: Color, focused: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = COLOR_TODAY if focused else Color(1.0, 1.0, 1.0, 0.15)
	style.content_margin_left = 12
	style.content_margin_right = 12
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


func _date_key_from_day_index(day_index: int) -> String:
	var date := Time.get_datetime_dict_from_unix_time(day_index * 86400)
	return _date_key(int(date["year"]), int(date["month"]), int(date["day"]))


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

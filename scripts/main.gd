extends Control

const ScheduleCalculator = preload("res://scripts/schedule_calculator.gd")

const MONTH_NAMES := [
	"Styczen",
	"Luty",
	"Marzec",
	"Kwiecien",
	"Maj",
	"Czerwiec",
	"Lipiec",
	"Sierpien",
	"Wrzesien",
	"Pazdziernik",
	"Listopad",
	"Grudzien",
]
const WEEKDAY_NAMES := ["Pon", "Wt", "Sr", "Czw", "Pt", "Sob", "Nd"]

const COLOR_BG := Color(0.055, 0.065, 0.075)
const COLOR_PANEL := Color(0.095, 0.105, 0.12)
const COLOR_PANEL_SOFT := Color(0.13, 0.14, 0.155)
const COLOR_TEXT := Color(0.92, 0.94, 0.95)
const COLOR_TEXT_MUTED := Color(0.62, 0.66, 0.70)
const COLOR_WORK := Color(0.72, 0.14, 0.16)
const COLOR_HOME := Color(0.12, 0.45, 0.24)
const COLOR_TODAY := Color(0.95, 0.72, 0.22)

var calculator := ScheduleCalculator.new()
var current_year: int
var current_month: int
var today_day_index: int

var month_label: Label
var summary_label: Label
var calendar_grid: GridContainer
var start_input: LineEdit
var work_spin: SpinBox
var home_spin: SpinBox
var unit_option: OptionButton
var start_work_toggle: CheckButton
var error_label: Label


func _ready() -> void:
	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	today_day_index = ScheduleCalculator.day_index_from_date(int(now["year"]), int(now["month"]), int(now["day"]))

	_build_ui()
	_apply_settings()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = COLOR_BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margins := MarginContainer.new()
	margins.set_anchors_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 28)
	margins.add_theme_constant_override("margin_right", 28)
	margins.add_theme_constant_override("margin_top", 28)
	margins.add_theme_constant_override("margin_bottom", 28)
	add_child(margins)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margins.add_child(root)

	var title := Label.new()
	title.text = "Kalendarz Kierowcy"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	root.add_child(title)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	root.add_child(nav)

	var previous_year_button := Button.new()
	previous_year_button.text = "<<"
	previous_year_button.custom_minimum_size = Vector2(76, 64)
	previous_year_button.pressed.connect(_on_previous_year)
	nav.add_child(previous_year_button)

	var previous_button := Button.new()
	previous_button.text = "<"
	previous_button.custom_minimum_size = Vector2(76, 64)
	previous_button.pressed.connect(_on_previous_month)
	nav.add_child(previous_button)

	month_label = Label.new()
	month_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	month_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	month_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	month_label.add_theme_font_size_override("font_size", 34)
	month_label.add_theme_color_override("font_color", COLOR_TEXT)
	nav.add_child(month_label)

	var next_button := Button.new()
	next_button.text = ">"
	next_button.custom_minimum_size = Vector2(76, 64)
	next_button.pressed.connect(_on_next_month)
	nav.add_child(next_button)

	var next_year_button := Button.new()
	next_year_button.text = ">>"
	next_year_button.custom_minimum_size = Vector2(76, 64)
	next_year_button.pressed.connect(_on_next_year)
	nav.add_child(next_year_button)

	var settings_panel := PanelContainer.new()
	settings_panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, 12))
	root.add_child(settings_panel)

	var settings_margin := MarginContainer.new()
	settings_margin.add_theme_constant_override("margin_left", 16)
	settings_margin.add_theme_constant_override("margin_right", 16)
	settings_margin.add_theme_constant_override("margin_top", 14)
	settings_margin.add_theme_constant_override("margin_bottom", 14)
	settings_panel.add_child(settings_margin)

	var settings := VBoxContainer.new()
	settings.add_theme_constant_override("separation", 10)
	settings_margin.add_child(settings)

	start_input = LineEdit.new()
	start_input.placeholder_text = "Data startu, np. 2026-09-09"
	start_input.text = "%04d-%02d-%02d" % [current_year, current_month, now_day()]
	start_input.text_submitted.connect(func(_text: String) -> void: _apply_settings())
	settings.add_child(_field_row("Start", start_input))

	work_spin = SpinBox.new()
	work_spin.min_value = 1
	work_spin.max_value = 52
	work_spin.step = 1
	work_spin.value = 2
	settings.add_child(_field_row("Praca", work_spin))

	home_spin = SpinBox.new()
	home_spin.min_value = 1
	home_spin.max_value = 52
	home_spin.step = 1
	home_spin.value = 1
	settings.add_child(_field_row("Dom", home_spin))

	unit_option = OptionButton.new()
	unit_option.add_item("Tygodnie")
	unit_option.add_item("Dni")
	unit_option.selected = 0
	settings.add_child(_field_row("Tryb", unit_option))

	start_work_toggle = CheckButton.new()
	start_work_toggle.text = "Data startu = praca"
	start_work_toggle.button_pressed = true
	settings.add_child(start_work_toggle)

	var apply_button := Button.new()
	apply_button.text = "Przelicz kalendarz"
	apply_button.custom_minimum_size = Vector2(0, 60)
	apply_button.pressed.connect(_apply_settings)
	settings.add_child(apply_button)

	error_label = Label.new()
	error_label.visible = false
	error_label.add_theme_font_size_override("font_size", 20)
	error_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	settings.add_child(error_label)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 24)
	summary_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	root.add_child(summary_label)

	calendar_grid = GridContainer.new()
	calendar_grid.columns = 7
	calendar_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	calendar_grid.add_theme_constant_override("h_separation", 8)
	calendar_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(calendar_grid)


func _field_row(label_text: String, field: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(130, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(label)

	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.y = 56
	row.add_child(field)
	return row


func _apply_settings() -> void:
	var unit := "weeks" if unit_option.selected == 0 else "days"
	var ok := calculator.configure(start_input.text, int(work_spin.value), int(home_spin.value), unit, start_work_toggle.button_pressed)

	error_label.visible = not ok
	error_label.text = calculator.last_error

	if ok:
		_rebuild_calendar()


func _rebuild_calendar() -> void:
	for child in calendar_grid.get_children():
		child.queue_free()

	month_label.text = "%s %d" % [MONTH_NAMES[current_month - 1], current_year]

	for weekday in WEEKDAY_NAMES:
		calendar_grid.add_child(_make_weekday_label(weekday))

	var first_offset := ScheduleCalculator.month_start_weekday_monday(current_year, current_month)
	var days_current := ScheduleCalculator.days_in_month(current_year, current_month)

	for cell_index in range(42):
		var date := _date_for_month_cell(cell_index, first_offset, days_current)
		var day_index: int = ScheduleCalculator.day_index_from_date(int(date["year"]), int(date["month"]), int(date["day"]))
		var state: int = calculator.get_state_for_day(day_index)
		var in_month: bool = int(date["month"]) == current_month
		calendar_grid.add_child(_make_day_cell(int(date["day"]), in_month, state, day_index == today_day_index))

	var counts := calculator.count_month(current_year, current_month)
	var current_state := calculator.get_state_for_day(today_day_index)
	var state_text := "w pracy" if current_state == ScheduleCalculator.DayState.WORK else "w domu"
	var change_days := calculator.days_until_next_change(today_day_index)
	summary_label.text = "Ten miesiac: praca %d dni, dom %d dni. Dzisiaj: %s. Zmiana za %d dni. System: %s." % [
		counts["work"],
		counts["home"],
		state_text,
		change_days,
		calculator.cycle_label(),
	]


func _date_for_month_cell(cell_index: int, first_offset: int, days_current: int) -> Dictionary:
	var day_number := cell_index - first_offset + 1
	var year := current_year
	var month := current_month
	var day := day_number

	if day_number < 1:
		var previous := _previous_month(year, month)
		year = int(previous["year"])
		month = int(previous["month"])
		day = ScheduleCalculator.days_in_month(year, month) + day_number
	elif day_number > days_current:
		var next := _next_month(year, month)
		year = int(next["year"])
		month = int(next["month"])
		day = day_number - days_current

	return {
		"year": year,
		"month": month,
		"day": day,
	}


func _make_weekday_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	label.custom_minimum_size = Vector2(0, 40)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_day_cell(day: int, in_month: bool, state: int, is_today: bool) -> PanelContainer:
	var color := COLOR_WORK if state == ScheduleCalculator.DayState.WORK else COLOR_HOME
	if not in_month:
		color = color.darkened(0.45)

	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(0, 112)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_stylebox_override("panel", _cell_style(color, is_today))

	var label := Label.new()
	label.text = str(day)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30 if in_month else 24)
	label.add_theme_color_override("font_color", COLOR_TEXT if in_month else COLOR_TEXT_MUTED)
	cell.add_child(label)
	return cell


func _cell_style(color: Color, is_today: bool) -> StyleBoxFlat:
	var style := _style(color, 8)
	style.set_border_width_all(3 if is_today else 0)
	style.border_color = COLOR_TODAY
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

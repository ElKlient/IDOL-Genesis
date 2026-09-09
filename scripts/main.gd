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
const WEEKDAY_NAMES := ["Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek", "Sobota", "Niedziela"]

const COLOR_PANEL := Color(0.070, 0.085, 0.087, 0.82)
const COLOR_PANEL_SOFT := Color(0.105, 0.120, 0.116, 0.76)
const COLOR_TILE_EMPTY := Color(0.90, 0.93, 0.88, 0.28)
const COLOR_TILE_EMPTY_OUTSIDE := Color(0.90, 0.93, 0.88, 0.08)
const COLOR_TEXT := Color(0.94, 0.955, 0.925)
const COLOR_TEXT_MUTED := Color(0.76, 0.80, 0.77)
const COLOR_TEXT_DIM := Color(0.54, 0.58, 0.55)
const COLOR_WORK := Color(0.58, 0.27, 0.30, 0.86)
const COLOR_HOME := Color(0.28, 0.50, 0.37, 0.86)
const COLOR_REST := Color(0.60, 0.49, 0.27, 0.86)
const COLOR_TODAY := Color(0.92, 0.72, 0.38)
const COLOR_NOTE := Color(0.43, 0.55, 0.60, 0.86)
const COLOR_VACATION := Color(0.40, 0.48, 0.58, 0.86)
const PORTRAIT_WIDTH := 640
const TILE_COLUMNS := 7
const SETTINGS_PATH := "user://driver_calendar.cfg"
const TAP_CANCEL_DISTANCE := 18.0
const TAP_BLOCK_AFTER_DRAG_MS := 180
const SWIPE_MIN_DISTANCE := 96.0
const RETURN_TODAY_BUTTON_TOP := 84
const RETURN_TODAY_BUTTON_HEIGHT := 44
const RETURN_TODAY_BUTTON_WIDTH := 310
const PROFILE_BUTTON_TOP := 84
const PROFILE_BUTTON_HEIGHT := 44
const PROFILE_BUTTON_WIDTH := 142
const PROFILE_PANEL_WIDTH := 230
const PROFILE_PANEL_HEIGHT := 350
const DEFAULT_PROFILE_COUNT := 3

var calculator := ScheduleCalculator.new()
var current_year: int
var current_month: int
var today_day_index: int

var main_scroll: ScrollContainer
var months_box: VBoxContainer
var return_today_button: Button
var profile_button: Button
var profile_overlay: VBoxContainer
var profile_panel: PanelContainer
var profile_option: OptionButton
var profile_save_button: Button
var profile_load_button: Button
var profile_delete_button: Button
var profile_status_label: Label
var summary_label: Label
var reset_settings_button: Button
var save_close_button: Button
var settings_header_button: Button
var navigation_panel: PanelContainer
var settings_toggle_button: Button
var settings_panel: PanelContainer
var legend_bar: HBoxContainer
var day_tools_panel: PanelContainer
var day_tools_body: VBoxContainer
var day_tools_toggle: CheckButton
var start_input: LineEdit
var schedule_option: OptionButton
var range_option: OptionButton
var system_work_spin: SpinBox
var system_home_spin: SpinBox
var weekly_rest_toggle: CheckButton
var fixed_start_toggle: CheckButton
var fixed_start_option: OptionButton
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
var scroll_safe_buttons: Array[BaseButton] = []
var weekly_rest_previous_pressed := true
var fixed_start_previous_pressed := false
var main_view_saved := false
var cycle_pending_apply := false
var day_tools_visible := true
var reset_undo_available := false
var reset_undo_snapshot: Dictionary = {}
var profile_count := DEFAULT_PROFILE_COUNT
var selected_profile_index := 1
var saved_profiles: Dictionary = {}
var profile_panel_visible := false
var touch_start_position := Vector2.ZERO
var touch_tracking_active := false
var touch_drag_cancelled := false
var last_drag_release_msec := -10000
var swipe_start_position := Vector2.ZERO
var swipe_tracking_active := false


func _ready() -> void:
	_force_portrait()

	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	_refresh_today_day_index()

	_reset_custom_pattern(21)
	_build_ui()
	_load_settings_from_disk()
	_apply_settings()
	_apply_main_view_mode(main_view_saved)


func _input(event: InputEvent) -> void:
	_track_scroll_touch(event)
	_track_month_swipe(event)


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

	main_scroll = ScrollContainer.new()
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.scroll_deadzone = 6
	main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe_margin.add_child(main_scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.add_child(center)

	_add_return_today_overlay()
	_add_profile_overlay()

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(PORTRAIT_WIDTH, 0)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_theme_constant_override("separation", 18)
	center.add_child(root)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)

	reset_settings_button = Button.new()
	reset_settings_button.text = "Resetuj"
	_connect_tap(reset_settings_button, Callable(self, "_on_reset_or_undo_pressed"))
	_prepare_control(reset_settings_button, 15, 54)
	reset_settings_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	header.add_child(reset_settings_button)

	var title := _make_label("Kalendarz Kierowcy", 30, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	save_close_button = Button.new()
	save_close_button.text = "Zapisz i zamknij"
	_connect_tap(save_close_button, Callable(self, "_save_and_close_main_view"))
	_prepare_control(save_close_button, 14, 54)
	save_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(save_close_button)

	settings_header_button = Button.new()
	settings_header_button.text = "Ustawienia"
	_connect_tap(settings_header_button, Callable(self, "_open_calendar_settings"))
	_prepare_control(settings_header_button, 15, 54)
	settings_header_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	settings_header_button.visible = false
	header.add_child(settings_header_button)

	var return_today_spacer := Control.new()
	return_today_spacer.custom_minimum_size = Vector2(0, RETURN_TODAY_BUTTON_HEIGHT)
	root.add_child(return_today_spacer)

	navigation_panel = _build_navigation_panel()
	root.add_child(navigation_panel)

	summary_label = _make_label("", 21, COLOR_TEXT)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(summary_label)

	months_box = VBoxContainer.new()
	months_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	months_box.add_theme_constant_override("separation", 26)
	root.add_child(months_box)

	legend_bar = _build_legend()
	root.add_child(legend_bar)

	settings_toggle_button = Button.new()
	settings_toggle_button.text = "Zastosuj"
	_connect_tap(settings_toggle_button, Callable(self, "_on_settings_primary_pressed"))
	_prepare_control(settings_toggle_button, 22, 62)
	root.add_child(settings_toggle_button)

	settings_panel = _build_settings_panel()
	root.add_child(settings_panel)
	day_tools_panel = _build_day_tools_panel()
	root.add_child(day_tools_panel)
	_set_settings_visible(true)

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
	_set_option_selected(schedule_option, 0)
	schedule_option.item_selected.connect(_on_schedule_selected)
	_prepare_control(schedule_option, 23, 64)
	box.add_child(schedule_option)

	var cycle_grid := GridContainer.new()
	cycle_grid.columns = 2
	cycle_grid.add_theme_constant_override("h_separation", 10)
	cycle_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(cycle_grid)

	system_work_spin = _make_spin(1, 90, 14)
	cycle_grid.add_child(_field_stack("Dni pracy", system_work_spin))

	system_home_spin = _make_spin(1, 90, 7)
	cycle_grid.add_child(_field_stack("Dni domu", system_home_spin))

	box.add_child(_make_section_label("Dzień pierwszy pracy albo cyklu"))

	start_input = LineEdit.new()
	start_input.placeholder_text = "Kliknij dzień w kalendarzu albo wpisz RRRR-MM-DD"
	start_input.text_submitted.connect(func(_text: String) -> void: _mark_cycle_pending())
	_prepare_control(start_input, 21, 62)
	box.add_child(start_input)

	fixed_start_toggle = CheckButton.new()
	fixed_start_toggle.text = "Zawsze zaczynam pracę w ten sam dzień"
	fixed_start_toggle.button_pressed = false
	fixed_start_previous_pressed = fixed_start_toggle.button_pressed
	fixed_start_toggle.toggled.connect(_on_fixed_start_toggled)
	_prepare_control(fixed_start_toggle, 20, 56)
	box.add_child(fixed_start_toggle)

	fixed_start_option = OptionButton.new()
	fixed_start_option.add_item("Wybierz dzień rozpoczęcia pracy")
	for weekday_name in WEEKDAY_NAMES:
		fixed_start_option.add_item(weekday_name)
	_set_option_selected(fixed_start_option, 0)
	fixed_start_option.item_selected.connect(_on_fixed_start_day_selected)
	_prepare_control(fixed_start_option, 20, 58)
	fixed_start_option.visible = false
	box.add_child(fixed_start_option)

	weekly_rest_toggle = CheckButton.new()
	weekly_rest_toggle.text = "Pauza 24h co 6 dni pracy"
	weekly_rest_toggle.button_pressed = true
	weekly_rest_previous_pressed = weekly_rest_toggle.button_pressed
	weekly_rest_toggle.toggled.connect(_on_weekly_rest_toggled)
	_prepare_control(weekly_rest_toggle, 20, 56)
	box.add_child(weekly_rest_toggle)

	custom_panel = _build_custom_cycle_panel()
	custom_panel.visible = false
	box.add_child(custom_panel)

	var close_settings_button := Button.new()
	close_settings_button.text = "Zamknij ustawienia"
	_connect_tap(close_settings_button, Callable(self, "_close_settings_panel"))
	_prepare_control(close_settings_button, 22, 62)
	box.add_child(close_settings_button)

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

	custom_length_spin = _make_spin(1, 56, 21, false)
	custom_length_spin.value_changed.connect(_on_custom_length_spin_changed)
	box.add_child(_field_stack("Długość powtarzalnego cyklu", custom_length_spin))

	return panel


func _build_navigation_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	box.add_child(nav)

	var previous_button := _make_nav_button("<")
	_connect_tap(previous_button, Callable(self, "_on_previous_month"))
	nav.add_child(previous_button)

	range_option = OptionButton.new()
	range_option.add_item("Miesiąc")
	range_option.add_item("Kwartał")
	range_option.add_item("4 mies.")
	range_option.add_item("Rok")
	_set_option_selected(range_option, 0)
	range_option.item_selected.connect(_on_range_selected)
	_prepare_control(range_option, 22, 60)
	_prepare_large_dropdown(range_option)
	nav.add_child(range_option)

	var next_button := _make_nav_button(">")
	_connect_tap(next_button, Callable(self, "_on_next_month"))
	nav.add_child(next_button)

	var year_buttons := HBoxContainer.new()
	year_buttons.add_theme_constant_override("separation", 8)
	box.add_child(year_buttons)

	var previous_year_button := _make_nav_button("<< rok")
	_connect_tap(previous_year_button, Callable(self, "_on_previous_year"))
	year_buttons.add_child(previous_year_button)

	var next_year_button := _make_nav_button("rok >>")
	_connect_tap(next_year_button, Callable(self, "_on_next_year"))
	year_buttons.add_child(next_year_button)

	return panel


func _add_return_today_overlay() -> void:
	var overlay := MarginContainer.new()
	overlay.set_anchors_preset(Control.PRESET_TOP_WIDE)
	overlay.offset_left = 18.0
	overlay.offset_right = -18.0
	overlay.offset_top = RETURN_TODAY_BUTTON_TOP
	overlay.offset_bottom = RETURN_TODAY_BUTTON_TOP + RETURN_TODAY_BUTTON_HEIGHT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 30
	add_child(overlay)

	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay.add_child(holder)

	return_today_button = Button.new()
	return_today_button.text = "Wróć do aktualnej daty"
	_connect_tap(return_today_button, Callable(self, "_on_return_to_today_pressed"))
	_prepare_control(return_today_button, 18, RETURN_TODAY_BUTTON_HEIGHT)
	return_today_button.custom_minimum_size.x = RETURN_TODAY_BUTTON_WIDTH
	return_today_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(return_today_button)


func _add_profile_overlay() -> void:
	profile_overlay = VBoxContainer.new()
	profile_overlay.anchor_left = 1.0
	profile_overlay.anchor_right = 1.0
	profile_overlay.anchor_top = 0.0
	profile_overlay.anchor_bottom = 0.0
	profile_overlay.offset_left = -PROFILE_PANEL_WIDTH - 18.0
	profile_overlay.offset_right = -18.0
	profile_overlay.offset_top = PROFILE_BUTTON_TOP
	profile_overlay.offset_bottom = PROFILE_BUTTON_TOP + PROFILE_BUTTON_HEIGHT + PROFILE_PANEL_HEIGHT
	profile_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_overlay.z_index = 35
	profile_overlay.add_theme_constant_override("separation", 7)
	add_child(profile_overlay)

	profile_button = Button.new()
	profile_button.text = "Profile"
	_connect_tap(profile_button, Callable(self, "_toggle_profile_panel"))
	_prepare_control(profile_button, 16, PROFILE_BUTTON_HEIGHT)
	profile_button.custom_minimum_size.x = PROFILE_BUTTON_WIDTH
	profile_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	profile_overlay.add_child(profile_button)

	profile_panel = _build_profile_panel()
	profile_overlay.add_child(profile_panel)
	_refresh_profile_options()
	_set_profile_panel_visible(false)


func _build_profile_panel() -> PanelContainer:
	var panel := _panel()
	panel.custom_minimum_size.x = PROFILE_PANEL_WIDTH
	var box := _panel_box(panel, 8)

	box.add_child(_make_label("Profile kalendarza", 17, COLOR_TEXT))

	profile_option = OptionButton.new()
	profile_option.item_selected.connect(_on_profile_selected)
	_prepare_control(profile_option, 16, 48)
	_prepare_large_dropdown(profile_option)
	box.add_child(profile_option)

	profile_save_button = Button.new()
	profile_save_button.text = "Zapisz w profilu"
	_connect_tap(profile_save_button, Callable(self, "_on_save_profile_pressed"))
	_prepare_control(profile_save_button, 16, 46)
	box.add_child(profile_save_button)

	profile_load_button = Button.new()
	profile_load_button.text = "Wczytaj"
	_connect_tap(profile_load_button, Callable(self, "_on_load_profile_pressed"))
	_prepare_control(profile_load_button, 16, 46)
	box.add_child(profile_load_button)

	profile_delete_button = Button.new()
	profile_delete_button.text = "Usuń profil"
	_connect_tap(profile_delete_button, Callable(self, "_on_delete_profile_pressed"))
	_prepare_control(profile_delete_button, 16, 46)
	box.add_child(profile_delete_button)

	var add_button := Button.new()
	add_button.text = "Dodaj profil"
	_connect_tap(add_button, Callable(self, "_on_add_profile_pressed"))
	_prepare_control(add_button, 16, 46)
	box.add_child(add_button)

	profile_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	profile_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(profile_status_label)

	return panel


func _build_day_tools_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)

	var title := _make_section_label("Dzień pracy i pauza")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	day_tools_toggle = CheckButton.new()
	day_tools_toggle.text = ""
	day_tools_toggle.button_pressed = day_tools_visible
	day_tools_toggle.toggled.connect(_on_day_tools_toggled)
	day_tools_toggle.custom_minimum_size = Vector2(88, 48)
	day_tools_toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	_register_scroll_safe_control(day_tools_toggle)
	header.add_child(day_tools_toggle)

	day_tools_body = VBoxContainer.new()
	day_tools_body.add_theme_constant_override("separation", 8)
	box.add_child(day_tools_body)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	day_tools_body.add_child(buttons)

	var start_button := Button.new()
	start_button.text = "Rozpocząłem pracę"
	_connect_tap(start_button, Callable(self, "_on_start_work_pressed"))
	_prepare_control(start_button, 21, 58)
	buttons.add_child(start_button)

	var end_button := Button.new()
	end_button.text = "Zakończyłem pracę"
	_connect_tap(end_button, Callable(self, "_on_end_work_pressed"))
	_prepare_control(end_button, 21, 58)
	buttons.add_child(end_button)

	var pause_row := HBoxContainer.new()
	pause_row.add_theme_constant_override("separation", 8)
	day_tools_body.add_child(pause_row)

	pause_option = OptionButton.new()
	pause_option.add_item("9h")
	pause_option.add_item("11h")
	pause_option.add_item("24h")
	_set_option_selected(pause_option, 0)
	pause_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_option.item_selected.connect(_on_pause_selected)
	_prepare_control(pause_option, 20, 56)
	pause_row.add_child(pause_option)

	var pause_button := Button.new()
	pause_button.text = "Policz pauzę"
	pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connect_tap(pause_button, Callable(self, "_update_pause_result"))
	_prepare_control(pause_button, 20, 56)
	pause_row.add_child(pause_button)

	work_status_label = _make_label("Tu później aplikacja policzy czas pracy.", 18, COLOR_TEXT_MUTED)
	work_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_tools_body.add_child(work_status_label)

	pause_result_label = _make_label("", 19, COLOR_TEXT)
	pause_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_tools_body.add_child(pause_result_label)

	_apply_day_tools_visibility()

	return panel


func _build_legend() -> HBoxContainer:
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 9)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_child(_legend_item(COLOR_WORK, "Praca"))
	legend.add_child(_legend_item(COLOR_HOME, "Dom"))
	legend.add_child(_legend_item(COLOR_REST, "24h"))
	legend.add_child(_legend_item(COLOR_VACATION, "Urlop"))
	return legend


func _build_day_action_dialog() -> void:
	day_action_dialog = AcceptDialog.new()
	day_action_dialog.title = "Wybierz dzień"
	day_action_dialog.exclusive = false
	day_action_dialog.min_size = Vector2i(640, 650)
	day_action_dialog.add_theme_stylebox_override("panel", _dialog_style())
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

	var set_work := _action_button("Ten dzień = praca", COLOR_WORK)
	_connect_tap(set_work, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.WORK))
	box.add_child(set_work)

	var set_rest := _action_button("Ten dzień = pauza 24h", COLOR_REST)
	_connect_tap(set_rest, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.REST))
	box.add_child(set_rest)

	var set_home := _action_button("Ten dzień = dom", COLOR_HOME)
	_connect_tap(set_home, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.HOME))
	box.add_child(set_home)

	var set_vacation := _action_button("Ten dzień = urlop", COLOR_VACATION)
	_connect_tap(set_vacation, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.VACATION))
	box.add_child(set_vacation)

	var clear_day := _action_button("Wyczyść ten dzień", Color(0.52, 0.55, 0.54, 0.86))
	_connect_tap(clear_day, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.NONE))
	box.add_child(clear_day)

	var note_button := _action_button("Dodaj notatkę", COLOR_NOTE)
	_connect_tap(note_button, Callable(self, "_open_note_from_action_dialog"))
	box.add_child(note_button)

	var close_button := day_action_dialog.get_ok_button()
	close_button.text = "Zamknij"
	_prepare_control(close_button, 18, 48)


func _build_note_dialog() -> void:
	note_dialog = ConfirmationDialog.new()
	note_dialog.title = "Notatka"
	note_dialog.confirmed.connect(_save_note)
	note_dialog.add_theme_stylebox_override("panel", _dialog_style())
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


func _save_settings_and_close() -> void:
	if _apply_settings(false, true):
		_save_settings_to_disk()


func _save_and_close_main_view() -> void:
	if not _apply_settings(false, true):
		return

	main_view_saved = true
	_save_settings_to_disk()
	_apply_main_view_mode(true)


func _open_calendar_settings() -> void:
	main_view_saved = false
	_apply_main_view_mode(false)
	_set_settings_visible(true)
	_save_settings_to_disk()


func _mark_cycle_pending() -> void:
	cycle_pending_apply = true
	_save_settings_to_disk()


func _on_settings_primary_pressed() -> void:
	if settings_panel != null and settings_panel.visible:
		_save_settings_and_close()
	else:
		_set_settings_visible(true)


func _close_settings_panel() -> void:
	_set_settings_visible(false)


func _on_day_tools_toggled(visible: bool) -> void:
	if _tap_is_blocked():
		day_tools_toggle.set_pressed_no_signal(day_tools_visible)
		return

	day_tools_visible = visible
	_apply_day_tools_visibility()
	_save_settings_to_disk()


func _apply_day_tools_visibility() -> void:
	if day_tools_body != null:
		day_tools_body.visible = day_tools_visible
	if day_tools_toggle != null:
		day_tools_toggle.set_pressed_no_signal(day_tools_visible)


func _toggle_profile_panel() -> void:
	_set_profile_panel_visible(not profile_panel_visible)


func _set_profile_panel_visible(visible: bool) -> void:
	profile_panel_visible = visible
	if profile_panel != null:
		profile_panel.visible = visible


func _toggle_settings_panel() -> void:
	if main_view_saved:
		return

	_set_settings_visible(settings_panel == null or not settings_panel.visible)


func _set_settings_visible(visible: bool) -> void:
	if main_view_saved:
		visible = false

	if settings_panel != null:
		settings_panel.visible = visible
	if settings_toggle_button != null:
		settings_toggle_button.text = "Zastosuj" if visible else "Ustaw kalendarz"
	if reset_settings_button != null:
		reset_settings_button.visible = true
	if save_close_button != null:
		save_close_button.visible = not main_view_saved
	if settings_header_button != null:
		settings_header_button.visible = main_view_saved


func _apply_main_view_mode(saved: bool) -> void:
	main_view_saved = saved

	if navigation_panel != null:
		navigation_panel.visible = not saved
	if summary_label != null:
		summary_label.visible = not saved
	if legend_bar != null:
		legend_bar.visible = not saved
	if settings_toggle_button != null:
		settings_toggle_button.visible = not saved
	if settings_panel != null and saved:
		settings_panel.visible = false
	if reset_settings_button != null:
		reset_settings_button.visible = true
	if save_close_button != null:
		save_close_button.visible = not saved
	if settings_header_button != null:
		settings_header_button.visible = saved
	if day_tools_panel != null:
		day_tools_panel.visible = true
	_apply_day_tools_visibility()
	_update_reset_button_text()


func _update_reset_button_text() -> void:
	if reset_settings_button != null:
		reset_settings_button.text = "Cofnij" if reset_undo_available else "Resetuj"


func _on_reset_or_undo_pressed() -> void:
	if reset_undo_available:
		_undo_calendar_reset()
	else:
		_reset_calendar_settings()


func _save_settings_to_disk() -> void:
	if schedule_option == null:
		return

	var config := ConfigFile.new()
	config.set_value("ui", "main_view_saved", main_view_saved)
	config.set_value("ui", "cycle_pending_apply", cycle_pending_apply)
	config.set_value("ui", "day_tools_visible", day_tools_visible)
	config.set_value("undo_reset", "available", reset_undo_available)
	config.set_value("undo_reset", "snapshot", reset_undo_snapshot.duplicate(true))
	config.set_value("profiles", "count", profile_count)
	config.set_value("profiles", "selected", selected_profile_index)
	config.set_value("profiles", "items", saved_profiles.duplicate(true))
	config.set_value("calendar", "current_year", current_year)
	config.set_value("calendar", "current_month", current_month)
	config.set_value("calendar", "schedule_selected", schedule_option.selected)
	config.set_value("calendar", "range_selected", range_option.selected)
	config.set_value("calendar", "start_date", start_input.text)
	config.set_value("calendar", "work_days", int(system_work_spin.value))
	config.set_value("calendar", "home_days", int(system_home_spin.value))
	config.set_value("calendar", "weekly_rest", weekly_rest_toggle.button_pressed)
	config.set_value("calendar", "fixed_start_enabled", fixed_start_toggle.button_pressed)
	config.set_value("calendar", "fixed_start_selected", fixed_start_option.selected)
	config.set_value("calendar", "custom_length", int(custom_length_spin.value))
	config.set_value("calendar", "custom_pattern", custom_pattern.duplicate())
	config.set_value("calendar", "manual_overrides", manual_overrides.duplicate(true))
	config.set_value("calendar", "notes", notes.duplicate(true))
	config.set_value("work", "start_unix", work_start_unix)
	config.set_value("work", "end_unix", work_end_unix)
	config.set_value("work", "pause_selected", pause_option.selected)

	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Nie udało się zapisać ustawień kalendarza: %d" % error)


func _load_settings_from_disk() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	main_view_saved = bool(config.get_value("ui", "main_view_saved", false))
	cycle_pending_apply = bool(config.get_value("ui", "cycle_pending_apply", false))
	day_tools_visible = bool(config.get_value("ui", "day_tools_visible", true))
	reset_undo_available = bool(config.get_value("undo_reset", "available", false))
	_load_reset_undo_snapshot(config.get_value("undo_reset", "snapshot", {}))
	profile_count = maxi(DEFAULT_PROFILE_COUNT, int(config.get_value("profiles", "count", DEFAULT_PROFILE_COUNT)))
	selected_profile_index = clampi(int(config.get_value("profiles", "selected", 1)), 1, profile_count)
	_load_saved_profiles(config.get_value("profiles", "items", {}))
	_refresh_profile_options()
	_set_profile_panel_visible(false)
	current_year = int(config.get_value("calendar", "current_year", current_year))
	current_month = clampi(int(config.get_value("calendar", "current_month", current_month)), 1, 12)

	_set_option_selected(schedule_option, _valid_option_index(schedule_option, int(config.get_value("calendar", "schedule_selected", 0))))
	_set_option_selected(range_option, _valid_option_index(range_option, int(config.get_value("calendar", "range_selected", 0))))
	_set_option_selected(pause_option, _valid_option_index(pause_option, int(config.get_value("work", "pause_selected", 0))))
	_set_spin_value(system_work_spin, int(config.get_value("calendar", "work_days", int(system_work_spin.value))))
	_set_spin_value(system_home_spin, int(config.get_value("calendar", "home_days", int(system_home_spin.value))))
	_set_spin_value(custom_length_spin, int(config.get_value("calendar", "custom_length", int(custom_length_spin.value))))

	start_input.text = String(config.get_value("calendar", "start_date", ""))

	weekly_rest_toggle.set_pressed_no_signal(bool(config.get_value("calendar", "weekly_rest", weekly_rest_toggle.button_pressed)))
	weekly_rest_previous_pressed = weekly_rest_toggle.button_pressed
	fixed_start_toggle.set_pressed_no_signal(bool(config.get_value("calendar", "fixed_start_enabled", fixed_start_toggle.button_pressed)))
	fixed_start_previous_pressed = fixed_start_toggle.button_pressed
	_set_option_selected(fixed_start_option, _valid_option_index(fixed_start_option, int(config.get_value("calendar", "fixed_start_selected", 0))))
	fixed_start_option.visible = fixed_start_toggle.button_pressed
	custom_panel.visible = _is_custom_schedule()

	_load_custom_pattern(config.get_value("calendar", "custom_pattern", []))
	_load_dictionary_as_ints(manual_overrides, config.get_value("calendar", "manual_overrides", {}))
	_load_dictionary_as_strings(notes, config.get_value("calendar", "notes", {}))

	work_start_unix = int(config.get_value("work", "start_unix", 0))
	work_end_unix = int(config.get_value("work", "end_unix", 0))
	_restore_work_panel_text()
	_apply_day_tools_visibility()


func _valid_option_index(option: OptionButton, index: int) -> int:
	if option == null or option.get_item_count() <= 0:
		return 0
	return clampi(index, 0, option.get_item_count() - 1)


func _load_custom_pattern(value: Variant) -> void:
	custom_pattern.clear()
	if value is Array:
		for state in value:
			custom_pattern.append(int(state))

	if custom_pattern.is_empty():
		_reset_custom_pattern(int(custom_length_spin.value))


func _load_dictionary_as_ints(target: Dictionary, value: Variant) -> void:
	target.clear()
	if not (value is Dictionary):
		return

	for key in value.keys():
		target[String(key)] = int(value[key])


func _load_dictionary_as_strings(target: Dictionary, value: Variant) -> void:
	target.clear()
	if not (value is Dictionary):
		return

	for key in value.keys():
		target[String(key)] = String(value[key])


func _load_reset_undo_snapshot(value: Variant) -> void:
	reset_undo_snapshot.clear()
	if value is Dictionary:
		reset_undo_snapshot = value.duplicate(true)
	if reset_undo_snapshot.is_empty():
		reset_undo_available = false


func _load_saved_profiles(value: Variant) -> void:
	saved_profiles.clear()
	if not (value is Dictionary):
		return

	for key in value.keys():
		var profile_key := String(key)
		var profile_state: Variant = value[key]
		if not (profile_state is Dictionary):
			continue

		saved_profiles[profile_key] = profile_state.duplicate(true)
		if profile_key.is_valid_int():
			profile_count = maxi(profile_count, int(profile_key))


func _refresh_profile_options() -> void:
	if profile_option == null:
		return

	profile_count = maxi(DEFAULT_PROFILE_COUNT, profile_count)
	selected_profile_index = clampi(selected_profile_index, 1, profile_count)
	profile_option.clear()

	for index in range(1, profile_count + 1):
		profile_option.add_item(_profile_label(index))

	_set_option_selected(profile_option, selected_profile_index - 1)
	_update_profile_actions()


func _profile_label(index: int) -> String:
	var state := "zapisany" if saved_profiles.has(_profile_key(index)) else "pusty"
	return "Profil %d - %s" % [index, state]


func _profile_key(index: int) -> String:
	return str(index)


func _selected_profile_key() -> String:
	return _profile_key(selected_profile_index)


func _selected_profile_saved() -> bool:
	return saved_profiles.has(_selected_profile_key())


func _update_profile_actions() -> void:
	var has_saved_profile := _selected_profile_saved()
	if profile_load_button != null:
		profile_load_button.disabled = not has_saved_profile
	if profile_delete_button != null:
		profile_delete_button.visible = has_saved_profile
	if profile_status_label != null:
		profile_status_label.text = "Ten profil jest zapisany." if has_saved_profile else "Ten profil jest pusty."


func _on_profile_selected(index: int) -> void:
	if _option_change_was_scroll(profile_option, index):
		return

	selected_profile_index = clampi(index + 1, 1, profile_count)
	_update_profile_actions()
	_save_settings_to_disk()


func _on_save_profile_pressed() -> void:
	if not _apply_settings(false, true):
		if profile_status_label != null:
			profile_status_label.text = "Popraw ustawienia przed zapisem profilu."
		return

	saved_profiles[_selected_profile_key()] = _calendar_state_snapshot()
	_refresh_profile_options()
	_set_profile_panel_visible(true)
	if profile_status_label != null:
		profile_status_label.text = "Zapisano profil %d." % selected_profile_index
	_save_settings_to_disk()


func _on_load_profile_pressed() -> void:
	if not _selected_profile_saved():
		if profile_status_label != null:
			profile_status_label.text = "Ten profil jest pusty."
		return

	var snapshot: Dictionary = saved_profiles[_selected_profile_key()].duplicate(true)
	reset_undo_available = false
	reset_undo_snapshot.clear()
	_restore_calendar_state(snapshot)
	_refresh_profile_options()
	_set_profile_panel_visible(true)
	if profile_status_label != null:
		profile_status_label.text = "Wczytano profil %d." % selected_profile_index
	_update_reset_button_text()
	_save_settings_to_disk()


func _on_delete_profile_pressed() -> void:
	var deleted_index := selected_profile_index
	saved_profiles.erase(_selected_profile_key())
	_refresh_profile_options()
	_set_profile_panel_visible(false)
	if profile_status_label != null:
		profile_status_label.text = "Usunięto profil %d." % deleted_index
	_save_settings_to_disk()


func _on_add_profile_pressed() -> void:
	profile_count += 1
	selected_profile_index = profile_count
	_refresh_profile_options()
	_set_profile_panel_visible(true)
	if profile_status_label != null:
		profile_status_label.text = "Dodano profil %d. Możesz go zapisać." % selected_profile_index
	_save_settings_to_disk()


func _calendar_state_snapshot() -> Dictionary:
	return {
		"main_view_saved": main_view_saved,
		"cycle_pending_apply": cycle_pending_apply,
		"day_tools_visible": day_tools_visible,
		"settings_visible": settings_panel != null and settings_panel.visible,
		"current_year": current_year,
		"current_month": current_month,
		"schedule_selected": schedule_option.selected,
		"range_selected": range_option.selected,
		"start_date": start_input.text,
		"work_days": int(system_work_spin.value),
		"home_days": int(system_home_spin.value),
		"weekly_rest": weekly_rest_toggle.button_pressed,
		"fixed_start_enabled": fixed_start_toggle.button_pressed,
		"fixed_start_selected": fixed_start_option.selected,
		"custom_length": int(custom_length_spin.value),
		"custom_pattern": custom_pattern.duplicate(),
		"manual_overrides": manual_overrides.duplicate(true),
		"notes": notes.duplicate(true),
		"work_start_unix": work_start_unix,
		"work_end_unix": work_end_unix,
		"pause_selected": pause_option.selected,
	}


func _restore_calendar_state(snapshot: Dictionary) -> void:
	main_view_saved = bool(snapshot.get("main_view_saved", false))
	cycle_pending_apply = bool(snapshot.get("cycle_pending_apply", false))
	day_tools_visible = bool(snapshot.get("day_tools_visible", true))
	current_year = int(snapshot.get("current_year", current_year))
	current_month = clampi(int(snapshot.get("current_month", current_month)), 1, 12)

	_set_option_selected(schedule_option, _valid_option_index(schedule_option, int(snapshot.get("schedule_selected", 0))))
	_set_option_selected(range_option, _valid_option_index(range_option, int(snapshot.get("range_selected", 0))))
	_set_option_selected(pause_option, _valid_option_index(pause_option, int(snapshot.get("pause_selected", 0))))
	_set_spin_value(system_work_spin, int(snapshot.get("work_days", int(system_work_spin.value))))
	_set_spin_value(system_home_spin, int(snapshot.get("home_days", int(system_home_spin.value))))
	_set_spin_value(custom_length_spin, int(snapshot.get("custom_length", int(custom_length_spin.value))))

	start_input.text = String(snapshot.get("start_date", ""))
	weekly_rest_toggle.set_pressed_no_signal(bool(snapshot.get("weekly_rest", true)))
	weekly_rest_previous_pressed = weekly_rest_toggle.button_pressed
	fixed_start_toggle.set_pressed_no_signal(bool(snapshot.get("fixed_start_enabled", false)))
	fixed_start_previous_pressed = fixed_start_toggle.button_pressed
	_set_option_selected(fixed_start_option, _valid_option_index(fixed_start_option, int(snapshot.get("fixed_start_selected", 0))))
	fixed_start_option.visible = fixed_start_toggle.button_pressed
	custom_panel.visible = _is_custom_schedule()

	_load_custom_pattern(snapshot.get("custom_pattern", []))
	_load_dictionary_as_ints(manual_overrides, snapshot.get("manual_overrides", {}))
	_load_dictionary_as_strings(notes, snapshot.get("notes", {}))

	work_start_unix = int(snapshot.get("work_start_unix", 0))
	work_end_unix = int(snapshot.get("work_end_unix", 0))
	_restore_work_panel_text()
	if not _apply_settings(false, false):
		_rebuild_calendar()
	_apply_main_view_mode(main_view_saved)
	if not main_view_saved:
		_set_settings_visible(bool(snapshot.get("settings_visible", true)))
	_apply_day_tools_visibility()


func _restore_work_panel_text() -> void:
	if work_status_label == null:
		return

	if work_start_unix <= 0:
		work_status_label.text = "Tu później aplikacja policzy czas pracy."
		if pause_result_label != null:
			pause_result_label.text = ""
		return

	if work_end_unix <= 0:
		work_status_label.text = "Start pracy: %s" % _format_unix_time(work_start_unix)
		if pause_result_label != null:
			pause_result_label.text = ""
		return

	var worked_seconds: int = maxi(0, work_end_unix - work_start_unix)
	work_status_label.text = "Praca trwała: %s. Koniec: %s" % [
		_format_duration(worked_seconds),
		_format_unix_time(work_end_unix),
	]
	_update_pause_result()


func _adopt_manual_cycle_from_overrides() -> void:
	var day_indices := _manual_override_day_indices()
	if day_indices.is_empty():
		return

	var start_index := int(day_indices[0])
	var end_index := int(day_indices[day_indices.size() - 1])
	var max_length := int(custom_length_spin.max_value)
	var cycle_length := clampi(end_index - start_index + 1, 1, max_length)

	_set_option_selected(schedule_option, schedule_option.get_item_count() - 1)
	_set_spin_value(custom_length_spin, cycle_length)
	start_input.text = _date_key_from_day_index(start_index)
	custom_panel.visible = true
	_reset_custom_pattern(cycle_length)

	for key in manual_overrides.keys():
		var parsed := ScheduleCalculator.parse_date(String(key))
		if parsed.is_empty():
			continue

		var day_index := ScheduleCalculator.day_index_from_date(
			int(parsed["year"]),
			int(parsed["month"]),
			int(parsed["day"])
		)
		var offset := day_index - start_index
		if offset >= 0 and offset < custom_pattern.size():
			custom_pattern[offset] = int(manual_overrides[key])


func _manual_override_day_indices() -> Array[int]:
	var day_indices: Array[int] = []
	for key in manual_overrides.keys():
		var parsed := ScheduleCalculator.parse_date(String(key))
		if parsed.is_empty():
			continue

		day_indices.append(ScheduleCalculator.day_index_from_date(
			int(parsed["year"]),
			int(parsed["month"]),
			int(parsed["day"])
		))

	day_indices.sort()
	return day_indices


func _undo_calendar_reset() -> void:
	if reset_undo_snapshot.is_empty():
		reset_undo_available = false
		_update_reset_button_text()
		_save_settings_to_disk()
		return

	var snapshot := reset_undo_snapshot.duplicate(true)
	reset_undo_available = false
	reset_undo_snapshot.clear()
	_restore_calendar_state(snapshot)
	_update_reset_button_text()
	_save_settings_to_disk()


func _reset_calendar_settings() -> void:
	reset_undo_snapshot = _calendar_state_snapshot()
	reset_undo_available = true
	main_view_saved = false
	cycle_pending_apply = false
	day_tools_visible = true
	_set_option_selected(schedule_option, 0)
	_set_option_selected(range_option, 0)
	_set_option_selected(pause_option, 0)
	_set_spin_value(system_work_spin, 14)
	_set_spin_value(system_home_spin, 7)
	_set_spin_value(custom_length_spin, 21)

	start_input.text = ""
	manual_overrides.clear()
	notes.clear()
	work_start_unix = 0
	work_end_unix = 0
	work_status_label.text = "Tu później aplikacja policzy czas pracy."
	pause_result_label.text = ""

	weekly_rest_toggle.set_pressed_no_signal(true)
	weekly_rest_previous_pressed = true
	fixed_start_toggle.set_pressed_no_signal(false)
	fixed_start_previous_pressed = false
	_set_option_selected(fixed_start_option, 0)
	fixed_start_option.visible = false
	custom_panel.visible = false

	_reset_custom_pattern(21)
	calculator.configure_empty()
	error_label.visible = false
	error_label.text = ""
	_rebuild_calendar()
	_apply_main_view_mode(false)
	_apply_day_tools_visibility()
	_set_settings_visible(true)
	_update_reset_button_text()
	_save_settings_to_disk()


func _apply_settings(close_settings_after_save: bool = false, adopt_pending_cycle: bool = false) -> bool:
	var ok := true
	var fixed_start_weekday := _selected_fixed_start_weekday()

	if cycle_pending_apply and adopt_pending_cycle and _should_adopt_manual_cycle_from_overrides():
		_adopt_manual_cycle_from_overrides()

	if cycle_pending_apply and not adopt_pending_cycle:
		ok = calculator.configure_empty()
	elif schedule_option.selected == 0:
		ok = calculator.configure_empty()
	elif fixed_start_weekday == -2:
		ok = false
		calculator.last_error = "Wybierz dzień stałego rozpoczęcia pracy."
	elif _is_custom_schedule():
		ok = calculator.configure_custom(start_input.text, custom_pattern, fixed_start_weekday)
	else:
		ok = calculator.configure_preset(
			start_input.text,
			int(system_work_spin.value),
			int(system_home_spin.value),
			"days",
			weekly_rest_toggle.button_pressed,
			fixed_start_weekday
		)

	error_label.visible = not ok
	error_label.text = calculator.last_error

	if ok:
		if adopt_pending_cycle:
			cycle_pending_apply = false
		_rebuild_calendar()
		if close_settings_after_save:
			_set_settings_visible(false)

	return ok


func _rebuild_calendar() -> void:
	if months_box == null:
		return

	_refresh_today_day_index()

	for child in months_box.get_children():
		child.queue_free()

	var month_count := _range_months()
	var counts := _count_visible_months(current_year, current_month, month_count)

	if calculator.mode == "none":
		summary_label.text = "Uzupełnij swoje pierwsze dwa cykle pracy."
	else:
		var today_state := _visual_state_for_day(today_day_index, _date_key_from_day_index(today_day_index))
		var change_days := calculator.days_until_next_change(today_day_index)
		summary_label.text = "Okres: praca %d, dom %d, pauza 24h %d, urlop %d. Dzisiaj: %s. Zmiana za %d dni. System: %s." % [
			int(counts["work"]),
			int(counts["home"]),
			int(counts["rest"]),
			int(counts["vacation"]),
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
	section.add_theme_constant_override("separation", 16)

	var title := _make_label("%s %d" % [MONTH_NAMES[month - 1], year], 33 if _range_months() == 1 else 28, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(title)

	if year == current_year and month == current_month and _should_show_first_cycle_hint():
		var hint := _make_label("Kliknij swój pierwszy dzień i wyznacz swój cykl.", 25, COLOR_TODAY)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(hint)

		var cycle_hint := _make_label("Zacznij od pierwszego dnia cyklu swojej pracy i wypisz cały cykl wraz z dniami wolnymi. Wtedy kliknij Zastosuj.", 22, COLOR_TODAY)
		cycle_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cycle_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(cycle_hint)

	var grid := GridContainer.new()
	grid.columns = TILE_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	section.add_child(grid)

	var first_offset := ScheduleCalculator.month_start_weekday_monday(year, month)
	for _offset in range(first_offset):
		grid.add_child(_make_day_spacer())

	var days_current := ScheduleCalculator.days_in_month(year, month)
	for day in range(1, days_current + 1):
		var day_index := ScheduleCalculator.day_index_from_date(year, month, day)
		var key := _date_key(year, month, day)
		var state := _visual_state_for_day(day_index, key)
		grid.add_child(_make_day_cell(year, month, day, day_index, state, day_index == today_day_index))

	return section


func _make_day_cell(year: int, month: int, day: int, day_index: int, state: int, is_today: bool) -> Button:
	var key := _date_key(year, month, day)
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, _day_cell_height())
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	var is_vacation := state == ScheduleCalculator.DayState.VACATION
	button.add_theme_stylebox_override("normal", _tile_style(_state_color(state), is_today, is_vacation))
	button.add_theme_stylebox_override("hover", _tile_style(_state_color(state).lightened(0.08), is_today, is_vacation))
	button.add_theme_stylebox_override("pressed", _tile_style(_state_color(state).darkened(0.09), is_today, is_vacation))
	button.add_theme_stylebox_override("focus", _tile_style(_state_color(state), true, is_vacation))
	_fill_day_tile(button, day, day_index, state, notes.has(key), is_today)
	_connect_tap(button, Callable(self, "_open_day_actions").bind(year, month, day))
	return button


func _make_day_spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, _day_cell_height())
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _fill_day_tile(button: Button, day: int, day_index: int, state: int, has_note: bool, is_today: bool) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)

	var day_label := _tile_label(str(day), _tile_day_font_size(), COLOR_TEXT)
	box.add_child(day_label)

	var weekday_label := _tile_label(_weekday_short_for_day_index(day_index), _tile_weekday_font_size(), COLOR_TEXT_MUTED)
	box.add_child(weekday_label)

	var state_name := _state_short_name(state)
	if not state_name.is_empty():
		box.add_child(_tile_label(state_name, _tile_badge_font_size(), COLOR_TEXT))
	elif has_note:
		box.add_child(_tile_label("not.", _tile_badge_font_size(), COLOR_TEXT_MUTED))

	var accent := Panel.new()
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.anchor_left = 0.24
	accent.anchor_right = 0.76
	accent.anchor_top = 1.0
	accent.anchor_bottom = 1.0
	accent.offset_top = -7.0
	accent.offset_bottom = -3.0
	accent.add_theme_stylebox_override("panel", _accent_style(_tile_accent_color(state, has_note)))
	button.add_child(accent)

	if is_today:
		var today_ring := Panel.new()
		today_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		today_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
		today_ring.add_theme_stylebox_override("panel", _today_ring_style())
		button.add_child(today_ring)


func _tile_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _open_day_actions(year: int, month: int, day: int) -> void:
	selected_day_year = year
	selected_day_month = month
	selected_day_number = day
	selected_day_key = _date_key(year, month, day)
	selected_day_index = ScheduleCalculator.day_index_from_date(year, month, day)
	day_action_dialog.title = selected_day_key
	day_action_dialog.popup_centered()


func _set_selected_day_state(state: int) -> void:
	if _manual_cycle_setup_active():
		_stage_selected_day_state(state)
	elif state == ScheduleCalculator.DayState.VACATION:
		manual_overrides[selected_day_key] = state
		_rebuild_calendar()
	elif _is_preset_schedule():
		if state == ScheduleCalculator.DayState.WORK:
			start_input.text = selected_day_key
			manual_overrides.clear()
			manual_overrides[selected_day_key] = state
			cycle_pending_apply = true
			_rebuild_calendar()
		elif state == ScheduleCalculator.DayState.NONE:
			manual_overrides[selected_day_key] = state
			_rebuild_calendar()
		else:
			manual_overrides[selected_day_key] = state
			_rebuild_calendar()
	else:
		_ensure_custom_mode_for_selected_day()
		var offset := ScheduleCalculator.positive_mod(selected_day_index - calculator.start_day_index, custom_pattern.size())
		custom_pattern[offset] = state
		cycle_pending_apply = true
		_rebuild_calendar()

	day_action_dialog.hide()
	_save_settings_to_disk()


func _manual_cycle_setup_active() -> bool:
	return not main_view_saved and (schedule_option == null or schedule_option.selected == 0 or _is_custom_schedule())


func _should_adopt_manual_cycle_from_overrides() -> bool:
	return not manual_overrides.is_empty() and (schedule_option.selected == 0 or _is_custom_schedule())


func _stage_selected_day_state(state: int) -> void:
	if not _is_custom_schedule():
		_set_option_selected(schedule_option, schedule_option.get_item_count() - 1)
		custom_panel.visible = true

	if manual_overrides.is_empty() or start_input.text.strip_edges().is_empty():
		start_input.text = selected_day_key

	manual_overrides[selected_day_key] = state
	cycle_pending_apply = true
	calculator.configure_empty()
	_rebuild_calendar()


func _ensure_custom_mode_for_selected_day() -> void:
	if not _is_custom_schedule():
		_set_option_selected(schedule_option, schedule_option.get_item_count() - 1)
		custom_panel.visible = true

	if start_input.text.strip_edges().is_empty() or ScheduleCalculator.parse_date(start_input.text).is_empty():
		start_input.text = selected_day_key

	var fixed_start_weekday := _selected_fixed_start_weekday()
	if fixed_start_weekday == -2:
		fixed_start_weekday = -1
	calculator.configure_custom(start_input.text, custom_pattern, fixed_start_weekday)


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
	_save_settings_to_disk()


func _on_schedule_selected(index: int) -> void:
	if _option_change_was_scroll(schedule_option, index):
		return

	custom_panel.visible = _is_custom_schedule()
	if schedule_option.selected == 0:
		start_input.text = ""
		manual_overrides.clear()
		cycle_pending_apply = false
	elif not _is_custom_schedule():
		_apply_preset_to_spins(schedule_option.selected)
		cycle_pending_apply = true
	else:
		cycle_pending_apply = true
	_save_settings_to_disk()


func _on_range_selected(index: int) -> void:
	if _option_change_was_scroll(range_option, index):
		return

	_rebuild_calendar()
	_save_settings_to_disk()


func _on_pause_selected(index: int) -> void:
	if _option_change_was_scroll(pause_option, index):
		return

	_update_pause_result()
	_save_settings_to_disk()


func _on_weekly_rest_toggled(enabled: bool) -> void:
	if _tap_is_blocked():
		weekly_rest_toggle.set_pressed_no_signal(weekly_rest_previous_pressed)
		return

	weekly_rest_previous_pressed = enabled
	cycle_pending_apply = true
	_save_settings_to_disk()


func _on_fixed_start_toggled(enabled: bool) -> void:
	if _tap_is_blocked():
		fixed_start_toggle.set_pressed_no_signal(fixed_start_previous_pressed)
		if fixed_start_option != null:
			fixed_start_option.visible = fixed_start_previous_pressed
		return

	fixed_start_previous_pressed = enabled
	if fixed_start_option != null:
		fixed_start_option.visible = enabled
	cycle_pending_apply = true
	_save_settings_to_disk()


func _on_fixed_start_day_selected(index: int) -> void:
	if _option_change_was_scroll(fixed_start_option, index):
		return

	cycle_pending_apply = true
	_save_settings_to_disk()


func _on_custom_length_spin_changed(value: float) -> void:
	if _spin_change_was_scroll(custom_length_spin, value):
		return

	_on_custom_length_changed(value)


func _on_custom_length_changed(value: float) -> void:
	_resize_custom_pattern(int(value))
	cycle_pending_apply = true
	_save_settings_to_disk()


func _reset_custom_pattern(days: int) -> void:
	custom_pattern.clear()
	for _index in range(maxi(1, days)):
		custom_pattern.append(ScheduleCalculator.DayState.NONE)


func _resize_custom_pattern(days: int) -> void:
	var old_pattern := custom_pattern.duplicate()
	_reset_custom_pattern(days)
	for index in range(mini(old_pattern.size(), custom_pattern.size())):
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
		"rest": 0,
		"vacation": 0,
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
				ScheduleCalculator.DayState.REST:
					result["rest"] += 1
				ScheduleCalculator.DayState.VACATION:
					result["vacation"] += 1
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


func _should_show_first_cycle_hint() -> bool:
	return not main_view_saved and calculator.mode == "none" and manual_overrides.is_empty() and start_input.text.strip_edges().is_empty()


func _preset_for_index(index: int) -> Dictionary:
	match index:
		1:
			return {"work": 14, "home": 7}
		2:
			return {"work": 14, "home": 14}
		3:
			return {"work": 21, "home": 7}
		4:
			return {"work": 21, "home": 14}
		5:
			return {"work": 28, "home": 7}
		6:
			return {"work": 13, "home": 8}
	return {"work": 14, "home": 7}


func _apply_preset_to_spins(index: int) -> void:
	var preset := _preset_for_index(index)
	_set_spin_value(system_work_spin, int(preset["work"]))
	_set_spin_value(system_home_spin, int(preset["home"]))


func _is_preset_schedule() -> bool:
	return schedule_option != null and schedule_option.selected > 0 and not _is_custom_schedule()


func _is_custom_schedule() -> bool:
	return schedule_option != null and schedule_option.selected == schedule_option.get_item_count() - 1


func _selected_fixed_start_weekday() -> int:
	if fixed_start_toggle == null or not fixed_start_toggle.button_pressed:
		return -1
	if fixed_start_option == null or fixed_start_option.selected <= 0:
		return -2
	return fixed_start_option.selected - 1


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
			return 56
		3, 4:
			return 70
	return 84


func _tile_day_font_size() -> int:
	match _range_months():
		12:
			return 17
		3, 4:
			return 22
	return 26


func _tile_weekday_font_size() -> int:
	match _range_months():
		12:
			return 9
		3, 4:
			return 12
	return 14


func _tile_badge_font_size() -> int:
	match _range_months():
		12:
			return 8
		3, 4:
			return 10
	return 11


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
		ScheduleCalculator.DayState.REST:
			return "pauza 24h"
		ScheduleCalculator.DayState.VACATION:
			return "urlop"
	return "pusty dzień"


func _state_short_name(state: int) -> String:
	match state:
		ScheduleCalculator.DayState.WORK:
			return "Praca"
		ScheduleCalculator.DayState.HOME:
			return "Dom"
		ScheduleCalculator.DayState.REST:
			return "24h"
		ScheduleCalculator.DayState.VACATION:
			return "Urlop"
	return ""


func _state_color(state: int, in_month: bool = true) -> Color:
	if not in_month:
		return COLOR_TILE_EMPTY_OUTSIDE

	match state:
		ScheduleCalculator.DayState.WORK:
			return COLOR_WORK
		ScheduleCalculator.DayState.HOME:
			return COLOR_HOME
		ScheduleCalculator.DayState.REST:
			return COLOR_REST
		ScheduleCalculator.DayState.VACATION:
			return COLOR_VACATION
	return COLOR_TILE_EMPTY


func _weekday_short_for_day_index(day_index: int) -> String:
	return WEEKDAY_SHORT_TILE[ScheduleCalculator.weekday_monday_first(day_index)]


func _make_spin(min_value: int, max_value: int, value: int, auto_apply: bool = true) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.value = value
	_remember_spin_value(spin)
	if auto_apply:
		spin.value_changed.connect(func(changed_value: float) -> void:
			if _spin_change_was_scroll(spin, changed_value):
				return
			_mark_cycle_pending()
		)
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
	if font_size >= 20:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.35))
	return label


func _make_nav_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prepare_control(button, 22, 58)
	return button


func _action_button(text: String, accent: Color = COLOR_TILE_EMPTY) -> Button:
	var button := Button.new()
	button.text = text
	_prepare_control(button, 21, 66)
	button.add_theme_stylebox_override("normal", _control_style(_alpha(accent, 0.34)))
	button.add_theme_stylebox_override("hover", _control_style(_alpha(accent, 0.44)))
	button.add_theme_stylebox_override("pressed", _control_style(_alpha(accent, 0.26)))
	button.add_theme_stylebox_override("focus", _control_style(_alpha(accent, 0.40), true))
	return button


func _set_option_selected(option: OptionButton, index: int) -> void:
	option.selected = index
	option.set_meta("last_selected", index)


func _prepare_large_dropdown(option: OptionButton) -> void:
	var popup := option.get_popup()
	popup.min_size = Vector2i(300, 250)
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_constant_override("v_separation", 14)
	popup.add_theme_constant_override("item_start_padding", 18)
	popup.add_theme_constant_override("item_end_padding", 18)


func _option_change_was_scroll(option: OptionButton, index: int) -> bool:
	if not _tap_is_blocked():
		option.set_meta("last_selected", index)
		return false

	var previous := int(option.get_meta("last_selected", index))
	if previous < 0:
		previous = 0
	elif previous >= option.get_item_count():
		previous = option.get_item_count() - 1

	option.selected = previous
	return true


func _set_spin_value(spin: SpinBox, value: int) -> void:
	if spin == null:
		return

	spin.set_value_no_signal(float(value))
	spin.set_meta("last_value", float(value))


func _remember_spin_value(spin: SpinBox) -> void:
	spin.set_meta("last_value", spin.value)


func _spin_change_was_scroll(spin: SpinBox, value: float) -> bool:
	if not _tap_is_blocked():
		spin.set_meta("last_value", value)
		return false

	var previous := float(spin.get_meta("last_value", value))
	spin.set_value_no_signal(previous)
	return true


func _connect_tap(button: BaseButton, action: Callable) -> void:
	_register_scroll_safe_control(button)
	button.pressed.connect(func() -> void:
		if _tap_is_blocked():
			return
		action.call()
	)


func _register_scroll_safe_control(control: Control) -> void:
	if control.has_meta("scroll_safe_registered"):
		return

	control.set_meta("scroll_safe_registered", true)
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	control.gui_input.connect(_track_scroll_touch)

	if control is BaseButton:
		var button := control as BaseButton
		scroll_safe_buttons.append(button)
		button.focus_mode = Control.FOCUS_NONE
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE


func _tap_is_blocked() -> bool:
	if touch_drag_cancelled:
		return true

	var elapsed_msec := int(Time.get_ticks_msec()) - last_drag_release_msec
	return elapsed_msec >= 0 and elapsed_msec < TAP_BLOCK_AFTER_DRAG_MS


func _track_scroll_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_touch_tracking(touch.position)
		else:
			_end_touch_tracking()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_update_touch_tracking(drag.position)
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_begin_touch_tracking(mouse_button.position)
			else:
				_end_touch_tracking()
	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if mouse_motion.button_mask != 0:
			_update_touch_tracking(mouse_motion.position)


func _track_month_swipe(event: InputEvent) -> void:
	if not main_view_saved:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_month_swipe(touch.position)
		elif swipe_tracking_active:
			_finish_month_swipe(touch.position)
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_begin_month_swipe(mouse_button.position)
			elif swipe_tracking_active:
				_finish_month_swipe(mouse_button.position)


func _begin_month_swipe(position: Vector2) -> void:
	swipe_start_position = position
	swipe_tracking_active = true


func _finish_month_swipe(position: Vector2) -> void:
	var delta := position - swipe_start_position
	swipe_tracking_active = false
	if delta.length() < SWIPE_MIN_DISTANCE:
		return

	if absf(delta.x) >= absf(delta.y):
		if delta.x < 0.0:
			_on_next_month()
		else:
			_on_previous_month()
	else:
		if delta.y < 0.0:
			_on_next_month()
		else:
			_on_previous_month()


func _begin_touch_tracking(position: Vector2) -> void:
	touch_tracking_active = true
	touch_start_position = position
	touch_drag_cancelled = false


func _update_touch_tracking(position: Vector2) -> void:
	if not touch_tracking_active:
		return

	if not touch_drag_cancelled and touch_start_position.distance_to(position) > TAP_CANCEL_DISTANCE:
		touch_drag_cancelled = true
		_release_scroll_buttons()


func _end_touch_tracking() -> void:
	if touch_drag_cancelled:
		last_drag_release_msec = int(Time.get_ticks_msec())

	touch_tracking_active = false


func _release_scroll_buttons() -> void:
	for index in range(scroll_safe_buttons.size() - 1, -1, -1):
		var button := scroll_safe_buttons[index]
		if not is_instance_valid(button):
			scroll_safe_buttons.remove_at(index)
		elif not button.toggle_mode:
			button.set_pressed_no_signal(false)


func _prepare_control(control: Control, font_size: int, min_height: int) -> void:
	control.custom_minimum_size.y = min_height
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size", font_size)
	if control is Button or control is OptionButton or control is LineEdit or control is SpinBox:
		_register_scroll_safe_control(control)
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
	item.add_theme_constant_override("separation", 6)

	var swatch := Panel.new()
	swatch.custom_minimum_size = Vector2(18, 18)
	swatch.add_theme_stylebox_override("panel", _accent_style(color))
	item.add_child(swatch)

	item.add_child(_make_label(text, 16, COLOR_TEXT_MUTED))
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


func _tile_style(color: Color, is_today: bool, is_vacation: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(18)
	style.set_border_width_all(2 if is_today or is_vacation else 1)
	if is_today:
		style.border_color = COLOR_TODAY
	elif is_vacation:
		style.border_color = Color(0.92, 0.96, 1.0, 0.58)
	else:
		style.border_color = Color(1.0, 1.0, 1.0, 0.20)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 11
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 10
	style.content_margin_bottom = 8
	return style


func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 1.0, 1.0, 0.10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
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
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _accent_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 1.0, 1.0, 0.15)
	return style


func _today_ring_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_corner_radius_all(18)
	style.set_border_width_all(3)
	style.border_color = COLOR_TODAY
	style.shadow_color = Color(0.92, 0.72, 0.38, 0.32)
	style.shadow_size = 8
	style.shadow_offset = Vector2.ZERO
	return style


func _dialog_style() -> StyleBoxFlat:
	var style := _style(Color(0.18, 0.19, 0.18, 0.96), 10)
	style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _tile_accent_color(state: int, has_note: bool) -> Color:
	match state:
		ScheduleCalculator.DayState.WORK:
			return _alpha(COLOR_WORK.lightened(0.18), 0.88)
		ScheduleCalculator.DayState.HOME:
			return _alpha(COLOR_HOME.lightened(0.18), 0.88)
		ScheduleCalculator.DayState.REST:
			return _alpha(COLOR_REST.lightened(0.16), 0.88)
		ScheduleCalculator.DayState.VACATION:
			return _alpha(COLOR_VACATION.lightened(0.16), 0.88)
	if has_note:
		return _alpha(COLOR_NOTE, 0.80)
	return Color(1.0, 1.0, 1.0, 0.18)


func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


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


func _refresh_today_day_index() -> void:
	var now := Time.get_datetime_dict_from_system()
	today_day_index = ScheduleCalculator.day_index_from_date(int(now["year"]), int(now["month"]), int(now["day"]))


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
	_save_settings_to_disk()


func _on_end_work_pressed() -> void:
	if work_start_unix <= 0:
		work_status_label.text = "Najpierw kliknij rozpoczęcie pracy."
		return

	work_end_unix = int(Time.get_unix_time_from_system())
	var worked_seconds: int = maxi(0, work_end_unix - work_start_unix)
	work_status_label.text = "Praca trwała: %s. Koniec: %s" % [
		_format_duration(worked_seconds),
		_format_unix_time(work_end_unix),
	]
	_update_pause_result()
	_save_settings_to_disk()


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
	_save_settings_to_disk()


func _on_previous_year() -> void:
	current_year -= 1
	_rebuild_calendar()
	_save_settings_to_disk()


func _on_next_month() -> void:
	var next := _next_month(current_year, current_month)
	current_year = int(next["year"])
	current_month = int(next["month"])
	_rebuild_calendar()
	_save_settings_to_disk()


func _on_next_year() -> void:
	current_year += 1
	_rebuild_calendar()
	_save_settings_to_disk()


func _on_return_to_today_pressed() -> void:
	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	_refresh_today_day_index()
	_rebuild_calendar()
	if main_scroll != null:
		main_scroll.set_deferred("scroll_vertical", 0)
	_save_settings_to_disk()


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

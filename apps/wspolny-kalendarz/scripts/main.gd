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
const SETTINGS_PATH := "user://shared_calendar.cfg"
const PORTRAIT_WIDTH := 640
const TILE_COLUMNS := 7
const SCROLLBAR_TOUCH_WIDTH := 28
const PROFILE_BUTTON_TOP := 18
const PROFILE_BUTTON_WIDTH := 148
const PROFILE_BUTTON_HEIGHT := 50
const PROFILE_PANEL_WIDTH := 282
const PROFILE_PANEL_HEIGHT := 410

const COLOR_PANEL := Color(0.070, 0.085, 0.087, 0.82)
const COLOR_PANEL_SOFT := Color(0.105, 0.120, 0.116, 0.76)
const COLOR_TILE_EMPTY := Color(0.18, 0.22, 0.21, 0.86)
const COLOR_TEXT := Color(0.94, 0.955, 0.925)
const COLOR_TEXT_MUTED := Color(0.76, 0.80, 0.77)
const COLOR_TEXT_DIM := Color(0.54, 0.58, 0.55)
const COLOR_TODAY := Color(0.92, 0.72, 0.38)
const COLOR_DRIVER_WORK := Color(0.58, 0.27, 0.30, 0.88)
const COLOR_DRIVER_HOME := Color(0.28, 0.50, 0.37, 0.88)
const COLOR_DRIVER_REST := Color(0.60, 0.49, 0.27, 0.88)

const CATEGORY_COLOR_NAMES := [
	"Czerwony",
	"Zielony",
	"Złoty",
	"Niebieski",
	"Fioletowy",
	"Szary",
]
const CATEGORY_COLOR_VALUES := [
	Color(0.58, 0.27, 0.30, 0.88),
	Color(0.28, 0.50, 0.37, 0.88),
	Color(0.60, 0.49, 0.27, 0.88),
	Color(0.34, 0.46, 0.58, 0.88),
	Color(0.46, 0.35, 0.58, 0.88),
	Color(0.42, 0.46, 0.45, 0.88),
]

var current_year: int
var current_month: int
var selected_calendar_index := 0
var calendars: Array[Dictionary] = []
var driver_calculator := ScheduleCalculator.new()

var main_scroll: ScrollContainer
var content_root: VBoxContainer
var calendar_root: VBoxContainer
var months_box: VBoxContainer
var month_title_label: Label
var calendar_name_label: Label
var profile_overlay: VBoxContainer
var profile_button: Button
var profile_panel: PanelContainer
var calendar_option: OptionButton
var calendar_status_label: Label
var category_option: OptionButton
var category_name_input: LineEdit
var category_color_option: OptionButton
var category_delete_button: Button
var share_code_label: Label
var join_code_input: LineEdit
var share_status_label: Label
var driver_enabled_toggle: CheckButton
var driver_preset_option: OptionButton
var driver_start_input: LineEdit
var driver_work_spin: SpinBox
var driver_home_spin: SpinBox
var driver_rest_toggle: CheckButton
var driver_status_label: Label

var day_dialog: AcceptDialog
var day_dialog_title: Label
var day_category_option: OptionButton
var day_add_marker_button: Button
var day_event_list_label: Label
var day_note_edit: TextEdit
var day_save_note_button: Button
var day_clear_button: Button

var selected_day_key := ""
var selected_day_year := 0
var selected_day_month := 0
var selected_day_number := 0


func _ready() -> void:
	randomize()
	_force_portrait()

	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])

	_build_ui()
	_load_settings_from_disk()
	_refresh_all()


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

	var screen_root := VBoxContainer.new()
	screen_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_root.add_theme_constant_override("separation", 12)
	screen_root.resized.connect(_sync_content_width)
	safe_margin.add_child(screen_root)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 8)
	screen_root.add_child(header)

	calendar_name_label = _make_label("Wspólny Kalendarz", 30, COLOR_TEXT)
	calendar_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calendar_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(calendar_name_label)

	var today_button := Button.new()
	today_button.text = "Dzisiaj"
	_prepare_control(today_button, 16, 50)
	today_button.custom_minimum_size.x = 120
	today_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_connect_tap(today_button, Callable(self, "_return_to_today"))
	header.add_child(today_button)

	_add_profile_overlay()

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	screen_root.add_child(nav)

	var previous_button := _make_nav_button("<")
	_connect_tap(previous_button, Callable(self, "_previous_month"))
	nav.add_child(previous_button)

	month_title_label = _make_label("", 32, COLOR_TEXT)
	month_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	month_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(month_title_label)

	var next_button := _make_nav_button(">")
	_connect_tap(next_button, Callable(self, "_next_month"))
	nav.add_child(next_button)

	main_scroll = ScrollContainer.new()
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.resized.connect(_sync_content_width)
	screen_root.add_child(main_scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.add_child(center)

	content_root = VBoxContainer.new()
	content_root.custom_minimum_size = Vector2(PORTRAIT_WIDTH, 0)
	content_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_root.add_theme_constant_override("separation", 18)
	center.add_child(content_root)

	calendar_root = VBoxContainer.new()
	calendar_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calendar_root.add_theme_constant_override("separation", 14)
	content_root.add_child(calendar_root)

	months_box = VBoxContainer.new()
	months_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calendar_root.add_child(months_box)

	content_root.add_child(_build_categories_panel())
	content_root.add_child(_build_driver_panel())
	content_root.add_child(_build_sharing_panel())
	_style_main_scrollbar()
	_build_day_dialog()
	_sync_content_width()


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
	profile_overlay.z_index = 30
	profile_overlay.add_theme_constant_override("separation", 7)
	add_child(profile_overlay)

	profile_button = Button.new()
	profile_button.text = "Profile"
	_prepare_control(profile_button, 16, PROFILE_BUTTON_HEIGHT)
	profile_button.custom_minimum_size.x = PROFILE_BUTTON_WIDTH
	profile_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_connect_tap(profile_button, Callable(self, "_toggle_profile_panel"))
	profile_overlay.add_child(profile_button)

	profile_panel = _build_profile_panel()
	profile_overlay.add_child(profile_panel)
	_set_profile_panel_visible(false)


func _build_profile_panel() -> PanelContainer:
	var panel := _panel()
	panel.custom_minimum_size.x = PROFILE_PANEL_WIDTH
	var box := _panel_box(panel, 10)

	box.add_child(_make_section_label("Kalendarze"))

	calendar_option = OptionButton.new()
	calendar_option.item_selected.connect(_on_calendar_selected)
	_prepare_control(calendar_option, 16, 48)
	_prepare_large_dropdown(calendar_option)
	box.add_child(calendar_option)

	var new_private_button := Button.new()
	new_private_button.text = "Nowy prywatny"
	_prepare_control(new_private_button, 16, 46)
	_connect_tap(new_private_button, Callable(self, "_create_private_calendar"))
	box.add_child(new_private_button)

	var new_group_button := Button.new()
	new_group_button.text = "Nowy grupowy"
	_prepare_control(new_group_button, 16, 46)
	_connect_tap(new_group_button, Callable(self, "_create_group_calendar"))
	box.add_child(new_group_button)

	var rename_button := Button.new()
	rename_button.text = "Zmień nazwę"
	_prepare_control(rename_button, 16, 46)
	_connect_tap(rename_button, Callable(self, "_rename_selected_calendar"))
	box.add_child(rename_button)

	var delete_button := Button.new()
	delete_button.text = "Usuń kalendarz"
	_prepare_control(delete_button, 16, 46)
	_connect_tap(delete_button, Callable(self, "_delete_selected_calendar"))
	box.add_child(delete_button)

	calendar_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	calendar_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(calendar_status_label)

	return panel


func _build_categories_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)
	box.add_child(_make_section_label("Twoje oznaczenia"))

	category_option = OptionButton.new()
	_prepare_control(category_option, 18, 54)
	_prepare_large_dropdown(category_option)
	box.add_child(category_option)

	category_name_input = LineEdit.new()
	category_name_input.placeholder_text = "Nazwa nowej opcji, np. lekarz, trening, urlop"
	_prepare_control(category_name_input, 18, 54)
	box.add_child(category_name_input)

	category_color_option = OptionButton.new()
	for color_name in CATEGORY_COLOR_NAMES:
		category_color_option.add_item(color_name)
	category_color_option.select(0)
	_prepare_control(category_color_option, 18, 54)
	box.add_child(category_color_option)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	var add_button := Button.new()
	add_button.text = "Dodaj opcję"
	_prepare_control(add_button, 18, 54)
	_connect_tap(add_button, Callable(self, "_add_category"))
	buttons.add_child(add_button)

	category_delete_button = Button.new()
	category_delete_button.text = "Usuń opcję"
	_prepare_control(category_delete_button, 18, 54)
	_connect_tap(category_delete_button, Callable(self, "_delete_category"))
	buttons.add_child(category_delete_button)

	return panel


func _build_driver_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)
	box.add_child(_make_section_label("System kierowcy"))

	driver_enabled_toggle = CheckButton.new()
	driver_enabled_toggle.text = "Użyj automatycznego grafiku kierowcy"
	driver_enabled_toggle.toggled.connect(_on_driver_enabled_toggled)
	_prepare_control(driver_enabled_toggle, 18, 56)
	box.add_child(driver_enabled_toggle)

	driver_preset_option = OptionButton.new()
	driver_preset_option.add_item("Własny")
	driver_preset_option.add_item("2 na 1")
	driver_preset_option.add_item("2 na 2")
	driver_preset_option.add_item("3 na 1")
	driver_preset_option.add_item("3 na 2")
	driver_preset_option.add_item("4 na 1")
	driver_preset_option.add_item("6 dni + 24h + 6 dni")
	driver_preset_option.item_selected.connect(_on_driver_preset_selected)
	_prepare_control(driver_preset_option, 18, 54)
	_prepare_large_dropdown(driver_preset_option)
	box.add_child(driver_preset_option)

	driver_start_input = LineEdit.new()
	driver_start_input.placeholder_text = "Pierwszy dzień cyklu, np. 2026-09-14"
	_prepare_control(driver_start_input, 18, 54)
	box.add_child(driver_start_input)

	var cycle_grid := GridContainer.new()
	cycle_grid.columns = 2
	cycle_grid.add_theme_constant_override("h_separation", 8)
	cycle_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(cycle_grid)

	driver_work_spin = _make_spin(1, 90, 14)
	cycle_grid.add_child(_field_stack("Dni pracy", driver_work_spin))

	driver_home_spin = _make_spin(1, 90, 7)
	cycle_grid.add_child(_field_stack("Dni domu", driver_home_spin))

	driver_rest_toggle = CheckButton.new()
	driver_rest_toggle.text = "Pauza 24h co 6 dni pracy"
	driver_rest_toggle.button_pressed = true
	_prepare_control(driver_rest_toggle, 18, 56)
	box.add_child(driver_rest_toggle)

	var apply_button := Button.new()
	apply_button.text = "Zastosuj system"
	_prepare_control(apply_button, 18, 56)
	_connect_tap(apply_button, Callable(self, "_apply_driver_settings_from_ui"))
	box.add_child(apply_button)

	driver_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	driver_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(driver_status_label)

	return panel


func _build_sharing_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)
	box.add_child(_make_section_label("Udostępnianie"))

	share_code_label = _make_label("", 18, COLOR_TEXT)
	share_code_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(share_code_label)

	var generate_button := Button.new()
	generate_button.text = "Generuj kod/link"
	_prepare_control(generate_button, 18, 54)
	_connect_tap(generate_button, Callable(self, "_generate_share_code"))
	box.add_child(generate_button)

	join_code_input = LineEdit.new()
	join_code_input.placeholder_text = "Wklej kod wspólnego kalendarza"
	_prepare_control(join_code_input, 18, 54)
	box.add_child(join_code_input)

	var join_button := Button.new()
	join_button.text = "Dołącz do kalendarza"
	_prepare_control(join_button, 18, 54)
	_connect_tap(join_button, Callable(self, "_join_calendar_by_code"))
	box.add_child(join_button)

	share_status_label = _make_label("Na razie kod przygotowuje kalendarz grupowy lokalnie. Synchronizacja online będzie kolejnym krokiem.", 14, COLOR_TEXT_MUTED)
	share_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(share_status_label)

	return panel


func _build_day_dialog() -> void:
	day_dialog = AcceptDialog.new()
	day_dialog.title = "Dzień"
	day_dialog.min_size = Vector2i(620, 680)
	add_child(day_dialog)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	day_dialog.add_child(box)

	day_dialog_title = _make_label("", 24, COLOR_TEXT)
	day_dialog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(day_dialog_title)

	day_category_option = OptionButton.new()
	_prepare_control(day_category_option, 18, 52)
	_prepare_large_dropdown(day_category_option)
	box.add_child(day_category_option)

	day_add_marker_button = Button.new()
	day_add_marker_button.text = "Dodaj do dnia"
	_prepare_control(day_add_marker_button, 18, 52)
	_connect_tap(day_add_marker_button, Callable(self, "_add_marker_to_selected_day"))
	box.add_child(day_add_marker_button)

	day_event_list_label = _make_label("", 16, COLOR_TEXT_MUTED)
	day_event_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(day_event_list_label)

	day_note_edit = TextEdit.new()
	day_note_edit.custom_minimum_size.y = 160
	day_note_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_note_edit.add_theme_font_size_override("font_size", 17)
	day_note_edit.add_theme_color_override("font_color", COLOR_TEXT)
	day_note_edit.add_theme_color_override("font_placeholder_color", COLOR_TEXT_DIM)
	day_note_edit.add_theme_stylebox_override("normal", _control_style(Color(0.90, 0.94, 0.90, 0.10)))
	box.add_child(day_note_edit)

	day_save_note_button = Button.new()
	day_save_note_button.text = "Zapisz notatkę"
	_prepare_control(day_save_note_button, 18, 52)
	_connect_tap(day_save_note_button, Callable(self, "_save_selected_day_note"))
	box.add_child(day_save_note_button)

	day_clear_button = Button.new()
	day_clear_button.text = "Wyczyść dzień"
	_prepare_control(day_clear_button, 18, 52)
	_connect_tap(day_clear_button, Callable(self, "_clear_selected_day"))
	box.add_child(day_clear_button)


func _refresh_all() -> void:
	_ensure_calendar_exists()
	selected_calendar_index = clampi(selected_calendar_index, 0, calendars.size() - 1)
	_refresh_profile_ui()
	_refresh_category_ui()
	_refresh_driver_ui()
	_configure_driver_calculator()
	_refresh_month_title()
	_rebuild_calendar()
	_refresh_sharing_ui()


func _refresh_month_title() -> void:
	if month_title_label != null:
		month_title_label.text = "%s %d" % [MONTH_NAMES[current_month - 1], current_year]
	if calendar_name_label != null:
		var calendar := _selected_calendar()
		calendar_name_label.text = String(calendar.get("name", "Wspólny Kalendarz"))


func _rebuild_calendar() -> void:
	if months_box == null:
		return

	for child in months_box.get_children():
		child.queue_free()

	months_box.add_child(_make_month_section(current_year, current_month))


func _make_month_section(year: int, month: int) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 14)

	var grid := GridContainer.new()
	grid.columns = TILE_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	section.add_child(grid)

	var first_offset := _month_start_weekday_monday(year, month)
	for _offset in range(first_offset):
		grid.add_child(_make_day_spacer())

	var days_current := _days_in_month(year, month)
	for day in range(1, days_current + 1):
		grid.add_child(_make_day_cell(year, month, day))

	return section


func _make_day_cell(year: int, month: int, day: int) -> Button:
	var key := _date_key(year, month, day)
	var event_ids := _event_ids_for_day(key)
	var has_note := _notes().has(key) and String(_notes()[key]).strip_edges() != ""
	var driver_state := _driver_state_for_date(year, month, day)
	var is_today := _is_today(year, month, day)
	var color := _color_for_day(event_ids, driver_state)

	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, 84)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _tile_style(color, is_today, not event_ids.is_empty() or has_note))
	button.add_theme_stylebox_override("hover", _tile_style(color.lightened(0.06), is_today, true))
	button.add_theme_stylebox_override("pressed", _tile_style(color.darkened(0.08), is_today, true))
	button.add_theme_stylebox_override("focus", _tile_style(color, true, true))
	_fill_day_tile(button, year, month, day, event_ids, has_note, driver_state)
	_connect_tap(button, Callable(self, "_open_day_dialog").bind(year, month, day))
	return button


func _make_day_spacer() -> Control:
	var spacer := Panel.new()
	spacer.custom_minimum_size = Vector2(0, 84)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.add_theme_stylebox_override("panel", _tile_style(Color(0.90, 0.93, 0.88, 0.05), false, false))
	return spacer


func _fill_day_tile(button: Button, year: int, month: int, day: int, event_ids: Array, has_note: bool, driver_state: int) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 6)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	var day_label := _tile_label(str(day), 26, COLOR_TEXT)
	box.add_child(day_label)

	var weekday_label := _tile_label(WEEKDAY_SHORT_TILE[_weekday_monday_index(year, month, day)], 13, COLOR_TEXT_MUTED)
	box.add_child(weekday_label)

	var marker_text := _marker_text(event_ids, has_note, driver_state)
	if marker_text != "":
		box.add_child(_tile_label(marker_text, 10, COLOR_TEXT))


func _marker_text(event_ids: Array, has_note: bool, driver_state: int) -> String:
	var parts: Array[String] = []
	var driver_label := _driver_short_label(driver_state)
	if driver_label != "":
		parts.append(driver_label)
	for event_id in event_ids:
		var category := _category_by_id(String(event_id))
		if category.is_empty():
			continue
		parts.append(String(category.get("name", "")))
	if has_note:
		parts.append("notatka")
	if parts.is_empty():
		return ""
	return ", ".join(parts).left(18)


func _open_day_dialog(year: int, month: int, day: int) -> void:
	selected_day_year = year
	selected_day_month = month
	selected_day_number = day
	selected_day_key = _date_key(year, month, day)
	_refresh_day_dialog()
	day_dialog.popup_centered(Vector2i(620, 680))


func _refresh_day_dialog() -> void:
	if day_dialog_title == null:
		return

	day_dialog_title.text = "%04d-%02d-%02d" % [selected_day_year, selected_day_month, selected_day_number]
	_refresh_day_category_option()
	day_note_edit.text = String(_notes().get(selected_day_key, ""))
	_refresh_day_event_list()


func _refresh_day_category_option() -> void:
	if day_category_option == null:
		return

	day_category_option.clear()
	var categories := _categories()
	for category in categories:
		day_category_option.add_item(String(category.get("name", "")))
	if categories.is_empty():
		day_category_option.add_item("Najpierw dodaj opcję")
		day_add_marker_button.disabled = true
	else:
		day_category_option.select(0)
		day_add_marker_button.disabled = false


func _refresh_day_event_list() -> void:
	var event_ids := _event_ids_for_day(selected_day_key)
	var names: Array[String] = []
	var driver_label := _driver_short_label(_driver_state_for_date(selected_day_year, selected_day_month, selected_day_number))
	if driver_label != "":
		names.append("system: %s" % driver_label)
	for event_id in event_ids:
		var category := _category_by_id(String(event_id))
		if not category.is_empty():
			names.append(String(category.get("name", "")))
	if names.is_empty():
		day_event_list_label.text = "Ten dzień nie ma jeszcze oznaczeń."
	else:
		day_event_list_label.text = "Oznaczenia: %s" % ", ".join(names)


func _add_marker_to_selected_day() -> void:
	var categories := _categories()
	if categories.is_empty() or selected_day_key == "":
		return

	var index := clampi(day_category_option.selected, 0, categories.size() - 1)
	var category := categories[index]
	var category_id := String(category.get("id", ""))
	if category_id == "":
		return

	var events := _events()
	var event_ids: Array = []
	if events.has(selected_day_key) and events[selected_day_key] is Array:
		event_ids = events[selected_day_key]
	if not event_ids.has(category_id):
		event_ids.append(category_id)
	events[selected_day_key] = event_ids
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()


func _save_selected_day_note() -> void:
	if selected_day_key == "":
		return

	var text := day_note_edit.text.strip_edges()
	if text == "":
		_notes().erase(selected_day_key)
	else:
		_notes()[selected_day_key] = text
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()


func _clear_selected_day() -> void:
	if selected_day_key == "":
		return

	_events().erase(selected_day_key)
	_notes().erase(selected_day_key)
	day_note_edit.text = ""
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()


func _add_category() -> void:
	var name := category_name_input.text.strip_edges()
	if name == "":
		return

	var categories := _categories()
	categories.append({
		"id": _new_id("cat"),
		"name": name,
		"color": clampi(category_color_option.selected, 0, CATEGORY_COLOR_VALUES.size() - 1),
	})
	category_name_input.text = ""
	_save_settings_to_disk()
	_refresh_category_ui()
	_rebuild_calendar()


func _delete_category() -> void:
	var categories := _categories()
	if categories.is_empty():
		return

	var index := clampi(category_option.selected, 0, categories.size() - 1)
	var category_id := String(categories[index].get("id", ""))
	categories.remove_at(index)
	_remove_category_from_events(category_id)
	_save_settings_to_disk()
	_refresh_category_ui()
	_rebuild_calendar()
	if day_dialog != null and day_dialog.visible:
		_refresh_day_dialog()


func _remove_category_from_events(category_id: String) -> void:
	if category_id == "":
		return

	var events := _events()
	for key in events.keys():
		if not (events[key] is Array):
			continue
		var clean: Array = []
		for event_id in events[key]:
			if String(event_id) != category_id:
				clean.append(event_id)
		if clean.is_empty():
			events.erase(key)
		else:
			events[key] = clean


func _refresh_category_ui() -> void:
	if category_option == null:
		return

	category_option.clear()
	var categories := _categories()
	for category in categories:
		category_option.add_item(String(category.get("name", "")))
	if categories.is_empty():
		category_option.add_item("Brak opcji - dodaj pierwszą")
		category_delete_button.disabled = true
	else:
		category_option.select(0)
		category_delete_button.disabled = false

	if day_dialog != null and day_dialog.visible:
		_refresh_day_category_option()


func _refresh_driver_ui() -> void:
	if driver_enabled_toggle == null:
		return

	var driver := _driver_settings()
	driver_enabled_toggle.set_pressed_no_signal(bool(driver.get("enabled", false)))
	driver_preset_option.select(clampi(int(driver.get("preset", 0)), 0, driver_preset_option.get_item_count() - 1))
	driver_start_input.text = String(driver.get("start_date", ""))
	driver_work_spin.set_value_no_signal(float(driver.get("work_days", 14)))
	driver_home_spin.set_value_no_signal(float(driver.get("home_days", 7)))
	driver_rest_toggle.set_pressed_no_signal(bool(driver.get("weekly_rest", true)))

	if driver_status_label != null:
		driver_status_label.text = "Wyłączony. Włącz, jeśli ten kalendarz ma automatycznie oznaczać system pracy."


func _on_driver_enabled_toggled(enabled: bool) -> void:
	_driver_settings()["enabled"] = enabled
	_apply_driver_settings_from_ui()


func _on_driver_preset_selected(index: int) -> void:
	match index:
		1:
			_set_driver_cycle_values(14, 7, true)
		2:
			_set_driver_cycle_values(14, 14, true)
		3:
			_set_driver_cycle_values(21, 7, true)
		4:
			_set_driver_cycle_values(21, 14, true)
		5:
			_set_driver_cycle_values(28, 7, true)
		6:
			_set_driver_cycle_values(12, 8, true)
		_:
			pass


func _set_driver_cycle_values(work_days: int, home_days: int, weekly_rest: bool) -> void:
	driver_work_spin.set_value_no_signal(work_days)
	driver_home_spin.set_value_no_signal(home_days)
	driver_rest_toggle.set_pressed_no_signal(weekly_rest)


func _apply_driver_settings_from_ui() -> void:
	if driver_enabled_toggle == null:
		return

	var driver := _driver_settings()
	driver["enabled"] = driver_enabled_toggle.button_pressed
	driver["preset"] = driver_preset_option.selected
	driver["start_date"] = driver_start_input.text.strip_edges()
	driver["work_days"] = int(driver_work_spin.value)
	driver["home_days"] = int(driver_home_spin.value)
	driver["weekly_rest"] = driver_rest_toggle.button_pressed

	_save_settings_to_disk()
	_configure_driver_calculator()
	_refresh_profile_ui()
	_refresh_month_title()
	_rebuild_calendar()


func _configure_driver_calculator() -> void:
	var driver := _driver_settings()
	if not bool(driver.get("enabled", false)):
		driver_calculator.configure_empty()
		if driver_status_label != null:
			driver_status_label.text = "Wyłączony. Włącz, jeśli ten kalendarz ma automatycznie oznaczać system pracy."
		return

	var ok := driver_calculator.configure_preset(
		String(driver.get("start_date", "")),
		int(driver.get("work_days", 14)),
		int(driver.get("home_days", 7)),
		"days",
		bool(driver.get("weekly_rest", true))
	)
	if driver_status_label == null:
		return
	if ok:
		driver_status_label.text = "Aktywny: %s" % driver_calculator.cycle_label()
	else:
		driver_status_label.text = driver_calculator.last_error


func _driver_state_for_date(year: int, month: int, day: int) -> int:
	if driver_calculator.mode == "none":
		return ScheduleCalculator.DayState.NONE
	return driver_calculator.get_state_for_day(ScheduleCalculator.day_index_from_date(year, month, day))


func _driver_short_label(state: int) -> String:
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


func _driver_state_color(state: int) -> Color:
	match state:
		ScheduleCalculator.DayState.WORK:
			return COLOR_DRIVER_WORK
		ScheduleCalculator.DayState.HOME:
			return COLOR_DRIVER_HOME
		ScheduleCalculator.DayState.REST:
			return COLOR_DRIVER_REST
	return COLOR_TILE_EMPTY


func _refresh_profile_ui() -> void:
	if calendar_option == null:
		return

	calendar_option.clear()
	for calendar in calendars:
		var kind := "grupowy" if String(calendar.get("kind", "private")) == "group" else "prywatny"
		calendar_option.add_item("%s (%s)" % [String(calendar.get("name", "Kalendarz")), kind])
	calendar_option.select(selected_calendar_index)

	var calendar := _selected_calendar()
	var share_code := String(calendar.get("share_code", ""))
	var kind_label := "grupowy" if String(calendar.get("kind", "private")) == "group" else "prywatny"
	if share_code == "":
		calendar_status_label.text = "Wybrany: %s. Kod udostępniania nie jest jeszcze wygenerowany." % kind_label
	else:
		calendar_status_label.text = "Wybrany: %s. Kod: %s" % [kind_label, share_code]


func _refresh_sharing_ui() -> void:
	if share_code_label == null:
		return

	var calendar := _selected_calendar()
	var share_code := String(calendar.get("share_code", ""))
	var kind_label := "grupowy" if String(calendar.get("kind", "private")) == "group" else "prywatny"
	if share_code == "":
		share_code_label.text = "Kalendarz %s: %s\nKod/link nie został wygenerowany." % [
			kind_label,
			String(calendar.get("name", "Kalendarz")),
		]
	else:
		share_code_label.text = "Kalendarz %s: %s\nKod: %s" % [
			kind_label,
			String(calendar.get("name", "Kalendarz")),
			share_code,
		]


func _on_calendar_selected(index: int) -> void:
	selected_calendar_index = clampi(index, 0, calendars.size() - 1)
	_set_profile_panel_visible(false)
	_save_settings_to_disk()
	_refresh_all()


func _create_private_calendar() -> void:
	_create_calendar("private")


func _create_group_calendar() -> void:
	_create_calendar("group")


func _create_calendar(kind: String) -> void:
	var base_name := "Grupowy" if kind == "group" else "Prywatny"
	calendars.append(_make_calendar("%s %d" % [base_name, calendars.size() + 1], kind))
	selected_calendar_index = calendars.size() - 1
	_save_settings_to_disk()
	_refresh_all()


func _rename_selected_calendar() -> void:
	var calendar := _selected_calendar()
	var name := String(calendar.get("name", "Kalendarz"))
	var suffix := " *" if not name.ends_with(" *") else ""
	calendar["name"] = name + suffix
	_save_settings_to_disk()
	_refresh_all()


func _delete_selected_calendar() -> void:
	if calendars.size() <= 1:
		return

	calendars.remove_at(selected_calendar_index)
	selected_calendar_index = clampi(selected_calendar_index, 0, calendars.size() - 1)
	_save_settings_to_disk()
	_refresh_all()


func _generate_share_code() -> void:
	var calendar := _selected_calendar()
	calendar["kind"] = "group"
	calendar["share_code"] = _new_share_code()
	share_status_label.text = "Wygenerowano kod. W tej wersji to lokalny identyfikator pod przyszłą synchronizację."
	_save_settings_to_disk()
	_refresh_profile_ui()
	_refresh_sharing_ui()


func _join_calendar_by_code() -> void:
	var code := join_code_input.text.strip_edges()
	if code == "":
		return

	for index in range(calendars.size()):
		if String(calendars[index].get("share_code", "")) == code:
			selected_calendar_index = index
			join_code_input.text = ""
			share_status_label.text = "Ten kalendarz już jest na liście."
			_save_settings_to_disk()
			_refresh_all()
			return

	calendars.append({
		"id": _new_id("calendar"),
		"name": "Grupowy %s" % code.substr(maxi(0, code.length() - 4)),
		"kind": "group",
		"share_code": code,
		"categories": [],
		"events": {},
		"notes": {},
		"driver": _default_driver_settings(),
	})
	selected_calendar_index = calendars.size() - 1
	join_code_input.text = ""
	share_status_label.text = "Dodano kalendarz grupowy z kodu. Synchronizacja online będzie kolejnym krokiem."
	_save_settings_to_disk()
	_refresh_all()


func _previous_month() -> void:
	current_month -= 1
	if current_month < 1:
		current_month = 12
		current_year -= 1
	_refresh_month_title()
	_rebuild_calendar()
	_save_settings_to_disk()


func _next_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	_refresh_month_title()
	_rebuild_calendar()
	_save_settings_to_disk()


func _return_to_today() -> void:
	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	_refresh_month_title()
	_rebuild_calendar()
	if main_scroll != null:
		main_scroll.set_deferred("scroll_vertical", 0)
	_save_settings_to_disk()


func _ensure_calendar_exists() -> void:
	if calendars.is_empty():
		calendars.append(_make_calendar("Prywatny", "private"))


func _make_calendar(name: String, kind: String) -> Dictionary:
	return {
		"id": _new_id("calendar"),
		"name": name,
		"kind": kind,
		"share_code": "",
		"categories": [],
		"events": {},
		"notes": {},
		"driver": _default_driver_settings(),
	}


func _selected_calendar() -> Dictionary:
	_ensure_calendar_exists()
	selected_calendar_index = clampi(selected_calendar_index, 0, calendars.size() - 1)
	return calendars[selected_calendar_index]


func _categories() -> Array:
	var calendar := _selected_calendar()
	if not calendar.has("categories") or not (calendar["categories"] is Array):
		calendar["categories"] = []
	return calendar["categories"]


func _events() -> Dictionary:
	var calendar := _selected_calendar()
	if not calendar.has("events") or not (calendar["events"] is Dictionary):
		calendar["events"] = {}
	return calendar["events"]


func _notes() -> Dictionary:
	var calendar := _selected_calendar()
	if not calendar.has("notes") or not (calendar["notes"] is Dictionary):
		calendar["notes"] = {}
	return calendar["notes"]


func _driver_settings() -> Dictionary:
	var calendar := _selected_calendar()
	if not calendar.has("driver") or not (calendar["driver"] is Dictionary):
		calendar["driver"] = _default_driver_settings()
	var driver: Dictionary = calendar["driver"]
	var defaults := _default_driver_settings()
	for key in defaults.keys():
		if not driver.has(key):
			driver[key] = defaults[key]
	return driver


func _default_driver_settings() -> Dictionary:
	return {
		"enabled": false,
		"preset": 0,
		"start_date": "",
		"work_days": 14,
		"home_days": 7,
		"weekly_rest": true,
	}


func _event_ids_for_day(key: String) -> Array:
	var events := _events()
	if not events.has(key) or not (events[key] is Array):
		return []
	return events[key]


func _category_by_id(category_id: String) -> Dictionary:
	for category in _categories():
		if String(category.get("id", "")) == category_id:
			return category
	return {}


func _color_for_day(event_ids: Array, driver_state: int) -> Color:
	if not event_ids.is_empty():
		var category := _category_by_id(String(event_ids[0]))
		if not category.is_empty():
			return _category_color(int(category.get("color", 0)))

	return _driver_state_color(driver_state)


func _category_color(index: int) -> Color:
	return CATEGORY_COLOR_VALUES[clampi(index, 0, CATEGORY_COLOR_VALUES.size() - 1)]


func _save_settings_to_disk() -> void:
	var config := ConfigFile.new()
	config.set_value("ui", "selected_calendar_index", selected_calendar_index)
	config.set_value("ui", "current_year", current_year)
	config.set_value("ui", "current_month", current_month)
	config.set_value("data", "calendars", calendars.duplicate(true))

	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Nie udało się zapisać kalendarza: %d" % error)


func _load_settings_from_disk() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_ensure_calendar_exists()
		return

	selected_calendar_index = int(config.get_value("ui", "selected_calendar_index", 0))
	current_year = int(config.get_value("ui", "current_year", current_year))
	current_month = clampi(int(config.get_value("ui", "current_month", current_month)), 1, 12)

	calendars.clear()
	var loaded: Variant = config.get_value("data", "calendars", [])
	if loaded is Array:
		for item in loaded:
			if item is Dictionary:
				calendars.append(_sanitize_calendar(item))
	_ensure_calendar_exists()


func _sanitize_calendar(value: Dictionary) -> Dictionary:
	var calendar := value.duplicate(true)
	if not calendar.has("id") or String(calendar["id"]) == "":
		calendar["id"] = _new_id("calendar")
	if not calendar.has("name") or String(calendar["name"]) == "":
		calendar["name"] = "Kalendarz"
	if not calendar.has("kind"):
		calendar["kind"] = "private"
	if not calendar.has("share_code"):
		calendar["share_code"] = ""
	if not calendar.has("categories") or not (calendar["categories"] is Array):
		calendar["categories"] = []
	if not calendar.has("events") or not (calendar["events"] is Dictionary):
		calendar["events"] = {}
	if not calendar.has("notes") or not (calendar["notes"] is Dictionary):
		calendar["notes"] = {}
	if not calendar.has("driver") or not (calendar["driver"] is Dictionary):
		calendar["driver"] = _default_driver_settings()
	return calendar


func _new_id(prefix: String) -> String:
	return "%s_%d_%04d" % [prefix, int(Time.get_unix_time_from_system()), randi() % 10000]


func _new_share_code() -> String:
	return "CAL-%d-%04d" % [int(Time.get_unix_time_from_system()), randi() % 10000]


func _date_key(year: int, month: int, day: int) -> String:
	return "%04d-%02d-%02d" % [year, month, day]


func _is_today(year: int, month: int, day: int) -> bool:
	var now := Time.get_datetime_dict_from_system()
	return year == int(now["year"]) and month == int(now["month"]) and day == int(now["day"])


func _unix_from_date(year: int, month: int, day: int) -> int:
	return int(Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": 0,
		"minute": 0,
		"second": 0,
	}))


func _weekday_monday_index(year: int, month: int, day: int) -> int:
	var date := Time.get_datetime_dict_from_unix_time(_unix_from_date(year, month, day))
	return (int(date["weekday"]) + 6) % 7


func _month_start_weekday_monday(year: int, month: int) -> int:
	return _weekday_monday_index(year, month, 1)


func _days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			if _is_leap_year(year):
				return 29
			return 28
	return 30


func _is_leap_year(year: int) -> bool:
	return year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)


func _make_spin(min_value: int, max_value: int, value: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.value = value
	spin.allow_greater = true
	spin.custom_minimum_size.y = 54
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.add_theme_font_size_override("font_size", 18)
	spin.add_theme_color_override("font_color", COLOR_TEXT)
	spin.add_theme_color_override("font_focus_color", COLOR_TEXT)
	spin.add_theme_stylebox_override("normal", _control_style(Color(0.90, 0.94, 0.90, 0.13)))
	spin.add_theme_stylebox_override("focus", _control_style(Color(0.92, 0.72, 0.38, 0.18), true))
	return spin


func _field_stack(label_text: String, field: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var label := _make_label(label_text, 14, COLOR_TEXT_MUTED)
	box.add_child(label)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(field)
	return box


func _connect_tap(button: BaseButton, action: Callable) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.pressed.connect(func() -> void:
		action.call()
	)


func _make_nav_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.x = 82
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_prepare_control(button, 24, 58)
	return button


func _prepare_control(control: Control, font_size: int, min_height: int) -> void:
	control.custom_minimum_size.y = min_height
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size", font_size)
	if control is Button or control is OptionButton or control is LineEdit:
		control.add_theme_stylebox_override("normal", _control_style(Color(0.90, 0.94, 0.90, 0.13)))
		control.add_theme_stylebox_override("hover", _control_style(Color(0.90, 0.94, 0.90, 0.18)))
		control.add_theme_stylebox_override("pressed", _control_style(Color(0.90, 0.94, 0.90, 0.09)))
		control.add_theme_stylebox_override("focus", _control_style(Color(0.92, 0.72, 0.38, 0.18), true))
		control.add_theme_color_override("font_color", COLOR_TEXT)
		control.add_theme_color_override("font_hover_color", COLOR_TEXT)
		control.add_theme_color_override("font_pressed_color", COLOR_TEXT)
		control.add_theme_color_override("font_focus_color", COLOR_TEXT)
		control.add_theme_color_override("font_placeholder_color", COLOR_TEXT_DIM)


func _prepare_large_dropdown(option: OptionButton) -> void:
	var popup := option.get_popup()
	popup.min_size = Vector2i(300, 250)
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_constant_override("v_separation", 14)
	popup.add_theme_constant_override("item_start_padding", 18)
	popup.add_theme_constant_override("item_end_padding", 18)


func _sync_content_width() -> void:
	if content_root == null:
		return

	var available_width := get_viewport_rect().size.x - 36.0 - SCROLLBAR_TOUCH_WIDTH
	if main_scroll != null and main_scroll.size.x > 0.0:
		available_width = main_scroll.size.x - SCROLLBAR_TOUCH_WIDTH
	if available_width <= 0.0:
		return

	content_root.custom_minimum_size.x = minf(float(PORTRAIT_WIDTH), available_width)
	if main_scroll != null:
		main_scroll.scroll_horizontal = 0


func _style_main_scrollbar() -> void:
	if main_scroll == null:
		return

	var scroll_bar := main_scroll.get_v_scroll_bar()
	scroll_bar.custom_minimum_size.x = SCROLLBAR_TOUCH_WIDTH
	scroll_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll_bar.add_theme_stylebox_override("scroll", _scrollbar_track_style())
	scroll_bar.add_theme_stylebox_override("scroll_focus", _scrollbar_track_style())
	scroll_bar.add_theme_stylebox_override("grabber", _scrollbar_grabber_style(0.48))
	scroll_bar.add_theme_stylebox_override("grabber_highlight", _scrollbar_grabber_style(0.68))
	scroll_bar.add_theme_stylebox_override("grabber_pressed", _scrollbar_grabber_style(0.82))

	var horizontal_bar := main_scroll.get_h_scroll_bar()
	horizontal_bar.visible = false
	horizontal_bar.custom_minimum_size.y = 0
	horizontal_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_profile_panel_visible(visible: bool) -> void:
	if profile_panel != null:
		profile_panel.visible = visible


func _toggle_profile_panel() -> void:
	_set_profile_panel_visible(profile_panel == null or not profile_panel.visible)


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


func _tile_label(text: String, font_size: int, color: Color) -> Label:
	var label := _make_label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	return label


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


func _tile_style(color: Color, is_today: bool, has_items: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(18)
	style.set_border_width_all(3 if is_today else 1)
	if is_today:
		style.border_color = COLOR_TODAY
	elif has_items:
		style.border_color = Color(1.0, 1.0, 1.0, 0.28)
	else:
		style.border_color = Color(1.0, 1.0, 1.0, 0.16)
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


func _scrollbar_track_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.90, 0.86, 0.08)
	style.set_corner_radius_all(14)
	style.content_margin_left = 7
	style.content_margin_right = 7
	return style


func _scrollbar_grabber_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.86, 0.90, 0.86, alpha)
	style.set_corner_radius_all(14)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

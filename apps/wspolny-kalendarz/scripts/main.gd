extends Control

const BackgroundArt = preload("res://scripts/background_art.gd")

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
var share_code_label: Label
var join_code_input: LineEdit
var share_status_label: Label

var day_dialog: AcceptDialog
var day_dialog_title: Label
var day_quick_buttons_grid: GridContainer
var day_event_form_box: VBoxContainer
var day_event_name_input: LineEdit
var day_event_time_input: LineEdit
var day_event_description_input: TextEdit
var day_event_color_palette: GridContainer
var day_event_color_index := 0
var day_event_status_label: Label
var day_fixed_button_form_box: VBoxContainer
var day_fixed_name_input: LineEdit
var day_fixed_color_palette: GridContainer
var day_fixed_color_index := 0
var day_fixed_delete_option: OptionButton
var day_fixed_delete_ids: Array[String] = []
var day_fixed_status_label: Label
var day_event_list_label: Label
var day_note_edit: TextEdit
var day_save_note_button: Button
var day_clear_button: Button

var system_days_body: VBoxContainer
var system_days_button_grid: GridContainer
var system_days_start_label: Label
var system_days_steps_label: Label
var system_days_status_label: Label
var system_day_category_ids: Array[String] = []

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

	_add_profile_overlay()

	var today_button := Button.new()
	today_button.text = "Wróć do aktualnej daty"
	_prepare_control(today_button, 18, 52)
	_connect_tap(today_button, Callable(self, "_return_to_today"))
	screen_root.add_child(today_button)

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

	content_root.add_child(_build_system_days_panel())
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


func _build_system_days_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	var toggle_button := Button.new()
	toggle_button.text = "Dodaj dni systemowe"
	_prepare_control(toggle_button, 18, 54)
	_connect_tap(toggle_button, Callable(self, "_toggle_system_days_panel"))
	box.add_child(toggle_button)

	system_days_body = VBoxContainer.new()
	system_days_body.visible = false
	system_days_body.add_theme_constant_override("separation", 10)
	box.add_child(system_days_body)

	system_days_start_label = _make_label("", 15, COLOR_TEXT_MUTED)
	system_days_start_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	system_days_body.add_child(system_days_start_label)

	system_days_button_grid = GridContainer.new()
	system_days_button_grid.columns = 2
	system_days_button_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	system_days_button_grid.add_theme_constant_override("h_separation", 8)
	system_days_button_grid.add_theme_constant_override("v_separation", 8)
	system_days_body.add_child(system_days_button_grid)

	system_days_steps_label = _make_label("", 16, COLOR_TEXT)
	system_days_steps_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	system_days_body.add_child(system_days_steps_label)

	var edit_row := HBoxContainer.new()
	edit_row.add_theme_constant_override("separation", 8)
	system_days_body.add_child(edit_row)

	var undo_button := Button.new()
	undo_button.text = "Cofnij ostatni"
	_prepare_control(undo_button, 16, 48)
	_connect_tap(undo_button, Callable(self, "_undo_system_day_step"))
	edit_row.add_child(undo_button)

	var clear_button := Button.new()
	clear_button.text = "Wyczyść system"
	_prepare_control(clear_button, 16, 48)
	_connect_tap(clear_button, Callable(self, "_clear_system_days"))
	edit_row.add_child(clear_button)

	var apply_button := Button.new()
	apply_button.text = "Zapisz system i zastosuj do roku"
	_prepare_control(apply_button, 18, 54)
	_connect_tap(apply_button, Callable(self, "_apply_system_days_to_year"))
	system_days_body.add_child(apply_button)

	system_days_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	system_days_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	system_days_body.add_child(system_days_status_label)

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
	day_dialog.title = ""
	day_dialog.borderless = true
	day_dialog.min_size = Vector2i(620, 560)
	add_child(day_dialog)
	day_dialog.get_ok_button().visible = false

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	day_dialog.add_child(box)

	_add_dialog_header(box, "Dzień", Callable(self, "_close_day_dialog"))

	day_dialog_title = _make_label("", 24, COLOR_TEXT)
	day_dialog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(day_dialog_title)

	box.add_child(_make_section_label("Szybkie przyciski"))

	day_quick_buttons_grid = GridContainer.new()
	day_quick_buttons_grid.columns = 2
	day_quick_buttons_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_quick_buttons_grid.add_theme_constant_override("h_separation", 8)
	day_quick_buttons_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(day_quick_buttons_grid)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	box.add_child(action_row)

	var event_button := Button.new()
	event_button.text = "Dodaj wydarzenie"
	_prepare_control(event_button, 18, 52)
	_connect_tap(event_button, Callable(self, "_toggle_day_event_form"))
	action_row.add_child(event_button)

	var fixed_button := Button.new()
	fixed_button.text = "Dodaj stały przycisk"
	_prepare_control(fixed_button, 18, 52)
	_connect_tap(fixed_button, Callable(self, "_toggle_day_fixed_button_form"))
	action_row.add_child(fixed_button)

	day_event_form_box = VBoxContainer.new()
	day_event_form_box.visible = false
	day_event_form_box.add_theme_constant_override("separation", 8)
	box.add_child(day_event_form_box)

	day_event_name_input = LineEdit.new()
	day_event_name_input.placeholder_text = "Nazwa wydarzenia"
	_prepare_control(day_event_name_input, 18, 52)
	day_event_form_box.add_child(day_event_name_input)

	day_event_time_input = LineEdit.new()
	day_event_time_input.placeholder_text = "Godzina startu, np. 08:00"
	_prepare_control(day_event_time_input, 18, 52)
	day_event_form_box.add_child(day_event_time_input)

	day_event_form_box.add_child(_make_label("Opis wydarzenia", 14, COLOR_TEXT_MUTED))

	day_event_description_input = TextEdit.new()
	day_event_description_input.custom_minimum_size.y = 90
	day_event_description_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_event_description_input.add_theme_font_size_override("font_size", 17)
	day_event_description_input.add_theme_color_override("font_color", COLOR_TEXT)
	day_event_description_input.add_theme_stylebox_override("normal", _control_style(Color(0.90, 0.94, 0.90, 0.10)))
	day_event_form_box.add_child(day_event_description_input)

	day_event_form_box.add_child(_make_label("Kolor", 14, COLOR_TEXT_MUTED))
	day_event_color_palette = _make_color_palette("event")
	day_event_form_box.add_child(day_event_color_palette)

	var save_event_button := Button.new()
	save_event_button.text = "Zapisz wydarzenie"
	_prepare_control(save_event_button, 18, 52)
	_connect_tap(save_event_button, Callable(self, "_save_day_event"))
	day_event_form_box.add_child(save_event_button)

	day_event_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	day_event_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_event_form_box.add_child(day_event_status_label)

	day_fixed_button_form_box = VBoxContainer.new()
	day_fixed_button_form_box.visible = false
	day_fixed_button_form_box.add_theme_constant_override("separation", 8)
	box.add_child(day_fixed_button_form_box)

	day_fixed_name_input = LineEdit.new()
	day_fixed_name_input.placeholder_text = "Nazwa przycisku, np. dzień wolny"
	_prepare_control(day_fixed_name_input, 18, 52)
	day_fixed_button_form_box.add_child(day_fixed_name_input)

	day_fixed_button_form_box.add_child(_make_label("Kolor przycisku", 14, COLOR_TEXT_MUTED))
	day_fixed_color_palette = _make_color_palette("fixed")
	day_fixed_button_form_box.add_child(day_fixed_color_palette)

	var save_fixed_button := Button.new()
	save_fixed_button.text = "Zapisz przycisk i dodaj do dnia"
	_prepare_control(save_fixed_button, 18, 52)
	_connect_tap(save_fixed_button, Callable(self, "_save_fixed_button"))
	day_fixed_button_form_box.add_child(save_fixed_button)

	var delete_fixed_row := HBoxContainer.new()
	delete_fixed_row.add_theme_constant_override("separation", 8)
	day_fixed_button_form_box.add_child(delete_fixed_row)

	day_fixed_delete_option = OptionButton.new()
	_prepare_control(day_fixed_delete_option, 16, 48)
	_prepare_large_dropdown(day_fixed_delete_option)
	delete_fixed_row.add_child(day_fixed_delete_option)

	var delete_fixed_button := Button.new()
	delete_fixed_button.text = "Usuń"
	_prepare_control(delete_fixed_button, 16, 48)
	delete_fixed_button.custom_minimum_size.x = 110
	delete_fixed_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_connect_tap(delete_fixed_button, Callable(self, "_delete_fixed_button"))
	delete_fixed_row.add_child(delete_fixed_button)

	day_fixed_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	day_fixed_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_fixed_button_form_box.add_child(day_fixed_status_label)

	day_event_list_label = _make_label("", 16, COLOR_TEXT_MUTED)
	day_event_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(day_event_list_label)

	box.add_child(_make_label("Notatka / opis", 14, COLOR_TEXT_MUTED))

	day_note_edit = TextEdit.new()
	day_note_edit.custom_minimum_size.y = 90
	day_note_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_note_edit.add_theme_font_size_override("font_size", 17)
	day_note_edit.add_theme_color_override("font_color", COLOR_TEXT)
	day_note_edit.add_theme_color_override("font_placeholder_color", COLOR_TEXT_DIM)
	day_note_edit.add_theme_stylebox_override("normal", _control_style(Color(0.90, 0.94, 0.90, 0.10)))
	box.add_child(day_note_edit)

	var note_buttons := HBoxContainer.new()
	note_buttons.add_theme_constant_override("separation", 8)
	box.add_child(note_buttons)

	day_save_note_button = Button.new()
	day_save_note_button.text = "Zapisz notatkę"
	_prepare_control(day_save_note_button, 18, 52)
	_connect_tap(day_save_note_button, Callable(self, "_save_selected_day_note"))
	note_buttons.add_child(day_save_note_button)

	day_clear_button = Button.new()
	day_clear_button.text = "Wyczyść dzień"
	_prepare_control(day_clear_button, 18, 52)
	_connect_tap(day_clear_button, Callable(self, "_clear_selected_day"))
	note_buttons.add_child(day_clear_button)


func _refresh_all() -> void:
	_ensure_calendar_exists()
	selected_calendar_index = clampi(selected_calendar_index, 0, calendars.size() - 1)
	_load_system_days_from_calendar()
	_refresh_profile_ui()
	_refresh_category_ui()
	_refresh_month_title()
	_rebuild_calendar()
	_refresh_sharing_ui()
	_refresh_system_days_ui()


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
	var detail_events := _event_details_for_day(key)
	var has_note := _notes().has(key) and String(_notes()[key]).strip_edges() != ""
	var is_today := _is_today(year, month, day)
	var color := _color_for_day(key, event_ids)

	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, 84)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _tile_style(color, is_today, not event_ids.is_empty() or not detail_events.is_empty() or has_note))
	button.add_theme_stylebox_override("hover", _tile_style(color.lightened(0.06), is_today, true))
	button.add_theme_stylebox_override("pressed", _tile_style(color.darkened(0.08), is_today, true))
	button.add_theme_stylebox_override("focus", _tile_style(color, true, true))
	_fill_day_tile(button, year, month, day, event_ids, has_note)
	_connect_tap(button, Callable(self, "_open_day_dialog").bind(year, month, day))
	return button


func _make_day_spacer() -> Control:
	var spacer := Panel.new()
	spacer.custom_minimum_size = Vector2(0, 84)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.add_theme_stylebox_override("panel", _tile_style(Color(0.90, 0.93, 0.88, 0.05), false, false))
	return spacer


func _fill_day_tile(button: Button, year: int, month: int, day: int, event_ids: Array, has_note: bool) -> void:
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

	var marker_text := _marker_text(_date_key(year, month, day), event_ids, has_note)
	if marker_text != "":
		box.add_child(_tile_label(marker_text, 10, COLOR_TEXT))


func _marker_text(day_key: String, event_ids: Array, has_note: bool) -> String:
	var parts: Array[String] = []
	for event_id in event_ids:
		var category: Dictionary = _category_by_id(String(event_id))
		if category.is_empty():
			continue
		parts.append(String(category.get("name", "")))
	for item in _event_details_for_day(day_key):
		if not (item is Dictionary):
			continue
		var detail: Dictionary = item as Dictionary
		var name := String(detail.get("name", "")).strip_edges()
		if name == "":
			continue
		var start_time := String(detail.get("time", "")).strip_edges()
		var detail_label := name
		if start_time != "":
			detail_label = "%s %s" % [start_time, name]
		parts.append(detail_label)
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
	_reset_day_dialog_forms()
	_refresh_day_dialog()
	_refresh_system_days_ui()
	day_dialog.popup_centered(Vector2i(620, 560))


func _close_day_dialog() -> void:
	if day_dialog != null:
		day_dialog.hide()


func _refresh_day_dialog() -> void:
	if day_dialog_title == null:
		return

	day_dialog_title.text = "%04d-%02d-%02d" % [selected_day_year, selected_day_month, selected_day_number]
	_refresh_day_quick_buttons()
	_refresh_fixed_delete_option()
	day_note_edit.text = String(_notes().get(selected_day_key, ""))
	_refresh_day_event_list()


func _reset_day_dialog_forms() -> void:
	if day_event_form_box != null:
		day_event_form_box.visible = false
	if day_fixed_button_form_box != null:
		day_fixed_button_form_box.visible = false
	day_event_color_index = 0
	day_fixed_color_index = 0
	_refresh_color_palettes()
	if day_event_status_label != null:
		day_event_status_label.text = ""
	if day_fixed_status_label != null:
		day_fixed_status_label.text = ""


func _refresh_day_quick_buttons() -> void:
	if day_quick_buttons_grid == null:
		return

	for child in day_quick_buttons_grid.get_children():
		day_quick_buttons_grid.remove_child(child)
		child.queue_free()

	var categories := _categories()
	var has_buttons := false
	for item in categories:
		if not (item is Dictionary):
			continue
		var category: Dictionary = item as Dictionary
		var category_id := String(category.get("id", ""))
		if category_id == "" or _is_category_hidden(category):
			continue
		var quick_button := Button.new()
		quick_button.text = String(category.get("name", ""))
		_prepare_control(quick_button, 16, 48)
		_style_category_button(quick_button, int(category.get("color", 0)))
		_connect_tap(quick_button, Callable(self, "_add_quick_category_to_selected_day").bind(category_id))
		day_quick_buttons_grid.add_child(quick_button)
		has_buttons = true

	if not has_buttons:
		var empty_label := _make_label("Brak stałych przycisków. Dodaj pierwszy.", 15, COLOR_TEXT_MUTED)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		day_quick_buttons_grid.add_child(empty_label)


func _refresh_day_event_list() -> void:
	if day_event_list_label == null:
		return

	var event_ids := _event_ids_for_day(selected_day_key)
	var lines: Array[String] = []
	for event_id in event_ids:
		var category: Dictionary = _category_by_id(String(event_id))
		if not category.is_empty():
			lines.append(String(category.get("name", "")))
	for item in _event_details_for_day(selected_day_key):
		if not (item is Dictionary):
			continue
		var detail: Dictionary = item as Dictionary
		var name := String(detail.get("name", "")).strip_edges()
		if name == "":
			continue
		var start_time := String(detail.get("time", "")).strip_edges()
		var line := name
		if start_time != "":
			line = "%s %s" % [start_time, name]
		var description := String(detail.get("description", "")).strip_edges().replace("\n", " ")
		if description != "":
			line = "%s - %s" % [line, description.left(58)]
		lines.append(line)
	if lines.is_empty():
		day_event_list_label.text = "Ten dzień jest pusty."
	else:
		day_event_list_label.text = "Wpisy:\n%s" % "\n".join(lines)


func _add_quick_category_to_selected_day(category_id: String) -> void:
	if selected_day_key == "":
		return

	_add_category_id_to_day(selected_day_key, category_id)
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()


func _toggle_system_days_panel() -> void:
	if system_days_body == null:
		return

	system_days_body.visible = not system_days_body.visible
	if system_days_status_label != null:
		system_days_status_label.text = ""
	_refresh_system_days_ui()


func _refresh_system_days_ui() -> void:
	if system_days_body == null:
		return

	if system_days_start_label != null:
		system_days_start_label.text = "Start systemu: %s. Kliknij dzień w kalendarzu, żeby zmienić start." % _system_days_start_key()
	_refresh_system_days_button_grid()
	_refresh_system_days_steps_label()


func _refresh_system_days_button_grid() -> void:
	if system_days_button_grid == null:
		return

	for child in system_days_button_grid.get_children():
		system_days_button_grid.remove_child(child)
		child.queue_free()

	var has_buttons := false
	for item in _categories():
		if not (item is Dictionary):
			continue
		var category: Dictionary = item as Dictionary
		var category_id := String(category.get("id", ""))
		if category_id == "" or _is_category_hidden(category):
			continue

		var button := Button.new()
		button.text = String(category.get("name", ""))
		_prepare_control(button, 16, 48)
		_style_category_button(button, int(category.get("color", 0)))
		_connect_tap(button, Callable(self, "_add_category_to_system_days").bind(category_id))
		system_days_button_grid.add_child(button)
		has_buttons = true

	if not has_buttons:
		var empty_label := _make_label("Najpierw dodaj stały przycisk w oknie dnia.", 15, COLOR_TEXT_MUTED)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		system_days_button_grid.add_child(empty_label)


func _add_category_to_system_days(category_id: String) -> void:
	if category_id == "":
		return

	system_day_category_ids.append(category_id)
	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_refresh_system_days_ui()


func _undo_system_day_step() -> void:
	if not system_day_category_ids.is_empty():
		system_day_category_ids.remove_at(system_day_category_ids.size() - 1)
	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_refresh_system_days_ui()


func _clear_system_days() -> void:
	system_day_category_ids.clear()
	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_refresh_system_days_ui()


func _refresh_system_days_steps_label() -> void:
	if system_days_steps_label == null:
		return

	var names: Array[String] = []
	for category_id in system_day_category_ids:
		var category: Dictionary = _category_by_id(String(category_id))
		if category.is_empty() or _is_category_hidden(category):
			continue
		names.append(String(category.get("name", "")))

	if names.is_empty():
		system_days_steps_label.text = "System: jeszcze pusty"
	else:
		system_days_steps_label.text = "System: %s" % " -> ".join(names)


func _apply_system_days_to_year() -> void:
	if system_days_status_label == null:
		return
	if system_day_category_ids.is_empty():
		system_days_status_label.text = "Kliknij guziki dni systemowych w kolejności cyklu."
		return

	var start_date := _date_from_string(_system_days_start_key())
	if start_date.is_empty():
		system_days_status_label.text = "Najpierw wybierz poprawny dzień startu."
		return

	var start_year := int(start_date["year"])
	var start_month := int(start_date["month"])
	var start_day := int(start_date["day"])
	var start_unix := _unix_from_date(start_year, start_month, start_day)
	var end_unix := _unix_from_date(start_year, 12, 31)
	var total_days := int((end_unix - start_unix) / 86400) + 1
	if total_days <= 0:
		system_days_status_label.text = "Ten system nie ma gdzie się zastosować w tym roku."
		return

	var changed_days := 0
	for offset in range(total_days):
		var category_id: String = system_day_category_ids[offset % system_day_category_ids.size()]
		var category: Dictionary = _category_by_id(category_id)
		if category.is_empty() or _is_category_hidden(category):
			continue
		var date := Time.get_datetime_dict_from_unix_time(start_unix + offset * 86400)
		var key := _date_key(int(date["year"]), int(date["month"]), int(date["day"]))
		if _add_category_id_to_day(key, category_id, true):
			changed_days += 1

	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()
	system_days_status_label.text = "Zastosowano od %s do %d-12-31. Dopisano lub ustawiono %d dni." % [_system_days_start_key(), start_year, changed_days]


func _system_days_start_key() -> String:
	if selected_day_key != "":
		return selected_day_key
	return _date_key(current_year, current_month, 1)


func _load_system_days_from_calendar() -> void:
	system_day_category_ids.clear()
	for item in _system_days():
		var category_id := String(item)
		var category: Dictionary = _category_by_id(category_id)
		if category_id == "" or category.is_empty() or _is_category_hidden(category):
			continue
		system_day_category_ids.append(category_id)


func _save_system_days_to_calendar() -> void:
	var calendar := _selected_calendar()
	calendar["system_days"] = system_day_category_ids.duplicate()


func _remove_category_from_system_days(category_id: String) -> void:
	if category_id == "":
		return

	var clean_ids: Array[String] = []
	for existing_id in system_day_category_ids:
		if String(existing_id) != category_id:
			clean_ids.append(String(existing_id))
	system_day_category_ids = clean_ids
	_save_system_days_to_calendar()


func _toggle_day_event_form() -> void:
	if day_event_form_box == null:
		return

	var show_form := not day_event_form_box.visible
	day_event_form_box.visible = show_form
	if day_fixed_button_form_box != null and show_form:
		day_fixed_button_form_box.visible = false
	if day_event_status_label != null:
		day_event_status_label.text = ""
	if show_form and day_event_name_input != null:
		day_event_name_input.grab_focus()


func _toggle_day_fixed_button_form() -> void:
	if day_fixed_button_form_box == null:
		return

	var show_form := not day_fixed_button_form_box.visible
	day_fixed_button_form_box.visible = show_form
	if day_event_form_box != null and show_form:
		day_event_form_box.visible = false
	if day_fixed_status_label != null:
		day_fixed_status_label.text = ""
	_refresh_fixed_delete_option()
	if show_form and day_fixed_name_input != null:
		day_fixed_name_input.grab_focus()


func _save_day_event() -> void:
	if selected_day_key == "" or day_event_name_input == null:
		return

	var name := day_event_name_input.text.strip_edges()
	if name == "":
		day_event_status_label.text = "Wpisz nazwę wydarzenia."
		return

	var color_index := clampi(day_event_color_index, 0, CATEGORY_COLOR_VALUES.size() - 1)
	var event: Dictionary = {
		"id": _new_id("event"),
		"name": name,
		"time": day_event_time_input.text.strip_edges(),
		"description": day_event_description_input.text.strip_edges(),
		"color": color_index,
	}
	var details := _event_details()
	var entries: Array = []
	if details.has(selected_day_key) and details[selected_day_key] is Array:
		var existing_entries: Array = details[selected_day_key]
		entries = existing_entries.duplicate(true)
	entries.append(event)
	details[selected_day_key] = entries

	day_event_name_input.text = ""
	day_event_time_input.text = ""
	day_event_description_input.text = ""
	day_event_form_box.visible = false
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()


func _save_fixed_button() -> void:
	if selected_day_key == "" or day_fixed_name_input == null:
		return

	var name := day_fixed_name_input.text.strip_edges()
	if name == "":
		day_fixed_status_label.text = "Wpisz nazwę stałego przycisku."
		return

	var color_index := clampi(day_fixed_color_index, 0, CATEGORY_COLOR_VALUES.size() - 1)
	var category_id := _category_id_for_name_with_color(name, color_index)
	_add_category_id_to_day(selected_day_key, category_id)
	day_fixed_name_input.text = ""
	day_fixed_button_form_box.visible = false
	_save_settings_to_disk()
	_refresh_day_quick_buttons()
	_refresh_fixed_delete_option(category_id)
	_refresh_system_days_ui()
	_rebuild_calendar()
	_refresh_day_event_list()


func _refresh_fixed_delete_option(selected_id: String = "") -> void:
	if day_fixed_delete_option == null:
		return

	day_fixed_delete_option.clear()
	day_fixed_delete_ids.clear()
	var selected_index := 0
	for item in _categories():
		if not (item is Dictionary):
			continue
		var category: Dictionary = item as Dictionary
		var category_id := String(category.get("id", ""))
		if category_id == "" or _is_category_hidden(category):
			continue
		if selected_id != "" and category_id == selected_id:
			selected_index = day_fixed_delete_ids.size()
		day_fixed_delete_ids.append(category_id)
		day_fixed_delete_option.add_item(String(category.get("name", "")))

	if day_fixed_delete_ids.is_empty():
		day_fixed_delete_option.add_item("Brak przycisków")
		day_fixed_delete_option.disabled = true
	else:
		day_fixed_delete_option.disabled = false
		day_fixed_delete_option.select(clampi(selected_index, 0, day_fixed_delete_ids.size() - 1))


func _delete_fixed_button() -> void:
	if day_fixed_delete_ids.is_empty():
		return

	var selected_index := clampi(day_fixed_delete_option.selected, 0, day_fixed_delete_ids.size() - 1)
	var category_id: String = day_fixed_delete_ids[selected_index]
	var categories := _categories()
	var removed_name := ""
	for index in range(categories.size()):
		if not (categories[index] is Dictionary):
			continue
		var category: Dictionary = categories[index] as Dictionary
		if String(category.get("id", "")) == category_id:
			removed_name = String(category.get("name", ""))
			category["hidden"] = true
			categories[index] = category
			break

	_remove_category_from_system_days(category_id)
	_save_settings_to_disk()
	_refresh_day_quick_buttons()
	_refresh_fixed_delete_option()
	_refresh_system_days_ui()
	_rebuild_calendar()
	_refresh_day_event_list()
	if day_fixed_status_label != null:
		if removed_name != "":
			day_fixed_status_label.text = "Usunięto: %s" % removed_name
		else:
			day_fixed_status_label.text = "Usunięto stały przycisk."


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
	_event_details().erase(selected_day_key)
	_notes().erase(selected_day_key)
	day_note_edit.text = ""
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()


func _add_category_id_to_day(day_key: String, category_id: String, preferred: bool = false) -> bool:
	if day_key == "" or category_id == "":
		return false

	var events := _events()
	var event_ids: Array = []
	if events.has(day_key) and events[day_key] is Array:
		var existing_ids: Array = events[day_key]
		event_ids = existing_ids.duplicate()
	if event_ids.has(category_id):
		if preferred and not event_ids.is_empty() and String(event_ids[0]) != category_id:
			event_ids.erase(category_id)
			event_ids.insert(0, category_id)
			events[day_key] = event_ids
			return true
	else:
		if preferred:
			event_ids.insert(0, category_id)
		else:
			event_ids.append(category_id)
		events[day_key] = event_ids
		return true
	events[day_key] = event_ids
	return false


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
	if day_quick_buttons_grid != null:
		_refresh_day_quick_buttons()
	_refresh_fixed_delete_option()
	_refresh_system_days_ui()


func _category_id_for_name_with_color(name: String, color_index: int) -> String:
	var categories := _categories()
	var wanted := _category_name_key(name)
	for index in range(categories.size()):
		if not (categories[index] is Dictionary):
			continue
		var category: Dictionary = categories[index] as Dictionary
		if _category_name_key(String(category.get("name", ""))) == wanted:
			var category_id := String(category.get("id", ""))
			if category_id != "":
				category["hidden"] = false
				category["color"] = clampi(color_index, 0, CATEGORY_COLOR_VALUES.size() - 1)
				categories[index] = category
				return category_id

	var category: Dictionary = {
		"id": _new_id("cat"),
		"name": name,
		"color": clampi(color_index, 0, CATEGORY_COLOR_VALUES.size() - 1),
		"hidden": false,
	}
	categories.append(category)
	return String(category["id"])


func _category_name_key(value: String) -> String:
	return value.strip_edges().to_lower()


func _is_category_hidden(category: Dictionary) -> bool:
	return bool(category.get("hidden", false))


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
		"event_details": {},
		"notes": {},
		"system_days": [],
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
		"event_details": {},
		"notes": {},
		"system_days": [],
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


func _event_details() -> Dictionary:
	var calendar := _selected_calendar()
	if not calendar.has("event_details") or not (calendar["event_details"] is Dictionary):
		calendar["event_details"] = {}
	return calendar["event_details"]


func _notes() -> Dictionary:
	var calendar := _selected_calendar()
	if not calendar.has("notes") or not (calendar["notes"] is Dictionary):
		calendar["notes"] = {}
	return calendar["notes"]


func _system_days() -> Array:
	var calendar := _selected_calendar()
	if not calendar.has("system_days") or not (calendar["system_days"] is Array):
		calendar["system_days"] = []
	return calendar["system_days"]


func _event_ids_for_day(key: String) -> Array:
	var events := _events()
	if not events.has(key) or not (events[key] is Array):
		return []
	return events[key]


func _event_details_for_day(key: String) -> Array:
	var details := _event_details()
	if not details.has(key) or not (details[key] is Array):
		return []
	return details[key]


func _category_by_id(category_id: String) -> Dictionary:
	for item in _categories():
		if not (item is Dictionary):
			continue
		var category: Dictionary = item as Dictionary
		if String(category.get("id", "")) == category_id:
			return category
	return {}


func _color_for_day(day_key: String, event_ids: Array) -> Color:
	if not event_ids.is_empty():
		var category: Dictionary = _category_by_id(String(event_ids[0]))
		if not category.is_empty():
			return _category_color(int(category.get("color", 0)))
	for item in _event_details_for_day(day_key):
		if not (item is Dictionary):
			continue
		var detail: Dictionary = item as Dictionary
		return _category_color(int(detail.get("color", 0)))

	return COLOR_TILE_EMPTY


func _category_color(index: int) -> Color:
	return CATEGORY_COLOR_VALUES[clampi(index, 0, CATEGORY_COLOR_VALUES.size() - 1)]


func _style_category_button(button: Button, color_index: int) -> void:
	var color := _category_color(color_index)
	button.add_theme_stylebox_override("normal", _control_style(color))
	button.add_theme_stylebox_override("hover", _control_style(color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _control_style(color.darkened(0.08)))
	button.add_theme_stylebox_override("focus", _control_style(color.lightened(0.05), true))


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
	if not calendar.has("event_details") or not (calendar["event_details"] is Dictionary):
		calendar["event_details"] = {}
	if not calendar.has("notes") or not (calendar["notes"] is Dictionary):
		calendar["notes"] = {}
	if not calendar.has("system_days") or not (calendar["system_days"] is Array):
		calendar["system_days"] = []
	calendar.erase("pattern")
	return calendar


func _new_id(prefix: String) -> String:
	return "%s_%d_%04d" % [prefix, int(Time.get_unix_time_from_system()), randi() % 10000]


func _new_share_code() -> String:
	return "CAL-%d-%04d" % [int(Time.get_unix_time_from_system()), randi() % 10000]


func _date_key(year: int, month: int, day: int) -> String:
	return "%04d-%02d-%02d" % [year, month, day]


func _date_from_string(value: String) -> Dictionary:
	var parts := value.strip_edges().split("-", false)
	if parts.size() != 3:
		return {}
	if not String(parts[0]).is_valid_int() or not String(parts[1]).is_valid_int() or not String(parts[2]).is_valid_int():
		return {}

	var year := int(parts[0])
	var month := int(parts[1])
	var day := int(parts[2])
	if month < 1 or month > 12:
		return {}
	if day < 1 or day > _days_in_month(year, month):
		return {}

	return {
		"year": year,
		"month": month,
		"day": day,
	}


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


func _make_color_palette(context: String) -> GridContainer:
	var palette := GridContainer.new()
	palette.columns = 3
	palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette.add_theme_constant_override("h_separation", 8)
	palette.add_theme_constant_override("v_separation", 8)
	for index in range(CATEGORY_COLOR_VALUES.size()):
		var swatch := Button.new()
		swatch.text = ""
		swatch.tooltip_text = CATEGORY_COLOR_NAMES[index]
		swatch.custom_minimum_size = Vector2(0, 48)
		swatch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		swatch.focus_mode = Control.FOCUS_NONE
		swatch.add_theme_font_size_override("font_size", 20)
		swatch.add_theme_color_override("font_color", COLOR_TEXT)
		_connect_tap(swatch, Callable(self, "_select_palette_color").bind(context, index))
		palette.add_child(swatch)
	_refresh_color_palette(palette, 0)
	return palette


func _select_palette_color(context: String, color_index: int) -> void:
	var clean_index := clampi(color_index, 0, CATEGORY_COLOR_VALUES.size() - 1)
	if context == "event":
		day_event_color_index = clean_index
	elif context == "fixed":
		day_fixed_color_index = clean_index
	_refresh_color_palettes()


func _refresh_color_palettes() -> void:
	_refresh_color_palette(day_event_color_palette, day_event_color_index)
	_refresh_color_palette(day_fixed_color_palette, day_fixed_color_index)


func _refresh_color_palette(palette: GridContainer, selected_index: int) -> void:
	if palette == null:
		return

	var color_index := 0
	for child in palette.get_children():
		if not (child is Button):
			continue
		var swatch: Button = child as Button
		_style_color_swatch(swatch, color_index, color_index == selected_index)
		color_index += 1


func _style_color_swatch(swatch: Button, color_index: int, selected: bool) -> void:
	var color := _category_color(color_index)
	swatch.add_theme_stylebox_override("normal", _color_swatch_style(color, selected))
	swatch.add_theme_stylebox_override("hover", _color_swatch_style(color.lightened(0.07), selected))
	swatch.add_theme_stylebox_override("pressed", _color_swatch_style(color.darkened(0.07), selected))
	swatch.add_theme_stylebox_override("focus", _color_swatch_style(color, true))


func _color_swatch_style(color: Color, selected: bool) -> StyleBoxFlat:
	var style := _control_style(color)
	style.set_border_width_all(4 if selected else 1)
	style.border_color = COLOR_TODAY if selected else Color(1.0, 1.0, 1.0, 0.18)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


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


func _add_dialog_header(parent: VBoxContainer, title: String, close_action: Callable) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	parent.add_child(header)

	var left_spacer := Control.new()
	left_spacer.custom_minimum_size.x = 64
	header.add_child(left_spacer)

	var title_label := _make_label(title, 20, COLOR_TEXT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.tooltip_text = "Zamknij"
	_prepare_control(close_button, 30, 64)
	close_button.custom_minimum_size.x = 64
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_connect_tap(close_button, close_action)
	header.add_child(close_button)


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

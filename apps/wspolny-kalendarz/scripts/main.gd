extends Control

const LOGO_BACKGROUND_TEXTURE = preload("res://assets/luzne_tloki_logo.jpg")
const LOGO_BACKGROUND_SHADER_CODE := """
shader_type canvas_item;

uniform vec4 logo_color : source_color = vec4(0.62, 0.66, 0.64, 0.22);
uniform float white_cutoff = 0.78;
uniform float softness = 0.20;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float ink = 1.0 - smoothstep(white_cutoff - softness, white_cutoff, luminance);
	COLOR = vec4(logo_color.rgb, logo_color.a * ink * tex.a);
}
"""

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
const PROFILE_BUTTON_WIDTH := 164
const PROFILE_BUTTON_HEIGHT := 54
const PROFILE_PANEL_WIDTH := 282
const PROFILE_PANEL_HEIGHT := 410
const PROFILE_PANEL_LEFT_MARGIN := 18.0
const PROFILE_PANEL_RIGHT_MARGIN := 96.0
const SYSTEM_REPEAT_YEARS_AHEAD := 5
const DEFAULT_EVENT_COLOR_INDEX := 2
const MAX_EVENT_DOTS_ON_TILE := 5
const MONTH_LAYOUT_COUNTS := [1, 4, 6, 12]

const COLOR_PANEL := Color(0.070, 0.085, 0.087, 0.82)
const COLOR_PANEL_SOFT := Color(0.105, 0.120, 0.116, 0.76)
const COLOR_TILE_EMPTY := Color(0.18, 0.22, 0.21, 0.86)
const COLOR_TEXT := Color(0.94, 0.955, 0.925)
const COLOR_TEXT_MUTED := Color(0.76, 0.80, 0.77)
const COLOR_TEXT_DIM := Color(0.54, 0.58, 0.55)
const COLOR_TODAY := Color(0.92, 0.72, 0.38)
const COLOR_HOLIDAY := Color(0.45, 0.80, 0.90, 0.78)
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
const FIXED_POLISH_HOLIDAYS := [
	{"month": 1, "day": 1, "name": "Nowy Rok"},
	{"month": 1, "day": 6, "name": "Święto Trzech Króli / Objawienie Pańskie"},
	{"month": 1, "day": 21, "name": "Dzień Babci"},
	{"month": 1, "day": 22, "name": "Dzień Dziadka"},
	{"month": 2, "day": 2, "name": "Ofiarowanie Pańskie / Matki Boskiej Gromnicznej"},
	{"month": 2, "day": 14, "name": "Walentynki"},
	{"month": 3, "day": 8, "name": "Dzień Kobiet"},
	{"month": 4, "day": 14, "name": "Święto Chrztu Polski"},
	{"month": 5, "day": 1, "name": "Święto Pracy"},
	{"month": 5, "day": 2, "name": "Dzień Flagi RP"},
	{"month": 5, "day": 3, "name": "Święto Konstytucji 3 Maja"},
	{"month": 5, "day": 26, "name": "Dzień Matki"},
	{"month": 6, "day": 1, "name": "Dzień Dziecka"},
	{"month": 6, "day": 23, "name": "Dzień Ojca"},
	{"month": 8, "day": 15, "name": "Wniebowzięcie NMP / Święto Wojska Polskiego"},
	{"month": 9, "day": 30, "name": "Dzień Chłopaka"},
	{"month": 10, "day": 14, "name": "Dzień Edukacji Narodowej"},
	{"month": 11, "day": 1, "name": "Wszystkich Świętych"},
	{"month": 11, "day": 2, "name": "Zaduszki"},
	{"month": 11, "day": 11, "name": "Narodowe Święto Niepodległości"},
	{"month": 11, "day": 30, "name": "Andrzejki"},
	{"month": 12, "day": 6, "name": "Mikołajki"},
	{"month": 12, "day": 24, "name": "Wigilia Bożego Narodzenia"},
	{"month": 12, "day": 25, "name": "Boże Narodzenie - pierwszy dzień"},
	{"month": 12, "day": 26, "name": "Boże Narodzenie - drugi dzień"},
	{"month": 12, "day": 27, "name": "Narodowy Dzień Zwycięskiego Powstania Wielkopolskiego"},
	{"month": 12, "day": 31, "name": "Sylwester"},
]

var current_year: int
var current_month: int
var month_layout_count := 1
var selected_calendar_index := 0
var calendars: Array[Dictionary] = []

var main_scroll: ScrollContainer
var content_root: VBoxContainer
var calendar_root: VBoxContainer
var months_box: VBoxContainer
var month_title_label: Label
var month_layout_option: OptionButton
var calendar_name_label: Label
var profile_overlay: VBoxContainer
var profile_button: Button
var profile_panel: PanelContainer
var today_button: Button
var nav_box: HBoxContainer
var calendar_option: OptionButton
var calendar_status_label: Label
var calendar_delete_dialog: AcceptDialog
var calendar_delete_label: Label
var share_code_label: Label
var join_code_input: LineEdit
var share_status_label: Label
var system_days_panel: PanelContainer
var system_days_toggle_button: Button
var system_record_button: Button
var system_record_status_label: Label
var system_scheme_box: VBoxContainer
var system_scheme_list_box: VBoxContainer
var sharing_panel: PanelContainer
var sharing_toggle_button: Button
var sharing_body: VBoxContainer
var calendar_only_button: Button
var system_days_expanded := false
var sharing_expanded := false
var calendar_only_mode := false
var profile_panel_open := false
var settings_loaded := false

var day_dialog: AcceptDialog
var day_dialog_title: Label
var day_quick_buttons_grid: VBoxContainer
var day_event_form_box: VBoxContainer
var day_event_name_input: LineEdit
var day_event_time_input: LineEdit
var day_event_description_input: TextEdit
var day_event_color_palette: GridContainer
var day_event_color_index := DEFAULT_EVENT_COLOR_INDEX
var day_event_status_label: Label
var day_fixed_button_form_box: VBoxContainer
var day_fixed_name_input: LineEdit
var day_fixed_color_palette: GridContainer
var day_fixed_color_index := 0
var day_fixed_delete_option: OptionButton
var day_fixed_delete_ids: Array[String] = []
var day_fixed_status_label: Label
var day_holiday_label: Label
var day_event_list_label: Label
var day_note_form_box: VBoxContainer
var day_note_edit: TextEdit
var day_save_note_button: Button
var day_clear_button: Button

var system_scheme_name_dialog: AcceptDialog
var system_scheme_name_input: LineEdit
var system_scheme_name_status_label: Label
var system_scheme_delete_dialog: AcceptDialog
var system_scheme_delete_label: Label

var system_days_body: VBoxContainer
var system_day_category_ids: Array[String] = []
var system_day_steps: Array[Dictionary] = []
var system_days_start_key_value := ""
var system_days_recording_active := false
var pending_calendar_delete_id := ""
var pending_system_scheme_delete_id := ""
var system_scheme_event_ids_by_day: Dictionary = {}
var holiday_cache_by_year: Dictionary = {}

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
	settings_loaded = true
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_save_current_view_state()


func _save_current_view_state() -> void:
	if not settings_loaded:
		return
	_save_settings_to_disk()


func _force_portrait() -> void:
	ProjectSettings.set_setting("display/window/handheld/orientation", DisplayServer.SCREEN_PORTRAIT)
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	DisplayServer.window_set_size(Vector2i(720, 1280))


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.025, 0.030, 0.032, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_add_logo_background()

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

	month_layout_option = OptionButton.new()
	month_layout_option.add_item("Układ: 1", 1)
	month_layout_option.add_item("Układ: 4", 4)
	month_layout_option.add_item("Układ: 6", 6)
	month_layout_option.add_item("Układ: 12", 12)
	month_layout_option.item_selected.connect(_on_month_layout_selected)
	_prepare_control(month_layout_option, 14, PROFILE_BUTTON_HEIGHT)
	month_layout_option.custom_minimum_size.x = 158
	month_layout_option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_prepare_large_dropdown(month_layout_option)
	header.add_child(month_layout_option)

	calendar_name_label = _make_label("", 30, COLOR_TEXT)
	calendar_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calendar_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(calendar_name_label)

	_add_profile_overlay()

	today_button = Button.new()
	today_button.text = "Wróć do aktualnej daty"
	_prepare_control(today_button, 18, 52)
	_connect_tap(today_button, Callable(self, "_return_to_today"))
	screen_root.add_child(today_button)

	nav_box = HBoxContainer.new()
	nav_box.add_theme_constant_override("separation", 8)
	screen_root.add_child(nav_box)

	var previous_button := _make_nav_button("<")
	_connect_tap(previous_button, Callable(self, "_previous_month"))
	nav_box.add_child(previous_button)

	month_title_label = _make_label("", 32, COLOR_TEXT)
	month_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	month_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_box.add_child(month_title_label)

	var next_button := _make_nav_button(">")
	_connect_tap(next_button, Callable(self, "_next_month"))
	nav_box.add_child(next_button)

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

	system_days_panel = _build_system_days_panel()
	content_root.add_child(system_days_panel)

	sharing_panel = _build_sharing_panel()
	content_root.add_child(sharing_panel)

	calendar_only_button = Button.new()
	calendar_only_button.text = "Pokaż tylko kalendarz"
	_prepare_control(calendar_only_button, 18, 56)
	_connect_tap(calendar_only_button, Callable(self, "_toggle_calendar_only_mode"))
	content_root.add_child(calendar_only_button)

	_style_main_scrollbar()
	_build_day_dialog()
	_build_system_scheme_name_dialog()
	_build_system_scheme_delete_dialog()
	_build_calendar_delete_dialog()
	_sync_content_width()


func _add_logo_background() -> void:
	var logo := TextureRect.new()
	logo.texture = LOGO_BACKGROUND_TEXTURE
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)

	var logo_shader := Shader.new()
	logo_shader.code = LOGO_BACKGROUND_SHADER_CODE
	var logo_material := ShaderMaterial.new()
	logo_material.shader = logo_shader
	logo.material = logo_material

	add_child(logo)


func _add_profile_overlay() -> void:
	profile_overlay = VBoxContainer.new()
	profile_overlay.anchor_left = 1.0
	profile_overlay.anchor_right = 1.0
	profile_overlay.anchor_top = 0.0
	profile_overlay.anchor_bottom = 0.0
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
	_sync_profile_overlay_bounds()
	resized.connect(_sync_profile_overlay_bounds)
	_set_profile_panel_visible(false)


func _sync_profile_overlay_bounds() -> void:
	if profile_overlay == null:
		return

	var viewport_width := get_viewport_rect().size.x
	var available_width: float = maxf(240.0, viewport_width - PROFILE_PANEL_LEFT_MARGIN - PROFILE_PANEL_RIGHT_MARGIN)
	var panel_width: float = minf(float(PROFILE_PANEL_WIDTH), available_width)

	profile_overlay.offset_left = -panel_width - PROFILE_PANEL_RIGHT_MARGIN
	profile_overlay.offset_right = -PROFILE_PANEL_RIGHT_MARGIN
	profile_overlay.offset_top = PROFILE_BUTTON_TOP
	profile_overlay.offset_bottom = PROFILE_BUTTON_TOP + PROFILE_BUTTON_HEIGHT + PROFILE_PANEL_HEIGHT
	if profile_panel != null:
		profile_panel.custom_minimum_size.x = panel_width


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
	delete_button.text = "Usuń wybrany profil"
	_prepare_control(delete_button, 16, 46)
	_connect_tap(delete_button, Callable(self, "_confirm_delete_selected_calendar"))
	box.add_child(delete_button)

	calendar_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	calendar_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(calendar_status_label)

	return panel


func _build_system_days_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	system_days_toggle_button = _make_panel_toggle_button("Schematy cykliczne", Callable(self, "_toggle_system_days_panel"))
	box.add_child(system_days_toggle_button)

	system_days_body = VBoxContainer.new()
	system_days_body.visible = system_days_expanded
	system_days_body.add_theme_constant_override("separation", 10)
	box.add_child(system_days_body)

	system_record_button = Button.new()
	system_record_button.text = "Wprowadzanie systemu cyklicznego"
	_prepare_control(system_record_button, 18, 54)
	_connect_tap(system_record_button, Callable(self, "_toggle_system_days_recording"))
	system_days_body.add_child(system_record_button)

	system_record_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	system_record_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	system_days_body.add_child(system_record_status_label)

	var edit_row := HBoxContainer.new()
	edit_row.add_theme_constant_override("separation", 8)
	system_days_body.add_child(edit_row)

	var undo_button := Button.new()
	undo_button.text = "Cofnij ostatni"
	_prepare_control(undo_button, 16, 48)
	_connect_tap(undo_button, Callable(self, "_undo_system_day_step"))
	edit_row.add_child(undo_button)

	var clear_button := Button.new()
	clear_button.text = "Wyczyść schematy"
	_prepare_control(clear_button, 16, 48)
	_connect_tap(clear_button, Callable(self, "_clear_system_days"))
	edit_row.add_child(clear_button)

	var apply_button := Button.new()
	apply_button.text = "Zastosuj jako schemat cykliczny"
	_prepare_control(apply_button, 18, 54)
	_connect_tap(apply_button, Callable(self, "_apply_system_days_to_year"))
	system_days_body.add_child(apply_button)

	system_scheme_box = VBoxContainer.new()
	system_scheme_box.visible = false
	system_scheme_box.add_theme_constant_override("separation", 8)
	system_days_body.add_child(system_scheme_box)

	system_scheme_list_box = VBoxContainer.new()
	system_scheme_list_box.add_theme_constant_override("separation", 8)
	system_scheme_box.add_child(system_scheme_list_box)

	return panel


func _build_sharing_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	sharing_toggle_button = _make_panel_toggle_button("Udostępnij kalendarz", Callable(self, "_toggle_sharing_panel"))
	box.add_child(sharing_toggle_button)

	sharing_body = VBoxContainer.new()
	sharing_body.visible = sharing_expanded
	sharing_body.add_theme_constant_override("separation", 10)
	box.add_child(sharing_body)

	share_code_label = _make_label("", 18, COLOR_TEXT)
	share_code_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sharing_body.add_child(share_code_label)

	var generate_button := Button.new()
	generate_button.text = "Generuj kod/link"
	_prepare_control(generate_button, 18, 54)
	_connect_tap(generate_button, Callable(self, "_generate_share_code"))
	sharing_body.add_child(generate_button)

	join_code_input = LineEdit.new()
	join_code_input.placeholder_text = "Wklej kod wspólnego kalendarza"
	_prepare_control(join_code_input, 18, 54)
	sharing_body.add_child(join_code_input)

	var join_button := Button.new()
	join_button.text = "Dołącz do kalendarza"
	_prepare_control(join_button, 18, 54)
	_connect_tap(join_button, Callable(self, "_join_calendar_by_code"))
	sharing_body.add_child(join_button)

	share_status_label = _make_label("Na razie kod przygotowuje kalendarz grupowy lokalnie. Synchronizacja online będzie kolejnym krokiem.", 14, COLOR_TEXT_MUTED)
	share_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sharing_body.add_child(share_status_label)

	return panel


func _build_system_scheme_name_dialog() -> void:
	system_scheme_name_dialog = AcceptDialog.new()
	system_scheme_name_dialog.title = ""
	system_scheme_name_dialog.borderless = true
	system_scheme_name_dialog.min_size = Vector2i(540, 300)
	add_child(system_scheme_name_dialog)
	system_scheme_name_dialog.get_ok_button().visible = false

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	system_scheme_name_dialog.add_child(box)

	_add_dialog_header(box, "Nazwa schematu", Callable(self, "_close_system_scheme_name_dialog"))

	var prompt := _make_label("Jak chcesz nazwać ten schemat?", 18, COLOR_TEXT)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(prompt)

	system_scheme_name_input = LineEdit.new()
	system_scheme_name_input.placeholder_text = "Np. Praca 6/1/6/8"
	_prepare_control(system_scheme_name_input, 18, 54)
	box.add_child(system_scheme_name_input)

	var save_button := Button.new()
	save_button.text = "Zapisz schemat"
	_prepare_control(save_button, 18, 54)
	_connect_tap(save_button, Callable(self, "_save_named_system_scheme"))
	box.add_child(save_button)

	system_scheme_name_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	system_scheme_name_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(system_scheme_name_status_label)


func _build_system_scheme_delete_dialog() -> void:
	system_scheme_delete_dialog = AcceptDialog.new()
	system_scheme_delete_dialog.title = ""
	system_scheme_delete_dialog.borderless = true
	system_scheme_delete_dialog.min_size = Vector2i(560, 300)
	add_child(system_scheme_delete_dialog)
	system_scheme_delete_dialog.get_ok_button().visible = false

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	system_scheme_delete_dialog.add_child(box)

	_add_dialog_header(box, "Usuń schemat", Callable(self, "_close_system_scheme_delete_dialog"))

	system_scheme_delete_label = _make_label("", 18, COLOR_TEXT)
	system_scheme_delete_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(system_scheme_delete_label)

	var delete_button := Button.new()
	delete_button.text = "Tak, usuń cały schemat"
	_prepare_control(delete_button, 18, 56)
	_connect_tap(delete_button, Callable(self, "_delete_applied_system_scheme_confirmed"))
	box.add_child(delete_button)

	var cancel_button := Button.new()
	cancel_button.text = "Anuluj"
	_prepare_control(cancel_button, 18, 54)
	_connect_tap(cancel_button, Callable(self, "_close_system_scheme_delete_dialog"))
	box.add_child(cancel_button)


func _build_calendar_delete_dialog() -> void:
	calendar_delete_dialog = AcceptDialog.new()
	calendar_delete_dialog.title = ""
	calendar_delete_dialog.borderless = true
	calendar_delete_dialog.min_size = Vector2i(560, 310)
	add_child(calendar_delete_dialog)
	calendar_delete_dialog.get_ok_button().visible = false

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	calendar_delete_dialog.add_child(box)

	_add_dialog_header(box, "Usuń profil", Callable(self, "_close_calendar_delete_dialog"))

	calendar_delete_label = _make_label("", 18, COLOR_TEXT)
	calendar_delete_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(calendar_delete_label)

	var delete_button := Button.new()
	delete_button.text = "Tak, usuń profil"
	_prepare_control(delete_button, 18, 56)
	_connect_tap(delete_button, Callable(self, "_delete_selected_calendar_confirmed"))
	box.add_child(delete_button)

	var cancel_button := Button.new()
	cancel_button.text = "Anuluj"
	_prepare_control(cancel_button, 18, 54)
	_connect_tap(cancel_button, Callable(self, "_close_calendar_delete_dialog"))
	box.add_child(cancel_button)


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

	day_quick_buttons_grid = VBoxContainer.new()
	day_quick_buttons_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_quick_buttons_grid.add_theme_constant_override("separation", 8)
	box.add_child(day_quick_buttons_grid)

	var add_event_button := Button.new()
	add_event_button.text = "Dodaj wydarzenie"
	_prepare_control(add_event_button, 18, 54)
	_connect_tap(add_event_button, Callable(self, "_toggle_day_event_form"))
	box.add_child(add_event_button)

	var add_fixed_button := Button.new()
	add_fixed_button.text = "+"
	_prepare_control(add_fixed_button, 30, 58)
	_connect_tap(add_fixed_button, Callable(self, "_toggle_day_fixed_button_form"))
	box.add_child(add_fixed_button)

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
	save_fixed_button.text = "Zapisz i ustaw ten dzień"
	_prepare_control(save_fixed_button, 18, 52)
	_connect_tap(save_fixed_button, Callable(self, "_save_fixed_button"))
	day_fixed_button_form_box.add_child(save_fixed_button)

	day_fixed_status_label = _make_label("", 14, COLOR_TEXT_MUTED)
	day_fixed_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_fixed_button_form_box.add_child(day_fixed_status_label)

	day_holiday_label = _make_label("", 22, COLOR_TEXT)
	day_holiday_label.visible = false
	day_holiday_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_holiday_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
	day_holiday_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	day_holiday_label.add_theme_constant_override("outline_size", 2)
	day_holiday_label.add_theme_constant_override("shadow_offset_x", 1)
	day_holiday_label.add_theme_constant_override("shadow_offset_y", 2)
	box.add_child(day_holiday_label)

	day_event_list_label = _make_label("", 16, COLOR_TEXT_MUTED)
	day_event_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(day_event_list_label)

	day_clear_button = Button.new()
	day_clear_button.text = "Wyczyść ten dzień"
	_prepare_control(day_clear_button, 18, 52)
	_connect_tap(day_clear_button, Callable(self, "_clear_selected_day"))
	box.add_child(day_clear_button)

	var note_button := Button.new()
	note_button.text = "Dodaj notatkę"
	_prepare_control(note_button, 18, 52)
	_connect_tap(note_button, Callable(self, "_toggle_day_note_form"))
	box.add_child(note_button)

	day_note_form_box = VBoxContainer.new()
	day_note_form_box.visible = false
	day_note_form_box.add_theme_constant_override("separation", 8)
	box.add_child(day_note_form_box)

	day_note_form_box.add_child(_make_label("Notatka / opis", 14, COLOR_TEXT_MUTED))

	day_note_edit = TextEdit.new()
	day_note_edit.custom_minimum_size.y = 90
	day_note_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_note_edit.add_theme_font_size_override("font_size", 17)
	day_note_edit.add_theme_color_override("font_color", COLOR_TEXT)
	day_note_edit.add_theme_color_override("font_placeholder_color", COLOR_TEXT_DIM)
	day_note_edit.add_theme_stylebox_override("normal", _control_style(Color(0.90, 0.94, 0.90, 0.10)))
	day_note_form_box.add_child(day_note_edit)

	day_save_note_button = Button.new()
	day_save_note_button.text = "Zapisz notatkę"
	_prepare_control(day_save_note_button, 18, 52)
	_connect_tap(day_save_note_button, Callable(self, "_save_selected_day_note"))
	day_note_form_box.add_child(day_save_note_button)

	var close_day_button := Button.new()
	close_day_button.text = "Zamknij"
	_prepare_control(close_day_button, 18, 52)
	_connect_tap(close_day_button, Callable(self, "_close_day_dialog"))
	box.add_child(close_day_button)


func _refresh_all() -> void:
	_ensure_calendar_exists()
	selected_calendar_index = clampi(selected_calendar_index, 0, calendars.size() - 1)
	_load_system_days_from_calendar()
	_refresh_profile_ui()
	_refresh_category_ui()
	_refresh_month_layout_option()
	_refresh_month_title()
	_rebuild_calendar()
	_refresh_sharing_ui()
	_refresh_system_days_ui()
	_apply_main_view_mode()


func _refresh_month_title() -> void:
	if month_title_label != null:
		match month_layout_count:
			12:
				month_title_label.text = "%d" % current_year
			4, 6:
				month_title_label.text = "%s %d - %d mies." % [MONTH_NAMES[current_month - 1], current_year, month_layout_count]
			_:
				month_title_label.text = "%s %d" % [MONTH_NAMES[current_month - 1], current_year]
	if calendar_name_label != null:
		calendar_name_label.text = ""


func _refresh_month_layout_option() -> void:
	if month_layout_option == null:
		return

	month_layout_count = _normalized_month_layout_count(month_layout_count)
	for index in range(month_layout_option.get_item_count()):
		if month_layout_option.get_item_id(index) == month_layout_count:
			month_layout_option.select(index)
			return


func _rebuild_calendar() -> void:
	if months_box == null:
		return

	_rebuild_system_scheme_event_cache()
	for child in months_box.get_children():
		child.queue_free()

	month_layout_count = _normalized_month_layout_count(month_layout_count)
	if month_layout_count == 1:
		months_box.add_child(_make_month_section(current_year, current_month, false, false, false))
		return

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 16)
	months_box.add_child(grid)

	for month_data in _visible_months():
		grid.add_child(_make_month_card(
			int(month_data["year"]),
			int(month_data["month"]),
			month_layout_count == 12
		))


func _visible_months() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if month_layout_count == 12:
		for month in range(1, 13):
			result.append({"year": current_year, "month": month})
		return result

	for offset in range(month_layout_count):
		result.append(_month_from_offset(current_year, current_month, offset))
	return result


func _month_from_offset(year: int, month: int, offset: int) -> Dictionary:
	var absolute_month := year * 12 + month - 1 + offset
	return {
		"year": int(absolute_month / 12),
		"month": absolute_month % 12 + 1,
	}


func _make_month_card(year: int, month: int, year_overview: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _month_card_style())
	card.add_child(_make_month_section(year, month, true, true, year_overview))
	return card


func _make_month_section(year: int, month: int, show_title: bool, compact: bool, year_overview: bool) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 7 if compact else 14)

	if show_title:
		var title := _make_label("%s %d" % [MONTH_NAMES[month - 1], year], 15 if year_overview else 17, COLOR_TEXT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_child(title)

	var grid := GridContainer.new()
	grid.columns = TILE_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 3 if compact else 8)
	grid.add_theme_constant_override("v_separation", 3 if compact else 10)
	section.add_child(grid)

	var first_offset := _month_start_weekday_monday(year, month)
	for _offset in range(first_offset):
		grid.add_child(_make_day_spacer(year, month, compact, year_overview))

	var days_current := _days_in_month(year, month)
	for day in range(1, days_current + 1):
		grid.add_child(_make_day_cell(year, month, day, compact, year_overview))

	return section


func _make_day_cell(year: int, month: int, day: int, compact: bool, year_overview: bool) -> Button:
	var key := _date_key(year, month, day)
	var event_ids := _event_ids_for_day(key)
	var detail_events := _event_details_for_day(key)
	var has_note := _notes().has(key) and String(_notes()[key]).strip_edges() != ""
	var is_today := _is_today(year, month, day)
	var has_holiday := not _holiday_names_for_day(year, month, day).is_empty()
	var color := _color_for_day(event_ids)

	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, _day_tile_height(compact, year_overview))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _tile_style(color, is_today, not event_ids.is_empty() or not detail_events.is_empty() or has_note, has_holiday))
	button.add_theme_stylebox_override("hover", _tile_style(color.lightened(0.06), is_today, true, has_holiday))
	button.add_theme_stylebox_override("pressed", _tile_style(color.darkened(0.08), is_today, true, has_holiday))
	button.add_theme_stylebox_override("focus", _tile_style(color, true, true, has_holiday))
	_fill_day_tile(button, year, month, day, event_ids, detail_events, has_note, compact, year_overview)
	if compact or year_overview:
		_connect_tap(button, Callable(self, "_open_single_month_from_overview").bind(year, month))
	else:
		_connect_tap(button, Callable(self, "_open_day_dialog").bind(year, month, day))
	return button


func _make_day_spacer(year: int, month: int, compact: bool, year_overview: bool) -> Control:
	if compact or year_overview:
		var spacer_button := Button.new()
		spacer_button.text = ""
		spacer_button.custom_minimum_size = Vector2(0, _day_tile_height(compact, year_overview))
		spacer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer_button.focus_mode = Control.FOCUS_NONE
		spacer_button.add_theme_stylebox_override("normal", _tile_style(Color(0.90, 0.93, 0.88, 0.05), false, false))
		spacer_button.add_theme_stylebox_override("hover", _tile_style(Color(0.90, 0.93, 0.88, 0.08), false, false))
		spacer_button.add_theme_stylebox_override("pressed", _tile_style(Color(0.90, 0.93, 0.88, 0.12), false, true))
		_connect_tap(spacer_button, Callable(self, "_open_single_month_from_overview").bind(year, month))
		return spacer_button

	var spacer := Panel.new()
	spacer.custom_minimum_size = Vector2(0, _day_tile_height(compact, year_overview))
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.add_theme_stylebox_override("panel", _tile_style(Color(0.90, 0.93, 0.88, 0.05), false, false))
	return spacer


func _day_tile_height(compact: bool, year_overview: bool) -> int:
	if year_overview:
		return 34
	if compact:
		return 46
	return 84


func _fill_day_tile(button: Button, year: int, month: int, day: int, event_ids: Array, detail_events: Array, has_note: bool, compact: bool, year_overview: bool) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 3 if compact else 6)
	margin.add_theme_constant_override("margin_right", 3 if compact else 6)
	margin.add_theme_constant_override("margin_top", 2 if compact else 7)
	margin.add_theme_constant_override("margin_bottom", 2 if compact else 6)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	var day_label := _tile_label(str(day), 13 if year_overview else (16 if compact else 26), COLOR_TEXT)
	box.add_child(day_label)

	if not year_overview:
		var weekday_label := _tile_label(WEEKDAY_SHORT_TILE[_weekday_monday_index(year, month, day)], 9 if compact else 13, COLOR_TEXT_MUTED)
		box.add_child(weekday_label)

	var marker_text := _marker_text(event_ids, has_note)
	if marker_text != "" and not year_overview:
		box.add_child(_tile_label(marker_text, 7 if compact else 10, COLOR_TEXT))

	_add_event_dots_to_tile(box, detail_events, compact or year_overview)


func _marker_text(event_ids: Array, has_note: bool) -> String:
	var parts: Array[String] = []
	for event_id in event_ids:
		var category: Dictionary = _category_by_id(String(event_id))
		if category.is_empty():
			continue
		parts.append(String(category.get("name", "")))
	if has_note:
		parts.append("notatka")
	if parts.is_empty():
		return ""
	return ", ".join(parts).left(18)


func _add_event_dots_to_tile(box: VBoxContainer, detail_events: Array, compact: bool) -> void:
	var colors: Array[int] = []
	for item in detail_events:
		if not (item is Dictionary):
			continue
		var detail: Dictionary = item as Dictionary
		var name := String(detail.get("name", "")).strip_edges()
		if name == "":
			continue
		colors.append(int(detail.get("color", DEFAULT_EVENT_COLOR_INDEX)))
		if colors.size() >= MAX_EVENT_DOTS_ON_TILE:
			break

	if colors.is_empty():
		return

	var dots := HBoxContainer.new()
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 3)
	box.add_child(dots)

	for color_index in colors:
		var dot := Panel.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot_size := 6 if compact else 9
		dot.custom_minimum_size = Vector2(dot_size, dot_size)
		dot.add_theme_stylebox_override("panel", _event_dot_style(_category_color(color_index)))
		dots.add_child(dot)


func _open_day_dialog(year: int, month: int, day: int) -> void:
	selected_day_year = year
	selected_day_month = month
	selected_day_number = day
	selected_day_key = _date_key(year, month, day)
	if system_days_recording_active:
		_record_selected_day_for_system()
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
	if day_note_form_box != null:
		day_note_form_box.visible = false
	day_event_color_index = DEFAULT_EVENT_COLOR_INDEX
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

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		day_quick_buttons_grid.add_child(row)

		var quick_button := Button.new()
		quick_button.text = "Ten dzień = %s" % String(category.get("name", ""))
		_prepare_control(quick_button, 18, 58)
		_style_category_button(quick_button, int(category.get("color", 0)))
		_connect_tap(quick_button, Callable(self, "_add_quick_category_to_selected_day").bind(category_id))
		row.add_child(quick_button)

		var delete_button := Button.new()
		delete_button.text = "Kosz"
		_prepare_control(delete_button, 14, 58)
		delete_button.custom_minimum_size.x = 76
		delete_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		_connect_tap(delete_button, Callable(self, "_delete_fixed_button_by_id").bind(category_id))
		row.add_child(delete_button)

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
	var has_holidays := _refresh_day_holiday_label()
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
		day_event_list_label.text = "Brak innych wpisów." if has_holidays else "Ten dzień jest pusty."
	else:
		day_event_list_label.text = "Wpisy:\n%s" % "\n".join(lines)


func _refresh_day_holiday_label() -> bool:
	if day_holiday_label == null:
		return false

	var holiday_names := _holiday_names_for_day(selected_day_year, selected_day_month, selected_day_number)
	if holiday_names.is_empty():
		day_holiday_label.text = ""
		day_holiday_label.visible = false
		return false

	var lines: Array[String] = []
	for holiday_name in holiday_names:
		lines.append("ŚWIĘTO: %s" % holiday_name)
	day_holiday_label.text = "\n".join(lines)
	day_holiday_label.visible = true
	return true


func _add_quick_category_to_selected_day(category_id: String) -> void:
	if selected_day_key == "":
		return

	_add_category_id_to_day(selected_day_key, category_id)
	_append_category_to_system_from_selected_day(category_id)
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()


func _refresh_system_days_ui() -> void:
	if system_days_body == null:
		return
	if system_record_button != null:
		system_record_button.text = "Zakończ dodawanie i zastosuj" if system_days_recording_active else "Wprowadzanie systemu cyklicznego"
	if system_record_status_label != null:
		system_record_status_label.text = _system_recording_status_text()
	_refresh_applied_system_scheme_ui()
	_refresh_collapsible_panels()


func _refresh_applied_system_scheme_ui() -> void:
	if system_scheme_box == null or system_scheme_list_box == null:
		return

	for child in system_scheme_list_box.get_children():
		child.queue_free()

	var schemes: Array = _applied_system_schemes()
	system_scheme_box.visible = not schemes.is_empty()
	if schemes.is_empty():
		return

	var title := _make_label("Dodane schematy", 16, COLOR_TEXT_MUTED)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	system_scheme_list_box.add_child(title)
	for index in range(schemes.size()):
		if not (schemes[index] is Dictionary):
			continue
		_add_system_scheme_row(system_scheme_list_box, schemes[index] as Dictionary, index + 1)


func _add_system_scheme_row(parent: VBoxContainer, scheme: Dictionary, number: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	parent.add_child(row)

	var scheme_id := String(scheme.get("id", ""))
	var label := _make_label(_system_scheme_display_name(scheme, number), 15, COLOR_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var show_check := CheckBox.new()
	show_check.text = "Pokaż"
	show_check.button_pressed = bool(scheme.get("visible", true))
	show_check.custom_minimum_size = Vector2(112, 48)
	show_check.size_flags_horizontal = Control.SIZE_SHRINK_END
	show_check.focus_mode = Control.FOCUS_NONE
	show_check.add_theme_font_size_override("font_size", 15)
	show_check.add_theme_color_override("font_color", COLOR_TEXT)
	show_check.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	show_check.add_theme_color_override("font_hover_color", COLOR_TEXT)
	show_check.toggled.connect(Callable(self, "_set_applied_system_scheme_visible").bind(scheme_id))
	row.add_child(show_check)

	var delete_button := Button.new()
	delete_button.text = "Usuń"
	_prepare_control(delete_button, 15, 48)
	delete_button.custom_minimum_size.x = 86
	delete_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_connect_tap(delete_button, Callable(self, "_confirm_delete_applied_system_scheme").bind(scheme_id))
	row.add_child(delete_button)


func _refresh_collapsible_panels() -> void:
	if system_days_body != null:
		system_days_body.visible = system_days_expanded and not calendar_only_mode
	if sharing_body != null:
		sharing_body.visible = sharing_expanded and not calendar_only_mode

	if system_days_toggle_button != null:
		system_days_toggle_button.text = "Schematy cykliczne - schowaj" if system_days_expanded else "Schematy cykliczne - otwórz"
	if sharing_toggle_button != null:
		sharing_toggle_button.text = "Udostępnij kalendarz - schowaj" if sharing_expanded else "Udostępnij kalendarz - otwórz"


func _toggle_system_days_panel() -> void:
	system_days_expanded = not system_days_expanded
	_refresh_collapsible_panels()
	_save_settings_to_disk()


func _toggle_sharing_panel() -> void:
	sharing_expanded = not sharing_expanded
	_refresh_collapsible_panels()
	_save_settings_to_disk()


func _toggle_calendar_only_mode() -> void:
	calendar_only_mode = not calendar_only_mode
	_apply_main_view_mode()
	_save_settings_to_disk()


func _apply_main_view_mode() -> void:
	if system_days_panel != null:
		system_days_panel.visible = not calendar_only_mode
	if sharing_panel != null:
		sharing_panel.visible = not calendar_only_mode
	if month_layout_option != null:
		month_layout_option.visible = true
	if profile_overlay != null:
		profile_overlay.visible = not calendar_only_mode
	if profile_panel != null:
		profile_panel.visible = profile_panel_open and not calendar_only_mode
	if today_button != null:
		today_button.visible = true
	if calendar_only_button != null:
		calendar_only_button.text = "Pokaż opcje" if calendar_only_mode else "Pokaż tylko kalendarz"
	_refresh_collapsible_panels()


func _normalized_month_layout_count(value: int) -> int:
	if MONTH_LAYOUT_COUNTS.has(value):
		return value
	return 1


func _on_month_layout_selected(index: int) -> void:
	if month_layout_option == null:
		return

	month_layout_count = _normalized_month_layout_count(month_layout_option.get_item_id(index))
	if month_layout_count == 12:
		current_month = 1
	_refresh_month_title()
	_rebuild_calendar()
	_save_settings_to_disk()


func _close_system_scheme_name_dialog() -> void:
	if system_scheme_name_dialog != null:
		system_scheme_name_dialog.hide()


func _close_system_scheme_delete_dialog() -> void:
	if system_scheme_delete_dialog != null:
		system_scheme_delete_dialog.hide()


func _close_calendar_delete_dialog() -> void:
	pending_calendar_delete_id = ""
	if calendar_delete_dialog != null:
		calendar_delete_dialog.hide()


func _open_single_month_from_overview(year: int, month: int) -> void:
	current_year = year
	current_month = clampi(month, 1, 12)
	month_layout_count = 1
	_refresh_month_layout_option()
	_refresh_month_title()
	_rebuild_calendar()
	if main_scroll != null:
		main_scroll.set_deferred("scroll_vertical", 0)
	_save_settings_to_disk()


func _toggle_system_days_recording() -> void:
	if system_days_recording_active:
		_finish_system_days_recording()
		return

	system_days_recording_active = true
	system_day_steps.clear()
	system_day_category_ids.clear()
	system_days_start_key_value = ""
	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_refresh_system_days_ui()


func _finish_system_days_recording() -> void:
	if system_day_steps.is_empty():
		system_days_recording_active = false
		_save_settings_to_disk()
		_refresh_system_days_ui()
		return

	system_days_recording_active = false
	_apply_system_days_to_year()


func _append_category_to_system_from_selected_day(_category_id: String) -> void:
	if not system_days_recording_active or selected_day_key == "":
		return

	_record_selected_day_for_system()


func _record_selected_day_for_system() -> void:
	if selected_day_key == "":
		return

	var step := {
		"key": selected_day_key,
		"category_ids": _manual_category_ids_for_day(selected_day_key),
	}
	var updated := false
	for index in range(system_day_steps.size()):
		if String(system_day_steps[index].get("key", "")) == selected_day_key:
			system_day_steps[index] = step
			updated = true
			break
	if not updated:
		system_day_steps.append(step)

	if system_day_steps.size() == 1:
		system_days_start_key_value = selected_day_key
	_rebuild_legacy_system_day_ids()
	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_refresh_system_days_ui()


func _undo_system_day_step() -> void:
	if not system_day_steps.is_empty():
		system_day_steps.remove_at(system_day_steps.size() - 1)
	_rebuild_legacy_system_day_ids()
	if system_day_steps.is_empty():
		system_days_start_key_value = ""
	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_refresh_system_days_ui()


func _clear_system_days() -> void:
	var calendar := _selected_calendar()
	for item in _applied_system_schemes():
		if item is Dictionary:
			_remove_scheme_marks_from_calendar_events(calendar, item as Dictionary)
	calendar["applied_system_schemes"] = []
	calendar["applied_system_scheme"] = {}
	system_scheme_event_ids_by_day.clear()
	system_day_category_ids.clear()
	system_day_steps.clear()
	system_days_start_key_value = ""
	system_days_recording_active = false
	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()
	_refresh_system_days_ui()


func _apply_system_days_to_year() -> void:
	if system_day_steps.is_empty():
		return

	var start_date := _date_from_string(_system_days_start_key())
	if start_date.is_empty():
		return
	system_days_recording_active = false

	if system_scheme_name_input != null:
		system_scheme_name_input.text = ""
		system_scheme_name_input.placeholder_text = "Np. Schemat %d" % (_applied_system_schemes().size() + 1)
	if system_scheme_name_status_label != null:
		system_scheme_name_status_label.text = ""
	if system_scheme_name_dialog != null:
		system_scheme_name_dialog.popup_centered(Vector2i(540, 300))
		if system_scheme_name_input != null:
			system_scheme_name_input.grab_focus()


func _save_named_system_scheme() -> void:
	if system_day_steps.is_empty():
		return

	var scheme_name := ""
	if system_scheme_name_input != null:
		scheme_name = system_scheme_name_input.text.strip_edges()
	if scheme_name == "":
		if system_scheme_name_status_label != null:
			system_scheme_name_status_label.text = "Wpisz nazwę schematu."
		return

	_apply_system_days_with_name(scheme_name)
	_close_system_scheme_name_dialog()


func _apply_system_days_with_name(scheme_name: String) -> void:
	var start_date := _date_from_string(_system_days_start_key())
	if start_date.is_empty():
		return
	var pattern_steps := _normalized_current_system_steps()
	if pattern_steps.is_empty():
		return

	var start_year := int(start_date["year"])
	var start_month := int(start_date["month"])
	var start_day := int(start_date["day"])
	var start_unix := _unix_from_date(start_year, start_month, start_day)
	var end_year := start_year + SYSTEM_REPEAT_YEARS_AHEAD
	var end_unix := _unix_from_date(end_year, 12, 31)
	var total_days := int((end_unix - start_unix) / 86400) + 1
	if total_days <= 0:
		return

	var applied_days: Array[Dictionary] = []
	for offset in range(total_days):
		var pattern_step: Dictionary = pattern_steps[offset % pattern_steps.size()]
		var category_ids := _category_ids_from_system_step(pattern_step)
		var date := Time.get_datetime_dict_from_unix_time(start_unix + offset * 86400)
		var key := _date_key(int(date["year"]), int(date["month"]), int(date["day"]))
		for category_id in category_ids:
			var category: Dictionary = _category_by_id(category_id)
			if category.is_empty() or _is_category_hidden(category):
				continue
			applied_days.append({
				"key": key,
				"category_ids": [category_id],
			})

	var calendar := _selected_calendar()
	var scheme: Dictionary = {
		"id": _new_id("scheme"),
		"name": scheme_name,
		"visible": true,
		"start": _system_days_start_key(),
		"end": _date_key(end_year, 12, 31),
		"system_days": pattern_steps.duplicate(true),
		"days": applied_days,
	}
	var schemes: Array = _applied_system_schemes()
	schemes.append(scheme)
	calendar["applied_system_schemes"] = schemes
	calendar["applied_system_scheme"] = {}
	system_day_category_ids.clear()
	system_day_steps.clear()
	system_days_start_key_value = ""
	system_days_recording_active = false
	_save_system_days_to_calendar()
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()
	_refresh_system_days_ui()


func _confirm_delete_applied_system_scheme(scheme_id: String = "") -> void:
	var scheme: Dictionary = _find_applied_system_scheme(scheme_id)
	var scheme_name := String(scheme.get("name", "")).strip_edges()
	if scheme_name == "":
		return

	pending_system_scheme_delete_id = scheme_id
	if system_scheme_delete_label != null:
		system_scheme_delete_label.text = "Czy na pewno usunąć cały schemat \"%s\" z kalendarza?" % scheme_name
	if system_scheme_delete_dialog != null:
		system_scheme_delete_dialog.popup_centered(Vector2i(560, 300))


func _delete_applied_system_scheme_confirmed() -> void:
	_remove_applied_system_scheme_by_id(pending_system_scheme_delete_id, false)
	pending_system_scheme_delete_id = ""
	_close_system_scheme_delete_dialog()


func _set_applied_system_scheme_visible(visible: bool, scheme_id: String) -> void:
	var schemes: Array = _applied_system_schemes()
	for index in range(schemes.size()):
		if not (schemes[index] is Dictionary):
			continue
		var scheme: Dictionary = schemes[index] as Dictionary
		if String(scheme.get("id", "")) != scheme_id:
			continue
		scheme["visible"] = visible
		schemes[index] = scheme
		_save_settings_to_disk()
		_rebuild_calendar()
		_refresh_day_event_list()
		_refresh_system_days_ui()
		return


func _find_applied_system_scheme(scheme_id: String) -> Dictionary:
	for item in _applied_system_schemes():
		if not (item is Dictionary):
			continue
		var scheme: Dictionary = item as Dictionary
		if String(scheme.get("id", "")) == scheme_id:
			return scheme
	return {}


func _remove_applied_system_scheme_by_id(scheme_id: String, clear_current_steps: bool = false) -> void:
	if scheme_id == "":
		return

	var calendar := _selected_calendar()
	var schemes: Array = _applied_system_schemes()
	var clean_schemes: Array = []
	var removed := false
	for item in schemes:
		if not (item is Dictionary):
			continue
		var scheme: Dictionary = item as Dictionary
		if String(scheme.get("id", "")) == scheme_id:
			_remove_scheme_marks_from_calendar_events(calendar, scheme)
			removed = true
		else:
			clean_schemes.append(scheme)

	if not removed:
		return

	calendar["applied_system_schemes"] = clean_schemes
	calendar["applied_system_scheme"] = {}
	if clear_current_steps:
		system_day_category_ids.clear()
		system_day_steps.clear()
		system_days_start_key_value = ""
		_save_system_days_to_calendar()
	_save_settings_to_disk()
	_rebuild_calendar()
	_refresh_day_event_list()
	_refresh_system_days_ui()


func _system_scheme_display_name(scheme: Dictionary, number: int) -> String:
	var scheme_name := String(scheme.get("name", "")).strip_edges()
	if scheme_name == "":
		scheme_name = "Schemat %d" % number
	return "%d. %s" % [number, scheme_name]


func _system_days_start_key() -> String:
	if system_days_start_key_value != "":
		return system_days_start_key_value
	if not system_day_steps.is_empty():
		var first_step: Dictionary = system_day_steps[0]
		var first_key := String(first_step.get("key", ""))
		if first_key != "":
			return first_key
	return _date_key(current_year, current_month, 1)


func _load_system_days_from_calendar() -> void:
	system_day_category_ids.clear()
	system_day_steps.clear()
	system_days_recording_active = false
	system_days_start_key_value = String(_selected_calendar().get("system_days_start", ""))
	var legacy_offset := 0
	for item in _system_days():
		if item is Dictionary:
			var step := _normalize_system_day_step(item as Dictionary)
			if not step.is_empty():
				system_day_steps.append(step)
			continue
		var category_id := String(item)
		var category: Dictionary = _category_by_id(category_id)
		if category_id == "" or category.is_empty() or _is_category_hidden(category):
			continue
		var legacy_key := ""
		var start_date := _date_from_string(system_days_start_key_value)
		if not start_date.is_empty():
			legacy_key = _date_key_with_day_offset(int(start_date["year"]), int(start_date["month"]), int(start_date["day"]), legacy_offset)
		system_day_steps.append({
			"key": legacy_key,
			"category_ids": [category_id],
		})
		legacy_offset += 1
	_rebuild_legacy_system_day_ids()
	if system_day_steps.is_empty():
		system_days_start_key_value = ""


func _save_system_days_to_calendar() -> void:
	var calendar := _selected_calendar()
	calendar["system_days"] = system_day_steps.duplicate(true)
	calendar["system_days_start"] = system_days_start_key_value


func _remove_category_from_system_days(category_id: String) -> void:
	if category_id == "":
		return

	var clean_steps: Array[Dictionary] = []
	for item in system_day_steps:
		var step := _normalize_system_day_step(item)
		if step.is_empty():
			continue
		var ids := _category_ids_from_system_step(step)
		ids.erase(category_id)
		step["category_ids"] = ids
		clean_steps.append(step)
	system_day_steps = clean_steps
	_rebuild_legacy_system_day_ids()
	if system_day_steps.is_empty():
		system_days_start_key_value = ""
	_save_system_days_to_calendar()


func _system_recording_status_text() -> String:
	if system_day_steps.is_empty():
		if system_days_recording_active:
			return "Nagrywanie aktywne. Klikaj dni po kolei i ustawiaj ich oznaczenia."
		return "Kliknij wprowadzanie systemu cyklicznego, potem dodawaj dni po kolei."

	var parts: Array[String] = []
	var max_items := mini(system_day_steps.size(), 10)
	for index in range(max_items):
		var step := _normalize_system_day_step(system_day_steps[index])
		var key := String(step.get("key", ""))
		var label := key.substr(8, 2) if key.length() >= 10 else "krok %d" % (index + 1)
		var names := _category_names_for_ids(_category_ids_from_system_step(step))
		if names == "":
			names = "pusto"
		parts.append("%s: %s" % [label, names])
	if system_day_steps.size() > max_items:
		parts.append("...")

	var prefix := "Nagrywanie aktywne. " if system_days_recording_active else ""
	return "%sWzór (%d dni): %s" % [prefix, system_day_steps.size(), " | ".join(parts)]


func _normalized_current_system_steps() -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	for item in system_day_steps:
		var step := _normalize_system_day_step(item)
		if not step.is_empty():
			steps.append(step)
	return steps


func _normalize_system_day_step(value: Dictionary) -> Dictionary:
	var key := String(value.get("key", ""))
	var category_ids := _category_ids_from_system_step(value)
	if key == "" and category_ids.is_empty():
		return {}
	return {
		"key": key,
		"category_ids": category_ids,
	}


func _category_ids_from_system_step(step: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	if step.has("category_ids") and step["category_ids"] is Array:
		for item in step["category_ids"]:
			var category_id := String(item)
			if category_id != "" and not ids.has(category_id):
				ids.append(category_id)
	elif step.has("category_id"):
		var category_id := String(step.get("category_id", ""))
		if category_id != "":
			ids.append(category_id)
	return ids


func _manual_category_ids_for_day(day_key: String) -> Array[String]:
	var ids: Array[String] = []
	var events := _events()
	if day_key == "" or not events.has(day_key) or not (events[day_key] is Array):
		return ids

	for event_id in events[day_key]:
		var category_id := String(event_id)
		var category: Dictionary = _category_by_id(category_id)
		if category_id != "" and not category.is_empty() and not _is_category_hidden(category) and not ids.has(category_id):
			ids.append(category_id)
	return ids


func _rebuild_legacy_system_day_ids() -> void:
	system_day_category_ids.clear()
	for item in system_day_steps:
		var ids := _category_ids_from_system_step(item)
		if ids.is_empty():
			continue
		system_day_category_ids.append(String(ids[0]))


func _category_names_for_ids(category_ids: Array) -> String:
	var names: Array[String] = []
	for category_id in category_ids:
		var category: Dictionary = _category_by_id(String(category_id))
		if category.is_empty() or _is_category_hidden(category):
			continue
		var name := String(category.get("name", "")).strip_edges()
		if name != "":
			names.append(name)
	return ", ".join(names)


func _toggle_day_event_form() -> void:
	if day_event_form_box == null:
		return

	var show_form := not day_event_form_box.visible
	day_event_form_box.visible = show_form
	if day_fixed_button_form_box != null and show_form:
		day_fixed_button_form_box.visible = false
	if day_note_form_box != null and show_form:
		day_note_form_box.visible = false
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
	if day_note_form_box != null and show_form:
		day_note_form_box.visible = false
	if day_fixed_status_label != null:
		day_fixed_status_label.text = ""
	_refresh_fixed_delete_option()
	if show_form and day_fixed_name_input != null:
		day_fixed_name_input.grab_focus()


func _toggle_day_note_form() -> void:
	if day_note_form_box == null:
		return

	var show_form := not day_note_form_box.visible
	day_note_form_box.visible = show_form
	if day_event_form_box != null and show_form:
		day_event_form_box.visible = false
	if day_fixed_button_form_box != null and show_form:
		day_fixed_button_form_box.visible = false


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
	day_event_color_index = DEFAULT_EVENT_COLOR_INDEX
	_refresh_color_palettes()
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
	_append_category_to_system_from_selected_day(category_id)
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
	if day_fixed_delete_option == null or day_fixed_delete_ids.is_empty():
		return

	var selected_index := clampi(day_fixed_delete_option.selected, 0, day_fixed_delete_ids.size() - 1)
	var category_id: String = day_fixed_delete_ids[selected_index]
	_delete_fixed_button_by_id(category_id)


func _delete_fixed_button_by_id(category_id: String) -> void:
	if category_id == "":
		return

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
	if day_note_form_box != null:
		day_note_form_box.visible = false
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
	if day_note_form_box != null:
		day_note_form_box.visible = false
	if system_days_recording_active:
		_record_selected_day_for_system()
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


func _remove_category_id_from_day(day_key: String, category_id: String) -> void:
	if day_key == "" or category_id == "":
		return

	var events := _events()
	if not events.has(day_key) or not (events[day_key] is Array):
		return

	var clean: Array = []
	for event_id in events[day_key]:
		if String(event_id) != category_id:
			clean.append(event_id)
	if clean.is_empty():
		events.erase(day_key)
	else:
		events[day_key] = clean


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
	if kind_label == "prywatny":
		calendar_status_label.text = "Wybrany: prywatny. Ten profil nie jest udostępniany."
	elif share_code == "":
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
	calendars.append(_make_calendar(_next_calendar_name(kind), kind))
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


func _confirm_delete_selected_calendar() -> void:
	if calendars.size() <= 1:
		if calendar_status_label != null:
			calendar_status_label.text = "Nie można usunąć ostatniego profilu."
		return

	var calendar := _selected_calendar()
	var calendar_name := String(calendar.get("name", "Kalendarz"))
	var kind_label := "grupowy" if String(calendar.get("kind", "private")) == "group" else "prywatny"
	pending_calendar_delete_id = String(calendar.get("id", ""))
	if calendar_delete_label != null:
		calendar_delete_label.text = "Na pewno usunąć profil \"%s\" (%s)?\nZnikną jego dni, wydarzenia, notatki i schematy." % [
			calendar_name,
			kind_label,
		]
	if calendar_delete_dialog != null:
		calendar_delete_dialog.popup_centered(Vector2i(560, 310))


func _delete_selected_calendar_confirmed() -> void:
	if pending_calendar_delete_id == "":
		_close_calendar_delete_dialog()
		return

	_delete_calendar_by_id(pending_calendar_delete_id)
	pending_calendar_delete_id = ""
	_close_calendar_delete_dialog()


func _delete_calendar_by_id(calendar_id: String) -> void:
	if calendars.size() <= 1:
		return

	var was_deleted := false
	for index in range(calendars.size()):
		if not (calendars[index] is Dictionary):
			continue
		var calendar: Dictionary = calendars[index] as Dictionary
		if String(calendar.get("id", "")) != calendar_id:
			continue
		calendars.remove_at(index)
		selected_calendar_index = clampi(index, 0, calendars.size() - 1)
		was_deleted = true
		break

	if not was_deleted:
		return

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
		"system_days_start": "",
		"applied_system_scheme": {},
		"applied_system_schemes": [],
	})
	selected_calendar_index = calendars.size() - 1
	join_code_input.text = ""
	share_status_label.text = "Dodano kalendarz grupowy z kodu. Synchronizacja online będzie kolejnym krokiem."
	_save_settings_to_disk()
	_refresh_all()


func _previous_month() -> void:
	if month_layout_count == 12:
		current_year -= 1
		current_month = 1
	else:
		_shift_current_month(-month_layout_count)
	_refresh_month_title()
	_rebuild_calendar()
	_save_settings_to_disk()


func _next_month() -> void:
	if month_layout_count == 12:
		current_year += 1
		current_month = 1
	else:
		_shift_current_month(month_layout_count)
	_refresh_month_title()
	_rebuild_calendar()
	_save_settings_to_disk()


func _shift_current_month(delta: int) -> void:
	var shifted := _month_from_offset(current_year, current_month, delta)
	current_year = int(shifted["year"])
	current_month = int(shifted["month"])


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
		calendars.append(_make_calendar("Prywatny 1", "private"))
		calendars.append(_make_calendar("Grupowy 1", "group"))


func _next_calendar_name(kind: String) -> String:
	var base_name := "Grupowy" if kind == "group" else "Prywatny"
	var used_names := {}
	for calendar in calendars:
		if not (calendar is Dictionary):
			continue
		var calendar_name := String(calendar.get("name", "")).strip_edges()
		if calendar_name != "":
			used_names[calendar_name] = true

	var number := 1
	while used_names.has("%s %d" % [base_name, number]):
		number += 1
	return "%s %d" % [base_name, number]


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
		"system_days_start": "",
		"applied_system_scheme": {},
		"applied_system_schemes": [],
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


func _applied_system_schemes() -> Array:
	var calendar := _selected_calendar()
	_ensure_applied_system_schemes(calendar)
	return calendar["applied_system_schemes"]


func _ensure_applied_system_schemes(calendar: Dictionary) -> void:
	if not calendar.has("applied_system_schemes") or not (calendar["applied_system_schemes"] is Array):
		calendar["applied_system_schemes"] = []

	var clean_schemes: Array = []
	for item in calendar["applied_system_schemes"]:
		if not (item is Dictionary):
			continue
		var scheme: Dictionary = _normalize_applied_system_scheme(item as Dictionary)
		if not scheme.is_empty():
			clean_schemes.append(scheme)
	calendar["applied_system_schemes"] = clean_schemes

	if calendar.has("applied_system_scheme") and calendar["applied_system_scheme"] is Dictionary:
		var legacy_scheme: Dictionary = _normalize_applied_system_scheme(calendar["applied_system_scheme"] as Dictionary)
		if not legacy_scheme.is_empty():
			clean_schemes.append(legacy_scheme)
			_remove_scheme_marks_from_calendar_events(calendar, legacy_scheme)
			calendar["applied_system_schemes"] = clean_schemes
	calendar["applied_system_scheme"] = {}


func _normalize_applied_system_scheme(value: Dictionary) -> Dictionary:
	var days: Array = []
	if value.has("days") and value["days"] is Array:
		for item in value["days"]:
			if not (item is Dictionary):
				continue
			var day: Dictionary = item as Dictionary
			var key := String(day.get("key", ""))
			var category_ids := _category_ids_from_system_step(day)
			if key != "" and not category_ids.is_empty():
				days.append({
					"key": key,
					"category_ids": category_ids,
				})
	if days.is_empty():
		return {}

	var system_days: Array = []
	if value.has("system_days") and value["system_days"] is Array:
		for item in value["system_days"]:
			if item is Dictionary:
				var step := _normalize_system_day_step(item as Dictionary)
				if not step.is_empty():
					system_days.append(step)
				continue
			var category_id := String(item)
			if category_id != "":
				system_days.append({
					"key": "",
					"category_ids": [category_id],
				})

	var name := String(value.get("name", "")).strip_edges()
	if name == "":
		name = "Schemat"
	var scheme_id := String(value.get("id", ""))
	if scheme_id == "":
		scheme_id = _new_id("scheme")
	return {
		"id": scheme_id,
		"name": name,
		"visible": bool(value.get("visible", true)),
		"start": String(value.get("start", "")),
		"end": String(value.get("end", "")),
		"system_days": system_days,
		"days": days,
	}


func _rebuild_system_scheme_event_cache() -> void:
	system_scheme_event_ids_by_day.clear()
	for item in _applied_system_schemes():
		if not (item is Dictionary):
			continue
		var scheme: Dictionary = item as Dictionary
		if not bool(scheme.get("visible", true)):
			continue
		if not scheme.has("days") or not (scheme["days"] is Array):
			continue
		for day_item in scheme["days"]:
			if not (day_item is Dictionary):
				continue
			var day: Dictionary = day_item as Dictionary
			var key := String(day.get("key", ""))
			if key == "":
				continue
			var ids: Array = []
			if system_scheme_event_ids_by_day.has(key) and system_scheme_event_ids_by_day[key] is Array:
				ids = system_scheme_event_ids_by_day[key]
			for category_id in _category_ids_from_system_step(day):
				var category: Dictionary = _category_by_id(category_id)
				if category_id == "" or category.is_empty() or _is_category_hidden(category):
					continue
				if not ids.has(category_id):
					ids.append(category_id)
			system_scheme_event_ids_by_day[key] = ids


func _remove_scheme_marks_from_calendar_events(_calendar: Dictionary, _scheme: Dictionary) -> void:
	return


func _event_ids_for_day(key: String) -> Array:
	var result: Array = []
	var events := _events()
	if events.has(key) and events[key] is Array:
		for event_id in events[key]:
			var category_id := String(event_id)
			if category_id != "" and not result.has(category_id):
				result.append(category_id)
	if system_scheme_event_ids_by_day.has(key) and system_scheme_event_ids_by_day[key] is Array:
		for event_id in system_scheme_event_ids_by_day[key]:
			var category_id := String(event_id)
			if category_id != "" and not result.has(category_id):
				result.append(category_id)
	return result


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


func _color_for_day(event_ids: Array) -> Color:
	if not event_ids.is_empty():
		var category: Dictionary = _category_by_id(String(event_ids[0]))
		if not category.is_empty():
			return _category_color(int(category.get("color", 0)))

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
	config.set_value("ui", "month_layout_count", month_layout_count)
	config.set_value("ui", "system_days_expanded", system_days_expanded)
	config.set_value("ui", "sharing_expanded", sharing_expanded)
	config.set_value("ui", "calendar_only_mode", calendar_only_mode)
	config.set_value("ui", "profile_panel_open", profile_panel_open)
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
	month_layout_count = _normalized_month_layout_count(int(config.get_value("ui", "month_layout_count", month_layout_count)))
	system_days_expanded = bool(config.get_value("ui", "system_days_expanded", system_days_expanded))
	sharing_expanded = bool(config.get_value("ui", "sharing_expanded", sharing_expanded))
	calendar_only_mode = bool(config.get_value("ui", "calendar_only_mode", calendar_only_mode))
	profile_panel_open = bool(config.get_value("ui", "profile_panel_open", profile_panel_open))

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
	if not calendar.has("system_days_start"):
		calendar["system_days_start"] = ""
	if not calendar.has("applied_system_scheme") or not (calendar["applied_system_scheme"] is Dictionary):
		calendar["applied_system_scheme"] = {}
	if not calendar.has("applied_system_schemes") or not (calendar["applied_system_schemes"] is Array):
		calendar["applied_system_schemes"] = []
	_ensure_applied_system_schemes(calendar)
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


func _holiday_names_for_day(year: int, month: int, day: int) -> Array[String]:
	var key := _date_key(year, month, day)
	var holidays := _polish_holidays_for_year(year)
	var names: Array[String] = []
	if not holidays.has(key) or not (holidays[key] is Array):
		return names

	for item in holidays[key]:
		var name := String(item).strip_edges()
		if name != "":
			names.append(name)
	return names


func _polish_holidays_for_year(year: int) -> Dictionary:
	if holiday_cache_by_year.has(year) and holiday_cache_by_year[year] is Dictionary:
		return holiday_cache_by_year[year]

	var holidays: Dictionary = {}
	for item in FIXED_POLISH_HOLIDAYS:
		if not (item is Dictionary):
			continue
		var holiday: Dictionary = item as Dictionary
		_add_holiday(holidays, _date_key(year, int(holiday.get("month", 1)), int(holiday.get("day", 1))), String(holiday.get("name", "")))

	var easter := _easter_date(year)
	if not easter.is_empty():
		var easter_month := int(easter.get("month", 1))
		var easter_day := int(easter.get("day", 1))
		_add_relative_holiday(holidays, year, easter_month, easter_day, -52, "Tłusty Czwartek")
		_add_relative_holiday(holidays, year, easter_month, easter_day, -46, "Środa Popielcowa")
		_add_relative_holiday(holidays, year, easter_month, easter_day, -7, "Niedziela Palmowa")
		_add_relative_holiday(holidays, year, easter_month, easter_day, -3, "Wielki Czwartek")
		_add_relative_holiday(holidays, year, easter_month, easter_day, -2, "Wielki Piątek")
		_add_relative_holiday(holidays, year, easter_month, easter_day, -1, "Wielka Sobota")
		_add_relative_holiday(holidays, year, easter_month, easter_day, 0, "Niedziela Wielkanocna")
		_add_relative_holiday(holidays, year, easter_month, easter_day, 1, "Poniedziałek Wielkanocny")
		_add_relative_holiday(holidays, year, easter_month, easter_day, 7, "Święto Miłosierdzia Bożego")
		_add_relative_holiday(holidays, year, easter_month, easter_day, 42, "Wniebowstąpienie Pańskie")
		_add_relative_holiday(holidays, year, easter_month, easter_day, 49, "Zesłanie Ducha Świętego / Zielone Świątki")
		_add_relative_holiday(holidays, year, easter_month, easter_day, 60, "Boże Ciało")

	holiday_cache_by_year[year] = holidays
	return holidays


func _add_relative_holiday(holidays: Dictionary, year: int, month: int, day: int, day_offset: int, name: String) -> void:
	_add_holiday(holidays, _date_key_with_day_offset(year, month, day, day_offset), name)


func _add_holiday(holidays: Dictionary, key: String, name: String) -> void:
	var clean_name := name.strip_edges()
	if key == "" or clean_name == "":
		return

	var names: Array = []
	if holidays.has(key) and holidays[key] is Array:
		names = holidays[key]
	if not names.has(clean_name):
		names.append(clean_name)
	holidays[key] = names


func _date_key_with_day_offset(year: int, month: int, day: int, day_offset: int) -> String:
	var unix_time := _unix_from_date(year, month, day) + day_offset * 86400
	var date := Time.get_datetime_dict_from_unix_time(unix_time)
	return _date_key(int(date["year"]), int(date["month"]), int(date["day"]))


func _easter_date(year: int) -> Dictionary:
	var a := year % 19
	var b := int(year / 100)
	var c := year % 100
	var d := int(b / 4)
	var e := b % 4
	var f := int((b + 8) / 25)
	var g := int((b - f + 1) / 3)
	var h := (19 * a + b - d - g + 15) % 30
	var i := int(c / 4)
	var k := c % 4
	var l := (32 + 2 * e + 2 * i - h - k) % 7
	var m := int((a + 11 * h + 22 * l) / 451)
	var value := h + l - 7 * m + 114
	var month := int(value / 31)
	var day := value % 31 + 1
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


func _make_panel_toggle_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	_prepare_control(button, 19, 62)
	_connect_tap(button, action)
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
	profile_panel_open = visible
	if profile_panel != null:
		profile_panel.visible = visible and not calendar_only_mode


func _toggle_profile_panel() -> void:
	_set_profile_panel_visible(not profile_panel_open)
	_save_settings_to_disk()


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


func _tile_style(color: Color, is_today: bool, has_items: bool, has_holiday: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(18)
	style.set_border_width_all(3 if is_today else (2 if has_holiday else 1))
	if is_today:
		style.border_color = COLOR_TODAY
	elif has_holiday:
		style.border_color = COLOR_HOLIDAY
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


func _event_dot_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.lightened(0.20)
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 1.0, 1.0, 0.60)
	style.shadow_color = Color(color.r, color.g, color.b, 0.78)
	style.shadow_size = 7
	style.shadow_offset = Vector2.ZERO
	return style


func _month_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.055, 0.055, 0.34)
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 1.0, 1.0, 0.14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 7
	style.content_margin_bottom = 7
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

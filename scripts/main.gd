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
const RANGE_LABELS := ["Miesiąc", "Kwartał", "Pół roku", "Rok"]

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
const TOUCH_DRAG_CANCEL_DISTANCE := 8.0
const TAP_BLOCK_AFTER_DRAG_MS := 450
const NAVIGATION_TAP_MAX_MS := 900
const NAVIGATION_TAP_MOVE_LIMIT := 12.0
const NAVIGATION_TAP_SCROLL_LIMIT := 10.0
const NAVIGATION_BLOCK_AFTER_SCROLL_MS := 1600
const TOUCH_SCROLL_DEADZONE_MENU := 18
const RETURN_TODAY_BUTTON_TOP := 84
const RETURN_TODAY_BUTTON_HEIGHT := 44
const RETURN_TODAY_BUTTON_WIDTH := 300
const RESET_UNDO_BUTTON_TOP := 84
const RESET_UNDO_BUTTON_HEIGHT := 44
const RESET_UNDO_BUTTON_WIDTH := 166
const SCROLLBAR_TOUCH_WIDTH := 28
const CALENDAR_ONLY_RETURN_TOP := 20
const CALENDAR_ONLY_RETURN_WIDTH := 142
const CALENDAR_ONLY_RETURN_HEIGHT := 54
const PROFILE_BUTTON_TOP := 84
const PROFILE_BUTTON_HEIGHT := 44
const PROFILE_BUTTON_WIDTH := 142
const PROFILE_PANEL_WIDTH := 230
const PROFILE_PANEL_HEIGHT := 350
const DEFAULT_PROFILE_COUNT := 3
const LEGACY_CYCLE_MENU_CLEANUP_MAX_CHECKS := 90
const LEGACY_CYCLE_MENU_MARKERS := [
	"Jakim systemem",
	"Inne -",
	"Dni pracy",
	"Dni domu",
	"Dzień pierwszy",
	"Zawsze zaczynam",
	"Pauza 24h co 6",
	"Własny cykl",
	"Długość powtarzalnego",
	"Zamknij ustawienia",
]

var calculator := ScheduleCalculator.new()
var current_year: int
var current_month: int
var today_day_index: int

var main_scroll: ScrollContainer
var calendar_root: VBoxContainer
var options_root: VBoxContainer
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
var undo_button: Button
var reset_undo_button: Button
var header_bar: HBoxContainer
var return_today_spacer: Control
var save_close_button: Button
var settings_header_button: Button
var navigation_panel: PanelContainer
var quick_navigation_panel: PanelContainer
var quick_navigation_body: VBoxContainer
var quick_navigation_toggle: CheckButton
var quick_range_option: OptionButton
var quick_month_picker_button: Button
var month_picker_panel: PanelContainer
var settings_toggle_button: Button
var settings_panel: PanelContainer
var legend_bar: HBoxContainer
var calendar_touch_shield: Control
var calendar_only_toggle_button: Button
var calendar_only_return_button: Button
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
var day_touch_targets: Array[Dictionary] = []
var scroll_safe_buttons: Array[BaseButton] = []
var navigation_buttons: Array[BaseButton] = []
var weekly_rest_previous_pressed := true
var fixed_start_previous_pressed := false
var main_view_saved := false
var calendar_only_mode := false
var cycle_pending_apply := false
var day_tools_visible := true
var quick_navigation_body_visible := true
var reset_undo_available := false
var reset_undo_snapshot: Dictionary = {}
var undo_available := false
var undo_snapshot: Dictionary = {}
var restoring_undo_state := false
var profile_count := DEFAULT_PROFILE_COUNT
var selected_profile_index := 1
var saved_profiles: Dictionary = {}
var profile_panel_visible := false
var month_picker_visible := false
var touch_start_position := Vector2.ZERO
var touch_drag_total := Vector2.ZERO
var touch_tracking_active := false
var touch_drag_cancelled := false
var touch_drag_block_generation := 0
var last_drag_release_msec := -10000
var navigation_action_unlock_msec := -10000
var navigation_blocked_until_msec := -10000
var navigation_button_action_active := false
var calendar_navigation_command_depth := 0
var confirmed_calendar_year: int = 0
var confirmed_calendar_month: int = 0
var calendar_page_guard_ready := false
var shield_touch_start_position := Vector2.ZERO
var shield_touch_tracking := false
var shield_touch_dragged := false
var legacy_cycle_menu_removed := false
var legacy_cycle_menu_cleanup_checks := 0


func _ready() -> void:
	_force_portrait()

	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	_refresh_today_day_index()

	_reset_custom_pattern(21)
	_build_ui()
	_remove_legacy_cycle_settings_menu()
	_load_settings_from_disk()
	_apply_settings()
	_apply_main_view_mode(main_view_saved)
	_remove_legacy_cycle_settings_menu()
	_accept_calendar_page()


func _input(event: InputEvent) -> void:
	_track_scroll_touch(event)
	if _consume_horizontal_drag(event):
		return
	if _consume_calendar_only_drag(event):
		return
	if _block_calendar_touch_drag(event):
		return
	if _event_is_drag_motion(event):
		_lock_horizontal_scroll_deferred()


func _gui_input(event: InputEvent) -> void:
	_track_scroll_touch(event)
	if _consume_horizontal_drag(event, true):
		return
	if _consume_calendar_only_drag(event):
		accept_event()
		return
	if _block_calendar_touch_drag(event):
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	_track_scroll_touch(event)
	if _event_is_drag_motion(event):
		_block_touch_drag_actions()
		_lock_horizontal_scroll_deferred()


func _on_main_scroll_gui_input(event: InputEvent) -> void:
	_track_scroll_touch(event)
	if _consume_horizontal_drag(event, true):
		return
	if event is InputEventScreenDrag or event is InputEventPanGesture:
		_block_touch_drag_actions()
		_lock_horizontal_scroll_deferred()
	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if (mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_block_touch_drag_actions()
			_lock_horizontal_scroll_deferred()


func _process(_delta: float) -> void:
	_lock_horizontal_scroll()
	_sync_calendar_touch_shield()
	_restore_unapproved_calendar_page()
	_remove_legacy_cycle_settings_menu()


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
	screen_root.clip_contents = true
	screen_root.add_theme_constant_override("separation", 12)
	screen_root.resized.connect(_sync_calendar_root_width)
	safe_margin.add_child(screen_root)

	var calendar_center := CenterContainer.new()
	calendar_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calendar_center.clip_contents = true
	screen_root.add_child(calendar_center)

	_add_return_today_overlay()
	_add_reset_undo_overlay()
	_add_profile_overlay()
	_add_calendar_touch_shield()
	_add_calendar_only_return_overlay()

	var root := VBoxContainer.new()
	calendar_root = root
	root.custom_minimum_size = Vector2(PORTRAIT_WIDTH, 0)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_theme_constant_override("separation", 18)
	calendar_center.add_child(root)

	main_scroll = ScrollContainer.new()
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.scroll_deadzone = TOUCH_SCROLL_DEADZONE_MENU
	main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.clip_contents = true
	main_scroll.resized.connect(_sync_calendar_root_width)
	main_scroll.gui_input.connect(_on_main_scroll_gui_input)
	screen_root.add_child(main_scroll)
	_lock_horizontal_scroll_deferred()
	_style_main_scrollbar()

	var options_center := CenterContainer.new()
	options_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_center.clip_contents = true
	main_scroll.add_child(options_center)

	options_root = VBoxContainer.new()
	options_root.custom_minimum_size = Vector2(PORTRAIT_WIDTH, 0)
	options_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options_root.add_theme_constant_override("separation", 18)
	options_center.add_child(options_root)
	_sync_calendar_root_width()

	header_bar = HBoxContainer.new()
	header_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_theme_constant_override("separation", 8)
	root.add_child(header_bar)

	var undo_row := HBoxContainer.new()
	undo_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	undo_row.add_theme_constant_override("separation", 6)
	header_bar.add_child(undo_row)

	reset_settings_button = Button.new()
	reset_settings_button.text = "Resetuj"
	_connect_tap(reset_settings_button, Callable(self, "_on_reset_pressed"))
	_prepare_control(reset_settings_button, 14, 54)
	reset_settings_button.custom_minimum_size.x = 82
	reset_settings_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	undo_row.add_child(reset_settings_button)

	undo_button = Button.new()
	undo_button.text = "Cofnij"
	_connect_tap(undo_button, Callable(self, "_on_undo_pressed"))
	_prepare_control(undo_button, 14, 54)
	undo_button.custom_minimum_size.x = 78
	undo_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	undo_row.add_child(undo_button)

	var title := _make_label("Kalendarz Kierowcy", 30, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_bar.add_child(title)

	save_close_button = Button.new()
	save_close_button.text = "Zapisz i zamknij"
	_connect_tap(save_close_button, Callable(self, "_save_and_close_main_view"))
	_prepare_control(save_close_button, 14, 54)
	save_close_button.custom_minimum_size.x = PROFILE_BUTTON_WIDTH
	save_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	header_bar.add_child(save_close_button)

	settings_header_button = Button.new()
	settings_header_button.text = "Ustawienia"
	_connect_tap(settings_header_button, Callable(self, "_open_calendar_settings"))
	_prepare_control(settings_header_button, 15, 54)
	settings_header_button.custom_minimum_size.x = PROFILE_BUTTON_WIDTH
	settings_header_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	settings_header_button.visible = false
	header_bar.add_child(settings_header_button)

	return_today_spacer = Control.new()
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
	_prepare_calendar_drag_blocker(months_box)
	root.add_child(months_box)

	legend_bar = _build_legend()
	root.add_child(legend_bar)

	quick_navigation_panel = _build_quick_navigation_panel()
	options_root.add_child(quick_navigation_panel)

	settings_toggle_button = Button.new()
	settings_toggle_button.text = "Zastosuj"
	_connect_tap(settings_toggle_button, Callable(self, "_on_settings_primary_pressed"))
	_prepare_control(settings_toggle_button, 22, 62)
	options_root.add_child(settings_toggle_button)

	settings_panel = _build_settings_panel()
	settings_panel.visible = false
	day_tools_panel = _build_day_tools_panel()
	options_root.add_child(day_tools_panel)

	calendar_only_toggle_button = Button.new()
	calendar_only_toggle_button.text = "Pokaż tylko kalendarz"
	_connect_tap(calendar_only_toggle_button, Callable(self, "_enter_calendar_only_mode"))
	_prepare_control(calendar_only_toggle_button, 22, 62)
	calendar_only_toggle_button.visible = false
	options_root.add_child(calendar_only_toggle_button)
	_set_settings_visible(true)

	_build_day_action_dialog()
	_build_note_dialog()


func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false

	schedule_option = OptionButton.new()
	for _index in range(8):
		schedule_option.add_item("")
	_set_option_selected(schedule_option, 0)
	schedule_option.item_selected.connect(_on_schedule_selected)

	system_work_spin = _make_spin(1, 90, 14)
	system_home_spin = _make_spin(1, 90, 7)

	start_input = LineEdit.new()
	start_input.text_submitted.connect(_on_start_date_submitted)
	start_input.set_meta("last_text", start_input.text)

	fixed_start_toggle = CheckButton.new()
	fixed_start_toggle.button_pressed = false
	fixed_start_previous_pressed = fixed_start_toggle.button_pressed
	fixed_start_toggle.toggled.connect(_on_fixed_start_toggled)

	fixed_start_option = OptionButton.new()
	fixed_start_option.add_item("")
	for weekday_name in WEEKDAY_NAMES:
		fixed_start_option.add_item(weekday_name)
	_set_option_selected(fixed_start_option, 0)
	fixed_start_option.item_selected.connect(_on_fixed_start_day_selected)
	fixed_start_option.visible = false

	weekly_rest_toggle = CheckButton.new()
	weekly_rest_toggle.button_pressed = true
	weekly_rest_previous_pressed = weekly_rest_toggle.button_pressed
	weekly_rest_toggle.toggled.connect(_on_weekly_rest_toggled)

	custom_panel = PanelContainer.new()
	custom_panel.visible = false

	custom_length_spin = _make_spin(1, 56, 21, false)
	custom_length_spin.value_changed.connect(_on_custom_length_spin_changed)

	error_label = Label.new()
	error_label.visible = false

	return panel


func _build_custom_cycle_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	return panel


func _remove_legacy_cycle_settings_menu() -> void:
	if legacy_cycle_menu_removed:
		return
	if legacy_cycle_menu_cleanup_checks >= LEGACY_CYCLE_MENU_CLEANUP_MAX_CHECKS:
		return

	legacy_cycle_menu_cleanup_checks += 1

	var marker_node := _find_legacy_cycle_menu_node(self)
	if marker_node == null:
		return

	var panel := _legacy_cycle_menu_panel_root(marker_node)
	if panel == null:
		return

	panel.visible = false
	var parent := panel.get_parent()
	if parent != null:
		parent.remove_child(panel)
	panel.queue_free()
	legacy_cycle_menu_removed = true


func _find_legacy_cycle_menu_node(node: Node) -> Node:
	if _node_has_legacy_cycle_menu_text(node):
		return node

	for child in node.get_children():
		var found := _find_legacy_cycle_menu_node(child)
		if found != null:
			return found

	return null


func _node_has_legacy_cycle_menu_text(node: Node) -> bool:
	var text_values: Array[String] = []
	if node is Label:
		text_values.append((node as Label).text)
	elif node is Button:
		text_values.append((node as Button).text)
	elif node is LineEdit:
		text_values.append((node as LineEdit).text)
		text_values.append((node as LineEdit).placeholder_text)
	elif node is CheckButton:
		text_values.append((node as CheckButton).text)
	elif node is OptionButton:
		var option := node as OptionButton
		for index in range(option.get_item_count()):
			text_values.append(option.get_item_text(index))

	for value in text_values:
		for marker in LEGACY_CYCLE_MENU_MARKERS:
			if value.find(marker) != -1:
				return true

	return false


func _legacy_cycle_menu_panel_root(node: Node) -> Control:
	var current := node
	while current != null:
		if current is PanelContainer:
			return current as Control
		if current == options_root:
			return node as Control if node is Control else null
		current = current.get_parent()

	return node as Control if node is Control else null


func _build_navigation_panel() -> PanelContainer:
	var panel := _panel()
	var box := _panel_box(panel)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	box.add_child(nav)

	var previous_button := _make_nav_button("<")
	_connect_navigation_tap(previous_button, Callable(self, "_button_previous_month"))
	nav.add_child(previous_button)

	range_option = OptionButton.new()
	for label_text in RANGE_LABELS:
		range_option.add_item(label_text)
	_set_option_selected(range_option, 0)
	range_option.item_selected.connect(_on_range_selected)
	_prepare_control(range_option, 22, 60)
	_prepare_large_dropdown(range_option)
	nav.add_child(range_option)

	var next_button := _make_nav_button(">")
	_connect_navigation_tap(next_button, Callable(self, "_button_next_month"))
	nav.add_child(next_button)

	var year_buttons := HBoxContainer.new()
	year_buttons.add_theme_constant_override("separation", 8)
	box.add_child(year_buttons)

	var previous_year_button := _make_nav_button("<< rok")
	_connect_navigation_tap(previous_year_button, Callable(self, "_button_previous_year"))
	year_buttons.add_child(previous_year_button)

	var next_year_button := _make_nav_button("rok >>")
	_connect_navigation_tap(next_year_button, Callable(self, "_button_next_year"))
	year_buttons.add_child(next_year_button)

	return panel


func _build_quick_navigation_panel() -> PanelContainer:
	var panel := _panel()
	panel.visible = false
	var box := _panel_box(panel, 10)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)

	var title := _make_section_label("Nawigacja")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	quick_navigation_toggle = CheckButton.new()
	quick_navigation_toggle.text = ""
	quick_navigation_toggle.button_pressed = quick_navigation_body_visible
	quick_navigation_toggle.toggled.connect(_on_quick_navigation_toggled)
	quick_navigation_toggle.custom_minimum_size = Vector2(88, 48)
	quick_navigation_toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	_register_scroll_safe_control(quick_navigation_toggle)
	header.add_child(quick_navigation_toggle)

	quick_navigation_body = VBoxContainer.new()
	quick_navigation_body.add_theme_constant_override("separation", 8)
	box.add_child(quick_navigation_body)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	quick_navigation_body.add_child(nav)

	var previous_button := _make_nav_button("<")
	_connect_navigation_tap(previous_button, Callable(self, "_button_previous_month"))
	nav.add_child(previous_button)

	quick_range_option = OptionButton.new()
	for label_text in RANGE_LABELS:
		quick_range_option.add_item(label_text)
	_set_option_selected(quick_range_option, range_option.selected if range_option != null else 0)
	quick_range_option.item_selected.connect(_on_quick_range_selected)
	_prepare_control(quick_range_option, 20, 54)
	_prepare_large_dropdown(quick_range_option)
	nav.add_child(quick_range_option)

	var next_button := _make_nav_button(">")
	_connect_navigation_tap(next_button, Callable(self, "_button_next_month"))
	nav.add_child(next_button)

	var year_buttons := HBoxContainer.new()
	year_buttons.add_theme_constant_override("separation", 8)
	quick_navigation_body.add_child(year_buttons)

	var previous_year_button := _make_nav_button("<< rok")
	_connect_navigation_tap(previous_year_button, Callable(self, "_button_previous_year"))
	year_buttons.add_child(previous_year_button)

	quick_month_picker_button = _make_nav_button("Miesiące")
	_connect_navigation_tap(quick_month_picker_button, Callable(self, "_button_toggle_month_picker"))
	year_buttons.add_child(quick_month_picker_button)

	var next_year_button := _make_nav_button("rok >>")
	_connect_navigation_tap(next_year_button, Callable(self, "_button_next_year"))
	year_buttons.add_child(next_year_button)

	month_picker_panel = _build_month_picker_panel()
	quick_navigation_body.add_child(month_picker_panel)
	_set_month_picker_visible(false)
	_apply_quick_navigation_body_visibility()

	return panel


func _build_month_picker_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL_SOFT, 8))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	margin.add_child(grid)

	for month_index in range(1, 13):
		var month_button := Button.new()
		month_button.text = MONTH_NAMES[month_index - 1]
		_connect_navigation_tap(month_button, Callable(self, "_button_pick_month").bind(month_index))
		_prepare_control(month_button, 16, 48)
		grid.add_child(month_button)

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
	_connect_navigation_tap(return_today_button, Callable(self, "_button_return_to_today"))
	_prepare_control(return_today_button, 18, RETURN_TODAY_BUTTON_HEIGHT)
	return_today_button.custom_minimum_size.x = RETURN_TODAY_BUTTON_WIDTH
	return_today_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(return_today_button)


func _add_reset_undo_overlay() -> void:
	var overlay := MarginContainer.new()
	overlay.anchor_left = 0.0
	overlay.anchor_right = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_bottom = 0.0
	overlay.offset_left = 18.0
	overlay.offset_right = 18.0 + RESET_UNDO_BUTTON_WIDTH
	overlay.offset_top = RESET_UNDO_BUTTON_TOP
	overlay.offset_bottom = RESET_UNDO_BUTTON_TOP + RESET_UNDO_BUTTON_HEIGHT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 35
	add_child(overlay)

	reset_undo_button = Button.new()
	reset_undo_button.text = "Cofnij reset"
	_connect_tap(reset_undo_button, Callable(self, "_on_reset_undo_pressed"))
	_prepare_control(reset_undo_button, 14, RESET_UNDO_BUTTON_HEIGHT)
	reset_undo_button.custom_minimum_size.x = RESET_UNDO_BUTTON_WIDTH
	reset_undo_button.visible = false
	overlay.add_child(reset_undo_button)


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


func _add_calendar_only_return_overlay() -> void:
	var overlay := MarginContainer.new()
	overlay.anchor_left = 1.0
	overlay.anchor_right = 1.0
	overlay.anchor_top = 0.0
	overlay.anchor_bottom = 0.0
	overlay.offset_left = -CALENDAR_ONLY_RETURN_WIDTH - 18.0
	overlay.offset_right = -18.0
	overlay.offset_top = CALENDAR_ONLY_RETURN_TOP
	overlay.offset_bottom = CALENDAR_ONLY_RETURN_TOP + CALENDAR_ONLY_RETURN_HEIGHT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 40
	add_child(overlay)

	calendar_only_return_button = Button.new()
	calendar_only_return_button.text = "Pokaż opcje"
	_connect_tap(calendar_only_return_button, Callable(self, "_exit_calendar_only_mode"))
	_prepare_control(calendar_only_return_button, 14, CALENDAR_ONLY_RETURN_HEIGHT)
	calendar_only_return_button.custom_minimum_size.x = CALENDAR_ONLY_RETURN_WIDTH
	calendar_only_return_button.visible = false
	overlay.add_child(calendar_only_return_button)


func _add_calendar_touch_shield() -> void:
	calendar_touch_shield = Control.new()
	calendar_touch_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	calendar_touch_shield.z_index = 38
	calendar_touch_shield.visible = false
	calendar_touch_shield.gui_input.connect(_handle_calendar_touch_shield_input)
	add_child(calendar_touch_shield)


func _handle_calendar_touch_shield_input(event: InputEvent) -> void:
	var position := _calendar_touch_event_position(event)

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_calendar_shield_touch(position)
		else:
			_finish_calendar_shield_touch(position)
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_begin_calendar_shield_touch(position)
			else:
				_finish_calendar_shield_touch(position)
	elif _event_is_drag_motion(event):
		_mark_calendar_shield_drag(position)

	if shield_touch_dragged:
		_block_touch_drag_actions()
	_lock_horizontal_scroll_deferred()
	accept_event()
	get_viewport().set_input_as_handled()


func _calendar_touch_event_position(event: InputEvent) -> Vector2:
	var position := Vector2.ZERO
	if event is InputEventScreenTouch:
		position = (event as InputEventScreenTouch).position
	elif event is InputEventScreenDrag:
		position = (event as InputEventScreenDrag).position
	elif event is InputEventMouseButton:
		position = (event as InputEventMouseButton).position
	elif event is InputEventMouseMotion:
		position = (event as InputEventMouseMotion).position
	elif event is InputEventPanGesture:
		position = (event as InputEventPanGesture).position

	if calendar_touch_shield == null:
		return position

	if calendar_touch_shield.get_global_rect().has_point(position):
		return position

	return calendar_touch_shield.get_global_transform_with_canvas() * position


func _begin_calendar_shield_touch(position: Vector2) -> void:
	shield_touch_start_position = position
	shield_touch_tracking = true
	shield_touch_dragged = false


func _mark_calendar_shield_drag(position: Vector2) -> void:
	if not shield_touch_tracking:
		shield_touch_dragged = true
		return

	if shield_touch_start_position.distance_to(position) > TOUCH_DRAG_CANCEL_DISTANCE:
		shield_touch_dragged = true


func _finish_calendar_shield_touch(position: Vector2) -> void:
	var was_dragged := shield_touch_dragged
	if shield_touch_tracking and shield_touch_start_position.distance_to(position) > TOUCH_DRAG_CANCEL_DISTANCE:
		was_dragged = true

	shield_touch_tracking = false
	shield_touch_dragged = false

	if was_dragged:
		_block_touch_drag_actions()
		return

	var target := _calendar_day_at_position(position)
	if target.is_empty():
		return

	if _range_months() > 1:
		_open_month_from_overview(int(target["year"]), int(target["month"]))
	elif calendar_only_mode:
		_block_touch_drag_actions()
	else:
		_open_day_actions(int(target["year"]), int(target["month"]), int(target["day"]))


func _sync_calendar_touch_shield() -> void:
	if calendar_touch_shield == null:
		return
	if calendar_only_mode:
		var viewport_rect := get_viewport_rect()
		calendar_touch_shield.position = viewport_rect.position
		calendar_touch_shield.size = viewport_rect.size
		calendar_touch_shield.visible = true
		return
	if months_box == null or not is_instance_valid(months_box):
		calendar_touch_shield.visible = false
		return
	if calendar_root == null or not is_instance_valid(calendar_root) or not calendar_root.visible:
		calendar_touch_shield.visible = false
		return

	var rect := months_box.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		calendar_touch_shield.visible = false
		return

	calendar_touch_shield.position = rect.position
	calendar_touch_shield.size = rect.size
	calendar_touch_shield.visible = true


func _register_day_touch_target(button: Button, year: int, month: int, day: int) -> void:
	day_touch_targets.append({
		"button": button,
		"year": year,
		"month": month,
		"day": day,
	})


func _calendar_day_at_position(position: Vector2) -> Dictionary:
	for index in range(day_touch_targets.size() - 1, -1, -1):
		var target := day_touch_targets[index]
		var button = target.get("button", null)
		if not (button is Button) or not is_instance_valid(button):
			day_touch_targets.remove_at(index)
			continue
		if button.visible and button.get_global_rect().has_point(position):
			return target

	return {}


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
	legend.add_child(_legend_item(COLOR_REST, "24/45h"))
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

	var set_work := _action_button("Praca", COLOR_WORK)
	_connect_tap(set_work, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.WORK))
	box.add_child(set_work)

	var set_rest := _action_button("Pauza 24h", COLOR_REST)
	_connect_tap(set_rest, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.REST))
	box.add_child(set_rest)

	var set_home := _action_button("Dom", COLOR_HOME)
	_connect_tap(set_home, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.HOME))
	box.add_child(set_home)

	var set_vacation := _action_button("Urlop", COLOR_VACATION)
	_connect_tap(set_vacation, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.VACATION))
	box.add_child(set_vacation)

	var clear_day := _action_button("Wyczyść", Color(0.52, 0.55, 0.54, 0.86))
	_connect_tap(clear_day, Callable(self, "_set_selected_day_state").bind(ScheduleCalculator.DayState.NONE))
	box.add_child(clear_day)

	var restore_day := _action_button("Cofnij zmianę", Color(0.40, 0.43, 0.42, 0.86))
	_connect_tap(restore_day, Callable(self, "_clear_selected_day_override"))
	box.add_child(restore_day)

	var note_button := _action_button("Notatka", COLOR_NOTE)
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
	var undo_before := _app_state_snapshot()
	if _apply_settings(false, true):
		_store_undo_snapshot(undo_before)
		_save_settings_to_disk()


func _save_and_close_main_view() -> void:
	var undo_before := _app_state_snapshot()
	if not _apply_settings(false, true):
		return

	_store_undo_snapshot(undo_before)
	main_view_saved = true
	calendar_only_mode = false
	_save_settings_to_disk()
	_apply_main_view_mode(true)


func _open_calendar_settings() -> void:
	_capture_undo_state()
	calendar_only_mode = false
	main_view_saved = false
	_apply_main_view_mode(false)
	_set_settings_visible(true)
	_save_settings_to_disk()


func _enter_calendar_only_mode() -> void:
	_capture_undo_state()
	main_view_saved = true
	calendar_only_mode = true
	_rebuild_calendar()
	_apply_main_view_mode(true)
	_save_settings_to_disk()


func _exit_calendar_only_mode() -> void:
	_capture_undo_state()
	calendar_only_mode = false
	main_view_saved = true
	_rebuild_calendar()
	_apply_main_view_mode(true)
	_save_settings_to_disk()


func _mark_cycle_pending() -> void:
	cycle_pending_apply = true
	_save_settings_to_disk()


func _on_settings_primary_pressed() -> void:
	_save_settings_and_close()


func _close_settings_panel() -> void:
	_capture_undo_state()
	_set_settings_visible(false)


func _on_day_tools_toggled(visible: bool) -> void:
	if _tap_is_blocked():
		day_tools_toggle.set_pressed_no_signal(day_tools_visible)
		return

	_capture_undo_state()
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


func _button_toggle_month_picker() -> void:
	if not _navigation_button_action_allowed():
		return

	_set_month_picker_visible(not month_picker_visible)


func _set_month_picker_visible(visible: bool) -> void:
	month_picker_visible = visible
	if month_picker_panel != null:
		month_picker_panel.visible = visible
	if quick_month_picker_button != null:
		quick_month_picker_button.text = "Schowaj miesiące" if visible else "Miesiące"


func _on_quick_navigation_toggled(enabled: bool) -> void:
	if _tap_is_blocked():
		quick_navigation_toggle.set_pressed_no_signal(quick_navigation_body_visible)
		return

	quick_navigation_body_visible = enabled
	_apply_quick_navigation_body_visibility()
	_save_settings_to_disk()


func _apply_quick_navigation_body_visibility() -> void:
	if quick_navigation_body != null:
		quick_navigation_body.visible = quick_navigation_body_visible
	if quick_navigation_toggle != null:
		quick_navigation_toggle.set_pressed_no_signal(quick_navigation_body_visible)
	if not quick_navigation_body_visible:
		_set_month_picker_visible(false)


func _toggle_settings_panel() -> void:
	if main_view_saved or calendar_only_mode:
		return

	_save_settings_and_close()


func _set_settings_visible(_visible: bool) -> void:
	if settings_panel != null:
		settings_panel.visible = false
	if settings_toggle_button != null:
		settings_toggle_button.text = "Zastosuj"
	if reset_settings_button != null:
		reset_settings_button.visible = true
	if save_close_button != null:
		save_close_button.visible = not main_view_saved
	if settings_header_button != null:
		settings_header_button.visible = main_view_saved


func _apply_main_view_mode(saved: bool) -> void:
	main_view_saved = saved
	if not saved:
		calendar_only_mode = false
	_update_main_scroll_touch_mode()

	if main_scroll != null:
		main_scroll.visible = not calendar_only_mode
	if navigation_panel != null:
		navigation_panel.visible = not calendar_only_mode
	if quick_navigation_panel != null:
		quick_navigation_panel.visible = false
		_set_month_picker_visible(false)
	if summary_label != null:
		summary_label.visible = not saved and not calendar_only_mode
	if legend_bar != null:
		legend_bar.visible = not saved and not calendar_only_mode
	_sync_calendar_touch_shield()
	if settings_toggle_button != null:
		settings_toggle_button.visible = not saved and not calendar_only_mode
	if settings_panel != null and (saved or calendar_only_mode):
		settings_panel.visible = false
	if header_bar != null:
		header_bar.visible = not calendar_only_mode
	if return_today_spacer != null:
		return_today_spacer.visible = not calendar_only_mode
	if return_today_button != null:
		return_today_button.visible = not calendar_only_mode
	if profile_overlay != null:
		profile_overlay.visible = not calendar_only_mode
	if reset_settings_button != null:
		reset_settings_button.visible = not calendar_only_mode
	if save_close_button != null:
		save_close_button.visible = not saved and not calendar_only_mode
	if settings_header_button != null:
		settings_header_button.visible = saved and not calendar_only_mode
	if day_tools_panel != null:
		day_tools_panel.visible = not calendar_only_mode
	if calendar_only_toggle_button != null:
		calendar_only_toggle_button.visible = saved and not calendar_only_mode
	if calendar_only_return_button != null:
		calendar_only_return_button.visible = calendar_only_mode
	if calendar_only_mode:
		_set_profile_panel_visible(false)
	_apply_day_tools_visibility()
	_update_undo_buttons()


func _update_main_scroll_touch_mode() -> void:
	if main_scroll == null:
		return

	main_scroll.scroll_deadzone = TOUCH_SCROLL_DEADZONE_MENU
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if calendar_only_mode else ScrollContainer.SCROLL_MODE_AUTO
	if calendar_only_mode:
		main_scroll.scroll_vertical = 0
	_lock_horizontal_scroll_deferred()


func _sync_calendar_root_width() -> void:
	if calendar_root == null and options_root == null:
		return

	var available_width := get_viewport_rect().size.x - 36.0 - SCROLLBAR_TOUCH_WIDTH
	if main_scroll != null and main_scroll.size.x > 0.0:
		available_width = main_scroll.size.x - SCROLLBAR_TOUCH_WIDTH
	if available_width <= 0.0:
		return

	var root_width := minf(float(PORTRAIT_WIDTH), available_width)
	if calendar_root != null:
		calendar_root.custom_minimum_size.x = root_width
	if options_root != null:
		options_root.custom_minimum_size.x = root_width
	_lock_horizontal_scroll_deferred()


func _update_undo_buttons() -> void:
	if reset_settings_button != null:
		reset_settings_button.text = "Resetuj"
	if undo_button != null:
		undo_button.disabled = not undo_available
	if reset_undo_button != null:
		reset_undo_button.visible = reset_undo_available and not calendar_only_mode


func _on_reset_pressed() -> void:
	_reset_calendar_settings()


func _on_undo_pressed() -> void:
	_undo_last_action()


func _on_reset_undo_pressed() -> void:
	_undo_calendar_reset()


func _save_settings_to_disk() -> void:
	if schedule_option == null:
		return

	var config := ConfigFile.new()
	config.set_value("ui", "main_view_saved", main_view_saved)
	config.set_value("ui", "calendar_only_mode", calendar_only_mode)
	config.set_value("ui", "cycle_pending_apply", cycle_pending_apply)
	config.set_value("ui", "day_tools_visible", day_tools_visible)
	config.set_value("ui", "quick_navigation_body_visible", quick_navigation_body_visible)
	config.set_value("undo", "available", undo_available)
	config.set_value("undo", "snapshot", undo_snapshot.duplicate(true))
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
	calendar_only_mode = bool(config.get_value("ui", "calendar_only_mode", false))
	if calendar_only_mode:
		main_view_saved = true
	cycle_pending_apply = bool(config.get_value("ui", "cycle_pending_apply", false))
	day_tools_visible = bool(config.get_value("ui", "day_tools_visible", true))
	quick_navigation_body_visible = bool(config.get_value("ui", "quick_navigation_body_visible", true))
	_apply_quick_navigation_body_visibility()
	undo_available = bool(config.get_value("undo", "available", false))
	_load_undo_snapshot(config.get_value("undo", "snapshot", {}))
	reset_undo_available = bool(config.get_value("undo_reset", "available", false))
	_load_reset_undo_snapshot(config.get_value("undo_reset", "snapshot", {}))
	profile_count = maxi(DEFAULT_PROFILE_COUNT, int(config.get_value("profiles", "count", DEFAULT_PROFILE_COUNT)))
	selected_profile_index = clampi(int(config.get_value("profiles", "selected", 1)), 1, profile_count)
	_load_saved_profiles(config.get_value("profiles", "items", {}))
	_refresh_profile_options()
	_set_profile_panel_visible(false)
	current_year = int(config.get_value("calendar", "current_year", current_year))
	current_month = clampi(int(config.get_value("calendar", "current_month", current_month)), 1, 12)
	_accept_calendar_page()

	_set_option_selected(schedule_option, _valid_option_index(schedule_option, int(config.get_value("calendar", "schedule_selected", 0))))
	_set_option_selected(range_option, _valid_option_index(range_option, int(config.get_value("calendar", "range_selected", 0))))
	_sync_quick_range_option()
	_set_option_selected(pause_option, _valid_option_index(pause_option, int(config.get_value("work", "pause_selected", 0))))
	_set_spin_value(system_work_spin, int(config.get_value("calendar", "work_days", int(system_work_spin.value))))
	_set_spin_value(system_home_spin, int(config.get_value("calendar", "home_days", int(system_home_spin.value))))
	_set_spin_value(custom_length_spin, int(config.get_value("calendar", "custom_length", int(custom_length_spin.value))))

	start_input.text = String(config.get_value("calendar", "start_date", ""))
	start_input.set_meta("last_text", start_input.text)

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


func _load_undo_snapshot(value: Variant) -> void:
	undo_snapshot.clear()
	if value is Dictionary and value.has("calendar"):
		undo_snapshot = value.duplicate(true)
	if undo_snapshot.is_empty():
		undo_available = false


func _app_state_snapshot() -> Dictionary:
	return {
		"calendar": _calendar_state_snapshot(),
		"profile_count": profile_count,
		"selected_profile_index": selected_profile_index,
		"saved_profiles": saved_profiles.duplicate(true),
		"profile_panel_visible": profile_panel_visible,
		"reset_undo_available": reset_undo_available,
		"reset_undo_snapshot": reset_undo_snapshot.duplicate(true),
	}


func _store_undo_snapshot(snapshot: Dictionary) -> void:
	if restoring_undo_state or snapshot.is_empty():
		return

	undo_snapshot = snapshot.duplicate(true)
	undo_available = true
	_update_undo_buttons()


func _capture_undo_state() -> void:
	_store_undo_snapshot(_app_state_snapshot())


func _capture_undo_state_for_option(option: OptionButton, previous_index: int) -> void:
	if option == null or option.selected == previous_index:
		return

	var snapshot := _app_state_snapshot()
	var calendar: Dictionary = snapshot["calendar"]
	if option == schedule_option:
		calendar["schedule_selected"] = previous_index
	elif option == range_option:
		calendar["range_selected"] = previous_index
	elif option == pause_option:
		calendar["pause_selected"] = previous_index
	elif option == fixed_start_option:
		calendar["fixed_start_selected"] = previous_index
	elif option == profile_option:
		snapshot["selected_profile_index"] = clampi(previous_index + 1, 1, profile_count)
	_store_undo_snapshot(snapshot)


func _capture_undo_state_for_spin(spin: SpinBox, previous_value: float) -> void:
	if spin == null or int(spin.value) == int(previous_value):
		return

	var snapshot := _app_state_snapshot()
	var calendar: Dictionary = snapshot["calendar"]
	if spin == system_work_spin:
		calendar["work_days"] = int(previous_value)
	elif spin == system_home_spin:
		calendar["home_days"] = int(previous_value)
	elif spin == custom_length_spin:
		calendar["custom_length"] = int(previous_value)
	_store_undo_snapshot(snapshot)


func _capture_undo_state_for_toggle(toggle: CheckButton, previous_pressed: bool) -> void:
	if toggle == null or toggle.button_pressed == previous_pressed:
		return

	var snapshot := _app_state_snapshot()
	var calendar: Dictionary = snapshot["calendar"]
	if toggle == weekly_rest_toggle:
		calendar["weekly_rest"] = previous_pressed
	elif toggle == fixed_start_toggle:
		calendar["fixed_start_enabled"] = previous_pressed
	_store_undo_snapshot(snapshot)


func _capture_undo_state_for_start_text(previous_text: String) -> void:
	if start_input == null or start_input.text == previous_text:
		return

	var snapshot := _app_state_snapshot()
	var calendar: Dictionary = snapshot["calendar"]
	calendar["start_date"] = previous_text
	_store_undo_snapshot(snapshot)


func _restore_app_state_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty() or not snapshot.has("calendar"):
		return

	restoring_undo_state = true
	profile_count = maxi(DEFAULT_PROFILE_COUNT, int(snapshot.get("profile_count", DEFAULT_PROFILE_COUNT)))
	selected_profile_index = int(snapshot.get("selected_profile_index", 1))
	_load_saved_profiles(snapshot.get("saved_profiles", {}))
	selected_profile_index = clampi(selected_profile_index, 1, profile_count)
	reset_undo_available = bool(snapshot.get("reset_undo_available", false))
	_load_reset_undo_snapshot(snapshot.get("reset_undo_snapshot", {}))
	_restore_calendar_state(snapshot["calendar"])
	_refresh_profile_options()
	_set_profile_panel_visible(bool(snapshot.get("profile_panel_visible", false)))
	restoring_undo_state = false
	_update_undo_buttons()


func _undo_last_action() -> void:
	if undo_snapshot.is_empty():
		undo_available = false
		_update_undo_buttons()
		_save_settings_to_disk()
		return

	var snapshot := undo_snapshot.duplicate(true)
	undo_available = false
	undo_snapshot.clear()
	_restore_app_state_snapshot(snapshot)
	_update_undo_buttons()
	_save_settings_to_disk()


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
	var previous_index := int(profile_option.get_meta("last_selected", profile_option.selected))
	if _option_change_was_scroll(profile_option, index):
		return

	_capture_undo_state_for_option(profile_option, previous_index)
	profile_option.set_meta("last_selected", index)
	selected_profile_index = clampi(index + 1, 1, profile_count)
	_update_profile_actions()
	_save_settings_to_disk()


func _on_save_profile_pressed() -> void:
	var undo_before := _app_state_snapshot()
	if not _apply_settings(false, true):
		if profile_status_label != null:
			profile_status_label.text = "Popraw ustawienia przed zapisem profilu."
		return

	_store_undo_snapshot(undo_before)
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

	_capture_undo_state()
	var snapshot: Dictionary = saved_profiles[_selected_profile_key()].duplicate(true)
	reset_undo_available = false
	reset_undo_snapshot.clear()
	_restore_calendar_state(snapshot)
	_refresh_profile_options()
	_set_profile_panel_visible(true)
	if profile_status_label != null:
		profile_status_label.text = "Wczytano profil %d." % selected_profile_index
	_update_undo_buttons()
	_save_settings_to_disk()


func _on_delete_profile_pressed() -> void:
	_capture_undo_state()
	var deleted_index := selected_profile_index
	saved_profiles.erase(_selected_profile_key())
	_refresh_profile_options()
	_set_profile_panel_visible(false)
	if profile_status_label != null:
		profile_status_label.text = "Usunięto profil %d." % deleted_index
	_save_settings_to_disk()


func _on_add_profile_pressed() -> void:
	_capture_undo_state()
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
		"calendar_only_mode": calendar_only_mode,
		"cycle_pending_apply": cycle_pending_apply,
		"day_tools_visible": day_tools_visible,
		"quick_navigation_body_visible": quick_navigation_body_visible,
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
	calendar_only_mode = bool(snapshot.get("calendar_only_mode", false))
	if calendar_only_mode:
		main_view_saved = true
	cycle_pending_apply = bool(snapshot.get("cycle_pending_apply", false))
	day_tools_visible = bool(snapshot.get("day_tools_visible", true))
	quick_navigation_body_visible = bool(snapshot.get("quick_navigation_body_visible", true))
	_apply_quick_navigation_body_visibility()
	current_year = int(snapshot.get("current_year", current_year))
	current_month = clampi(int(snapshot.get("current_month", current_month)), 1, 12)
	_accept_calendar_page()

	_set_option_selected(schedule_option, _valid_option_index(schedule_option, int(snapshot.get("schedule_selected", 0))))
	_set_option_selected(range_option, _valid_option_index(range_option, int(snapshot.get("range_selected", 0))))
	_sync_quick_range_option()
	_set_option_selected(pause_option, _valid_option_index(pause_option, int(snapshot.get("pause_selected", 0))))
	_set_spin_value(system_work_spin, int(snapshot.get("work_days", int(system_work_spin.value))))
	_set_spin_value(system_home_spin, int(snapshot.get("home_days", int(system_home_spin.value))))
	_set_spin_value(custom_length_spin, int(snapshot.get("custom_length", int(custom_length_spin.value))))

	start_input.text = String(snapshot.get("start_date", ""))
	start_input.set_meta("last_text", start_input.text)
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
	start_input.set_meta("last_text", start_input.text)
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
		_update_undo_buttons()
		_save_settings_to_disk()
		return

	var snapshot := reset_undo_snapshot.duplicate(true)
	reset_undo_available = false
	reset_undo_snapshot.clear()
	_restore_calendar_state(snapshot)
	_update_undo_buttons()
	_save_settings_to_disk()


func _reset_calendar_settings() -> void:
	reset_undo_snapshot = _calendar_state_snapshot()
	reset_undo_available = true
	undo_available = false
	undo_snapshot.clear()
	main_view_saved = false
	calendar_only_mode = false
	cycle_pending_apply = false
	day_tools_visible = true
	quick_navigation_body_visible = true
	_apply_quick_navigation_body_visibility()
	_set_option_selected(schedule_option, 0)
	_set_option_selected(range_option, 0)
	_sync_quick_range_option()
	_set_option_selected(pause_option, 0)
	_set_spin_value(system_work_spin, 14)
	_set_spin_value(system_home_spin, 7)
	_set_spin_value(custom_length_spin, 21)

	start_input.text = ""
	start_input.set_meta("last_text", start_input.text)
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
	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	_accept_calendar_page()
	_refresh_today_day_index()
	_rebuild_calendar()
	_apply_main_view_mode(false)
	_apply_day_tools_visibility()
	_set_settings_visible(true)
	_update_undo_buttons()
	if main_scroll != null:
		main_scroll.set_deferred("scroll_vertical", 0)
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
	day_touch_targets.clear()

	for child in months_box.get_children():
		child.queue_free()

	var month_count := _range_months()
	var range_start_month := _visible_range_start_month()
	var counts := _count_visible_months(current_year, range_start_month, month_count)

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
			_state_name_for_day(today_day_index, today_state),
			change_days,
			calculator.cycle_label(),
		]

	var year := current_year
	var month := range_start_month
	var month_parent: Control = months_box
	if month_count > 1:
		var month_grid := GridContainer.new()
		month_grid.columns = 2
		month_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		month_grid.add_theme_constant_override("h_separation", 10)
		month_grid.add_theme_constant_override("v_separation", 18)
		_prepare_calendar_drag_blocker(month_grid)
		months_box.add_child(month_grid)
		month_parent = month_grid

	for _i in range(month_count):
		month_parent.add_child(_make_month_section(year, month))
		month += 1
		if month > 12:
			month = 1
			year += 1
	_lock_horizontal_scroll_deferred()
	call_deferred("_sync_calendar_touch_shield")


func _make_month_section(year: int, month: int) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 16)
	_prepare_calendar_drag_blocker(section)

	var title := _make_label("%s %d" % [MONTH_NAMES[month - 1], year], 33 if _range_months() == 1 else 20, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(title)

	if _range_months() == 1 and year == current_year and month == current_month and _should_show_first_cycle_hint():
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
	_prepare_calendar_drag_blocker(grid)
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


func _make_year_overview_section(year: int) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 16)
	_prepare_calendar_drag_blocker(section)

	var title := _make_label("Rok %d" % year, 33, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	_prepare_calendar_drag_blocker(grid)
	section.add_child(grid)

	var now := Time.get_datetime_dict_from_system()
	var today_year := int(now["year"])
	var today_month := int(now["month"])

	for month in range(1, 13):
		grid.add_child(_make_year_month_cell(year, month, year == today_year and month == today_month))

	return section


func _make_year_month_cell(year: int, month: int, is_current_month: bool) -> Button:
	var counts := _count_visible_months(year, month, 1)
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, 86)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.add_theme_stylebox_override("normal", _month_overview_style(_month_overview_color(counts), is_current_month))
	button.add_theme_stylebox_override("hover", _month_overview_style(_month_overview_color(counts).lightened(0.06), is_current_month))
	button.add_theme_stylebox_override("pressed", _month_overview_style(_month_overview_color(counts).darkened(0.06), is_current_month))
	button.add_theme_stylebox_override("focus", _month_overview_style(_month_overview_color(counts), true))
	_fill_year_month_tile(button, month, counts, is_current_month)
	_connect_navigation_tap(button, Callable(self, "_button_pick_month").bind(month))
	return button


func _fill_year_month_tile(button: Button, month: int, counts: Dictionary, is_current_month: bool) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	var month_label := _tile_label(MONTH_NAMES[month - 1], 18, COLOR_TEXT)
	box.add_child(month_label)

	var stats := _tile_label("P %d  D %d  24 %d" % [
		int(counts["work"]),
		int(counts["home"]),
		int(counts["rest"]),
	], 11, COLOR_TEXT_MUTED)
	box.add_child(stats)

	if is_current_month:
		box.add_child(_tile_label("aktualny", 10, COLOR_TODAY))


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
	if _range_months() == 1:
		_connect_tap(button, Callable(self, "_open_day_actions").bind(year, month, day))
	else:
		_connect_month_select_tap(button, year, month)
	_prepare_calendar_drag_blocker(button)
	_register_day_touch_target(button, year, month, day)
	return button


func _make_day_spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, _day_cell_height())
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prepare_calendar_drag_blocker(spacer)
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

	var state_name := _state_short_name_for_day(day_index, state)
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
	_capture_undo_state()
	if _single_day_edit_active():
		_set_selected_day_override(state)
	elif _manual_cycle_setup_active():
		_stage_selected_day_state(state)
	elif state == ScheduleCalculator.DayState.VACATION:
		manual_overrides[selected_day_key] = state
		_rebuild_calendar()
	elif _is_preset_schedule():
		if state == ScheduleCalculator.DayState.WORK:
			start_input.text = selected_day_key
			start_input.set_meta("last_text", start_input.text)
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


func _single_day_edit_active() -> bool:
	return main_view_saved or calendar_only_mode


func _set_selected_day_override(state: int) -> void:
	manual_overrides[selected_day_key] = state
	_rebuild_calendar()


func _clear_selected_day_override() -> void:
	_capture_undo_state()
	manual_overrides.erase(selected_day_key)
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
		start_input.set_meta("last_text", start_input.text)

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
		start_input.set_meta("last_text", start_input.text)

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
	_capture_undo_state()
	var text := note_edit.text.strip_edges()
	if text.is_empty():
		notes.erase(selected_note_key)
	else:
		notes[selected_note_key] = text
	_rebuild_calendar()
	_save_settings_to_disk()


func _on_start_date_submitted(text: String) -> void:
	var previous_text := String(start_input.get_meta("last_text", ""))
	_capture_undo_state_for_start_text(previous_text)
	start_input.set_meta("last_text", text)
	_mark_cycle_pending()


func _on_schedule_selected(index: int) -> void:
	var previous_index := int(schedule_option.get_meta("last_selected", schedule_option.selected))
	if _option_change_was_scroll(schedule_option, index):
		return

	_capture_undo_state_for_option(schedule_option, previous_index)
	custom_panel.visible = _is_custom_schedule()
	if schedule_option.selected == 0:
		start_input.text = ""
		start_input.set_meta("last_text", start_input.text)
		manual_overrides.clear()
		cycle_pending_apply = false
	elif not _is_custom_schedule():
		_apply_preset_to_spins(schedule_option.selected)
		cycle_pending_apply = true
	else:
		cycle_pending_apply = true
	_save_settings_to_disk()


func _on_range_selected(index: int) -> void:
	if range_option == null:
		return

	var previous_index := int(range_option.get_meta("last_selected", range_option.selected))
	_apply_range_selection(index, previous_index)


func _on_quick_range_selected(index: int) -> void:
	if range_option == null or quick_range_option == null:
		return

	var previous_index := int(range_option.get_meta("last_selected", range_option.selected))
	_apply_range_selection(index, previous_index)


func _apply_range_selection(index: int, previous_index: int) -> void:
	if range_option == null:
		return

	var valid_index := _valid_option_index(range_option, index)
	_set_option_selected(range_option, valid_index)
	if quick_range_option != null:
		_set_option_selected(quick_range_option, _valid_option_index(quick_range_option, valid_index))
	_capture_undo_state_for_option(range_option, previous_index)
	_set_month_picker_visible(false)
	_rebuild_calendar()
	if main_scroll != null:
		main_scroll.set_deferred("scroll_vertical", 0)
	_save_settings_to_disk()


func _button_pick_month(month_index: int) -> void:
	if not _navigation_button_action_allowed():
		return

	if current_month == month_index and _range_months() == 1:
		_set_month_picker_visible(false)
		return

	_capture_undo_state()
	current_month = clampi(month_index, 1, 12)
	_accept_calendar_page()
	if range_option != null:
		_set_option_selected(range_option, 0)
	_sync_quick_range_option()
	_set_month_picker_visible(false)
	_rebuild_calendar()
	if main_scroll != null:
		main_scroll.set_deferred("scroll_vertical", 0)
	_save_settings_to_disk()


func _on_pause_selected(index: int) -> void:
	var previous_index := int(pause_option.get_meta("last_selected", pause_option.selected))
	if _option_change_was_scroll(pause_option, index):
		return

	_capture_undo_state_for_option(pause_option, previous_index)
	_update_pause_result()
	_save_settings_to_disk()


func _on_weekly_rest_toggled(enabled: bool) -> void:
	if _tap_is_blocked():
		weekly_rest_toggle.set_pressed_no_signal(weekly_rest_previous_pressed)
		return

	_capture_undo_state_for_toggle(weekly_rest_toggle, weekly_rest_previous_pressed)
	weekly_rest_previous_pressed = enabled
	cycle_pending_apply = true
	_save_settings_to_disk()


func _on_fixed_start_toggled(enabled: bool) -> void:
	if _tap_is_blocked():
		fixed_start_toggle.set_pressed_no_signal(fixed_start_previous_pressed)
		if fixed_start_option != null:
			fixed_start_option.visible = fixed_start_previous_pressed
		return

	_capture_undo_state_for_toggle(fixed_start_toggle, fixed_start_previous_pressed)
	fixed_start_previous_pressed = enabled
	if fixed_start_option != null:
		fixed_start_option.visible = enabled
	cycle_pending_apply = true
	_save_settings_to_disk()


func _on_fixed_start_day_selected(index: int) -> void:
	var previous_index := int(fixed_start_option.get_meta("last_selected", fixed_start_option.selected))
	if _option_change_was_scroll(fixed_start_option, index):
		return

	_capture_undo_state_for_option(fixed_start_option, previous_index)
	cycle_pending_apply = true
	_save_settings_to_disk()


func _on_custom_length_spin_changed(value: float) -> void:
	var previous_value := float(custom_length_spin.get_meta("last_value", custom_length_spin.value))
	if _spin_change_was_scroll(custom_length_spin, value):
		return

	_capture_undo_state_for_spin(custom_length_spin, previous_value)
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
			return 6
		3:
			return 12
	return 1


func _visible_range_start_month() -> int:
	match _range_months():
		3:
			if current_month <= 3:
				return 1
			if current_month <= 6:
				return 4
			if current_month <= 9:
				return 7
			return 10
		6:
			return 1 if current_month <= 6 else 7
		12:
			return 1
	return current_month


func _day_cell_height() -> int:
	match _range_months():
		3, 6:
			return 56
		12:
			return 56
	return 84


func _tile_day_font_size() -> int:
	match _range_months():
		3, 6:
			return 17
		12:
			return 17
	return 26


func _tile_weekday_font_size() -> int:
	match _range_months():
		3, 6:
			return 9
		12:
			return 9
	return 14


func _tile_badge_font_size() -> int:
	match _range_months():
		3, 6:
			return 8
		12:
			return 8
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


func _state_name_for_day(day_index: int, state: int) -> String:
	if state == ScheduleCalculator.DayState.REST and _rest_connects_to_neighbor(day_index):
		return "pauza 45h"
	return _state_name(state)


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


func _state_short_name_for_day(day_index: int, state: int) -> String:
	if state == ScheduleCalculator.DayState.REST and _rest_connects_to_neighbor(day_index):
		return "45h"
	return _state_short_name(state)


func _rest_connects_to_neighbor(day_index: int) -> bool:
	return (
		_visual_state_for_day(day_index - 1, _date_key_from_day_index(day_index - 1)) == ScheduleCalculator.DayState.REST
		or _visual_state_for_day(day_index + 1, _date_key_from_day_index(day_index + 1)) == ScheduleCalculator.DayState.REST
	)


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


func _month_overview_color(counts: Dictionary) -> Color:
	var best_state := ScheduleCalculator.DayState.NONE
	var best_count := int(counts.get("none", 0))
	var candidates := [
		{"state": ScheduleCalculator.DayState.WORK, "count": int(counts.get("work", 0))},
		{"state": ScheduleCalculator.DayState.HOME, "count": int(counts.get("home", 0))},
		{"state": ScheduleCalculator.DayState.REST, "count": int(counts.get("rest", 0))},
		{"state": ScheduleCalculator.DayState.VACATION, "count": int(counts.get("vacation", 0))},
	]

	for candidate in candidates:
		var candidate_count := int(candidate["count"])
		if candidate_count > best_count:
			best_count = candidate_count
			best_state = int(candidate["state"])

	return _state_color(best_state)


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
			var previous_value := float(spin.get_meta("last_value", spin.value))
			if _spin_change_was_scroll(spin, changed_value):
				return
			_capture_undo_state_for_spin(spin, previous_value)
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


func _sync_quick_range_option() -> void:
	if range_option == null or quick_range_option == null:
		return

	_set_option_selected(quick_range_option, _valid_option_index(quick_range_option, range_option.selected))


func _prepare_large_dropdown(option: OptionButton) -> void:
	var popup := option.get_popup()
	popup.min_size = Vector2i(300, 250)
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_constant_override("v_separation", 14)
	popup.add_theme_constant_override("item_start_padding", 18)
	popup.add_theme_constant_override("item_end_padding", 18)


func _option_change_was_scroll(option: OptionButton, index: int) -> bool:
	if not touch_drag_cancelled:
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


func _connect_navigation_tap(button: BaseButton, action: Callable) -> void:
	_register_scroll_safe_control(button)
	if not navigation_buttons.has(button):
		navigation_buttons.append(button)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.pressed.connect(func() -> void:
		_run_navigation_button_action_for_button(button, action)
	)


func _connect_month_select_tap(button: BaseButton, year: int, month: int) -> void:
	_register_scroll_safe_control(button)
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.pressed.connect(func() -> void:
		if touch_drag_cancelled:
			return
		_open_month_from_overview(year, month)
	)


func _prepare_calendar_drag_blocker(control: Control) -> void:
	if control.has_meta("calendar_drag_blocker_registered"):
		return

	control.set_meta("calendar_drag_blocker_registered", true)
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	control.gui_input.connect(_handle_calendar_area_input)


func _handle_calendar_area_input(event: InputEvent) -> void:
	_track_scroll_touch(event)
	if not _event_is_drag_motion(event):
		return

	_block_touch_drag_actions()
	_lock_horizontal_scroll_deferred()
	accept_event()
	get_viewport().set_input_as_handled()


func _handle_navigation_button_input(event: InputEvent, button: BaseButton, action: Callable) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_navigation_button_tap(button, touch.position)
		else:
			_finish_navigation_button_tap(button, action, touch.position)
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_begin_navigation_button_tap(button, mouse_button.position)
		else:
			_finish_navigation_button_tap(button, action, mouse_button.position)
	elif _event_is_drag_motion(event):
		_block_touch_drag_actions()
		_cancel_navigation_button_tap_if_moved(button, _event_pointer_position(event))


func _begin_navigation_button_tap(button: BaseButton, position: Vector2) -> void:
	var viewport_position := _control_event_to_viewport_position(button, position)
	button.set_meta("nav_press_position", position)
	button.set_meta("nav_press_viewport_position", viewport_position)
	button.set_meta("nav_press_generation", touch_drag_block_generation)
	button.set_meta("nav_press_msec", int(Time.get_ticks_msec()))
	button.set_meta("nav_press_scroll", _current_vertical_scroll())


func _finish_navigation_button_tap(button: BaseButton, action: Callable, position: Vector2) -> void:
	var clean_tap := _navigation_button_tap_is_clean(button, position)
	_clear_navigation_button_tap(button)
	button.set_pressed_no_signal(false)
	accept_event()

	if not clean_tap:
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	_run_navigation_button_action_for_button(button, action)


func _cancel_navigation_button_tap_if_moved(button: BaseButton, position: Vector2) -> void:
	if not button.has_meta("nav_press_position"):
		_block_touch_drag_actions()
		button.set_pressed_no_signal(false)
		_lock_horizontal_scroll_deferred()
		return

	var start_position: Vector2 = button.get_meta("nav_press_position", position)
	var start_viewport_position: Vector2 = button.get_meta("nav_press_viewport_position", _control_event_to_viewport_position(button, position))
	var viewport_position := _control_event_to_viewport_position(button, position)
	var event_moved := start_position.distance_to(position) > NAVIGATION_TAP_MOVE_LIMIT
	var viewport_moved := start_viewport_position.distance_to(viewport_position) > NAVIGATION_TAP_MOVE_LIMIT
	if not event_moved and not viewport_moved:
		return

	_block_touch_drag_actions()
	_clear_navigation_button_tap(button)
	button.set_pressed_no_signal(false)
	_lock_horizontal_scroll_deferred()


func _navigation_button_tap_is_clean(button: BaseButton, position: Vector2) -> bool:
	if touch_drag_cancelled:
		return false
	if not button.has_meta("nav_press_position"):
		return false

	var start_generation := int(button.get_meta("nav_press_generation", touch_drag_block_generation))
	if start_generation != touch_drag_block_generation:
		return false

	var start_msec := int(button.get_meta("nav_press_msec", int(Time.get_ticks_msec())))
	if int(Time.get_ticks_msec()) - start_msec > NAVIGATION_TAP_MAX_MS:
		return false

	var start_scroll := float(button.get_meta("nav_press_scroll", _current_vertical_scroll()))
	if absf(_current_vertical_scroll() - start_scroll) > NAVIGATION_TAP_SCROLL_LIMIT:
		return false

	var start_position: Vector2 = button.get_meta("nav_press_position", position)
	if start_position.distance_to(position) > NAVIGATION_TAP_MOVE_LIMIT:
		return false

	var start_viewport_position: Vector2 = button.get_meta("nav_press_viewport_position", _control_event_to_viewport_position(button, position))
	var viewport_position := _control_event_to_viewport_position(button, position)
	if start_viewport_position.distance_to(viewport_position) > NAVIGATION_TAP_MOVE_LIMIT:
		return false

	return true


func _control_event_to_viewport_position(control: Control, position: Vector2) -> Vector2:
	return control.get_global_transform_with_canvas() * position


func _event_pointer_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).position
	if event is InputEventPanGesture:
		return (event as InputEventPanGesture).position

	return get_viewport().get_mouse_position()


func _current_vertical_scroll() -> float:
	if main_scroll == null:
		return 0.0

	return float(main_scroll.scroll_vertical)


func _run_navigation_button_action(action: Callable) -> void:
	_allow_navigation_action_once()
	navigation_button_action_active = true
	calendar_navigation_command_depth += 1
	action.call()
	calendar_navigation_command_depth = maxi(calendar_navigation_command_depth - 1, 0)
	navigation_button_action_active = false


func _run_navigation_button_action_for_button(button: BaseButton, action: Callable) -> void:
	if not is_instance_valid(button):
		return

	var now_msec := int(Time.get_ticks_msec())
	var last_action_msec := int(button.get_meta("nav_action_msec", -10000))
	if now_msec - last_action_msec >= 0 and now_msec - last_action_msec < 120:
		return

	button.set_meta("nav_action_msec", now_msec)
	_run_navigation_button_action(action)


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

	var now_msec := int(Time.get_ticks_msec())
	if now_msec <= navigation_blocked_until_msec:
		return true

	var elapsed_msec := now_msec - last_drag_release_msec
	return elapsed_msec >= 0 and elapsed_msec < TAP_BLOCK_AFTER_DRAG_MS


func _track_scroll_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_touch_tracking(touch.position)
		else:
			_update_touch_tracking(touch.position)
			_end_touch_tracking()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		touch_drag_total += drag.relative
		_block_touch_drag_actions()
		_update_touch_tracking(drag.position)
	elif event is InputEventPanGesture:
		var pan := event as InputEventPanGesture
		_block_touch_drag_actions()
		_update_touch_tracking(pan.position)
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_begin_touch_tracking(mouse_button.position)
			else:
				_update_touch_tracking(mouse_button.position)
				_end_touch_tracking()
	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if mouse_motion.button_mask != 0:
			touch_drag_total += mouse_motion.relative
			_block_touch_drag_actions()
			_update_touch_tracking(mouse_motion.position)


func _consume_calendar_only_drag(event: InputEvent) -> bool:
	if not calendar_only_mode or not _event_is_drag_motion(event):
		return false

	_block_touch_drag_actions()
	_lock_horizontal_scroll_deferred()
	get_viewport().set_input_as_handled()
	return true


func _consume_horizontal_drag(event: InputEvent, accept_gui_event: bool = false) -> bool:
	if not _event_is_horizontal_drag(event):
		return false

	_block_touch_drag_actions()
	_lock_horizontal_scroll_deferred()
	if accept_gui_event:
		accept_event()
	get_viewport().set_input_as_handled()
	return true


func _event_is_drag_motion(event: InputEvent) -> bool:
	if event is InputEventScreenDrag or event is InputEventPanGesture:
		return true
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		return (mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0

	return false


func _event_is_horizontal_drag(event: InputEvent) -> bool:
	if not _event_is_drag_motion(event):
		return false

	var delta := _event_drag_delta(event)
	var horizontal := absf(delta.x)
	var vertical := absf(delta.y)
	if touch_tracking_active:
		horizontal = maxf(horizontal, absf(touch_drag_total.x))
		vertical = maxf(vertical, absf(touch_drag_total.y))

	return horizontal >= TOUCH_DRAG_CANCEL_DISTANCE and horizontal > vertical * 1.2


func _event_drag_delta(event: InputEvent) -> Vector2:
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).relative
	if event is InputEventPanGesture:
		return (event as InputEventPanGesture).delta
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if (mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			return mouse_motion.relative

	return Vector2.ZERO


func _block_calendar_touch_drag(event: InputEvent) -> bool:
	var position := Vector2.ZERO

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		position = drag.position
	elif event is InputEventPanGesture:
		var pan := event as InputEventPanGesture
		position = pan.position
	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if (mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return false
		position = mouse_motion.position
	else:
		return false

	var starts_on_calendar := touch_tracking_active and _point_inside_calendar_area(touch_start_position)
	var is_over_calendar := _point_inside_calendar_area(position)
	if not starts_on_calendar and not is_over_calendar:
		return false

	_block_touch_drag_actions()
	_lock_horizontal_scroll_deferred()
	get_viewport().set_input_as_handled()
	return true


func _point_inside_calendar_area(position: Vector2) -> bool:
	var target: Control = months_box if months_box != null and is_instance_valid(months_box) else calendar_root
	if target == null or not is_instance_valid(target) or not target.visible:
		return false

	return target.get_global_rect().has_point(position)


func _begin_touch_tracking(position: Vector2) -> void:
	touch_tracking_active = true
	touch_start_position = position
	touch_drag_total = Vector2.ZERO
	touch_drag_cancelled = false


func _update_touch_tracking(position: Vector2) -> void:
	if not touch_tracking_active:
		return

	if not touch_drag_cancelled and touch_start_position.distance_to(position) > TOUCH_DRAG_CANCEL_DISTANCE:
		_block_touch_drag_actions()


func _end_touch_tracking() -> void:
	if touch_drag_cancelled:
		last_drag_release_msec = int(Time.get_ticks_msec())

	touch_tracking_active = false


func _block_touch_drag_actions() -> void:
	touch_drag_block_generation += 1
	touch_drag_cancelled = true
	_block_navigation_after_scroll()
	_release_scroll_buttons()
	_cancel_navigation_button_taps()


func _cancel_navigation_button_taps() -> void:
	for index in range(navigation_buttons.size() - 1, -1, -1):
		var button := navigation_buttons[index]
		if not is_instance_valid(button):
			navigation_buttons.remove_at(index)
		else:
			_clear_navigation_button_tap(button)


func _clear_navigation_button_tap(button: BaseButton) -> void:
	if not is_instance_valid(button):
		return

	if button.has_meta("nav_press_position"):
		button.remove_meta("nav_press_position")
	if button.has_meta("nav_press_viewport_position"):
		button.remove_meta("nav_press_viewport_position")
	if button.has_meta("nav_press_generation"):
		button.remove_meta("nav_press_generation")
	if button.has_meta("nav_press_msec"):
		button.remove_meta("nav_press_msec")
	if button.has_meta("nav_press_scroll"):
		button.remove_meta("nav_press_scroll")
	if not button.toggle_mode:
		button.set_pressed_no_signal(false)


func _accept_calendar_page() -> void:
	confirmed_calendar_year = current_year
	confirmed_calendar_month = current_month
	calendar_page_guard_ready = true


func _restore_unapproved_calendar_page() -> void:
	if not calendar_page_guard_ready:
		return
	if current_year == confirmed_calendar_year and current_month == confirmed_calendar_month:
		return

	current_year = confirmed_calendar_year
	current_month = confirmed_calendar_month
	_rebuild_calendar()


func _allow_navigation_action_once() -> void:
	navigation_action_unlock_msec = int(Time.get_ticks_msec())


func _navigation_action_allowed() -> bool:
	var elapsed_msec := int(Time.get_ticks_msec()) - navigation_action_unlock_msec
	navigation_action_unlock_msec = -10000
	return elapsed_msec >= 0 and elapsed_msec <= TAP_BLOCK_AFTER_DRAG_MS


func _navigation_button_action_allowed() -> bool:
	if not navigation_button_action_active:
		navigation_action_unlock_msec = -10000
		return false
	if calendar_navigation_command_depth <= 0:
		navigation_action_unlock_msec = -10000
		return false

	return _navigation_action_allowed()


func _block_navigation_after_scroll() -> void:
	var now_msec := int(Time.get_ticks_msec())
	last_drag_release_msec = now_msec
	navigation_blocked_until_msec = now_msec + NAVIGATION_BLOCK_AFTER_SCROLL_MS
	navigation_action_unlock_msec = -10000


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


func _month_overview_style(color: Color, is_current_month: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(14)
	style.set_border_width_all(2 if is_current_month else 1)
	style.border_color = COLOR_TODAY if is_current_month else Color(1.0, 1.0, 1.0, 0.16)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
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
	if not scroll_bar.value_changed.is_connected(_on_main_scroll_vertical_changed):
		scroll_bar.value_changed.connect(_on_main_scroll_vertical_changed)

	var horizontal_bar := main_scroll.get_h_scroll_bar()
	horizontal_bar.visible = false
	horizontal_bar.custom_minimum_size.y = 0
	horizontal_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not horizontal_bar.value_changed.is_connected(_on_horizontal_scroll_changed):
		horizontal_bar.value_changed.connect(_on_horizontal_scroll_changed)


func _on_horizontal_scroll_changed(value: float) -> void:
	if value != 0.0:
		_lock_horizontal_scroll_deferred()


func _on_main_scroll_vertical_changed(_value: float) -> void:
	_block_touch_drag_actions()


func _lock_horizontal_scroll_deferred() -> void:
	if main_scroll == null:
		return

	_lock_horizontal_scroll()
	main_scroll.set_deferred("scroll_horizontal", 0)
	main_scroll.get_h_scroll_bar().set_deferred("value", 0)


func _lock_horizontal_scroll() -> void:
	if main_scroll == null:
		return

	var horizontal_bar := main_scroll.get_h_scroll_bar()
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.scroll_horizontal = 0
	horizontal_bar.value = 0
	horizontal_bar.visible = false
	horizontal_bar.custom_minimum_size.y = 0
	horizontal_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
	_capture_undo_state()
	work_start_unix = int(Time.get_unix_time_from_system())
	work_end_unix = 0
	work_status_label.text = "Start pracy: %s" % _format_unix_time(work_start_unix)
	pause_result_label.text = ""
	_save_settings_to_disk()


func _on_end_work_pressed() -> void:
	if work_start_unix <= 0:
		work_status_label.text = "Najpierw kliknij rozpoczęcie pracy."
		return

	_capture_undo_state()
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


func _button_previous_month() -> void:
	if not _navigation_button_action_allowed():
		return

	_capture_undo_state()
	_shift_current_month(-_navigation_step_months())
	_accept_calendar_page()
	_rebuild_calendar()
	_save_settings_to_disk()


func _button_previous_year() -> void:
	if not _navigation_button_action_allowed():
		return

	_capture_undo_state()
	current_year -= 1
	_accept_calendar_page()
	_rebuild_calendar()
	_save_settings_to_disk()


func _button_next_month() -> void:
	if not _navigation_button_action_allowed():
		return

	_capture_undo_state()
	_shift_current_month(_navigation_step_months())
	_accept_calendar_page()
	_rebuild_calendar()
	_save_settings_to_disk()


func _button_next_year() -> void:
	if not _navigation_button_action_allowed():
		return

	_capture_undo_state()
	current_year += 1
	_accept_calendar_page()
	_rebuild_calendar()
	_save_settings_to_disk()


func _button_return_to_today() -> void:
	if not _navigation_button_action_allowed():
		return

	_capture_undo_state()
	var now := Time.get_datetime_dict_from_system()
	current_year = int(now["year"])
	current_month = int(now["month"])
	_accept_calendar_page()
	_refresh_today_day_index()
	_rebuild_calendar()
	if main_scroll != null:
		main_scroll.set_deferred("scroll_vertical", 0)
	_save_settings_to_disk()


func _open_month_from_overview(year: int, month: int) -> void:
	_capture_undo_state()
	current_year = year
	current_month = clampi(month, 1, 12)
	if range_option != null:
		_set_option_selected(range_option, 0)
	_sync_quick_range_option()
	_set_month_picker_visible(false)
	_accept_calendar_page()
	_rebuild_calendar()
	if main_scroll != null:
		main_scroll.set_deferred("scroll_vertical", 0)
	_save_settings_to_disk()


func _navigation_step_months() -> int:
	var month_count := _range_months()
	if month_count >= 12:
		return 12
	return maxi(month_count, 1)


func _shift_current_month(month_delta: int) -> void:
	current_month += month_delta
	while current_month < 1:
		current_month += 12
		current_year -= 1
	while current_month > 12:
		current_month -= 12
		current_year += 1


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

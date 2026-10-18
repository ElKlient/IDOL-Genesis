extends CanvasLayer
class_name GameHUD

signal attack_requested
signal skill_requested
signal fire_skill_requested
signal camera_orbit_requested(delta: Vector2)
signal potion_requested
signal interact_requested
signal close_requested

const CREAM: Color = Color("f1e4c8")
const MUTED: Color = Color("a7bbb4")
const GOLD: Color = Color("e4bd77")
const GREEN: Color = Color("72cbae")
const INK: Color = Color("10232b")

var move_vector: Vector2 = Vector2.ZERO
var attack_held: bool = false
var modal_open: bool = false
var hero: Node3D
var screen: Control
var joystick: RPGJoystick
var attack_pad: RPGTouchPad
var skill_pad: RPGTouchPad
var fire_pad: RPGTouchPad
var camera_pad: CameraOrbitPad
var fire_skill_text: Label
var fire_status_text: Label
var fire_glyph: Control
var potion_pad: RPGTouchPad
var context_button: Button
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var hp_text: Label
var level_text: Label
var gold_text: Label
var quest_text: Label
var potion_text: Label
var target_panel: PanelContainer
var target_name: Label
var target_bar: ProgressBar
var minimap: RPGMinimap
var toast_label: Label
var toast_panel: PanelContainer
var toast_timer: float = 0.0
var overlay: ColorRect
var modal: PanelContainer
var modal_body: VBoxContainer
var modal_title: Label
var modal_gold: Label
var modal_mode: String = "inventory"
var tabs: Dictionary = {}
var selected_uid: int = -1
var selected_catalog: String = ""
var _refresh_pending: bool = false
var _forge_action_pending: bool = false
var _panel_session_id: int = 0
var _reset_confirmation: bool = false
var _audio_enabled: bool = true
var _npc_access: String = ""
var _map_time: float = 0.0
var _modal_generation: int = 0
var _diagnostics_status_label: Label
var _modal_header: HBoxContainer
var _modal_tabs: HBoxContainer
var _modal_eyebrow: Label
var _modal_column: VBoxContainer
var _camera_values: Dictionary = {}
var _camera_sliders: Dictionary = {}
var _camera_value_labels: Dictionary = {}
var _camera_grip: Texture2D
# Keep this single preview alive while cards and modal panels rebuild around it.
var character_preview: Control
var _preview_equipment_signature: String = ""
var _inventory_scroll: ScrollContainer
var _inventory_scroll_offset: int = 0
var _sword_flame_active: bool = false

class FireSwordGlyph extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var unit: float = minf(size.x,size.y)/80.0
		draw_set_transform(size*0.5,0.0,Vector2(unit,unit))
		# Three nested flames keep the ability readable at phone button size.
		draw_colored_polygon(PackedVector2Array([Vector2(-20,24),Vector2(-29,11),Vector2(-24,-5),Vector2(-17,4),Vector2(-19,-20),Vector2(-7,-9),Vector2(1,-36),Vector2(9,-15),Vector2(19,-24),Vector2(16,-4),Vector2(26,-10),Vector2(28,10),Vector2(18,25)]),Color("d9472f"))
		draw_colored_polygon(PackedVector2Array([Vector2(-16,21),Vector2(-20,8),Vector2(-11,12),Vector2(-12,-8),Vector2(-3,1),Vector2(2,-24),Vector2(10,-3),Vector2(18,-9),Vector2(16,10),Vector2(20,13),Vector2(12,24)]),Color("ff9d3f"))
		draw_colored_polygon(PackedVector2Array([Vector2(-9,20),Vector2(-12,8),Vector2(-4,12),Vector2(1,-10),Vector2(7,5),Vector2(12,0),Vector2(10,21)]),Color("ffdf80"))
		draw_colored_polygon(PackedVector2Array([Vector2(-3,12),Vector2(-3,-21),Vector2(0,-29),Vector2(3,-21),Vector2(3,12)]),Color("fff5cf"))
		draw_line(Vector2(-10,13),Vector2(10,13),Color("5d3227"),4,true)
		draw_line(Vector2(0,14),Vector2(0,27),Color("5d3227"),5,true)
		draw_circle(Vector2(0,28),3,Color("ffe1a0"))
		for spark: Vector2 in [Vector2(-27,-22),Vector2(24,-29),Vector2(29,24)]:
			draw_line(spark-Vector2(0,2),spark+Vector2(0,2),Color("fff5d6"),1.5,true)
			draw_line(spark-Vector2(2,0),spark+Vector2(2,0),Color("fff5d6"),1.5,true)
		draw_set_transform(Vector2.ZERO)

func _ready() -> void:
	layer = 10
	_build_hud()
	_build_modal()
	_audio_enabled = GameState.audio_enabled
	_connect_diagnostics()
	refresh()

func setup(player: Node3D) -> void:
	hero = player

func _process(delta: float) -> void:
	move_vector = Vector2.ZERO if modal_open else joystick.vector
	if toast_timer > 0:
		toast_timer -= delta
		toast_panel.modulate.a = minf(1.0,toast_timer*3.0)
		toast_panel.visible = toast_timer > 0
	_map_time -= delta
	if _map_time <= 0 and is_instance_valid(hero):
		_map_time = 0.15
		minimap.hero_position = hero.global_position
		minimap.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if modal_open:
			_close_panel()
		else:
			open_panel("settings")
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if modal_open and modal_mode == "inventory" and is_instance_valid(character_preview):
			character_preview.call("set_preview_active",true)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_instance_valid(character_preview):
			character_preview.call("set_preview_active",false)
		attack_held = false
		move_vector = Vector2.ZERO
		if is_instance_valid(joystick):
			joystick._reset()
		if is_instance_valid(attack_pad):
			attack_pad._release()
		if is_instance_valid(skill_pad):
			skill_pad._release()
		if is_instance_valid(potion_pad):
			potion_pad._release()
		if is_instance_valid(fire_pad):
			fire_pad._release()
		if is_instance_valid(camera_pad):
			camera_pad.cancel_drag()

func _build_hud() -> void:
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	var theme: Theme = Theme.new()
	theme.default_font_size = 18
	screen.theme = theme
	var vitals: PanelContainer = _panel(Color(0.055,0.11,0.14,0.9),Color("526459"),12,14)
	_position(vitals,Vector2(24,22),Vector2(326,106))
	screen.add_child(vitals)
	var vitals_row: HBoxContainer = HBoxContainer.new()
	vitals_row.add_theme_constant_override("separation",12)
	vitals.add_child(vitals_row)
	var portrait: PanelContainer = _panel(Color("283e3d"),Color("c0a16b"),9,1)
	portrait.custom_minimum_size = Vector2(62,70)
	vitals_row.add_child(portrait)
	var portrait_icon: RPGItemIcon = RPGItemIcon.new()
	portrait_icon.kind = "weapon"
	portrait_icon.accent = Color("cfdbd1")
	portrait.add_child(portrait_icon)
	var stats: VBoxContainer = VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation",5)
	vitals_row.add_child(stats)
	level_text = _label("WOJOWNIK  ·  POZIOM 1",14,GOLD)
	stats.add_child(level_text)
	hp_bar = _bar(Color("b34e56"),17)
	stats.add_child(hp_bar)
	hp_text = _label("180 / 180",13,CREAM)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_bar.add_child(hp_text)
	xp_bar = _bar(Color("69b6a8"),5)
	stats.add_child(xp_bar)
	var stats_hint: Label = _label("ŻELAZNY ŚWIT · v%s" % str(ProjectSettings.get_setting("application/config/version","?")),10,MUTED)
	stats.add_child(stats_hint)
	var wallet: PanelContainer = _panel(Color(0.055,0.11,0.14,0.9),Color("7b704d"),10,12)
	_position(wallet,Vector2(366,22),Vector2(150,48))
	screen.add_child(wallet)
	gold_text = _label("10 000 złota",19,GOLD)
	gold_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet.add_child(gold_text)
	var quest: PanelContainer = _panel(Color(0.05,0.1,0.12,0.77),Color(0.3,0.4,0.35,0.45),9,12)
	_position(quest,Vector2(24,140),Vector2(326,74))
	screen.add_child(quest)
	var quest_col: VBoxContainer = VBoxContainer.new()
	quest_col.add_theme_constant_override("separation",4)
	quest.add_child(quest_col)
	quest_col.add_child(_label("DZIENNIK WYPRAWY",11,GOLD))
	quest_text = _label("Kup miecz u handlarza.",14,CREAM)
	quest_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_col.add_child(quest_text)
	minimap = RPGMinimap.new()
	minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	minimap.position = Vector2(-181,22)
	minimap.size = Vector2(157,157)
	screen.add_child(minimap)
	var map_title: Label = _label("BRZEZINY",11,CREAM)
	map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_title.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	map_title.position = Vector2(0,4)
	map_title.size = Vector2(157,20)
	minimap.add_child(map_title)
	camera_pad = CameraOrbitPad.new()
	camera_pad.name = "CameraOrbitPad"
	camera_pad.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	camera_pad.position = Vector2(-181,216)
	camera_pad.size = Vector2(157,100)
	camera_pad.orbit_requested.connect(func(delta: Vector2) -> void: camera_orbit_requested.emit(delta))
	screen.add_child(camera_pad)
	var inventory: Button = _button("EKWIPUNEK",Vector2(152,48),false)
	inventory.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inventory.position = Vector2(-350,22)
	screen.add_child(inventory)
	inventory.pressed.connect(func() -> void: open_panel("inventory"))
	var menu: Button = _button("MENU",Vector2(152,44),true)
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	menu.position = Vector2(-350,78)
	screen.add_child(menu)
	menu.pressed.connect(func() -> void: open_panel("settings"))
	target_panel = _panel(Color(0.06,0.1,0.13,0.92),Color("826b57"),9,11)
	target_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	target_panel.position = Vector2(-158,82)
	target_panel.size = Vector2(316,61)
	screen.add_child(target_panel)
	var target_col: VBoxContainer = VBoxContainer.new()
	target_col.add_theme_constant_override("separation",5)
	target_panel.add_child(target_col)
	target_name = _label("Dziki wilk · poziom 1",15,CREAM)
	target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_col.add_child(target_name)
	target_bar = _bar(Color("bb6256"),8)
	target_col.add_child(target_bar)
	target_panel.hide()
	joystick = RPGJoystick.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(34,-230)
	joystick.size = Vector2(190,190)
	screen.add_child(joystick)
	var walk_hint: Label = _label("RUCH",10,Color(0.84,0.88,0.81,0.58))
	walk_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	walk_hint.position = Vector2(105,-32)
	screen.add_child(walk_hint)
	attack_pad = _action_pad("weapon",Vector2(-167,-182),118,GOLD)
	attack_pad.pressed.connect(func() -> void: attack_held = true; attack_requested.emit())
	attack_pad.released.connect(func() -> void: attack_held = false)
	_action_caption("ATAK",Vector2(-158,-58),100)
	skill_pad = _action_pad("skill",Vector2(-113,-287),78,Color("83d7cc"))
	skill_pad.pressed.connect(func() -> void: skill_requested.emit())
	_action_caption("WIR OSTRZA",Vector2(-134,-203),118)
	fire_pad = _action_pad("fire",Vector2(-246,-323),78,Color("f7974f"))
	fire_pad.name = "FireSkillPad"
	fire_pad.pressed.connect(func() -> void: fire_skill_requested.emit())
	var fire_icon: FireSwordGlyph = FireSwordGlyph.new()
	fire_glyph = fire_icon
	fire_icon.name = "FireSwordIcon"
	fire_icon.position = fire_pad.size*0.17
	fire_icon.size = fire_pad.size*0.66
	fire_pad.add_child(fire_icon)
	fire_skill_text = _action_caption("PIERDOLNIĘCIE\nMIECZA",Vector2(-286,-239),158)
	fire_skill_text.name = "FireSkillCaption"
	fire_skill_text.size.y = 36
	fire_skill_text.add_theme_font_size_override("font_size",12)
	fire_status_text = _action_caption("GOTOWE",Vector2(-267,-350),120)
	fire_status_text.name = "FireSkillStatus"
	fire_status_text.add_theme_color_override("font_color",Color("f6be77"))
	for fire_label: Label in [fire_skill_text,fire_status_text]:
		fire_label.add_theme_font_size_override("font_size",12)
		fire_label.add_theme_constant_override("outline_size",3)
		fire_label.add_theme_color_override("font_outline_color",Color("08191f"))
		fire_label.add_theme_color_override("font_shadow_color",Color(0.01,0.025,0.03,0.95))
		fire_label.add_theme_constant_override("shadow_offset_x",0)
		fire_label.add_theme_constant_override("shadow_offset_y",2)
	potion_pad = _action_pad("potion",Vector2(-276,-142),78,Color("da8e94"))
	potion_pad.pressed.connect(func() -> void: potion_requested.emit())
	potion_text = _action_caption("POTKA · 10",Vector2(-290,-58),106)
	context_button = _button("ROZMOWA",Vector2(226,54),false)
	context_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	context_button.position = Vector2(-113,-90)
	screen.add_child(context_button)
	context_button.pressed.connect(func() -> void: interact_requested.emit())
	context_button.hide()
	toast_panel = _panel(Color(0.06,0.15,0.17,0.97),Color("c8a669"),10,13)
	toast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast_panel.position = Vector2(-300,-166)
	toast_panel.size = Vector2(600,55)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(toast_panel)
	toast_label = _label("",18,CREAM)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_panel.add_child(toast_label)
	toast_panel.hide()

func _build_modal() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.015,0.035,0.045,0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(overlay)
	modal = _panel(Color("10232b"),Color("8b7957"),16,22)
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.offset_left = -556
	modal.offset_top = -304
	modal.offset_right = 556
	modal.offset_bottom = 304
	overlay.add_child(modal)
	var col: VBoxContainer = VBoxContainer.new()
	_modal_column = col
	col.add_theme_constant_override("separation",14)
	modal.add_child(col)
	var header: HBoxContainer = HBoxContainer.new()
	_modal_header = header
	header.add_theme_constant_override("separation",20)
	col.add_child(header)
	var title_col: VBoxContainer = VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)
	_modal_eyebrow = _label("ŻELAZNY ŚWIT  /  BRZEZINY",11,GOLD)
	title_col.add_child(_modal_eyebrow)
	modal_title = _label("Ekwipunek",30,CREAM)
	title_col.add_child(modal_title)
	modal_gold = _label("10 000 złota",22,GOLD)
	modal_gold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(modal_gold)
	var close: Button = _button("X",Vector2(54,54),true)
	header.add_child(close)
	close.pressed.connect(_close_panel)
	var tab_row: HBoxContainer = HBoxContainer.new()
	_modal_tabs = tab_row
	tab_row.add_theme_constant_override("separation",8)
	col.add_child(tab_row)
	for entry: Array in [["inventory","EKWIPUNEK"],["shop","HANDLARZ"],["forge","KOWAL"],["help","JAK GRAĆ"]]:
		var b: Button = _button(str(entry[1]),Vector2(140,43),true)
		b.pressed.connect(open_panel.bind(str(entry[0])))
		tab_row.add_child(b)
		tabs[str(entry[0])] = b
	modal_body = VBoxContainer.new()
	modal_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation",12)
	col.add_child(modal_body)
	overlay.hide()

func _action_pad(glyph: String, offset: Vector2, diameter: float, color: Color) -> RPGTouchPad:
	var pad: RPGTouchPad = RPGTouchPad.new()
	pad.glyph = glyph
	pad.accent = color
	pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	pad.position = offset
	pad.size = Vector2(diameter,diameter)
	screen.add_child(pad)
	return pad

func _action_caption(text: String, offset: Vector2, width: float) -> Label:
	var label: Label = _label(text,11,CREAM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.position = offset
	label.size = Vector2(width,22)
	screen.add_child(label)
	return label

func set_context(text: String) -> void:
	context_button.text = text
	context_button.visible = not text.is_empty() and not modal_open

func set_target(name: String, hp: int, max_hp: int, level: int) -> void:
	target_panel.visible = hp > 0
	target_name.text = "%s  ·  poz. %d" % [name,level]
	target_bar.max_value = max_hp
	target_bar.value = hp

func clear_target() -> void:
	target_panel.hide()

func set_skill_cooldown(remaining: float,total: float) -> void:
	skill_pad.cooldown_ratio = clampf(remaining / maxf(total,0.01),0,1)
	skill_pad.queue_redraw()

func set_fire_skill_cooldown(remaining: float,total: float,buff: float) -> void:
	if not is_instance_valid(fire_pad):
		return
	fire_pad.cooldown_ratio = clampf(remaining / maxf(total,0.01),0,1)
	fire_pad.queue_redraw()
	var status: String = "GOTOWE"
	var status_color: Color = Color("f6be77")
	if buff > 0.0:
		status = "OGIEŃ · %d s" % int(ceilf(buff))
		status_color = Color("ffd58d")
	elif remaining > 0.0:
		status = "ODNOWA · %d s" % int(ceilf(remaining))
		status_color = MUTED
	if fire_status_text.text != status:
		fire_status_text.text = status
	if fire_status_text.get_theme_color("font_color") != status_color:
		fire_status_text.add_theme_color_override("font_color",status_color)
	if is_instance_valid(fire_glyph):
		fire_glyph.modulate.a = 0.45 if remaining > 0.0 and buff <= 0.0 else 1.0
	var active: bool = buff > 0.0
	if active != _sword_flame_active:
		_sword_flame_active = active
		if is_instance_valid(character_preview) and character_preview.has_method("set_sword_flame"):
			character_preview.call("set_sword_flame",active)

func set_world_positions(hero_pos: Vector3, enemies: Array, npcs: Dictionary) -> void:
	minimap.hero_position = hero_pos
	minimap.enemy_positions = enemies
	minimap.npc_positions = npcs
	minimap.queue_redraw()

func toast(text: String) -> void:
	toast_label.text = text
	_position_inventory_toast()
	toast_timer = 3.8
	toast_panel.modulate.a = 1.0
	toast_panel.show()
	# Toasts sit above the modal so purchase and upgrade feedback stays readable.
	screen.move_child(toast_panel,-1)

func open_panel(mode: String) -> void:
	if mode.is_empty():
		close_panel()
		return
	if not modal_open:
		_npc_access = mode if mode in ["shop","forge"] else ""
	_panel_session_id += 1
	_reset_confirmation = false
	_park_inventory_preview()
	modal_mode = mode
	modal_open = true
	_diagnostic_note("ui_panel_open",{"category":mode})
	move_vector = Vector2.ZERO
	attack_held = false
	joystick.enabled = false
	attack_pad.enabled = false
	skill_pad.enabled = false
	fire_pad.enabled = false
	fire_pad._release()
	camera_pad.enabled = false
	potion_pad.enabled = false
	context_button.hide()
	overlay.show()
	_render_panel()

func _close_panel() -> void:
	close_panel()
	close_requested.emit()

func close_panel() -> void:
	if modal_open:
		_diagnostic_note("ui_panel_close",{"category":modal_mode})
		_panel_session_id += 1
	modal_open = false
	_reset_confirmation = false
	_park_inventory_preview()
	_position_inventory_toast()
	overlay.hide()
	joystick.enabled = true
	attack_pad.enabled = true
	skill_pad.enabled = true
	fire_pad.enabled = true
	camera_pad.enabled = true
	potion_pad.enabled = true

func refresh() -> void:
	if not is_instance_valid(hp_bar):
		return
	level_text.text = "WOJOWNIK  ·  POZIOM %d" % GameState.level
	hp_bar.max_value = GameState.max_health()
	hp_bar.value = GameState.hp
	hp_text.text = "%d / %d" % [GameState.hp,GameState.max_health()]
	xp_bar.max_value = GameState.xp_needed()
	xp_bar.value = GameState.xp
	gold_text.text = "%s złota" % _number(GameState.gold)
	quest_text.text = GameState.quest_text()
	potion_text.text = "POTKA · %d" % GameState.potions
	if modal_open and modal_mode != "camera":
		_render_panel()

func _render_panel() -> void:
	# GUI signals only request work. Their source button/card must stay alive
	# until Godot has finished dispatching the current input event.
	if not modal_open or _refresh_pending:
		return
	_refresh_pending = true
	call_deferred("_rebuild_panel")

func _rebuild_panel() -> void:
	if not modal_open or not is_instance_valid(modal_body):
		_refresh_pending = false
		return
	if _forge_action_pending:
		# An upgrade queued after this refresh owns the next model change.
		# Let it finish first so its changed signal joins this same rebuild.
		call_deferred("_rebuild_panel")
		return
	_refresh_pending = false
	_diagnostic_note("ui_modal_rebuild_begin",{"category":modal_mode})
	_diagnostics_status_label = null
	_modal_generation += 1
	_park_inventory_preview()
	for child: Node in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	_camera_sliders.clear()
	_camera_value_labels.clear()
	_apply_modal_layout()
	modal_gold.text = "%s złota" % _number(GameState.gold)
	for key: Variant in tabs:
		var b: Button = tabs[key]
		b.visible = key not in ["shop","forge"] or key == _npc_access
		b.add_theme_stylebox_override("normal",_style(Color("365047") if key == modal_mode else Color("172d34"),GOLD if key == modal_mode else Color("40524a"),7,1))
	var titles: Dictionary = {"inventory":"Ekwipunek wojownika","shop":"Handlarz · Mira","forge":"Kuźnia · Born","help":"Pierwsze kroki","settings":"Obozowisko","camera":"Kamera"}
	modal_title.text = str(titles.get(modal_mode,"Ekwipunek"))
	if modal_mode == "settings" and _reset_confirmation:
		_render_reset_confirmation()
	else:
		match modal_mode:
			"shop": _render_shop()
			"forge": _render_forge()
			"help": _render_help()
			"settings": _render_settings()
			"camera": _render_camera()
			_: _render_inventory()
	_diagnostic_note("ui_modal_rebuild_end",{"category":modal_mode})

func _render_inventory() -> void:
	var split := HBoxContainer.new()
	split.name = "InventoryColumns"
	split.add_theme_constant_override("separation",16)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.add_child(split)
	# Two columns leave enough width for two full-size item cards on a phone.
	var portrait_column := VBoxContainer.new()
	portrait_column.name = "InventoryPortrait"
	portrait_column.custom_minimum_size.x = 304
	portrait_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	portrait_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_column.add_theme_constant_override("separation",6)
	split.add_child(portrait_column)
	portrait_column.add_child(_label("TWÓJ WOJOWNIK  ·  PRZECIĄGNIJ, BY OBRÓCIĆ",11,GOLD))
	_attach_inventory_preview(portrait_column)
	var rotation_row := HBoxContainer.new()
	rotation_row.add_theme_constant_override("separation",6)
	portrait_column.add_child(rotation_row)
	_preview_button(rotation_row,"W LEWO","PreviewRotateLeft",func() -> void: _rotate_inventory_preview(-30.0))
	_preview_button(rotation_row,"RESET","PreviewReset",func() -> void:
		if is_instance_valid(character_preview):
			character_preview.call("reset_view")
	)
	_preview_button(rotation_row,"W PRAWO","PreviewRotateRight",func() -> void: _rotate_inventory_preview(30.0))
	var animation_row := HBoxContainer.new()
	animation_row.add_theme_constant_override("separation",6)
	portrait_column.add_child(animation_row)
	_preview_button(animation_row,"POSTÓJ","PreviewIdle",func() -> void: _set_inventory_animation("idle"))
	_preview_button(animation_row,"CIOS","PreviewAttack",func() -> void:
		if is_instance_valid(character_preview):
			character_preview.call("play_preview_attack")
	)
	_preview_button(animation_row,"BIEG","PreviewRun",func() -> void: _set_inventory_animation("run"))

	var bag_column := VBoxContainer.new()
	bag_column.name = "InventoryBag"
	bag_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_column.add_theme_constant_override("separation",8)
	split.add_child(bag_column)
	var stats_panel: PanelContainer = _panel(Color("162c32"),Color("354d47"),9,10)
	stats_panel.name = "InventoryStats"
	bag_column.add_child(stats_panel)
	var stats_column := VBoxContainer.new()
	stats_column.add_theme_constant_override("separation",5)
	stats_panel.add_child(stats_column)
	stats_column.add_child(_text("POZIOM %d   ·   ATAK %d   ·   OBRONA %d   ·   PŻ %d   ·   POTKI %d" % [GameState.level,GameState.attack_power(),GameState.defense(),GameState.max_health(),GameState.potions],15,CREAM))
	var equipped_row := HBoxContainer.new()
	equipped_row.add_theme_constant_override("separation",12)
	stats_column.add_child(equipped_row)
	for kind: String in ["weapon","armor"]:
		var equipped_item: Dictionary = GameState.equipped(kind)
		var equipment_name: String = GameState.item_name(equipped_item) if not equipped_item.is_empty() else "Brak"
		var equipment_label: Label = _text(("BROŃ: " if kind == "weapon" else "ZBROJA: ") + equipment_name,14,GOLD)
		equipment_label.name = "InventoryWeaponName" if kind == "weapon" else "InventoryArmorName"
		equipped_row.add_child(equipment_label)
	bag_column.add_child(_label("PLECAK  ·  wybierz przedmiot, aby go założyć",14,MUTED))
	var grid: GridContainer = _inventory_grid(bag_column,2)
	grid.name = "InventoryBagGrid"
	_inventory_scroll = grid.get_parent() as ScrollContainer
	_inventory_scroll.name = "InventoryBagScroll"
	_restore_inventory_scroll.call_deferred(_inventory_scroll,_inventory_scroll_offset)
	for item: Dictionary in GameState.inventory:
		var card: RPGItemCard = _item_card(item,false,false)
		card.selected.connect(_select_inventory)
		grid.add_child(card)
	if GameState.inventory.is_empty():
		grid.add_child(_text("Plecak jest pusty. Odwiedź handlarza.",17,CREAM))
	_render_inventory_actions(bag_column)

func _render_inventory_actions(parent: VBoxContainer) -> void:
	var panel: PanelContainer = _panel(Color("162c32"),Color("354d47"),9,10)
	panel.name = "InventorySelectedActions"
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	panel.add_child(column)
	var selected: Dictionary = GameState.find_item(selected_uid)
	if selected.is_empty():
		column.add_child(_text("Dotknij karty w plecaku, aby założyć broń lub zbroję. Podgląd pokazuje aktualnie założony sprzęt.",15,MUTED))
		return
	var selected_name: Label = _text(GameState.item_name(selected),17,CREAM)
	selected_name.name = "InventorySelectedName"
	column.add_child(selected_name)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation",8)
	column.add_child(action_row)
	var is_equipped: bool = _is_equipped(selected)
	var equip_button: Button = _button("ZAŁOŻONO" if is_equipped else "ZAŁÓŻ PRZEDMIOT",Vector2(196,48),false)
	equip_button.name = "InventoryEquip"
	equip_button.add_theme_font_size_override("font_size",14)
	equip_button.disabled = is_equipped
	equip_button.pressed.connect(func() -> void: GameState.equip(selected_uid))
	action_row.add_child(equip_button)
	var forge_button: Button = _button("OTWÓRZ KUŹNIĘ" if _npc_access == "forge" else "GDZIE JEST KOWAL?",Vector2(210,48),true)
	forge_button.add_theme_font_size_override("font_size",14)
	forge_button.pressed.connect(func() -> void:
		if _npc_access == "forge":
			open_panel("forge")
		else:
			_close_panel()
			toast("Born czeka przy kuźni po prawej stronie placu.")
	)
	action_row.add_child(forge_button)
	if _npc_access == "shop":
		var shop_button: Button = _button("DO HANDLARZA",Vector2(158,48),true)
		shop_button.add_theme_font_size_override("font_size",14)
		shop_button.pressed.connect(func() -> void: open_panel("shop"))
		action_row.add_child(shop_button)

func _attach_inventory_preview(parent: Control) -> void:
	if not is_instance_valid(character_preview):
		var preview_script: Script = load("res://ui/character_preview.gd")
		character_preview = preview_script.new() as Control
		character_preview.name = "CharacterPreview"
		_preview_equipment_signature = ""
		parent.add_child(character_preview)
		if character_preview.has_method("set_sword_flame"):
			character_preview.call("set_sword_flame",_sword_flame_active)
	elif character_preview.get_parent() != parent:
		character_preview.reparent(parent,false)
	character_preview.custom_minimum_size = Vector2(304,264)
	character_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sync_inventory_preview_equipment()
	character_preview.show()
	character_preview.call("set_preview_active",true)

func _park_inventory_preview() -> void:
	if is_instance_valid(_inventory_scroll):
		_inventory_scroll_offset = _inventory_scroll.scroll_vertical
	_inventory_scroll = null
	if not is_instance_valid(character_preview):
		return
	character_preview.call("set_preview_active",false)
	character_preview.hide()
	if is_instance_valid(screen) and character_preview.get_parent() != screen:
		character_preview.reparent(screen,false)

func _sync_inventory_preview_equipment() -> void:
	var weapon: Dictionary = GameState.equipped("weapon")
	var armor: Dictionary = GameState.equipped("armor")
	var weapon_tier: int = int(weapon.get("tier",0))
	var armor_tier: int = int(armor.get("tier",0))
	var upgrade: int = int(weapon.get("upgrade",0))
	var signature: String = "%d:%d:%d" % [weapon_tier,armor_tier,upgrade]
	if signature != _preview_equipment_signature:
		_preview_equipment_signature = signature
		character_preview.call("set_equipment",weapon_tier,armor_tier,upgrade)

func _preview_button(parent: HBoxContainer,text: String,node_name: String,action: Callable) -> void:
	var button: Button = _button(text,Vector2(0,48),true)
	button.name = node_name
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",13)
	button.pressed.connect(action)
	parent.add_child(button)

func _rotate_inventory_preview(degrees: float) -> void:
	if modal_open and modal_mode == "inventory" and is_instance_valid(character_preview):
		character_preview.call("rotate_preview",degrees)

func _set_inventory_animation(mode: String) -> void:
	if modal_open and modal_mode == "inventory" and is_instance_valid(character_preview):
		character_preview.call("set_animation",mode)

func _restore_inventory_scroll(scroll: ScrollContainer,offset: int) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll) and modal_open and modal_mode == "inventory" and scroll == _inventory_scroll:
		scroll.scroll_vertical = offset

func _exit_tree() -> void:
	if is_instance_valid(character_preview):
		character_preview.call("set_preview_active",false)

func _select_inventory(uid: int) -> void:
	selected_uid = uid
	_render_panel()

func _render_shop() -> void:
	var split: HBoxContainer = HBoxContainer.new()
	split.add_theme_constant_override("separation",20)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.add_child(split)
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",10)
	split.add_child(left)
	left.add_child(_label("TOWARY MIRY  ·  wybierz towar, potem kup",14,MUTED))
	var grid: GridContainer = _inventory_grid(left,2)
	var selected: Dictionary = {}
	for item: Dictionary in GameState.catalog():
		var card: RPGItemCard = _item_card(item,true,false)
		card.catalog_selected.connect(_select_catalog)
		grid.add_child(card)
		if str(item.get("id","")) == selected_catalog:
			selected = item
	var right: VBoxContainer = _sidebar(split,280)
	right.add_child(_label("„Dobry miecz to początek.”",19,CREAM))
	right.add_child(_text("Masz 10 000 złota na start. Kup broń i zbroję, załóż je w ekwipunku, a potem odwiedź kuźnię.",15,MUTED))
	_hline(right)
	if not selected.is_empty():
		right.add_child(_label(str(selected.get("name","")),21,GOLD))
		right.add_child(_text(str(selected.get("description","")),15,MUTED))
		right.add_child(_label("Cena: %s złota" % _number(int(selected.get("price",0))),18,CREAM))
		var buy_button: Button = _button("KUP PRZEDMIOT",Vector2(260,52),false)
		buy_button.disabled = GameState.gold < int(selected.get("price",0))
		buy_button.pressed.connect(_buy_selected)
		right.add_child(buy_button)
	else:
		right.add_child(_text("Wybierz przedmiot z oferty po lewej.",16,CREAM))
	var bag_button: Button = _button("OTWÓRZ EKWIPUNEK",Vector2(260,44),true)
	bag_button.pressed.connect(func() -> void: open_panel("inventory"))
	right.add_child(bag_button)
	if not GameState.quest_claimed and GameState.kills >= 3:
		var quest_button: Button = _button("ODBIERZ NAGRODĘ MISJI",Vector2(260,46),false)
		quest_button.pressed.connect(func() -> void: GameState.claim_quest())
		right.add_child(quest_button)

func _select_catalog(id: String) -> void:
	selected_catalog = id
	_render_panel()

func _buy_selected() -> void:
	var before: int = GameState.inventory.size()
	if GameState.buy(selected_catalog):
		if GameState.inventory.size() > before:
			var item: Dictionary = GameState.inventory[-1]
			selected_uid = int(item.get("uid",-1))
		# GameState emits purchase feedback via the main controller.

func _render_forge() -> void:
	var split: HBoxContainer = HBoxContainer.new()
	split.add_theme_constant_override("separation",20)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.add_child(split)
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",10)
	split.add_child(left)
	left.add_child(_label("PRZECIĄGNIJ NA KOWADŁO lub dotknij przedmiotu",14,MUTED))
	var grid: GridContainer = _inventory_grid(left,2)
	for item: Dictionary in GameState.inventory:
		var card: RPGItemCard = _item_card(item,false,true)
		card.selected.connect(_select_inventory)
		grid.add_child(card)
	var right: VBoxContainer = _sidebar(split,322)
	right.add_theme_constant_override("separation",9)
	var slot: RPGForgeSlot = RPGForgeSlot.new()
	slot.custom_minimum_size = Vector2(300,120)
	var slot_style: StyleBoxFlat = _style(Color("1d3538"),Color("a58b5d"),11,2)
	slot_style.set_content_margin_all(12)
	slot.add_theme_stylebox_override("panel",slot_style)
	slot.item_dropped.connect(_select_inventory)
	right.add_child(slot)
	var slot_col: VBoxContainer = VBoxContainer.new()
	slot_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(slot_col)
	var item: Dictionary = GameState.find_item(selected_uid)
	if item.is_empty():
		var anvil: RPGItemIcon = RPGItemIcon.new()
		anvil.kind = "forge"
		anvil.custom_minimum_size = Vector2(80,75)
		slot_col.add_child(anvil)
		var empty_label: Label = _label("UMIEŚĆ PRZEDMIOT",15,GOLD)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_col.add_child(empty_label)
		right.add_child(_text("Wybierz miecz lub zbroję z plecaka. Sam wybór nic nie kosztuje.",16,MUTED))
	else:
		var icon: RPGItemIcon = RPGItemIcon.new()
		icon.kind = str(item.get("kind","weapon"))
		icon.tier = int(item.get("tier",1))
		icon.accent = item.get("color",Color("bccdcf"))
		icon.custom_minimum_size = Vector2(70,60)
		slot_col.add_child(icon)
		var item_label: Label = _label(GameState.item_name(item),20,CREAM)
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_col.add_child(item_label)
		var upgrade: int = int(item.get("upgrade",0))
		if upgrade >= 6:
			right.add_child(_label("MAKSYMALNE ULEPSZENIE +6",18,GREEN))
			right.add_child(_text("To arcydzieło kuźni. Załóż sprzęt i sprawdź go w walce.",16,MUTED))
		else:
			var chance: int = GameState.upgrade_chance(selected_uid)
			var cost: int = GameState.upgrade_cost(selected_uid)
			right.add_child(_label("+%d  →  +%d" % [upgrade,upgrade+1],27,GOLD))
			right.add_child(_label("Koszt: %s złota" % _number(cost),18,CREAM))
			right.add_child(_label("Szansa: %d%%" % chance,18,GREEN if chance == 100 else GOLD))
			var upgrade_button: Button = _button("ULEPSZ ZA %s" % _number(cost),Vector2(300,52),false)
			upgrade_button.disabled = GameState.gold < cost
			upgrade_button.pressed.connect(_upgrade_selected)
			right.add_child(upgrade_button)
	right.add_child(_text("+1–+3: pewny sukces. +4: 80%, +5: 65%, +6: 50%. Niepowodzenie zabiera koszt, ale zachowuje poziom przedmiotu.",13,MUTED))

func _upgrade_selected() -> void:
	if _forge_action_pending or not modal_open or modal_mode != "forge":
		return
	if GameState.find_item(selected_uid).is_empty():
		return
	_forge_action_pending = true
	_diagnostic_note("forge_requested",_forge_diagnostic_data(selected_uid))
	call_deferred("_perform_upgrade",selected_uid,_panel_session_id)

func _perform_upgrade(uid: int, session_id: int) -> void:
	# A queued click must not charge an item after closing/switching panels
	# or selecting another item. Repeated signals before this flush coalesce.
	if modal_open and modal_mode == "forge" and session_id == _panel_session_id and uid == selected_uid:
		if not GameState.find_item(uid).is_empty():
			_diagnostic_note("forge_before_upgrade",_forge_diagnostic_data(uid))
			GameState.upgrade_item(uid)
			_diagnostic_note("forge_after_upgrade",_forge_diagnostic_data(uid))
	else:
		_diagnostic_note("forge_cancelled",_forge_diagnostic_data(uid))
	# GameState.changed -> main.refresh() queues the one necessary rebuild.
	_forge_action_pending = false

func _render_help() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_body.add_child(scroll)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",13)
	scroll.add_child(col)
	for entry: Array in [
		["01  UZBRÓJ SIĘ","Podejdź do Miry w wiosce i naciśnij przycisk rozmowy. Wybierz miecz i zbroję, potem KUP PRZEDMIOT. Zaczynasz z 10 000 złota."],
		["02  ZAŁÓŻ SPRZĘT","Otwórz EKWIPUNEK, dotknij kupionej broni i naciśnij ZAŁÓŻ PRZEDMIOT. Tak samo załóż zbroję."],
		["03  ODWIEDŹ KOWALA","U Borna przeciągnij sprzęt na kowadło albo wybierz go dotykiem. Sprawdź koszt i szansę, potem naciśnij ULEPSZ. Poziomy +1, +2 i +3 zawsze się udają."],
		["04  WYJDŹ ZA BRAMĘ","Lewym drążkiem poruszasz bohaterem. Przytrzymaj ATAK, żeby wykonywać serię ciosów. WIR OSTRZA trafia przeciwników wokół. Czerwona potka przywraca życie."],
		["05  WRÓĆ PO NAGRODĘ","Pokonaj trzy potwory i wróć do Miry. Zdobywaj złoto oraz doświadczenie. Postęp zapisuje się automatycznie. Na komputerze możesz używać WASD, spacji i myszy."]
	]:
		col.add_child(_label(str(entry[0]),17,GOLD))
		col.add_child(_text(str(entry[1]),17,CREAM))

func _render_settings() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_body.add_child(scroll)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",15)
	scroll.add_child(col)
	col.add_child(_text("Twoja przygoda zapisuje się automatycznie na tym urządzeniu.",19,CREAM))
	var save_button: Button = _button("ZAPISZ GRĘ",Vector2(330,52),false)
	save_button.pressed.connect(func() -> void: GameState.save_game(); toast("Postęp zapisany."))
	col.add_child(save_button)
	var camera_button: Button = _button("KAMERA",Vector2(330,52),false)
	camera_button.pressed.connect(func() -> void: open_panel("camera"))
	col.add_child(camera_button)
	var sound_button: Button = _button("DŹWIĘK: WŁĄCZONY" if _audio_enabled else "DŹWIĘK: WYŁĄCZONY",Vector2(330,48),true)
	sound_button.pressed.connect(_toggle_audio)
	col.add_child(sound_button)
	var quality_button: Button = _button("GRAFIKA: OSZCZĘDNA" if bool(get_parent().get("low_quality")) else "GRAFIKA: PEŁNA",Vector2(330,48),true)
	quality_button.pressed.connect(func() -> void:
		if get_parent().has_method("set_low_quality"):
			get_parent().call("set_low_quality",not bool(get_parent().get("low_quality")))
		_render_panel()
	)
	col.add_child(quality_button)
	var diagnostics: Node = get_node_or_null("/root/Diagnostics")
	var reports_toggle: CheckButton = CheckButton.new()
	reports_toggle.text = "Automatyczne raporty błędów"
	reports_toggle.custom_minimum_size = Vector2(330,52)
	reports_toggle.add_theme_font_size_override("font_size",18)
	reports_toggle.add_theme_color_override("font_color",CREAM)
	reports_toggle.disabled = not is_instance_valid(diagnostics)
	if is_instance_valid(diagnostics):
		reports_toggle.button_pressed = bool(diagnostics.call("is_enabled"))
	reports_toggle.toggled.connect(_set_diagnostics_enabled)
	col.add_child(reports_toggle)
	col.add_child(_text("Raport zawiera tylko diagnostykę gry. Bez danych kontaktowych i lokalizacji.",14,MUTED))
	_diagnostics_status_label = _text("",14,MUTED)
	col.add_child(_diagnostics_status_label)
	_update_diagnostics_status()
	var help_button: Button = _button("JAK GRAĆ",Vector2(330,48),true)
	help_button.pressed.connect(func() -> void: open_panel("help"))
	col.add_child(help_button)
	var reset_button: Button = _button("NOWA GRA…",Vector2(330,48),true)
	reset_button.pressed.connect(_confirm_reset)
	col.add_child(reset_button)

func _position_inventory_toast() -> void:
	if is_instance_valid(toast_panel):
		# Inventory action buttons occupy the bottom of the modal.
		toast_panel.position = Vector2(-300,-62 if modal_open and modal_mode == "inventory" else -166)

func _apply_modal_layout() -> void:
	_position_inventory_toast()
	var camera_mode: bool = modal_mode == "camera"
	overlay.color = Color(0,0,0,0) if camera_mode else Color(0.015,0.035,0.045,0.84)
	_modal_tabs.visible = not camera_mode
	_modal_eyebrow.visible = not camera_mode
	modal_gold.visible = not camera_mode
	modal_title.add_theme_font_size_override("font_size",24 if camera_mode else 30)
	_modal_header.add_theme_constant_override("separation",10 if camera_mode else 20)
	_modal_column.add_theme_constant_override("separation",12 if camera_mode else 14)
	var style: StyleBoxFlat = modal.get_theme_stylebox("panel") as StyleBoxFlat
	style.set_content_margin_all(16 if camera_mode else 22)
	if camera_mode:
		modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		modal.offset_left = -374
		modal.offset_right = -24
		modal.offset_top = -270
		modal.offset_bottom = 270
	else:
		modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		modal.offset_left = -556
		modal.offset_right = 556
		modal.offset_top = -304
		modal.offset_bottom = 304

func _render_camera() -> void:
	_camera_values = _read_camera_settings()
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_body.add_child(scroll)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",8)
	scroll.add_child(col)
	col.add_child(_text("Dostosuj widok. Bohater jest widoczny na żywo.",14,MUTED))
	_camera_slider(col,"zoom","Przybliżenie",1.0,2.50,0.05,"CameraZoom")
	_camera_slider(col,"pitch","Wysokość widoku",38.0,65.0,1.0,"CameraPitch")
	_camera_slider(col,"yaw","Obrót",-180.0,180.0,5.0,"CameraYaw")
	var reset: Button = _button("PRZYWRÓĆ DOMYŚLNE",Vector2(0,48),true)
	reset.add_theme_font_size_override("font_size",14)
	reset.pressed.connect(_reset_camera_settings)
	col.add_child(reset)
	var back: Button = _button("WRÓĆ DO MENU",Vector2(0,48),false)
	back.add_theme_font_size_override("font_size",14)
	back.pressed.connect(func() -> void: open_panel("settings"))
	col.add_child(back)

func _camera_slider(parent: VBoxContainer,key: String,title: String,minimum: float,maximum: float,increment: float,node_name: String) -> void:
	var group: VBoxContainer = VBoxContainer.new()
	group.add_theme_constant_override("separation",2)
	parent.add_child(group)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	group.add_child(row)
	var caption: Label = _label(title,16,CREAM)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	var value_label: Label = _label(_camera_value_text(key,float(_camera_values[key])),16,GOLD)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 62
	row.add_child(value_label)
	var slider: HSlider = HSlider.new()
	slider.name = node_name
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	slider.value = float(_camera_values[key])
	slider.custom_minimum_size = Vector2(0,48)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var track: StyleBoxFlat = _style(Color("314b4c"),Color.TRANSPARENT,4,0)
	track.set_content_margin_all(0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider",track)
	var filled: StyleBoxFlat = track.duplicate() as StyleBoxFlat
	filled.bg_color = Color("bda36b")
	slider.add_theme_stylebox_override("grabber_area",filled)
	slider.add_theme_stylebox_override("grabber_area_highlight",filled)
	if not is_instance_valid(_camera_grip):
		_camera_grip = _camera_grip_texture()
	slider.add_theme_icon_override("grabber",_camera_grip)
	slider.add_theme_icon_override("grabber_highlight",_camera_grip)
	slider.add_theme_icon_override("grabber_disabled",_camera_grip)
	slider.add_theme_constant_override("grabber_offset",0)
	slider.add_theme_constant_override("center_grabber",0)
	slider.value_changed.connect(_camera_slider_changed.bind(key))
	group.add_child(slider)
	_camera_sliders[key] = slider
	_camera_value_labels[key] = value_label

func _camera_grip_texture() -> Texture2D:
	var image: Image = Image.create(48,48,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y: int in range(48):
		for x: int in range(48):
			var distance: float = Vector2(float(x)-23.5,float(y)-23.5).length()
			if distance <= 23.5:
				var color: Color = GOLD if distance > 20.0 else Color("24454b")
				if distance < 6.0:
					color = Color("e7d2a0")
				color.a = clampf(23.5-distance,0,1)
				image.set_pixel(x,y,color)
	return ImageTexture.create_from_image(image)

func _read_camera_settings() -> Dictionary:
	var current: Dictionary = {"zoom":1.35,"pitch":48.0,"yaw":0.0}
	if get_parent().has_method("get_camera_settings"):
		var value: Variant = get_parent().call("get_camera_settings")
		if value is Dictionary:
			current.merge(value,true)
	return {"zoom":clampf(float(current.get("zoom",1.35)),1.0,2.50),"pitch":clampf(float(current.get("pitch",48.0)),38.0,65.0),"yaw":clampf(float(current.get("yaw",0.0)),-180.0,180.0)}

func _camera_value_text(key: String,value: float) -> String:
	return "%.2f×" % value if key == "zoom" else "%d°" % int(round(value))

func _camera_slider_changed(value: float,key: String) -> void:
	if not modal_open or modal_mode != "camera":
		return
	_camera_values[key] = value
	var label: Label = _camera_value_labels.get(key)
	if is_instance_valid(label):
		label.text = _camera_value_text(key,value)
	if get_parent().has_method("set_camera_settings"):
		get_parent().call("set_camera_settings",float(_camera_values.zoom),float(_camera_values.pitch),float(_camera_values.yaw))

func _reset_camera_settings() -> void:
	if not modal_open or modal_mode != "camera":
		return
	if get_parent().has_method("reset_camera_settings"):
		get_parent().call("reset_camera_settings")
	_camera_values = _read_camera_settings()
	for key: Variant in _camera_sliders:
		var slider: HSlider = _camera_sliders[key]
		slider.set_value_no_signal(float(_camera_values[key]))
		var label: Label = _camera_value_labels[key]
		label.text = _camera_value_text(str(key),float(_camera_values[key]))

func _connect_diagnostics() -> void:
	var diagnostics: Node = get_node_or_null("/root/Diagnostics")
	if is_instance_valid(diagnostics) and diagnostics.has_signal("status_changed"):
		if not diagnostics.is_connected("status_changed",_update_diagnostics_status):
			diagnostics.connect("status_changed",_update_diagnostics_status)

func _diagnostic_note(name: String, data: Dictionary = {}) -> void:
	var diagnostics: Node = get_node_or_null("/root/Diagnostics")
	if is_instance_valid(diagnostics):
		diagnostics.call("note",name,data)

func _forge_diagnostic_data(uid: int) -> Dictionary:
	var item: Dictionary = GameState.find_item(uid)
	return {"uid":uid,"category":str(item.get("kind","missing")),"upgrade":int(item.get("upgrade",-1))}

func _set_diagnostics_enabled(enabled: bool) -> void:
	var diagnostics: Node = get_node_or_null("/root/Diagnostics")
	if is_instance_valid(diagnostics):
		diagnostics.call("set_enabled",enabled)
	_update_diagnostics_status()

func _update_diagnostics_status() -> void:
	if not is_instance_valid(_diagnostics_status_label) or not _diagnostics_status_label.is_inside_tree():
		return
	var diagnostics: Node = get_node_or_null("/root/Diagnostics")
	_diagnostics_status_label.text = str(diagnostics.call("status_text")) if is_instance_valid(diagnostics) else "Raporty niedostępne w tej wersji."

func _toggle_audio() -> void:
	_audio_enabled = not _audio_enabled
	if get_parent().has_method("set_audio_enabled"):
		get_parent().call("set_audio_enabled",_audio_enabled)
	else:
		AudioServer.set_bus_mute(0,not _audio_enabled)
	_render_panel()

func _confirm_reset() -> void:
	if not modal_open or modal_mode != "settings":
		return
	_reset_confirmation = true
	_render_panel()

func _cancel_reset_confirmation() -> void:
	_reset_confirmation = false
	_render_panel()

func _render_reset_confirmation() -> void:
	modal_body.add_child(_label("Zacząć od początku?",25,GOLD))
	modal_body.add_child(_text("Usuniesz zapis tej przygody. Nowy wojownik rozpocznie grę z 10 000 złota i podstawowym wyposażeniem.",19,CREAM))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	modal_body.add_child(row)
	var cancel: Button = _button("ZACHOWAJ PRZYGODĘ",Vector2(300,56),false)
	row.add_child(cancel)
	cancel.pressed.connect(_cancel_reset_confirmation)
	var confirm: Button = _button("TAK, NOWA GRA",Vector2(260,56),true)
	row.add_child(confirm)
	confirm.pressed.connect(func() -> void:
		if get_parent().has_method("start_new_game"):
			get_parent().call("start_new_game")
	)

func _inventory_grid(parent: VBoxContainer,columns: int) -> GridContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 24
	scroll.add_theme_constant_override("scroll_speed",25)
	parent.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	scroll.add_child(grid)
	return grid

func _item_card(item: Dictionary, catalog_entry: bool, draggable: bool) -> RPGItemCard:
	var card: RPGItemCard = RPGItemCard.new()
	card.item = item
	card.catalog_entry = catalog_entry
	card.draggable = draggable
	card.chosen = str(item.get("id","")) == selected_catalog if catalog_entry else int(item.get("uid",-1)) == selected_uid
	card.equipped = not catalog_entry and _is_equipped(item)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(280,108)
	return card

func _is_equipped(item: Dictionary) -> bool:
	var uid: int = int(item.get("uid",-1))
	return uid == GameState.weapon_uid or uid == GameState.armor_uid

func _sidebar(parent: HBoxContainer,width: float) -> VBoxContainer:
	var wrap: PanelContainer = _panel(Color("162c32"),Color("354d47"),10,15)
	wrap.custom_minimum_size.x = width
	parent.add_child(wrap)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	wrap.add_child(scroll)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",11)
	scroll.add_child(col)
	return col

func _hline(parent: Control) -> void:
	var line: HSeparator = HSeparator.new()
	line.add_theme_stylebox_override("separator",_style(Color("405249"),Color.TRANSPARENT,0,0))
	line.custom_minimum_size.y = 6
	parent.add_child(line)

func _position(control: Control,position: Vector2,dimensions: Vector2) -> void:
	control.position = position
	control.size = dimensions

func _panel(background: Color,border: Color,radius: int,padding: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = _style(background,border,radius,1)
	style.set_content_margin_all(padding)
	panel.add_theme_stylebox_override("panel",style)
	return panel

func _style(background: Color,border: Color,radius: int,width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_corner_radius_all(radius)
	box.set_border_width_all(width)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func _button(text: String,minimum: Vector2,secondary: bool) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = minimum
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_color_override("font_color",CREAM if secondary else Color("172927"))
	b.add_theme_color_override("font_hover_color",Color("fff5d7") if secondary else Color("172927"))
	b.add_theme_color_override("font_pressed_color",CREAM if secondary else Color("172927"))
	b.add_theme_color_override("font_disabled_color",Color("74817a"))
	b.add_theme_stylebox_override("normal",_style(Color("193139") if secondary else Color("c6a56b"),Color("526352") if secondary else Color("e7ca8c"),8,1))
	b.add_theme_stylebox_override("hover",_style(Color("2a494a") if secondary else Color("dfbe7d"),GOLD,8,1))
	b.add_theme_stylebox_override("pressed",_style(Color("34524e") if secondary else Color("ac8d57"),CREAM,8,1))
	b.add_theme_stylebox_override("disabled",_style(Color("273934"),Color("405049"),8,1))
	b.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("ebd498"),8,2))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

func _label(text: String,font_size: int,color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _text(text: String,font_size: int,color: Color) -> Label:
	var l: Label = _label(text,font_size,color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _bar(color: Color,height: float) -> ProgressBar:
	var b: ProgressBar = ProgressBar.new()
	b.custom_minimum_size = Vector2(0,height)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background: StyleBoxFlat = _style(Color("0a181f"),Color("42504a"),3,1)
	background.set_content_margin_all(0)
	b.add_theme_stylebox_override("background",background)
	var fill: StyleBoxFlat = _style(color,Color.TRANSPARENT,3,0)
	fill.set_content_margin_all(0)
	b.add_theme_stylebox_override("fill",fill)
	return b

func _number(value: int) -> String:
	var input: String = str(value)
	var result: String = ""
	for i: int in range(input.length()):
		if i > 0 and (input.length()-i)%3 == 0:
			result += " "
		result += input[i]
	return result

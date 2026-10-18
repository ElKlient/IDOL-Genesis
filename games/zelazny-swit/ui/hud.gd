extends CanvasLayer
class_name GameHUD

signal attack_requested
signal skill_requested
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
var _audio_enabled: bool = true
var _npc_access: String = ""
var _map_time: float = 0.0
var _modal_generation: int = 0

func _ready() -> void:
	layer = 10
	_build_hud()
	_build_modal()
	_audio_enabled = GameState.audio_enabled
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
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
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

func _state_changed() -> void:
	if not _refresh_pending:
		_refresh_pending = true
		call_deferred("_deferred_refresh")

func _deferred_refresh() -> void:
	_refresh_pending = false
	refresh()

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
	var stats_hint: Label = _label("ŻELAZNY ŚWIT",10,MUTED)
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
	col.add_theme_constant_override("separation",14)
	modal.add_child(col)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation",20)
	col.add_child(header)
	var title_col: VBoxContainer = VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)
	title_col.add_child(_label("ŻELAZNY ŚWIT  /  BRZEZINY",11,GOLD))
	modal_title = _label("Ekwipunek",30,CREAM)
	title_col.add_child(modal_title)
	modal_gold = _label("10 000 złota",22,GOLD)
	modal_gold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(modal_gold)
	var close: Button = _button("X",Vector2(54,54),true)
	header.add_child(close)
	close.pressed.connect(_close_panel)
	var tab_row: HBoxContainer = HBoxContainer.new()
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

func set_world_positions(hero_pos: Vector3, enemies: Array, npcs: Dictionary) -> void:
	minimap.hero_position = hero_pos
	minimap.enemy_positions = enemies
	minimap.npc_positions = npcs
	minimap.queue_redraw()

func toast(text: String) -> void:
	toast_label.text = text
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
	modal_mode = mode
	modal_open = true
	move_vector = Vector2.ZERO
	attack_held = false
	joystick.enabled = false
	attack_pad.enabled = false
	skill_pad.enabled = false
	potion_pad.enabled = false
	context_button.hide()
	overlay.show()
	_render_panel()

func _close_panel() -> void:
	close_panel()
	close_requested.emit()

func close_panel() -> void:
	modal_open = false
	overlay.hide()
	joystick.enabled = true
	attack_pad.enabled = true
	skill_pad.enabled = true
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
	if modal_open:
		_render_panel()

func _render_panel() -> void:
	_modal_generation += 1
	for child: Node in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	modal_gold.text = "%s złota" % _number(GameState.gold)
	for key: Variant in tabs:
		var b: Button = tabs[key]
		b.visible = key not in ["shop","forge"] or key == _npc_access
		b.add_theme_stylebox_override("normal",_style(Color("365047") if key == modal_mode else Color("172d34"),GOLD if key == modal_mode else Color("40524a"),7,1))
	var titles: Dictionary = {"inventory":"Ekwipunek wojownika","shop":"Handlarz · Mira","forge":"Kuźnia · Born","help":"Pierwsze kroki","settings":"Obozowisko"}
	modal_title.text = str(titles.get(modal_mode,"Ekwipunek"))
	match modal_mode:
		"shop": _render_shop()
		"forge": _render_forge()
		"help": _render_help()
		"settings": _render_settings()
		_: _render_inventory()

func _render_inventory() -> void:
	var split: HBoxContainer = HBoxContainer.new()
	split.add_theme_constant_override("separation",20)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.add_child(split)
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",10)
	split.add_child(left)
	left.add_child(_label("PLECAK  ·  wybierz przedmiot, aby go założyć",14,MUTED))
	var grid: GridContainer = _inventory_grid(left,2)
	for item: Dictionary in GameState.inventory:
		var card: RPGItemCard = _item_card(item,false,false)
		card.selected.connect(_select_inventory)
		grid.add_child(card)
	if GameState.inventory.is_empty():
		left.add_child(_label("Plecak jest pusty. Odwiedź handlarza.",18,CREAM))
	var right: VBoxContainer = _sidebar(split,280)
	right.add_child(_label("TWÓJ WOJOWNIK",13,GOLD))
	right.add_child(_label("Atak %d   /   Obrona %d" % [GameState.attack_power(),GameState.defense()],20,CREAM))
	right.add_child(_label("Życie %d   /   Potki %d" % [GameState.max_health(),GameState.potions],15,MUTED))
	_hline(right)
	for kind: String in ["weapon","armor"]:
		var equipped_item: Dictionary = GameState.equipped(kind)
		right.add_child(_label("BROŃ" if kind == "weapon" else "ZBROJA",11,GOLD))
		right.add_child(_label(GameState.item_name(equipped_item) if not equipped_item.is_empty() else "Brak",17,CREAM))
	_hline(right)
	var selected: Dictionary = GameState.find_item(selected_uid)
	if not selected.is_empty():
		right.add_child(_label(GameState.item_name(selected),19,CREAM))
		var is_equipped: bool = _is_equipped(selected)
		var equip_button: Button = _button("ZAŁOŻONO" if is_equipped else "ZAŁÓŻ PRZEDMIOT",Vector2(260,48),false)
		equip_button.disabled = is_equipped
		equip_button.pressed.connect(func() -> void: GameState.equip(selected_uid))
		right.add_child(equip_button)
		var forge_button: Button = _button("PRZENIEŚ DO KOWALA",Vector2(260,44),true)
		forge_button.text = "OTWÓRZ KUŹNIĘ" if _npc_access == "forge" else "GDZIE JEST KOWAL?"
		forge_button.pressed.connect(func() -> void:
			if _npc_access == "forge":
				open_panel("forge")
			else:
				_close_panel()
				toast("Born czeka przy kuźni po prawej stronie placu.")
		)
		right.add_child(forge_button)
	else:
		right.add_child(_text("Dotknij karty w plecaku. Broń i zbroję możesz zmieniać w każdej chwili.",15,MUTED))

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
	GameState.upgrade_item(selected_uid)
	_render_panel()

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
	var help_button: Button = _button("JAK GRAĆ",Vector2(330,48),true)
	help_button.pressed.connect(func() -> void: open_panel("help"))
	col.add_child(help_button)
	var reset_button: Button = _button("NOWA GRA…",Vector2(330,48),true)
	reset_button.pressed.connect(_confirm_reset)
	col.add_child(reset_button)

func _toggle_audio() -> void:
	_audio_enabled = not _audio_enabled
	if get_parent().has_method("set_audio_enabled"):
		get_parent().call("set_audio_enabled",_audio_enabled)
	else:
		AudioServer.set_bus_mute(0,not _audio_enabled)
	_render_panel()

func _confirm_reset() -> void:
	for child: Node in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	modal_body.add_child(_label("Zacząć od początku?",25,GOLD))
	modal_body.add_child(_text("Usuniesz zapis tej przygody. Nowy wojownik rozpocznie grę z 10 000 złota i podstawowym wyposażeniem.",19,CREAM))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	modal_body.add_child(row)
	var cancel: Button = _button("ZACHOWAJ PRZYGODĘ",Vector2(300,56),false)
	row.add_child(cancel)
	cancel.pressed.connect(_render_panel)
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

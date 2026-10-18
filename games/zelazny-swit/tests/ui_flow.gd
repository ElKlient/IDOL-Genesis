extends SceneTree
## Actual GUI pointer input: merchant -> inventory/equip -> drag onto anvil -> explicit upgrade.
var state: Node
var game: Node3D
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		push_error("Supply --test-isolated.")
		quit(2)
		return
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	state.new_game()
	var scene: PackedScene = load("res://main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await _layout()
	game.hero.reset_to(game.world.npc_positions.merchant + Vector3(0,0,1.4))
	game.interact()
	await _layout()
	var card: Control = _card(game.hud.modal,"iron_sword",true)
	_check(card != null, "merchant shows a selectable iron sword card")
	await _click(card)
	_check(game.hud.selected_catalog == "iron_sword", "pointer tap selects merchant catalog item")
	var buy: Button = _button(game.hud.modal,"KUP PRZEDMIOT")
	_check(buy != null and not buy.disabled, "selected catalog item exposes an enabled purchase button")
	await _click(buy)
	_check(state.inventory.size() == 2 and state.gold == 9650, "purchase button buys exactly one sword for 350 gold")
	var sword_uid: int = int(state.inventory.back().uid)
	await _click(_button(game.hud.modal,"OTWÓRZ EKWIPUNEK"))
	_check(game.hud.modal_mode == "inventory", "shop inventory button opens equipment view")
	await _click(_button(game.hud.modal,"ZAŁÓŻ PRZEDMIOT"))
	_check(state.weapon_uid == sword_uid, "inventory equip button equips the selected purchased sword")
	game._close_modal()
	game.hero.reset_to(game.world.npc_positions.blacksmith + Vector3(0,0,1.4))
	game.hud.selected_uid = -1
	game.interact()
	await _layout()
	card = _card(game.hud.modal,"iron_sword",false)
	var slot: Control = _script_node(game.hud.modal,"forge_slot.gd")
	_check(card != null and slot != null, "forge shows owned draggable sword and anvil target")
	var before_gold: int = state.gold
	await _drag(card,slot)
	_check(game.hud.selected_uid == sword_uid, "actual pointer drag selects sword on the anvil")
	_check(state.gold == before_gold and state.find_item(sword_uid).upgrade == 0, "drag and drop previews upgrade without spending gold")
	var upgrade: Button = _button(game.hud.modal,"ULEPSZ ZA 180")
	_check(upgrade != null and not upgrade.disabled, "anvil displays explicit upgrade button with quoted price")
	await _click(upgrade)
	_check(state.find_item(sword_uid).upgrade == 1 and state.gold == before_gold - 180, "explicit upgrade button raises sword exactly once and charges exactly once")
	game._close_modal()
	await _layout()
	_check(not game.hud.modal_open and game.hud.joystick.enabled and game.hud.attack_pad.enabled, "closing forge restores touch movement and attack controls")
	# A new adventure must rebuild the world as well as reset the save model.
	var old_scene_id: int = game.get_instance_id()
	game.enemies[0].take_damage(5)
	game.attack_cooldown = 4.0
	game.skill_cooldown = 6.0
	game.hud.open_panel("settings")
	await _layout()
	await _click(_button(game.hud.modal,"NOWA GRA…"))
	_check(_button(game.hud.modal,"TAK, NOWA GRA") != null and state.gold == 9470, "new-game menu asks for confirmation and preserves progress before approval")
	await _click(_button(game.hud.modal,"TAK, NOWA GRA"))
	game = current_scene
	_check(game.get_instance_id() != old_scene_id, "confirmed new game creates a fresh world scene")
	_check(state.gold == 10000 and state.inventory.size() == 1 and state.equipped("weapon").id == "training_sword" and state.armor_uid == 0, "confirmed new game restores ten thousand gold and starter equipment")
	var fresh_enemies: bool = game.enemies.size() == 7
	for enemy: Node3D in game.enemies:
		fresh_enemies = fresh_enemies and enemy.hp == enemy.max_hp
	_check(fresh_enemies and game.attack_cooldown == 0.0 and game.skill_cooldown == 0.0, "new adventure rebuilds all seven enemies at full health and resets combat cooldowns")
	_check(state.kills == 0 and not state.quest_claimed and not game.hud.modal_open and game.hero.position.distance_to(game.world.spawn_position) < 0.3, "new adventure resets quest and returns an active warrior to village spawn")
	print("UI FLOW RESULT: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await process_frame
	# Let the audio mixer release the just-reloaded scene's playback resources.
	await create_timer(0.25).timeout
	quit(0 if failures == 0 else 1)

func _layout() -> void:
	await process_frame
	await process_frame
	await process_frame

func _card(node: Node, item_id: String, catalog: bool) -> Control:
	if node is Control and node.get_script() != null and node.get_script().resource_path.ends_with("item_card.gd"):
		if str(node.item.id) == item_id and node.catalog_entry == catalog:
			return node
	for child: Node in node.get_children():
		var found: Control = _card(child,item_id,catalog)
		if found != null:
			return found
	return null

func _button(node: Node, text: String) -> Button:
	if node is Button and node.text == text and node.is_visible_in_tree():
		return node
	for child: Node in node.get_children():
		var found: Button = _button(child,text)
		if found != null:
			return found
	return null

func _script_node(node: Node, filename: String) -> Control:
	if node is Control and node.get_script() != null and node.get_script().resource_path.ends_with(filename):
		return node
	for child: Node in node.get_children():
		var found: Control = _script_node(child,filename)
		if found != null:
			return found
	return null

func _click(control: Control) -> void:
	if not is_instance_valid(control):
		return
	await _ensure_visible(control)
	var point: Vector2 = control.get_global_rect().get_center()
	_motion(point)
	_mouse(point,true)
	await process_frame
	_mouse(point,false)
	await _layout()

func _mouse(point: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = point
	event.global_position = point
	event.pressed = pressed
	Input.parse_input_event(event)

func _motion(point: Vector2, relative: Vector2 = Vector2.ZERO, held: bool = false) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(event)

func _drag(source: Control, destination: Control) -> void:
	if not is_instance_valid(source) or not is_instance_valid(destination):
		return
	await _ensure_visible(source)
	await _ensure_visible(destination)
	var start: Vector2 = source.get_global_rect().get_center()
	var end: Vector2 = destination.get_global_rect().get_center()
	_motion(start)
	_mouse(start,true)
	await process_frame
	var previous: Vector2 = start
	for index: int in range(1,9):
		var point: Vector2 = start.lerp(end,float(index)/8.0)
		_motion(point,point-previous,true)
		previous = point
		await process_frame
	_mouse(end,false)
	await _layout()

func _ensure_visible(control: Control) -> void:
	# Settings/sidebar content can legitimately scroll. Pointer input must target
	# its visible part rather than a clipped descendant's off-screen rectangle.
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
		ancestor = ancestor.get_parent()
	await _layout()

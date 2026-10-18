extends SceneTree
## Deferred GUI regression: repeated signals, refresh coalescing and stale actions.
var state: Node
var game: Node3D
var checks: int = 0
var failures: int = 0

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
		push_error("Refusing forge regression without --test-isolated.")
		quit(2)
		return
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	_check(not state.save_enabled,"forge regression disables save writes")
	state.new_game()
	var scene: PackedScene = load("res://main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await _frames(4)
	var uid: int = state.weapon_uid
	game.hero.reset_to(game.world.npc_positions.blacksmith + Vector3(0,0,1.4))
	game.hud.selected_uid = uid
	game.interact()
	await _frames(4)
	var button: Button = _upgrade_button(game.hud.modal)
	_check(button != null,"actual starter-sword forge exposes upgrade button")
	var generation_before: int = game.hud._modal_generation
	var before_gold: int = state.gold
	button.pressed.emit()
	button.pressed.emit()
	_check(is_instance_valid(button) and button.is_inside_tree(),"upgrade signal keeps its source button alive during input dispatch")
	_check(state.gold == before_gold and state.find_item(uid).upgrade == 0 and game.hud._forge_action_pending,"upgrade model mutation waits until GUI signal dispatch completes")
	for _index: int in range(8):
		game.hud.refresh()
	await _frames(4)
	_check(state.gold == before_gold-100 and state.find_item(uid).upgrade == 1,"repeated pending upgrade signals charge once and raise starter sword once")
	_check(game.hud._modal_generation == generation_before+1,"pending forge action and repeated refresh requests coalesce into one panel rebuild")
	_check(not game.hud._forge_action_pending and not game.hud._refresh_pending,"deferred forge and refresh queues finish without a stuck pending flag")
	# Closing and reopening creates a different panel session. The old action
	# must not spend gold in the newly opened forge even for the same item.
	button = _upgrade_button(game.hud.modal)
	before_gold = state.gold
	button.pressed.emit()
	game.hud.close_panel()
	game.hud.open_panel("forge")
	await _frames(4)
	_check(state.gold == before_gold and state.find_item(uid).upgrade == 1,"closing and reopening forge cancels the queued action from the old session")
	_check(game.hud.modal_open and game.hud.modal_mode == "forge" and _upgrade_button(game.hud.modal) != null,"reopened forge remains usable after cancelling a stale action")
	state.buy("iron_sword")
	var other_uid: int = int(state.inventory.back().uid)
	await _frames(4)
	button = _upgrade_button(game.hud.modal)
	before_gold = state.gold
	button.pressed.emit()
	game.hud._select_inventory(other_uid)
	await _frames(4)
	_check(state.gold == before_gold and state.find_item(uid).upgrade == 1 and state.find_item(other_uid).upgrade == 0,"selecting a different item before flush cancels the queued upgrade")
	# Rebuild panels repeatedly as touch selection, tabs and model notifications
	# would do in real play. Removed controls must not accumulate in the tree.
	for index: int in range(12):
		var mode: String = "forge" if index % 2 == 0 else "inventory"
		game.hud.open_panel(mode)
		game.hud._select_inventory(uid if index % 3 == 0 else other_uid)
		game.hud.refresh()
		game.hud.refresh()
		await _frames(4)
		_check(game.hud.modal_body.get_child_count() == 1 and not game.hud._refresh_pending,"repeated UI rebuild %d leaves one live content tree and clears pending refresh" % (index+1))
	_check(state.gold == before_gold and state.find_item(uid).upgrade == 1,"repeated selection and panel rebuilding never charge gold")
	game.hud.open_panel("forge")
	game.hud._select_inventory(uid)
	await _frames(4)
	button = _upgrade_button(game.hud.modal)
	before_gold = state.gold
	for _index: int in range(20):
		button.pressed.emit()
	await _frames(4)
	_check(state.gold == before_gold-200 and state.find_item(uid).upgrade == 2,"twenty signals during one dispatch charge the +2 attempt exactly once")
	_check(game.hero._upgrade == 2 and state.weapon_uid == uid,"deferred +2 upgrade keeps equipped warrior visual synchronized")
	game.hud.close_panel()
	await _frames(3)
	_check(not game.hud.modal_open and game.hud.joystick.enabled and not game.hud._forge_action_pending,"closing final forge restores controls with no outstanding action")
	game.queue_free()
	await _frames(3)
	print("DEFERRED FORGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame

func _upgrade_button(node: Node) -> Button:
	if node is Button and node.text.begins_with("ULEPSZ ZA ") and node.is_visible_in_tree():
		return node
	for child: Node in node.get_children():
		var found: Button = _upgrade_button(child)
		if found != null:
			return found
	return null

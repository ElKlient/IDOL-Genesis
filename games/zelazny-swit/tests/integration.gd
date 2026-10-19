extends SceneTree
## Real scene smoke test. Run with:
## godot --headless --path . --script res://tests/integration.gd -- --test-isolated
## This flag is mandatory: the test never writes or replaces a player's save.

var failures: Array[String] = []
var checks: int = 0
var hit_signals: int = 0
var defeated_signals: int = 0
var state: Node
var game: Node3D
var save_before: PackedByteArray
var save_existed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func _run() -> void:
	# SceneTree --script starts with a 64x64 dummy headless window; emulate the phone viewport.
	root.size = Vector2i(1280,720)
	if not "--test-isolated" in OS.get_cmdline_user_args():
		push_error("Refusing to run without --test-isolated; a player's save must remain untouched.")
		quit(2)
		return
	state = root.get_node("GameState")
	save_existed = FileAccess.file_exists(state.SAVE_PATH)
	if save_existed:
		save_before = FileAccess.get_file_as_bytes(state.SAVE_PATH)
	_check(not state.save_enabled, "isolated run disables save writes")
	state.new_game()
	_check(state.gold == 10000 and state.level == 1 and state.xp == 0, "fresh warrior starts at level 1 with exactly 10,000 gold")
	_check(state.hp == state.max_health() and state.potions == 10, "fresh warrior has full health and ten potions")
	_check(state.inventory.size() == 1 and state.equipped("weapon").id == "training_sword", "fresh warrior carries and equips the training sword")
	var scene: PackedScene = load("res://main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await physics_frame
	await physics_frame
	_check(is_instance_valid(game.hero) and is_instance_valid(game.hud) and is_instance_valid(game.world), "actual main scene builds world, warrior, and touch HUD")
	_check(game.enemies.size() >= 3, "world contains at least three real enemies")
	var initial_enemy_count: int = game.enemies.size()
	_check(game.world.npc_positions.has("merchant") and game.world.npc_positions.has("blacksmith"), "village contains merchant and blacksmith")
	var weapon_count: int = 0
	var armor_count: int = 0
	for item: Dictionary in state.catalog():
		weapon_count += 1 if str(item.kind) == "weapon" else 0
		armor_count += 1 if str(item.kind) == "armor" else 0
	_check(weapon_count == 3 and armor_count == 3, "merchant catalog offers three sword and three armor tiers")
	# Freeze AI for deterministic damage accounting; damage/death still run on real instances.
	for enemy: Node3D in game.enemies:
		enemy.set_physics_process(false)
	_check(not state.claim_quest() and state.gold == 10000, "unfinished quest pays nothing")
	_check(state.buy("iron_sword") and state.gold == 9650, "buying the first sword deducts its 350 gold price exactly once")
	var sword: Dictionary = state.inventory.back()
	var sword_uid: int = int(sword.uid)
	_check(state.equip(sword_uid) and state.weapon_uid == sword_uid, "purchased sword can be equipped")
	_check(state.buy("leather_armor") and state.gold == 9150, "buying first armor deducts its 500 gold price exactly once")
	var armor_uid: int = int(state.inventory.back().uid)
	_check(state.equip(armor_uid) and state.defense() == 4, "purchased armor equips and supplies defense")
	var before_attack: int = state.attack_power()
	var cost: int = state.upgrade_cost(sword_uid)
	_check(cost == 180 and state.upgrade_chance(sword_uid) == 100, "first sword upgrade preview costs 180 gold with a 100 percent chance")
	var before_gold: int = state.gold
	_check(state.upgrade_item(sword_uid), "first sword upgrade succeeds")
	_check(int(state.find_item(sword_uid).upgrade) == 1 and state.gold == before_gold - cost, "smith raises the selected sword once and charges once")
	_check(state.attack_power() == before_attack + 5, "equipped upgraded sword increases actual attack damage")
	before_gold = state.gold
	var inventory_before: int = state.inventory.size()
	_check(not state.buy("missing_item") and not state.equip(-99) and not state.upgrade_item(-99), "invalid item operations are rejected")
	_check(state.gold == before_gold and state.inventory.size() == inventory_before, "rejected operations preserve gold and inventory")
	var potions_before: int = state.potions
	_check(not state.use_potion() and state.potions == potions_before, "full health does not consume a potion")
	state.damage(70)
	var damaged_hp: int = state.hp
	_check(damaged_hp == state.max_health() - 66, "equipped armor reduces incoming damage")
	game.use_potion()
	_check(state.hp == state.max_health() and state.potions == potions_before - 1, "actual potion action heals and consumes exactly one potion")
	before_gold = state.gold
	potions_before = state.potions
	_check(state.buy("potion_pack") and state.potions == potions_before + 10 and state.gold == before_gold - 500, "merchant potion bundle supplies ten potions at its displayed price")
	# A modal must pause combat and prevent an accidental attack behind the shop.
	game.hero.reset_to(game.world.npc_positions.merchant + Vector3(0,0,1.3))
	game.interact()
	_check(game.hud.modal_open, "interacting near merchant opens the actual shop")
	game.attack_cooldown = 0.0
	game.request_attack()
	_check(game.attack_cooldown == 0.0, "shop modal blocks combat input")
	game._close_modal()
	await process_frame
	_check(not game.hud.modal_open, "shop closes and returns control")
	game.hero.reset_to(game.world.npc_positions.blacksmith + Vector3(0,0,1.3))
	game.interact()
	_check(game.hud.modal_open, "interacting near blacksmith opens the actual forge")
	game._close_modal()
	await process_frame
	for mode: String in ["inventory","shop","forge","help","settings"]:
		game.hud.open_panel(mode)
		await process_frame
		await process_frame
		var minimum: Vector2 = game.hud.modal.get_combined_minimum_size()
		_check(minimum.x <= 1112.0 and minimum.y <= 608.0, "modal content fits landscape bounds: %s (%s)" % [mode,minimum])
		game._close_modal()
		await process_frame
	# Verify continuous physics-driven warrior movement rather than changing coordinates only.
	game.hero.reset_to(game.world.spawn_position)
	var movement_start: Vector3 = game.hero.position
	_stick(Vector2.UP)
	await create_timer(0.65).timeout
	_release_stick()
	_check(game.hero.position.z < movement_start.z - 1.0, "touch movement vector drives the actual warrior through the village")
	_check(game.hero.position.y > -0.5, "warrior remains on collision ground")
	# Follow the open southern approach to each NPC and the center path through the north gate.
	for npc_key: String in ["merchant","blacksmith"]:
		game.hero.reset_to(game.world.spawn_position)
		await _walk_to(Vector3(game.world.npc_positions[npc_key].x,0,game.world.spawn_position.z),2.3)
		await _walk_to(game.world.npc_positions[npc_key] + Vector3(0,0,1.7),2.3)
		_check(game.hero.position.distance_to(game.world.npc_positions[npc_key]) < 3.7, "actual collision route reaches " + npc_key)
	game.hero.reset_to(game.world.spawn_position)
	await _walk_to(Vector3(0,0,-17),5.7)
	_check(game.hero.position.z < -15.0, "actual collision route crosses the north gate")
	# Kill real world enemies through the normal windup/cooldown attack path.
	var victims: Array[Node3D] = []
	for enemy: Node3D in game.enemies:
		if enemy.kind == 0:
			victims.append(enemy)
	for enemy: Node3D in game.enemies:
		if victims.size() >= 3:
			break
		if not victims.has(enemy) and enemy.kind != 2:
			victims.append(enemy)
	_check(victims.size() >= 3, "three non-boss enemies are available for the first quest")
	var reward_total: int = 0
	var experience_total: int = 0
	var combat_gold: int = state.gold
	for victim: Node3D in victims.slice(0,3):
		reward_total += victim.reward_gold
		experience_total += victim.reward_xp
		victim.damaged.connect(_enemy_damaged)
		victim.defeated.connect(_enemy_defeated)
		game.hero.reset_to(victim.position + Vector3(0,0,1.7))
		game._set_target(victim)
		var swings: int = 0
		while is_instance_valid(victim) and victim.is_alive() and swings < 15:
			game.request_attack()
			await create_timer(maxf(game.attack_cooldown,game.hero.visual.attack_duration)+0.08).timeout
			swings += 1
		_check(is_instance_valid(victim) and not victim.is_alive(), "normal attack defeats a spawned enemy: %s" % victim.display_name)
		# Restore death animation processing after deterministic AI freeze.
		victim.set_physics_process(true)
	_check(hit_signals >= 3 and defeated_signals == 3, "real enemies emit damage and defeat signals during combat")
	_check(state.kills == 3 and state.gold == combat_gold + reward_total, "three kills grant each enemy's gold reward exactly once")
	_check(state.level >= 2 and state.xp == experience_total - 100, "enemy rewards cross first level threshold and retain remaining XP")
	_check(state.quest_text().contains("1200"), "quest reaches reward-ready stage after sword, smith, and three kills")
	before_gold = state.gold
	potions_before = state.potions
	_check(state.claim_quest() and state.gold == before_gold + 1200 and state.potions == potions_before + 5, "first quest grants its 1,200 gold and five potions")
	before_gold = state.gold
	_check(not state.claim_quest() and state.gold == before_gold, "quest reward cannot be claimed twice")
	game.hero.reset_to(game.world.spawn_position)
	game.hud.open_panel("settings")
	await create_timer(18.6).timeout
	_check(game.enemies.size() == initial_enemy_count, "defeated wild enemies respawn after the real cooldown")
	game._close_modal()
	_check(not state.save_enabled, "save isolation remains enabled throughout scene and reward actions")
	state.save_game()
	_check(FileAccess.file_exists(state.SAVE_PATH) == save_existed, "test does not create or delete a player save")
	if save_existed:
		_check(FileAccess.get_file_as_bytes(state.SAVE_PATH) == save_before, "existing player save bytes remain unchanged")
	print("INTEGRATION RESULT: %d checks, %d failures" % [checks, failures.size()])
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _enemy_damaged(_amount: int, _critical: bool) -> void:
	hit_signals += 1

func _enemy_defeated(_enemy: Node3D) -> void:
	defeated_signals += 1

func _stick(direction: Vector2) -> void:
	var joystick: Control = game.hud.joystick
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 42
	event.pressed = true
	event.position = joystick.global_position + joystick.size * 0.5 + direction * joystick.size.x * 0.34
	Input.parse_input_event(event)

func _release_stick() -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 42
	event.pressed = false
	Input.parse_input_event(event)

func _walk_to(destination: Vector3, timeout_seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < timeout_seconds and game.hero.position.distance_to(destination) > 0.45:
		var offset: Vector3 = destination - game.hero.position
		_release_stick()
		_stick(Vector2(offset.x,offset.z).normalized())
		await create_timer(0.1).timeout
		elapsed += 0.1
	_release_stick()

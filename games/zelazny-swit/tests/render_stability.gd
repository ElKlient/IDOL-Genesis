extends SceneTree
## Regression for changing the render target MSAA while the Android GL renderer is active.
## Run headless or on a real graphical display with -- --test-isolated.
var game: Node3D
var state: Node
var checks: int = 0
var failures: int = 0
var rendered_frames: int = 0
var started_ms: int = 0
var initial_msaa: int = 0
var draw_enabled: bool = false
var sword_uid: int = 0
var armor_uid: int = 0
var saved_before: PackedByteArray
var save_existed: bool = false

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
		push_error("Refusing render regression without --test-isolated; player's saves must remain untouched.")
		quit(2)
		return
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	save_existed = FileAccess.file_exists(state.SAVE_PATH)
	if save_existed:
		saved_before = FileAccess.get_file_as_bytes(state.SAVE_PATH)
	_check(not state.save_enabled,"isolated renderer run disables save writes")
	state.new_game()
	draw_enabled = DisplayServer.get_name() != "headless"
	if draw_enabled:
		RenderingServer.frame_post_draw.connect(_on_frame_drawn)
	var scene: PackedScene = load("res://main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	started_ms = Time.get_ticks_msec()
	await _frames(3)
	initial_msaa = root.msaa_3d
	_check(is_instance_valid(game.world) and is_instance_valid(game.hero) and is_instance_valid(game.hud),"full real village, warrior and interface initialize")
	_check(state.gold == 10000,"fresh isolated warrior starts with ten thousand gold")
	sword_uid = state.weapon_uid
	_check(state.equipped("weapon").id == "training_sword","regression uses actual equipped starter sword")
	_check(state.buy("leather_armor"),"prepare armor through normal purchase model")
	armor_uid = int(state.inventory.back().uid)
	_check(state.equip(armor_uid),"prepare equipped armor before forge and renderer toggles")
	game.hero.reset_to(game.world.npc_positions.blacksmith + Vector3(0,0,1.4))
	game.hud.selected_uid = sword_uid
	game.interact()
	await _frames(3)
	_check(game.hud.modal_open and game.hud.modal_mode == "forge","actual blacksmith interaction opens starter-sword forge")
	await _forge_upgrade(1)
	# Each call must preserve the render target's startup MSAA setting. The old
	# implementation assigned MSAA_DISABLED on the first true toggle, failing here.
	await _toggle_quality(true,1)
	await _toggle_quality(false,2)
	await _until_elapsed(8.3)
	_check(root.msaa_3d == initial_msaa and not game.low_quality,"former eight-second boundary preserves startup MSAA and manual graphics choice")
	await _forge_upgrade(2)
	await _forge_upgrade(3)
	for index: int in range(3,11):
		await _toggle_quality(index % 2 == 1,index)
	await _until_elapsed(12.4)
	_check(Time.get_ticks_msec()-started_ms >= 12000,"real scene stays active beyond the former eight-second transition and autosave interval")
	_check(root.msaa_3d == initial_msaa,"render target retains original MSAA throughout forge upgrades and manual toggles")
	_check(state.weapon_uid == sword_uid and state.armor_uid == armor_uid and state.equipped("weapon").upgrade == 3,"equipped item identities and starter-sword +3 remain stable")
	_check(game.hero._upgrade == 3 and game.hero._armor_tier == 1 and state.defense() == 4,"warrior visual equipment and armor defense remain synchronized")
	_check(state.gold == 8900,"three guaranteed starter upgrades charge exactly 100 plus 200 plus 300 gold after 500-gold armor")
	if draw_enabled:
		_check(rendered_frames > 10,"real OpenGL renderer continues producing frames through quality toggles and upgrades")
	else:
		print("INFO: headless run verifies scene state; actual redraw checks require an OpenGL display")
	_check(not state.save_enabled and FileAccess.file_exists(state.SAVE_PATH) == save_existed,"render regression never enables saving or creates a player save")
	if save_existed:
		_check(FileAccess.get_file_as_bytes(state.SAVE_PATH) == saved_before,"existing player save bytes remain untouched")
	game._close_modal()
	game.queue_free()
	await _frames(3)
	# Allow the audio mixer to release its final playback reference after scene disposal.
	await create_timer(0.25).timeout
	if draw_enabled:
		RenderingServer.frame_post_draw.disconnect(_on_frame_drawn)
	print("RENDER STABILITY RESULT: %d checks, %d failures; display=%s; initial_msaa=%d; rendered_frames=%d" % [checks,failures,DisplayServer.get_name(),initial_msaa,rendered_frames])
	quit(0 if failures == 0 else 1)

func _forge_upgrade(target_level: int) -> void:
	var before_gold: int = state.gold
	var cost: int = state.upgrade_cost(sword_uid)
	var button: Button = _upgrade_button(game.hud.modal)
	_check(button != null and not button.disabled,"forge exposes an enabled upgrade action for starter sword +%d" % target_level)
	if button != null:
		button.pressed.emit()
	await _frames(3)
	_check(state.find_item(sword_uid).upgrade == target_level and state.gold == before_gold-cost,"actual forge button raises starter sword to +%d and deducts its cost once" % target_level)
	_check(game.hero._upgrade == target_level and state.armor_uid == armor_uid,"forge +%d updates warrior visual without changing equipped armor" % target_level)

func _toggle_quality(value: bool, index: int) -> void:
	var draws_before: int = rendered_frames
	game.set_low_quality(value)
	await _frames(3)
	_check(game.low_quality == value and root.msaa_3d == initial_msaa,"manual graphics toggle %d preserves initial viewport MSAA" % index)
	var sun_found: bool = false
	var sun_matches: bool = true
	for child: Node in game.world.get_children():
		if child is DirectionalLight3D and child.name == "WarmAfternoonSun":
			sun_found = true
			sun_matches = sun_matches and child.shadow_enabled == not value
	_check(sun_found and sun_matches and game.world._fire_light.visible == not value,"manual graphics toggle %d still controls sun shadows and forge fire light" % index)
	_check(not game.world.get_node("CharacterSoftFill").shadow_enabled,"character fill never adds a shadow pass on quality toggle %d" % index)
	if draw_enabled:
		_check(rendered_frames > draws_before,"manual graphics toggle %d continues rendering without a lost redraw" % index)

func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame

func _until_elapsed(seconds: float) -> void:
	var remaining: float = seconds-float(Time.get_ticks_msec()-started_ms)/1000.0
	if remaining > 0.0:
		await create_timer(remaining).timeout

func _upgrade_button(node: Node) -> Button:
	if node is Button and node.text.begins_with("ULEPSZ ZA ") and node.is_visible_in_tree():
		return node
	for child: Node in node.get_children():
		var found: Button = _upgrade_button(child)
		if found != null:
			return found
	return null

func _on_frame_drawn() -> void:
	rendered_frames += 1

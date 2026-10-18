extends SceneTree
## Use a disposable directory only:
## XDG_DATA_HOME=/tmp/zelazny-qa godot --headless --path . --script res://tests/persistence.gd -- --test-isolated --test-data-root=/tmp/zelazny-qa
var failures: int = 0
var checks: int = 0
var state: Node

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
	var expected_root: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--test-data-root="):
			expected_root = arg.trim_prefix("--test-data-root=").trim_suffix("/")
	if not "--test-isolated" in OS.get_cmdline_user_args() or expected_root.is_empty() or not expected_root.is_absolute_path() or not OS.get_user_data_dir().begins_with(expected_root + "/"):
		push_error("Refusing persistence test outside explicit disposable XDG_DATA_HOME/--test-data-root.")
		quit(2)
		return
	state = root.get_node("GameState")
	_check(not state.save_enabled, "autoload starts with saving disabled")
	state.new_game()
	state.save_enabled = true
	state.buy("hunter_sword")
	var sword_uid: int = int(state.inventory.back().uid)
	state.equip(sword_uid)
	state.upgrade_item(sword_uid)
	state.buy("guard_armor")
	var armor_uid: int = int(state.inventory.back().uid)
	state.equip(armor_uid)
	state.damage(75)
	state.use_potion()
	state.gain_reward(115,35)
	state.gain_reward(115,35)
	state.gain_reward(115,35)
	state.claim_quest()
	state.audio_enabled = false
	state.save_game()
	var expected: Dictionary = _snapshot()
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH))
	_check(decoded is Dictionary and decoded.version == 1, "save writes valid versioned JSON in disposable data directory")
	_check(decoded.items.size() == 3 and decoded.items[1].id == "hunter_sword" and decoded.items[1].upgrade == 1, "JSON stores stable item identifiers and upgrade levels")
	state.gold = 1
	state.hp = 1
	state.potions = 0
	state.weapon_uid = 0
	state.armor_uid = 0
	state.inventory.clear()
	state.audio_enabled = true
	state.load_game()
	_check(_snapshot() == expected, "reload exactly restores economy, equipment, health, quest, and audio state")
	_check(state.equipped("weapon").id == "hunter_sword" and state.equipped("armor").id == "guard_armor", "reloaded equipment references resolve to reconstructed inventory items")
	_check(state.attack_power() > 30 and state.defense() >= 9, "reconstructed equipment supplies gameplay stats after reload")
	state.save_game()
	state.gold += 123
	state.save_game()
	_check(FileAccess.file_exists(state.SAVE_PATH + ".bak"), "atomic save keeps previous valid backup")
	_write(state.SAVE_PATH,"{corrupted save")
	state.load_game()
	_check(_snapshot() == expected, "corrupted primary save recovers complete previous backup")
	var malformed: Array[Dictionary] = [
		{"label":"non-numeric gold","key":"gold","value":"broken"},
		{"label":"fractional level","key":"level","value":1.5},
		{"label":"out-of-range level","key":"level","value":500},
		{"label":"negative potion count","key":"potions","value":-1},
		{"label":"non-boolean quest flag","key":"quest_claimed","value":"yes"}
	]
	for sample: Dictionary in malformed:
		var bad: Dictionary = decoded.duplicate(true)
		bad[sample.key] = sample.value
		_write(state.SAVE_PATH,JSON.stringify(bad))
		state.load_game()
		_check(_snapshot() == expected,"malformed JSON field recovers valid backup: " + str(sample.label))
	for fault: String in ["duplicate uid","unknown item","invalid upgrade"]:
		var bad: Dictionary = decoded.duplicate(true)
		if fault == "duplicate uid":
			bad.items[1].uid = bad.items[0].uid
		elif fault == "unknown item":
			bad.items[1].id = "not_real_equipment"
		else:
			bad.items[1].upgrade = 99
		_write(state.SAVE_PATH,JSON.stringify(bad))
		state.load_game()
		_check(_snapshot() == expected,"malformed inventory recovers valid backup: " + fault)
	_write(state.SAVE_PATH,"unrecoverable primary test data")
	_write(state.SAVE_PATH + ".bak","unrecoverable backup test data")
	state.load_game()
	_check(state.gold == 10000 and state.level == 1 and state.inventory.size() == 1, "two invalid saves fall back to a usable fresh game")
	_check(FileAccess.get_file_as_string(state.SAVE_PATH + ".corrupt") == "unrecoverable primary test data", "unrecoverable primary is preserved for recovery")
	_check(JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH)) is Dictionary, "recovery writes a new usable save")
	state.save_enabled = false
	print("PERSISTENCE RESULT: %d checks, %d failures; isolated path %s" % [checks,failures,OS.get_user_data_dir()])
	quit(0 if failures == 0 else 1)

func _write(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _snapshot() -> Dictionary:
	var items: Array[Dictionary] = []
	for item: Dictionary in state.inventory:
		items.append({"id":item.id,"uid":item.uid,"upgrade":item.upgrade,"power":state.item_power(item)})
	return {"gold":state.gold,"level":state.level,"xp":state.xp,"hp":state.hp,"potions":state.potions,"kills":state.kills,"quest_claimed":state.quest_claimed,"quest_stage":state.quest_stage,"weapon_uid":state.weapon_uid,"armor_uid":state.armor_uid,"items":items,"audio_enabled":state.audio_enabled}

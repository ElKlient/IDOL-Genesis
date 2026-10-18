extends Node
## Persistent RPG model. Saves only item IDs and upgrades, never resource objects.
signal changed
signal message(text: String)

const SAVE_PATH := "user://adventure_v1.json"
const MAX_UPGRADE := 6
var gold: int = 10000
var level: int = 1
var xp: int = 0
var hp: int = 180
var potions: int = 10
var kills: int = 0
var quest_stage: int = 0
var quest_claimed: bool = false
var inventory: Array[Dictionary] = []
var weapon_uid: int = 0
var armor_uid: int = 0
var next_uid: int = 1
var bought_weapon: bool = false
var upgraded_any: bool = false
var audio_enabled: bool = true
var save_enabled: bool = true
var last_upgrade_success: bool = false

func _ready() -> void:
	if "--test-isolated" in OS.get_cmdline_user_args():
		save_enabled = false
		new_game()
	else:
		load_game()

func catalog() -> Array[Dictionary]:
	return [
		{"id":"iron_sword", "kind":"weapon", "name":"Szabla Karmazynowej Straży", "tier":1, "power":12, "price":350, "icon":"sword", "color":Color("c97960"), "set_name":"Karmazynowa Straż", "description":"Wygięta stalowa klinga, karmazynowy chwyt i słoneczna garda. Pierwszy oręż straży Brzezin."},
		{"id":"hunter_sword", "kind":"weapon", "name":"Ostrze Jadeitowej Bramy", "tier":2, "power":24, "price":1300, "icon":"sword", "color":Color("78b9a7"), "set_name":"Jadeitowa Brama", "description":"Jasna stal i brązowa garda z jadeitowym rdzeniem. Broń wartowników górskiej bramy."},
		{"id":"dawn_sword", "kind":"weapon", "name":"Miecz Popielnego Żaru", "tier":3, "power":40, "price":3400, "icon":"sword", "color":Color("eea16a"), "set_name":"Popielny Żar", "description":"Ciężka klinga z czernionej stali. W jej wykutym kanale tli się żar dawnej kuźni."},
		{"id":"leather_armor", "kind":"armor", "name":"Zbroja Karmazynowej Straży", "tier":1, "power":4, "price":500, "icon":"armor", "color":Color("c97960"), "set_name":"Karmazynowa Straż", "description":"Stalowe lamele, skórzane wiązania i karmazynowa szarfa. Pancerz ludzi chroniących Brzeziny."},
		{"id":"guard_armor", "kind":"armor", "name":"Pancerz Jadeitowej Bramy", "tier":2, "power":9, "price":1800, "icon":"armor", "color":Color("78b9a7"), "set_name":"Jadeitowa Brama", "description":"Jasne płyty, patynowany brąz i jadeitowe okucia na ciemnej tkaninie."},
		{"id":"dawn_armor", "kind":"armor", "name":"Zbroja Popielnego Żaru", "tier":3, "power":16, "price":4200, "icon":"armor", "color":Color("eea16a"), "set_name":"Popielny Żar", "description":"Warstwowe czarne żelazo, popielate wiązania i stary karmazyn. Ślady napraw pamiętają wiele bitew."},
		{"id":"potion", "kind":"consumable", "name":"Mikstura zdrowia", "tier":0, "power":90, "price":60, "icon":"potion", "color":Color("de6a70"), "description":"Przywraca 90 PŻ. Przytrzymaj zapas na walkę."},
		{"id":"potion_pack", "kind":"consumable", "name":"Zapas mikstur ×10", "tier":0, "power":900, "price":500, "icon":"potion", "color":Color("de6a70"), "description":"Dziesięć mikstur w korzystniejszej cenie."}
	]

func definition(id: String) -> Dictionary:
	if id == "training_sword":
		return {"id":id,"kind":"weapon","name":"Miecz rekruta","tier":0,"power":5,"price":0,"icon":"sword","color":Color("9ca8a8"),"description":"Prosty miecz treningowy."}
	for entry: Dictionary in catalog():
		if str(entry.id) == id:
			return entry.duplicate()
	return {}

func _add_item(id: String, upgrade: int = 0, uid: int = 0) -> Dictionary:
	var data: Dictionary = definition(id)
	if data.is_empty() or str(data.kind) == "consumable":
		return {}
	if uid <= 0:
		uid = next_uid
	next_uid = maxi(next_uid, uid + 1)
	data.uid = uid
	data.upgrade = clampi(upgrade, 0, MAX_UPGRADE)
	inventory.append(data)
	return data

func new_game() -> void:
	gold = 10000
	level = 1
	xp = 0
	potions = 10
	kills = 0
	quest_stage = 0
	quest_claimed = false
	bought_weapon = false
	upgraded_any = false
	next_uid = 1
	inventory.clear()
	var starter: Dictionary = _add_item("training_sword")
	weapon_uid = int(starter.uid)
	armor_uid = 0
	hp = max_health()
	_commit()

func item_name(item: Dictionary) -> String:
	if item.is_empty():
		return "Brak"
	return "%s +%d" % [str(item.name), int(item.get("upgrade",0))]

func item_power(item: Dictionary) -> int:
	if item.is_empty():
		return 0
	var step: int = 4 + int(item.tier) if str(item.kind) == "weapon" else 2
	return int(item.power) + int(item.get("upgrade",0)) * step

func find_item(uid: int) -> Dictionary:
	for item: Dictionary in inventory:
		if int(item.uid) == uid:
			return item
	return {}

func equipped(kind: String) -> Dictionary:
	return find_item(weapon_uid if kind == "weapon" else armor_uid)

func attack_power() -> int:
	return 8 + level * 2 + item_power(equipped("weapon"))

func defense() -> int:
	return item_power(equipped("armor")) + level - 1

func max_health() -> int:
	return 180 + (level - 1) * 24

func xp_needed() -> int:
	return 100 + (level - 1) * 65

func buy(id: String) -> bool:
	var data: Dictionary = definition(id)
	if data.is_empty():
		return false
	if inventory.size() >= 30 and str(data.kind) != "consumable":
		message.emit("Plecak jest pełny (30 przedmiotów).")
		return false
	var price: int = int(data.price)
	if gold < price:
		message.emit("Za mało złota. Potrzebujesz %d G." % price)
		return false
	gold -= price
	if str(data.kind) == "consumable":
		potions += 10 if id == "potion_pack" else 1
	else:
		_add_item(id)
		if str(data.kind) == "weapon":
			bought_weapon = true
	message.emit("Kupiono: %s" % str(data.name))
	_commit()
	return true

func equip(uid: int) -> bool:
	var item: Dictionary = find_item(uid)
	if item.is_empty():
		return false
	if str(item.kind) == "weapon":
		weapon_uid = uid
	else:
		armor_uid = uid
	message.emit("Założono: %s" % item_name(item))
	_commit()
	return true

func use_potion() -> bool:
	if hp >= max_health():
		message.emit("Masz pełne zdrowie.")
		return false
	if potions <= 0:
		message.emit("Brak mikstur. Uzupełnij zapas u Miry.")
		return false
	potions -= 1
	hp = mini(max_health(), hp + 90)
	message.emit("Mikstura: +90 PŻ")
	_commit()
	return true

func upgrade_cost(uid: int) -> int:
	var item: Dictionary = find_item(uid)
	if item.is_empty() or int(item.upgrade) >= MAX_UPGRADE:
		return 0
	return (100 + int(item.tier) * 80) * (int(item.upgrade) + 1)

func upgrade_chance(uid: int) -> int:
	var item: Dictionary = find_item(uid)
	if item.is_empty() or int(item.upgrade) >= MAX_UPGRADE:
		return 0
	var chances: Array[int] = [100,100,100,80,65,50]
	return chances[int(item.upgrade)]

func upgrade_item(uid: int) -> bool:
	_diagnostic("upgrade_begin", {"uid":uid})
	last_upgrade_success = false
	var item: Dictionary = find_item(uid)
	if item.is_empty():
		return false
	if int(item.upgrade) >= MAX_UPGRADE:
		message.emit("Ten przedmiot osiągnął maksymalny poziom +6.")
		return false
	var cost: int = upgrade_cost(uid)
	if gold < cost:
		message.emit("Za mało złota na ulepszenie (%d G)." % cost)
		return false
	gold -= cost
	last_upgrade_success = randi_range(1,100) <= upgrade_chance(uid)
	if last_upgrade_success:
		item.upgrade = int(item.upgrade) + 1
		upgraded_any = true
		_diagnostic("upgrade_message_begin", {"upgrade":int(item.upgrade)})
		message.emit("SUKCES! %s" % item_name(item))
	else:
		message.emit("Próba nieudana. Przedmiot i poziom zachowane; koszt zużyty.")
	_diagnostic("upgrade_message_end", {"upgrade":int(item.upgrade)})
	_commit()
	_diagnostic("upgrade_end", {"upgrade":int(item.upgrade),"success":last_upgrade_success})
	return last_upgrade_success

func gain_reward(gold_amount: int, xp_amount: int) -> void:
	gold += maxi(0,gold_amount)
	xp += maxi(0,xp_amount)
	kills += 1
	while xp >= xp_needed() and level < 50:
		xp -= xp_needed()
		level += 1
		hp = max_health()
		message.emit("NOWY POZIOM %d! Zdrowie odnowione." % level)
	_commit()

func damage(amount: int) -> void:
	hp = maxi(0, hp - maxi(1,amount - defense()))
	changed.emit()
	# Death is resolved by main before saving, preventing a zero-HP reload loop.

func heal_full() -> void:
	hp = max_health()
	_commit()

func quest_text() -> String:
	if quest_claimed:
		return "Strażnik Brzezin • Pokonaj Strażnika Korzeni na północy."
	if not bought_weapon:
		return "Pierwsze kroki • Kup miecz u Miry na targu."
	if not upgraded_any:
		return "Pierwsze kroki • Ulepsz przedmiot u kowala Borna."
	if kills < 3:
		return "Pierwsze kroki • Pokonaj potwory: %d/3." % kills
	return "Pierwsze kroki • Odbierz 1200 G u Miry."

func claim_quest() -> bool:
	if quest_claimed or not bought_weapon or not upgraded_any or kills < 3:
		message.emit("Mira: kup miecz, ulepsz go i pokonaj 3 potwory.")
		return false
	quest_claimed = true
	gold += 1200
	potions += 5
	message.emit("Zadanie wykonane! +1200 G i 5 mikstur.")
	_commit()
	return true

func _commit() -> void:
	quest_stage = 3 if quest_claimed else (2 if upgraded_any else (1 if bought_weapon else 0))
	save_game()
	_diagnostic("state_signal_begin")
	changed.emit()
	_diagnostic("state_signal_end")

func save_game() -> void:
	if not save_enabled:
		return
	_diagnostic("save_begin")
	var items: Array[Dictionary] = []
	for item: Dictionary in inventory:
		items.append({"id":str(item.id),"uid":int(item.uid),"upgrade":int(item.upgrade)})
	var data: Dictionary = {"version":1,"gold":gold,"level":level,"xp":xp,"hp":hp,"potions":potions,"kills":kills,"quest_claimed":quest_claimed,"bought_weapon":bought_weapon,"upgraded_any":upgraded_any,"weapon_uid":weapon_uid,"armor_uid":armor_uid,"items":items,"audio_enabled":audio_enabled}
	var temporary: String = SAVE_PATH + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Nie udało się otworzyć pliku zapisu.")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	# Keep one previous valid save and replace using a rename on the same volume.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, SAVE_PATH + ".bak")
	var result: Error = DirAccess.rename_absolute(temporary, SAVE_PATH)
	if result != OK:
		push_warning("Nie udało się zatwierdzić zapisu: %d" % result)
	_diagnostic("save_end", {"result":int(result)})

func _diagnostic(event_name: String, details: Dictionary = {}) -> void:
	var diagnostics: Node = get_node_or_null("/root/Diagnostics")
	if diagnostics != null and diagnostics.has_method("note"):
		diagnostics.call("note", event_name, details)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		new_game()
		return
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not _valid_save(decoded):
		decoded = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH + ".bak")) if FileAccess.file_exists(SAVE_PATH + ".bak") else null
	if not _valid_save(decoded):
		# Preserve corrupted data before starting over.
		DirAccess.copy_absolute(SAVE_PATH,SAVE_PATH + ".corrupt")
		new_game()
		return
	var data: Dictionary = decoded
	gold = maxi(0,int(data.get("gold",10000)))
	level = clampi(int(data.get("level",1)),1,50)
	xp = maxi(0,int(data.get("xp",0)))
	hp = clampi(int(data.get("hp",max_health())),1,max_health())
	potions = maxi(0,int(data.get("potions",10)))
	kills = maxi(0,int(data.get("kills",0)))
	quest_claimed = bool(data.get("quest_claimed",false))
	bought_weapon = bool(data.get("bought_weapon",false))
	upgraded_any = bool(data.get("upgraded_any",false))
	audio_enabled = bool(data.get("audio_enabled",true))
	next_uid = 1
	inventory.clear()
	for raw: Variant in data.get("items",[]):
		if raw is Dictionary:
			_add_item(str(raw.get("id","")),int(raw.get("upgrade",0)),int(raw.get("uid",0)))
	if inventory.is_empty():
		_add_item("training_sword")
	weapon_uid = int(data.get("weapon_uid",int(inventory[0].uid)))
	armor_uid = int(data.get("armor_uid",0))
	if find_item(weapon_uid).is_empty() or str(find_item(weapon_uid).kind) != "weapon":
		weapon_uid = 0
		for item: Dictionary in inventory:
			if str(item.kind) == "weapon":
				weapon_uid = int(item.uid)
				break
	if find_item(armor_uid).is_empty() or str(find_item(armor_uid).kind) != "armor":
		armor_uid = 0
	quest_stage = 3 if quest_claimed else (2 if upgraded_any else (1 if bought_weapon else 0))
	changed.emit()

func _valid_save(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var data: Dictionary = value
	if not _integer_value(data.get("version",null),1,1) or not data.get("items",null) is Array:
		return false
	for key: String in ["gold","xp","hp","potions","kills","weapon_uid","armor_uid"]:
		if data.has(key) and not _integer_value(data[key],0,2000000000):
			return false
	if data.has("level") and not _integer_value(data.level,1,50):
		return false
	for key: String in ["quest_claimed","bought_weapon","upgraded_any","audio_enabled"]:
		if data.has(key) and not data[key] is bool:
			return false
	var seen_uids: Dictionary = {}
	var items: Array = data.items
	if items.size()>30:
		return false
	for item: Variant in items:
		if not item is Dictionary or not item.get("id",null) is String:
			return false
		var item_definition: Dictionary = definition(item.id)
		if item_definition.is_empty() or str(item_definition.kind)=="consumable":
			return false
		if not _integer_value(item.get("uid",null),1,2000000000) or not _integer_value(item.get("upgrade",null),0,MAX_UPGRADE):
			return false
		var uid: int = int(item.uid)
		if seen_uids.has(uid):
			return false
		seen_uids[uid]=true
	return true

func _integer_value(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	var number: float = float(value)
	return is_finite(number) and number>=minimum and number<=maximum and floorf(number)==number

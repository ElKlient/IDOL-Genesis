extends Node3D
## Single-player vertical slice: village -> merchant -> smith -> wilds -> reward.
const WorldScript = preload("res://scripts/world.gd")
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const HUDScript = preload("res://ui/hud.gd")
const AudioScript = preload("res://scripts/audio.gd")
var world: Node3D
var hero: CharacterBody3D
var hud: CanvasLayer
var camera: Camera3D
var audio: Node
var enemies: Array[Node3D] = []
var target: Node3D
var attack_cooldown: float = 0.0
var skill_cooldown: float = 0.0
var combo: int = 0
var combo_time: float = 0.0
var context_npc: String = ""
var autosave_time: float = 0.0
var respawning: bool = false
var last_level: int = 1
var minimap_time: float = 0.0
var low_quality: bool = false
var spawn_records: Array[Dictionary] = []
var equipment_signature: String = ""
var skill_effect: Node3D
var attack_effect_material: StandardMaterial3D

func _ready() -> void:
	randomize()
	get_tree().auto_accept_quit = false
	world = WorldScript.new()
	add_child(world)
	hero = PlayerScript.new()
	hero.position = world.spawn_position
	add_child(hero)
	camera = Camera3D.new()
	camera.fov = 48.0
	camera.near = 0.2
	camera.far = 190.0
	camera.position = hero.position + Vector3(0,16,13)
	add_child(camera)
	camera.look_at(hero.position + Vector3(0,0.6,-1.5),Vector3.UP)
	camera.current = true
	audio = AudioScript.new()
	audio.enabled = GameState.audio_enabled
	add_child(audio)
	hud = HUDScript.new()
	add_child(hud)
	hud.setup(hero)
	hud.attack_requested.connect(request_attack)
	hud.skill_requested.connect(use_skill)
	hud.potion_requested.connect(use_potion)
	hud.interact_requested.connect(interact)
	if hud.has_signal("close_requested"):
		hud.close_requested.connect(_close_modal)
	GameState.message.connect(_on_message)
	GameState.changed.connect(_on_state_changed)
	last_level = GameState.level
	_on_state_changed()
	for record: Dictionary in world.enemy_spawns:
		spawn_records.append(record.duplicate())
		_spawn_enemy(record)
	hud.toast("Witaj w Brzezinach! Masz 10 000 G. Podejdź do Miry przy straganie po lewej.")
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_keep_on(true)

func _spawn_enemy(record: Dictionary) -> Node3D:
	var enemy: CharacterBody3D = EnemyScript.new()
	enemy.position = record.position
	enemy.setup(int(record.kind),hero)
	add_child(enemy)
	enemies.append(enemy)
	enemy.struck_player.connect(_enemy_hit)
	enemy.damaged.connect(func(amount: int, critical: bool): _floating_text(enemy.position+Vector3(0,2.6,0), str(amount)+("!" if critical else ""), Color("ffe5a2") if critical else Color("fff1d0")))
	enemy.defeated.connect(func(dead_enemy: Node3D): _on_enemy_defeated(dead_enemy,record))
	return enemy

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero) or not is_instance_valid(hud):
		return
	attack_cooldown = maxf(0.0,attack_cooldown-delta)
	skill_cooldown = maxf(0.0,skill_cooldown-delta)
	combo_time -= delta
	if combo_time <= 0.0:
		combo = 0
	var blocked: bool = hud.modal_open or respawning
	var movement: Vector2 = hud.move_vector
	if not blocked:
		var keys: Vector2 = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		if keys.length_squared() > 0:
			movement = keys.normalized()
		hero.move_input = movement.limit_length(1.0)
		if hud.attack_held or Input.is_physical_key_pressed(KEY_SPACE):
			request_attack()
	else:
		hero.move_input = Vector2.ZERO
	for enemy: Node3D in enemies:
		if is_instance_valid(enemy):
			enemy.frozen = blocked
	# World border is a gentle clamp; all main routes remain physically open.
	hero.position.x = clampf(hero.position.x,-44.0,44.0)
	hero.position.z = clampf(hero.position.z,-46.0,24.0)
	if hero.position.y < -4.0:
		hero.reset_to(world.spawn_position)
	_update_context()
	_update_target()
	autosave_time += delta
	if autosave_time > 12.0:
		autosave_time = 0.0
		GameState.save_game()
	if hud.has_method("set_skill_cooldown"):
		hud.set_skill_cooldown(skill_cooldown,7.0)

func _process(delta: float) -> void:
	if not is_instance_valid(hero) or not is_instance_valid(camera):
		return
	var offset: Vector3 = Vector3(0,16,13)
	camera.position = camera.position.lerp(hero.position+offset,1.0-exp(-delta*6.0))
	camera.look_at(hero.position+Vector3(0,0.6,-1.5),Vector3.UP)
	minimap_time -= delta
	if minimap_time <= 0.0 and hud.has_method("set_world_positions"):
		minimap_time = 0.1
		hud.set_world_positions(hero.position,enemies,world.npc_positions)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E: interact()
			KEY_I: hud.open_panel("inventory")
			KEY_Q: use_potion()
			KEY_R: use_skill()
			KEY_ESCAPE, KEY_BACK: _close_modal()
			KEY_TAB: _cycle_target()
	if hud.modal_open or respawning:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pick_target(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_pick_target(event.position)

func _pick_target(screen_position: Vector2) -> void:
	var best: Node3D = null
	var radius: float = 80.0 * get_viewport().get_visible_rect().size.y / 720.0
	for enemy: Node3D in enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive() or hero.position.distance_to(enemy.position)>20.0:
			continue
		if camera.is_position_behind(enemy.position):
			continue
		var screen: Vector2 = camera.unproject_position(enemy.position+Vector3(0,1.0,0))
		var d: float = screen.distance_to(screen_position)
		if d < radius:
			best = enemy
			radius = d
	if best != null:
		_set_target(best)

func _nearest_enemy(max_distance: float = 16.0) -> Node3D:
	var nearest: Node3D = null
	var distance: float = max_distance
	for enemy: Node3D in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			var d: float = hero.position.distance_to(enemy.position)
			if d < distance:
				distance = d
				nearest = enemy
	return nearest

func _set_target(enemy: Node3D) -> void:
	if is_instance_valid(target):
		target.set_targeted(false)
	target = enemy
	if is_instance_valid(target):
		target.set_targeted(true)

func _update_target() -> void:
	if is_instance_valid(target) and (not target.is_alive() or hero.position.distance_to(target.position)>21.0):
		_set_target(null)
	if not is_instance_valid(target):
		_set_target(_nearest_enemy(12.0))
	if is_instance_valid(target):
		hud.set_target(target.display_name,target.hp,target.max_hp,target.level)
	else:
		hud.clear_target()

func _cycle_target() -> void:
	var nearby: Array[Node3D] = []
	for enemy: Node3D in enemies:
		if is_instance_valid(enemy) and enemy.is_alive() and hero.position.distance_to(enemy.position)<18:
			nearby.append(enemy)
	if nearby.is_empty():
		return
	var index: int = nearby.find(target)
	_set_target(nearby[(index+1)%nearby.size()])

func request_attack() -> void:
	if not is_instance_valid(hud) or hud.modal_open or respawning or attack_cooldown>0:
		return
	attack_cooldown = 0.48
	combo_time = 1.2
	combo = (combo % 3) + 1
	var nearest: Node3D = _nearest_enemy(3.0)
	if is_instance_valid(target) and target.is_alive() and hero.position.distance_to(target.position)<3.0:
		nearest = target
	if nearest != null:
		_set_target(nearest)
		var direction: Vector3 = nearest.position-hero.position
		direction.y = 0.0
		hero.face_direction(direction.normalized())
	hero.play_attack(combo-1,false)
	audio.play_sfx("swing")
	# Delay the hit until the sword reaches its arc. Target is rechecked then.
	_hit_after_windup(nearest,combo)

func _hit_after_windup(enemy: Node3D, step: int) -> void:
	await get_tree().create_timer(0.16).timeout
	if not is_instance_valid(enemy) or not enemy.is_alive() or respawning or hud.modal_open:
		return
	if hero.position.distance_to(enemy.position)>3.2:
		return
	var critical: bool = randf()<0.14
	var damage: int = GameState.attack_power()+randi_range(-2,3)
	if step == 3:
		damage = int(damage*1.25)
	if critical:
		damage = int(damage*1.65)
	enemy.take_damage(damage,critical)
	audio.play_sfx("hit")

func use_skill() -> void:
	if hud.modal_open or respawning:
		return
	if skill_cooldown>0:
		hud.toast("Wir stali gotowy za %.1f s" % skill_cooldown)
		return
	skill_cooldown = 7.0
	attack_cooldown = 0.7
	hero.play_attack(0,true)
	audio.play_sfx("skill")
	_ring_effect(hero.position,Color("70dcd0"),4.2)
	await get_tree().create_timer(0.24).timeout
	if respawning or hud.modal_open:
		return
	for enemy: Node3D in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.is_alive() and hero.position.distance_to(enemy.position)<4.2:
			enemy.take_damage(int(GameState.attack_power()*1.8)+5,true)

func use_potion() -> void:
	if respawning:
		return
	if GameState.use_potion():
		audio.play_sfx("heal")
		_ring_effect(hero.position,Color("84db9b"),1.4)

func _enemy_hit(amount: int) -> void:
	if respawning or hud.modal_open:
		return
	var before: int = GameState.hp
	GameState.damage(amount)
	hero.receive_hit()
	_floating_text(hero.position+Vector3(0,2.5,0),"−%d" % (before-GameState.hp),Color("ff8580"))
	if GameState.hp<=0:
		_respawn_hero()

func _respawn_hero() -> void:
	respawning = true
	hero.dead = true
	hero.move_input = Vector2.ZERO
	hud.toast("Padłeś w walce. Strażnicy przenoszą Cię do wioski. Ekwipunek i złoto zachowane.")
	await get_tree().create_timer(2.0).timeout
	hero.reset_to(world.spawn_position)
	hero.dead = false
	GameState.heal_full()
	_set_target(null)
	respawning = false
	_ring_effect(hero.position,Color("a0dfce"),2.0)

func _on_enemy_defeated(enemy: Node3D, record: Dictionary) -> void:
	var g: int = enemy.reward_gold
	var exp_points: int = enemy.reward_xp
	GameState.gain_reward(g,exp_points)
	_floating_text(enemy.position+Vector3(0,1.5,0),"+%d G   +%d PD" % [g,exp_points],Color("f1ce75"))
	audio.play_sfx("coin")
	if int(record.kind)==2:
		GameState.gold += 800
		GameState.potions += 3
		GameState.save_game()
		GameState.changed.emit()
		hud.toast("Strażnik Korzeni pokonany! Skrzynia: +800 G i 3 mikstury.")
	if randf()<0.22:
		GameState.potions += 1
		GameState.save_game()
		GameState.changed.emit()
	if target==enemy:
		_set_target(null)
	enemies.erase(enemy)
	await get_tree().create_timer(24.0 if int(record.kind)==2 else 18.0).timeout
	if is_inside_tree():
		_spawn_enemy(record)

func _update_context() -> void:
	context_npc = ""
	var nearest_distance: float = 3.7
	for key: String in world.npc_positions:
		var d: float = hero.position.distance_to(world.npc_positions[key])
		if d<nearest_distance:
			nearest_distance=d
			context_npc=key
	if context_npc == "merchant":
		hud.set_context("Mira • Handel")
	elif context_npc == "blacksmith":
		hud.set_context("Born • Ulepszanie")
	else:
		hud.set_context("")

func interact() -> void:
	if respawning or hud.modal_open:
		return
	_update_context()
	if context_npc == "merchant":
		hud.open_panel("shop")
	elif context_npc == "blacksmith":
		hud.open_panel("forge")
	else:
		hud.toast("Podejdź do Miry po lewej lub Borna po prawej stronie placu.")

func _on_state_changed() -> void:
	if not is_instance_valid(hero):
		return
	var weapon: Dictionary = GameState.equipped("weapon")
	var armor: Dictionary = GameState.equipped("armor")
	var weapon_tier: int = int(weapon.get("tier",0))
	var armor_tier: int = int(armor.get("tier",0))
	var upgrade: int = int(weapon.get("upgrade",0))
	var signature: String = "%d:%d:%d" % [weapon_tier,armor_tier,upgrade]
	if signature!=equipment_signature:
		equipment_signature=signature
		hero.set_equipment(weapon_tier,armor_tier,upgrade)
	if GameState.level>last_level:
		last_level=GameState.level
		_ring_effect(hero.position,Color("f7d780"),2.6)
		if is_instance_valid(audio):
			audio.play_sfx("level")
	if is_instance_valid(hud):
		hud.refresh()

func _on_message(text: String) -> void:
	if is_instance_valid(hud):
		hud.toast(text)
	if is_instance_valid(audio) and text.begins_with("SUKCES"):
		audio.play_sfx("forge")

func _close_modal() -> void:
	if hud.has_method("close_panel"):
		hud.close_panel()
	elif hud.has_method("open_panel") and hud.modal_open:
		hud.open_panel("")

func set_audio_enabled(value: bool) -> void:
	GameState.audio_enabled=value
	GameState.save_game()
	audio.set_enabled(value)

func start_new_game() -> void:
	GameState.new_game()
	# Recreate enemies, respawn timers, cooldowns and camera as well as the save.
	get_tree().call_deferred("reload_current_scene")

func set_low_quality(value: bool) -> void:
	low_quality=value
	# Keep startup MSAA fixed to avoid render-target reallocation while playing,
	# especially in Android/ANGLE embedded views where a process exit was reported.
	for child: Node in world.get_children():
		if child is DirectionalLight3D:
			child.shadow_enabled=not value
	if world.has_method("set_low_quality"):
		world.set_low_quality(value)

func _floating_text(at: Vector3, text: String, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text=text
	label.font_size=42
	label.pixel_size=0.011
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=true
	label.modulate=color
	label.outline_modulate=Color(0.06,0.07,0.07,0.9)
	label.outline_size=8
	label.position=at
	add_child(label)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label,"position:y",at.y+1.7,1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label,"modulate:a",0.0,0.9).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)

func _ring_effect(at: Vector3, color: Color, radius: float) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius=0.93
	torus.outer_radius=1.0
	torus.rings=24
	torus.ring_segments=8
	mesh.mesh=torus
	var material: StandardMaterial3D=StandardMaterial3D.new()
	material.albedo_color=color
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test=false
	mesh.material_override=material
	mesh.position=at+Vector3(0,0.18,0)
	mesh.scale=Vector3(0.2,0.07,0.2)
	add_child(mesh)
	var tween: Tween=create_tween().set_parallel(true)
	tween.tween_property(mesh,"scale",Vector3(radius,0.07,radius),0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material,"albedo_color:a",0.0,0.6)
	tween.chain().tween_callback(mesh.queue_free)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST or what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		GameState.save_game()
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(hud) and hud.modal_open:
			_close_modal()
		elif is_instance_valid(hud):
			hud.open_panel("settings")
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()

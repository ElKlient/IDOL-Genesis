extends SceneTree
## Actual imported, skinned warrior regression; no player writes or telemetry.
const VisualScript = preload("res://scripts/character_visual.gd")
var game: Node3D
var state: Node
var visual: Node3D
var model: Node3D
var preview: Control
var checks: int = 0
var failures: int = 0
var capture_dir: String = ""
var measured_stats: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS: "+label)
	else:
		failures += 1
		push_error("FAIL: "+label)

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		push_error("Supply --test-isolated; never inspect models against a player's save.")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	var save_exists: bool = FileAccess.file_exists(state.SAVE_PATH)
	var save_before: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if save_exists else PackedByteArray()
	_check(not state.save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"warrior QA disables player saving and diagnostic networking")
	_check(ResourceLoader.exists("res://assets/warrior/warrior.glb") and ResourceLoader.exists("res://assets/warrior/weapons.glb"),"actual warrior and four-weapon GLB packages are imported")
	state.new_game()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for enemy: Node in game.enemies:
		enemy.set_physics_process(false)
	game.hero.set_physics_process(false)
	await _frames(4)
	visual = game.hero.visual
	model = visual.get("model") as Node3D
	_check(is_instance_valid(model) and bool(model.get("load_succeeded")),"playable warrior uses the imported model adapter with no primitive fallback")
	if not is_instance_valid(model) or not bool(model.get("load_succeeded")):
		quit(1)
		return
	var skeleton: Skeleton3D = model.get("skeleton") as Skeleton3D
	_check(is_instance_valid(skeleton) and skeleton.get_bone_count() >= 40,"imported warrior has a complete articulated adult skeleton")
	var body: MeshInstance3D = model.find_child("Body",true,false) as MeshInstance3D
	_check(is_instance_valid(body) and body.mesh is ArrayMesh and body.skin != null and body.mesh.get_surface_count() == 1,"continuous smooth body is a skinned ArrayMesh rather than separate box limbs")
	if not is_instance_valid(body) or body.skin == null:
		quit(1)
		return
	var body_data: Array = body.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = body_data[Mesh.ARRAY_VERTEX]
	var weights: PackedFloat32Array = body_data[Mesh.ARRAY_WEIGHTS]
	_check(verts.size() > 1000 and weights.size() >= verts.size()*4,"body contains a real detailed, weighted surface")
	var head_points: PackedVector3Array = _head_vertices(body,skeleton)
	var body_points: PackedVector3Array = _skin_vertices(body)
	var body_bounds: AABB = _bounds(body_points)
	var head_bounds: AABB = _bounds(head_points)
	var adult_height: float = body_bounds.end.y
	var head_height: float = head_bounds.size.y
	print("WARRIOR PROPORTIONS: top=%.3f m, head=%.3f m, ratio=%.2f" % [adult_height,head_height,adult_height/maxf(head_height,0.001)])
	_check(adult_height > 1.75 and adult_height < 2.15 and head_height > 0.16 and head_height < 0.31 and adult_height/head_height > 6.5,"actual skinned head and adult height have natural proportions above 6.5 heads")
	var hidden_boxes: bool = true
	for part: Node in visual.find_children("*","MeshInstance3D",true,false):
		if part.is_visible_in_tree() and part.mesh is BoxMesh:
			hidden_boxes = false
	_check(hidden_boxes,"no old block-body or primitive sword pieces remain visibly rendered")
	var armor_shapes: Dictionary = {}
	var weapon_shapes: Dictionary = {}
	for tier: int in range(4):
		visual.set_equipment(tier,tier,tier+1)
		visual.attack_elapsed = -1.0
		visual.tick(0.0,0.0)
		await _frames(2)
		var stats: Dictionary = _render_stats(visual)
		stats["tier"] = tier
		measured_stats.append(stats)
		print("WARRIOR TIER %d: %s" % [tier,JSON.stringify(stats)])
		_check(int(stats.triangles) > 5000 and int(stats.triangles) <= 30000 and int(stats.surfaces) <= 16,"tier %d stays within 30k visible triangles and sixteen bounded material surfaces" % tier)
		_check(_skin_count(visual) >= 4,"tier %d keeps the body and worn equipment attached to a real skin" % tier)
		var armor: Dictionary = model.get("armor_variants")
		var weapons: Dictionary = model.get("weapon_variants")
		if armor.has(tier) and weapons.has(tier):
			armor_shapes[_mesh_signature(armor[tier])] = true
			weapon_shapes[_mesh_signature(weapons[tier])] = true
	_check(armor_shapes.size() == 4,"four equipment stages use distinct armor geometry")
	_check(weapon_shapes.size() == 4,"four equipped swords use distinct exported blade geometry")
	var textures: Dictionary = _texture_stats(model)
	print("WARRIOR TEXTURES: "+JSON.stringify(textures))
	_check(int(textures.largest_dimension) <= 1024 and int(textures.count) <= 8,"body, hair and eye textures stay at or below 1024 pixels with a bounded shared texture set")
	_check(int(textures.transparent_materials) == 0,"imported body, armor and sword use opaque materials without transparent depth passes")
	state.gold = 20000
	state.buy("dawn_sword")
	var sword_uid: int = int(state.inventory.back().uid)
	state.find_item(sword_uid).upgrade = 5
	state.equip(sword_uid)
	state.buy("dawn_armor")
	state.equip(int(state.inventory.back().uid))
	await _frames(4)
	game.hud.open_panel("inventory")
	await _frames(5)
	preview = game.hud.character_preview
	var portrait: Node3D = preview.preview_model
	var portrait_model: Node3D = portrait.get("model") as Node3D
	_check(is_instance_valid(portrait_model) and bool(portrait_model.get("load_succeeded")),"actual inventory portrait also renders the imported skinned model")
	portrait.set_equipment(0,0,0)
	var portrait_color: Color = portrait.armor_material.albedo_color
	visual.set_equipment(3,3,6)
	_check(visual.armor_material != portrait.armor_material and visual.blade_material != portrait.blade_material and portrait.armor_material.albedo_color == portrait_color,"main and portrait own independent mutable armor and blade materials")
	var portrait_body: MeshInstance3D = portrait_model.find_child("Body",true,false) as MeshInstance3D
	_check(is_instance_valid(portrait_body) and portrait_body.mesh == body.mesh and portrait_body.skin == body.skin,"main and portrait share immutable imported mesh and skin resources")
	var main_body_material: StandardMaterial3D = body.get_active_material(0) as StandardMaterial3D
	var portrait_body_material: StandardMaterial3D = portrait_body.get_active_material(0) as StandardMaterial3D
	var main_armor: MeshInstance3D = model.find_child("Armor3",true,false) as MeshInstance3D
	var portrait_armor: MeshInstance3D = portrait_model.find_child("Armor3",true,false) as MeshInstance3D
	var main_armor_material: StandardMaterial3D = main_armor.get_active_material(0) as StandardMaterial3D
	var portrait_armor_material: StandardMaterial3D = portrait_armor.get_active_material(0) as StandardMaterial3D
	var main_color: Color = main_armor_material.albedo_color
	var portrait_armor_color: Color = portrait_armor_material.albedo_color
	main_armor_material.albedo_color = Color(0.12,0.73,0.26)
	_check(main_body_material != portrait_body_material and main_armor_material != portrait_armor_material and portrait_armor_material.albedo_color == portrait_armor_color and main_body_material.albedo_texture == portrait_body_material.albedo_texture,"actual imported armor/body materials are independent while their immutable skin textures remain shared")
	main_armor_material.albedo_color = main_color
	visual.set_equipment(3,3,5)
	portrait.set_equipment(3,3,5)
	preview.set_process(false)
	await _portrait_skin_bounds(portrait,portrait_model)
	portrait.attack_elapsed = -1
	portrait.tick(0.0,0.0)
	preview.set_preview_yaw(0)
	await _capture("02-inventory-front")
	preview.set_preview_yaw(90)
	await _capture("03-inventory-side")
	preview.set_process(true)
	game.hud.close_panel()
	await _frames(3)
	game.hero.reset_to(Vector3(0,0,2.0))
	game.hero.set_physics_process(false)
	visual.rotation = Vector3.ZERO
	game.set_camera_settings(2.5,38,145)
	visual.attack_elapsed = -1
	visual.tick(0.0,0.0)
	await _capture("01-village-warrior")
	var original_points: PackedVector3Array = _skin_vertices(body)
	visual.tick(0.7,1.0)
	var running_points: PackedVector3Array = _skin_vertices(body)
	_check(_vertex_difference(original_points,running_points) > 0.12,"run animation actually deforms imported body vertices")
	await _capture("04-run")
	visual.locomotion_blend = 0.0
	for combo: int in range(4):
		visual.attack_elapsed = -1
		visual.tick(1.0,0.0)
		visual.start_attack(combo,false)
		visual.tick(0.16 if combo < 3 else 0.25,0.0)
		var points: PackedVector3Array = _skin_vertices(body)
		_check(_finite_pose(points) and _all_skins_finite() and _vertex_difference(original_points,points) > 0.08,"cut %d deforms the real weighted body and armor without invalid or exploded vertices" % (combo+1))
		await _capture("05-cut-%d" % (combo+1))
	visual.attack_elapsed = -1
	visual.tick(1.0,0.0)
	visual.start_fire_slam()
	visual.tick(0.35,0.0)
	_check(_finite_pose(_skin_vertices(body)) and _all_skins_finite(),"two-handed raised pose retains finite bounded skinning")
	await _capture("06-slam-raised")
	visual.tick(0.13,0.0)
	var tip: Vector3 = visual.to_local(visual.sword.to_global(Vector3(0,-1.205,0)))
	var left_hand: Node3D = visual.get("left_wrist") as Node3D
	var left_grip_error: float = left_hand.global_position.distance_to(visual.sword.to_global(Vector3(0,-0.14,0))) if is_instance_valid(left_hand) else INF
	print("WARRIOR SLAM: blade tip height=%.4f m, support hand distance=%.4f m" % [tip.y,left_grip_error])
	_check(absf(tip.y-0.07) < 0.035 and left_grip_error < 0.065,"slam reaches the floor while both hands remain on the actual sword hilt")
	_check(_finite_pose(_skin_vertices(body)) and _all_skins_finite(),"planted slam retains finite bounded body and armor skinning")
	await _capture("07-slam-contact")
	for tier: int in range(4):
		visual.set_equipment(tier,tier,5)
		visual.attack_elapsed = -1
		visual.tick(1.0,0.0)
		visual.start_fire_slam()
		visual.tick(0.48,0.0)
		tip = visual.to_local(visual.sword.to_global(Vector3(0,-1.205,0)))
		left_grip_error = visual.left_wrist.global_position.distance_to(visual.sword.to_global(Vector3(0,-0.14,0)))
		var left_ankle: Vector3 = _bone_position(model,"foot_l")
		var right_ankle: Vector3 = _bone_position(model,"foot_r")
		var base_armor: MeshInstance3D = model.find_child("Armor0",true,false) as MeshInstance3D
		var sole_height: float = _bounds(_skin_vertices(base_armor)).position.y
		print("WARRIOR BOOT SOLE tier %d: minimum=%.5f, ankle heights %.5f / %.5f" % [tier,sole_height,left_ankle.y,right_ankle.y])
		_check(absf(tip.y-0.07) < 0.035 and left_grip_error < 0.065 and absf(left_ankle.y-0.09515) < 0.035 and absf(right_ankle.y-0.09515) < 0.035 and sole_height >= -0.04 and _all_skins_finite(),"tier %d planted slam keeps actual boot soles above the floor, both hands on its hilt and the blade at floor contact" % tier)
	visual.set_equipment(3,3,5)
	visual.attack_elapsed = -1
	visual.tick(1.0,0.0)
	visual.set_sword_flame(true)
	_check(visual.sword_fire.get_parent() == visual.sword and visual.sword_fire.is_burning(),"flame renderer remains attached to the actual equipped sword transform")
	await _capture("08-flaming-sword")
	visual.set_sword_flame(false)
	_check(FileAccess.file_exists(state.SAVE_PATH) == save_exists and (not save_exists or FileAccess.get_file_as_bytes(state.SAVE_PATH) == save_before),"model, pose and portrait QA preserve all existing player-save bytes")
	game.queue_free()
	await _frames(2)
	await create_timer(0.25).timeout
	print("WARRIOR MODEL RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _skin_vertices(part: MeshInstance3D, reference: Node3D = null) -> PackedVector3Array:
	var points := PackedVector3Array()
	var skeleton: Skeleton3D = part.get_node_or_null(part.skeleton) as Skeleton3D
	if skeleton == null or part.skin == null:
		return points
	var space: Node3D = reference if reference != null else model
	skeleton.force_update_all_bone_transforms()
	var palette: Array[Transform3D] = []
	for bind: int in range(part.skin.get_bind_count()):
		var bone: int = part.skin.get_bind_bone(bind)
		if bone < 0:
			bone = skeleton.find_bone(part.skin.get_bind_name(bind))
		palette.append(space.global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(bone)*part.skin.get_bind_pose(bind))
	for surface: int in range(part.mesh.get_surface_count()):
		var arrays: Array = part.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var influences: int = weights.size()/maxi(vertices.size(),1)
		for index: int in range(vertices.size()):
			var point: Vector3 = Vector3.ZERO
			for influence: int in range(influences):
				var offset: int = index*influences+influence
				if weights[offset] > 0:
					point += (palette[bones[offset]]*vertices[index])*weights[offset]
			points.append(point)
	return points

func _head_vertices(part: MeshInstance3D, skeleton: Skeleton3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	var bind_head: Dictionary = {}
	for bind: int in range(part.skin.get_bind_count()):
		var name: String = str(part.skin.get_bind_name(bind))
		if name.is_empty() and part.skin.get_bind_bone(bind) >= 0:
			name = skeleton.get_bone_name(part.skin.get_bind_bone(bind))
		if name.to_lower().contains("head"):
			bind_head[bind] = true
	var arrays: Array = part.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var transformed: PackedVector3Array = _skin_vertices(part)
	var influences: int = weights.size()/maxi(vertices.size(),1)
	for index: int in range(vertices.size()):
		var head_weight: float = 0
		for influence: int in range(influences):
			var offset: int = index*influences+influence
			if bind_head.has(bones[offset]):
				head_weight += weights[offset]
		if head_weight > 0.75:
			points.append(transformed[index])
	return points

func _bounds(points: PackedVector3Array) -> AABB:
	if points.is_empty():
		return AABB()
	var result: AABB = AABB(points[0],Vector3.ZERO)
	for point: Vector3 in points:
		result = result.expand(point)
	return result

func _vertex_difference(first: PackedVector3Array,second: PackedVector3Array) -> float:
	var difference: float = 0
	for index: int in range(mini(first.size(),second.size())):
		difference = maxf(difference,first[index].distance_to(second[index]))
	return difference

func _finite_pose(points: PackedVector3Array) -> bool:
	if points.size() < 1000:
		return false
	for point: Vector3 in points:
		if not point.is_finite() or point.length() > 6.0:
			return false
	return _bounds(points).size.length() < 5.0

func _all_skins_finite() -> bool:
	for part: Node in visual.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree() or part.skin == null:
			continue
		var points: PackedVector3Array = _skin_vertices(part)
		if points.is_empty():
			return false
		for point: Vector3 in points:
			if not point.is_finite() or point.length() > 6.0:
				return false
	return true

func _bone_position(adapter: Node3D,bone_name: String) -> Vector3:
	var skeleton: Skeleton3D = adapter.get("skeleton") as Skeleton3D
	var bone: int = skeleton.find_bone(bone_name)
	if bone < 0:
		return Vector3(INF,INF,INF)
	return (adapter.global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(bone)).origin

func _portrait_skin_bounds(portrait: Node3D,portrait_model: Node3D) -> void:
	var camera: Camera3D = preview.preview_camera
	var framed: bool = true
	var rect: Rect2 = Rect2(Vector2(1,1),Vector2(318,318))
	for attack: int in range(-1,4):
		for sample: float in ([0.0] if attack < 0 else [0.0,0.20,0.35,0.55,0.80,1.0]):
			portrait.attack_elapsed = -1
			portrait.tick(1.0,0.0)
			if attack >= 0:
				portrait.start_attack(attack,false)
				portrait.tick(portrait.attack_duration*sample,0.0)
			preview.update_framing(0.0)
			var points := PackedVector3Array()
			for part: Node in portrait.find_children("*","MeshInstance3D",true,false):
				if not part.is_visible_in_tree() or part.mesh == null:
					continue
				if part.skin != null:
					points.append_array(_skin_vertices(part,portrait_model))
				else:
					for surface: int in range(part.mesh.get_surface_count()):
						var arrays: Array = part.mesh.surface_get_arrays(surface)
						for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
							points.append(portrait_model.to_local(part.to_global(point)))
			for angle: int in range(0,360,45):
				preview.set_preview_yaw(angle)
				for point: Vector3 in points:
					var world: Vector3 = portrait_model.to_global(point)
					if camera.is_position_behind(world) or not rect.has_point(camera.unproject_position(world)):
						framed = false
						print("SKIN PORTRAIT outside: attack=%d sample=%.2f angle=%d point=%s" % [attack,sample,angle,camera.unproject_position(world)])
						break
	_check(framed,"actual deformed skin and equipped blade fit the portrait across idle, four complete cuts and eight viewing angles")
	portrait.attack_elapsed = -1
	portrait.tick(1.0,0.0)
	camera.size = preview.BODY_CAMERA_SIZE
	preview.set_preview_yaw(0)

func _texture_stats(adapter: Node3D) -> Dictionary:
	var texture_ids: Dictionary = {}
	var largest: int = 0
	var rgba_bytes: int = 0
	var transparent_materials: int = 0
	for material: StandardMaterial3D in adapter.get("materials"):
		if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			transparent_materials += 1
		for key: String in ["albedo_texture","normal_texture","roughness_texture","metallic_texture","ao_texture"]:
			var texture: Texture2D = material.get(key) as Texture2D
			if texture == null or texture_ids.has(texture.get_instance_id()):
				continue
			texture_ids[texture.get_instance_id()] = true
			largest = maxi(largest,maxi(texture.get_width(),texture.get_height()))
			rgba_bytes += texture.get_width()*texture.get_height()*4
	return {"count":texture_ids.size(),"largest_dimension":largest,"transparent_materials":transparent_materials,"rgba_base_level_bytes":rgba_bytes,"rgba_with_mips_upper_bound_bytes":ceili(float(rgba_bytes)*4.0/3.0)}

func _render_stats(node: Node) -> Dictionary:
	var result: Dictionary = {"triangles":0,"surfaces":0,"meshes":0}
	for part: Node in node.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree() or part.mesh == null:
			continue
		result.meshes += 1
		for surface: int in range(part.mesh.get_surface_count()):
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			result.triangles += indices.size()/3 if not indices.is_empty() else vertices.size()/3
			result.surfaces += 1
	return result

func _skin_count(node: Node) -> int:
	var result: int = 0
	for part: Node in node.find_children("*","MeshInstance3D",true,false):
		if part.is_visible_in_tree() and part.skin != null:
			result += 1
	return result

func _mesh_signature(node: Node) -> String:
	var ids: Array[String] = []
	if node is MeshInstance3D and node.mesh != null:
		ids.append(str(node.mesh.get_instance_id()))
	for part: Node in node.find_children("*","MeshInstance3D",true,false):
		if part.mesh != null:
			ids.append(str(part.mesh.get_instance_id()))
	return ",".join(ids)

func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame

func _capture(filename: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	game.hud.toast_timer = 0.0
	game.hud.toast_panel.hide()
	if is_instance_valid(preview) and preview.preview_active:
		preview.preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await _frames(3)
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(capture_dir.path_join(filename+".png")) == OK,"saved actual OpenGL warrior render "+filename)

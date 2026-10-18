extends SceneTree
## Real equipment atlas, animated skin and portrait regressions. No network/save writes.
const ATLAS_NAME: String = "EquipmentAtlas"
const BLADE_ATLAS_NAME: String = "BladeEquipmentAtlas"
const SHARED_PBR_MAPS: Array[String] = ["equipment_color", "equipment_normal", "equipment_orm"]
const EXPECTED_ATLAS: Array[String] = ["equipment_color", "equipment_normal", "equipment_orm", "equipment_emission", "equipment_blade_emission"]
var game: Node3D
var state: Node
var visual: Node3D
var preview: Control
var checks: int = 0
var failures: int = 0
var capture_dir: String = ""
var measured: Array[Dictionary] = []

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
		push_error("Supply --test-isolated; graphics QA must never use a player save or private telemetry.")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	root.size = Vector2i(1280,720)
	state = root.get_node("GameState")
	var save_exists: bool = FileAccess.file_exists(state.SAVE_PATH)
	var save_before: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if save_exists else PackedByteArray()
	_check(not state.save_enabled and not root.get_node("Diagnostics").is_network_enabled(), "graphics QA disables saving and private diagnostic transmissions")
	state.new_game()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.hero.set_physics_process(false)
	for enemy: Node in game.enemies:
		enemy.set_physics_process(false)
	await _frames(4)
	visual = game.hero.visual
	var adapter: Node3D = visual.get("model") as Node3D
	_check(is_instance_valid(adapter) and bool(adapter.get("load_succeeded")), "real HD package loads on the playable actor without a primitive fallback")
	if not is_instance_valid(adapter) or not bool(adapter.get("load_succeeded")):
		game.queue_free()
		await _frames(2)
		quit(1)
		return
	var armors: Dictionary = adapter.get("armor_variants")
	var weapons: Dictionary = adapter.get("weapon_variants")
	var geometry_ids: Dictionary = {}
	var armor_atlas: Material
	var blade_atlas: Material
	for tier: int in range(4):
		visual.set_equipment(tier,tier,0)
		_reset_pose(visual)
		var stats: Dictionary = adapter.call("get_render_stats")
		stats["tier"] = tier
		measured.append(stats)
		print("HD EQUIPMENT BUDGET "+JSON.stringify(stats))
		_check(int(stats.visible_triangles) <= 35000 and int(stats.visible_surfaces) <= 12, "equipment %d stays within 35,000 visible triangles and twelve surfaces" % tier)
		var armor: Node3D = armors.get(tier) as Node3D
		var weapon: Node3D = weapons.get(tier) as Node3D
		_check(is_instance_valid(armor) and is_instance_valid(weapon), "equipment %d has an actual armor mesh and sword variant" % tier)
		if not is_instance_valid(armor) or not is_instance_valid(weapon):
			continue
		geometry_ids[_geometry_signature(armor)] = true
		var atlas_info: Dictionary = _atlas_usage(armor, ATLAS_NAME)
		_check(bool(atlas_info.bound) and int(atlas_info.uv_cells) >= (2 if tier == 0 else 4), "armor %d uses the real shared PBR atlas over distinct UV material regions" % tier)
		var weights: Dictionary = _weight_quality(armor)
		_check(bool(weights.valid) and int(weights.vertices) > 500, "armor %d has normalized finite skin weights with at most four influences" % tier)
		var blade_info: Dictionary = _atlas_usage(weapon, BLADE_ATLAS_NAME)
		_check(bool(blade_info.bound) and int(blade_info.uv_cells) > 0, "sword %d binds its atlas to exported blade UVs" % tier)
		if tier == 3:
			armor_atlas = atlas_info.material
			blade_atlas = blade_info.material
	_check(geometry_ids.size() == 4, "underclothes and all three visual families have distinct geometry rather than color swaps")
	if armor_atlas != null and blade_atlas != null:
		var armor_maps: Dictionary = _material_maps(armor_atlas)
		var blade_maps: Dictionary = _material_maps(blade_atlas)
		var shared: bool = armor_maps.size() == 4 and blade_maps.size() == 4
		for atlas_name: String in SHARED_PBR_MAPS:
			shared = shared and armor_maps.has(atlas_name) and blade_maps.has(atlas_name)
			if armor_maps.has(atlas_name) and blade_maps.has(atlas_name):
				shared = shared and armor_maps[atlas_name] == blade_maps[atlas_name]
		shared = shared and armor_maps.has("equipment_emission") and blade_maps.has("equipment_blade_emission")
		_check(shared, "armor and blade share the same three immutable PBR textures and use separate bounded emission masks")
		_inspect_atlas_pixels(armor_maps,blade_maps)
		var texture_stats: Dictionary = _texture_stats(adapter)
		print("HD TEXTURE BUDGET "+JSON.stringify(texture_stats))
		_check(int(texture_stats.largest_dimension) <= 1024 and int(texture_stats.count) <= 12, "all body and equipment maps stay within twelve shared textures and a maximum dimension of 1024")
		_check(int(texture_stats.transparent_materials) == 0, "body and equipment remain opaque without transparent clothing or hair passes")
	else:
		_check(false, "both actual EquipmentAtlas and BladeEquipmentAtlas are available for shared-map verification")
	game.hud.open_panel("inventory")
	await _frames(5)
	preview = game.hud.character_preview
	_check(is_instance_valid(preview) and preview.preview_active, "actual inventory creates its independent active 3D preview")
	if is_instance_valid(preview):
		await _inspect_preview_controls()
		preview.set_process(false)
		var portrait: Node3D = preview.preview_model
		var portrait_adapter: Node3D = portrait.get("model") as Node3D
		visual.set_equipment(3,3,6)
		portrait.set_equipment(3,3,0)
		var main_blade: BaseMaterial3D = visual.blade_material
		var portrait_blade: BaseMaterial3D = portrait.blade_material
		var before: Color = portrait_blade.albedo_color
		var main_before: Color = main_blade.albedo_color
		main_blade.albedo_color = Color(0.1,0.8,0.2)
		_check(main_blade != portrait_blade and portrait_blade.albedo_color == before, "upgrades and hit tint use private actor/portrait blade materials")
		main_blade.albedo_color = main_before
		var main_body: MeshInstance3D = adapter.find_child("Body",true,false) as MeshInstance3D
		var portrait_body: MeshInstance3D = portrait_adapter.find_child("Body",true,false) as MeshInstance3D
		_check(main_body != null and portrait_body != null and main_body.mesh == portrait_body.mesh and main_body.skin == portrait_body.skin, "portrait and actor share immutable body geometry and skin resources")
		var portrait_atlas: Material = (_atlas_usage((portrait_adapter.get("armor_variants") as Dictionary)[3],ATLAS_NAME)).material
		var shared_portrait_maps: bool = portrait_atlas != null and armor_atlas != null and portrait_atlas != armor_atlas
		if shared_portrait_maps:
			var main_maps: Dictionary = _material_maps(armor_atlas)
			var portrait_maps: Dictionary = _material_maps(portrait_atlas)
			for atlas_name: String in SHARED_PBR_MAPS + ["equipment_emission"]:
				shared_portrait_maps = shared_portrait_maps and main_maps.has(atlas_name) and portrait_maps.has(atlas_name)
				if main_maps.has(atlas_name) and portrait_maps.has(atlas_name):
					shared_portrait_maps = shared_portrait_maps and main_maps[atlas_name] == portrait_maps[atlas_name]
		_check(shared_portrait_maps, "main and portrait keep independent equipment materials while sharing all four atlas maps")
		for tier: int in range(1,4):
			_equip_family(tier)
			await _frames(4)
			preview.set_process(false)
			await _inspect_family(tier,portrait,portrait_adapter)
		for width: int in [1280,1600]:
			root.size = Vector2i(width,720)
			await _frames(4)
			for message: String in ["Kupiono: Zbroja Karmazynowej Straży.","Ulepszono: Pancerz Jadeitowej Bramy +6.","Ulepszono: Pancerz Popielnego Żaru i Ostrze Popielnego Żaru +6."]:
				game.hud.toast(message.repeat(8))
			await _frames(3)
			var long_toast: Rect2 = game.hud.toast_panel.get_global_rect()
			_check(root.get_visible_rect().encloses(long_toast) and absf(long_toast.get_center().x-float(width)*0.5)<1.0 and absf(long_toast.size.x-600.0)<1.0 and long_toast.size.y<=76.0 and game.hud.toast_label.get_global_rect().size.y>=40.0 and game.hud.toast_label.is_visible_in_tree() and not game.hud.toast_label.text.is_empty(), "rapid long purchase and upgrade messages stay visible in a centered bounded toast at width %d" % width)
			game.hud.toast("Ulepszono +1.")
			await _frames(3)
			var short_toast: Rect2 = game.hud.toast_panel.get_global_rect()
			_check(short_toast.size.y<=76.0 and absf(short_toast.size.y-long_toast.size.y)<1.0 and root.get_visible_rect().encloses(short_toast) and game.hud.toast_label.get_global_rect().size.y>=40.0 and game.hud.toast_label.is_visible_in_tree() and not game.hud.toast_label.text.is_empty(), "returning to a short message stays visible without growing or displacing the toast at width %d" % width)
			var inventory_rect: Rect2 = game.hud.modal.get_global_rect()
			var bag_scroll: ScrollContainer = game.hud.modal.find_child("InventoryBagScroll",true,false) as ScrollContainer
			var bag_grid: GridContainer = game.hud.modal.find_child("InventoryBagGrid",true,false) as GridContainer
			_check(root.get_visible_rect().encloses(inventory_rect) and inventory_rect.encloses(preview.get_global_rect()) and bag_scroll != null and bag_grid != null and bag_grid.size.x <= bag_scroll.size.x+1.0, "long family names and seven-item inventory fit landscape %dx720 without horizontal overflow" % width)
			var overlay_ok: bool = preview.find_children("PreviewZoom*","Button",true,false).size() == 2
			for node_name: String in ["PreviewRotateLeft","PreviewReset","PreviewRotateRight","PreviewIdle","PreviewAttack","PreviewRun","PreviewInspect"]:
				overlay_ok = overlay_ok and preview.find_children(node_name,"Button",true,false).size() == 1
			_check(overlay_ok, "equipment rebuilds preserve exactly one complete preview overlay at width %d" % width)
		root.size = Vector2i(1280,720)
		preview.set_process(true)
		game.hud.close_panel()
		await _frames(3)
		var renders: int = preview.render_request_count
		var ticks: int = preview.visual_tick_count
		await create_timer(0.2).timeout
		_check(not preview.preview_active and not preview.is_processing() and preview.render_request_count == renders and preview.visual_tick_count == ticks, "closed HD portrait has zero continued animation ticks and render requests")
	game.hero.reset_to(Vector3(0,0,2.0))
	game.hero.set_physics_process(false)
	game.set_camera_settings(2.5,38,145)
	visual.rotation = Vector3.ZERO
	for tier: int in range(1,4):
		_equip_family(tier)
		await _frames(3)
		_reset_pose(visual)
		await _capture("family-%d-world" % tier)
	visual.set_equipment(3,3,5)
	visual.set_sword_flame(true)
	_reset_pose(visual)
	visual.start_fire_slam()
	visual.tick(0.48,0.0)
	await _capture("family-3-slam-contact")
	visual.cancel_fire_slam()
	visual.set_sword_flame(false)
	_check(FileAccess.file_exists(state.SAVE_PATH) == save_exists and (not save_exists or FileAccess.get_file_as_bytes(state.SAVE_PATH) == save_before), "graphics inspection and equipment changes preserve all player save bytes")
	game.queue_free()
	await _frames(2)
	await create_timer(0.25).timeout
	print("GRAPHICS HD RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _equip_family(tier: int) -> void:
	var families: Array = [[],["iron_sword","leather_armor"],["hunter_sword","guard_armor"],["dawn_sword","dawn_armor"]]
	var ids: Array = families[tier]
	state.gold = maxi(state.gold,100000)
	for id: String in ids:
		var selected: Dictionary = {}
		for item: Dictionary in state.inventory:
			if str(item.id) == id:
				selected = item
				break
		if selected.is_empty():
			state.buy(id)
			selected = state.inventory.back()
		selected.upgrade = 3
		state.equip(int(selected.uid))

func _inspect_atlas_pixels(armor_maps: Dictionary,blade_maps: Dictionary) -> void:
	var records: Dictionary = {}
	for key: String in SHARED_PBR_MAPS + ["equipment_emission","equipment_blade_emission"]:
		var maps: Dictionary = blade_maps if key == "equipment_blade_emission" else armor_maps
		if not maps.has(key):
			continue
		var texture: Texture2D = maps[key]
		var source: String = texture.resource_path
		if not FileAccess.file_exists(source):
			continue
		var pixels := Image.new()
		if pixels.load_png_from_buffer(FileAccess.get_file_as_bytes(source)) != OK:
			continue
		var low: Vector3 = Vector3.ONE
		var high: Vector3 = Vector3.ZERO
		var luminous: int = 0
		var count: int = 0
		var step: int = maxi(1,int(float(pixels.get_width())/64.0))
		for y: int in range(0,pixels.get_height(),step):
			for x: int in range(0,pixels.get_width(),step):
				var color: Color = pixels.get_pixel(x,y)
				low.x = minf(low.x,color.r)
				low.y = minf(low.y,color.g)
				low.z = minf(low.z,color.b)
				high.x = maxf(high.x,color.r)
				high.y = maxf(high.y,color.g)
				high.z = maxf(high.z,color.b)
				if maxf(color.r,maxf(color.g,color.b)) > 0.01:
					luminous += 1
				count += 1
		records[key] = {"range":high-low,"nonblack_fraction":float(luminous)/maxi(1,count)}
	print("HD ACTUAL ATLAS PIXELS "+str(records))
	_check(records.has("equipment_color") and records.equipment_color.range.length() > 0.3, "actual shared color PNG contains distinct material colors rather than a uniform placeholder")
	_check(records.has("equipment_normal") and records.equipment_normal.range.x+records.equipment_normal.range.y > 0.01, "actual normal PNG contains tangent-space surface detail")
	_check(records.has("equipment_orm") and records.equipment_orm.range.y > 0.1 and records.equipment_orm.range.z > 0.5, "actual ORM PNG varies both roughness and metallic channels across cloth and steel")
	_check(records.has("equipment_blade_emission") and records.equipment_blade_emission.nonblack_fraction > 0.001 and records.equipment_blade_emission.nonblack_fraction < 0.20, "actual blade glow mask contains narrow sparse details rather than lighting the entire blade")

func _inspect_preview_controls() -> void:
	var hero_position: Vector3 = game.hero.position
	var serial: int = game._attack_serial
	var yaw: float = preview.preview_yaw
	var camera_before: float = preview.preview_camera.size
	await _click(preview,"PreviewZoomIn")
	await create_timer(0.15).timeout
	var zoomed: bool = is_equal_approx(preview.preview_zoom,1.2) and preview.preview_camera.size < camera_before-0.05
	await _click(preview,"PreviewZoomOut")
	_check(zoomed and is_equal_approx(preview.preview_zoom,1.0) and is_equal_approx(preview.preview_yaw,yaw) and not preview.mouse_dragging and preview.touch_id == -1, "actual zoom overlay buttons adjust detail size without starting model rotation")
	await _click(game.hud.modal,"PreviewInspect")
	await create_timer(0.15).timeout
	_check(preview.animation_mode == "inspect" and preview.preview_model.presentation_active and not game.hero.visual.presentation_active, "actual POZA button runs the independent presentation stance only in the portrait")
	await _click(preview,"PreviewZoomIn")
	await _click(game.hud.modal,"PreviewReset")
	_check(is_equal_approx(preview.preview_zoom,1.0) and is_zero_approx(preview.preview_yaw), "actual RESET button restores the portrait's default zoom and front view")
	await _click(game.hud.modal,"PreviewIdle")
	_check(not preview.preview_model.presentation_active and game._attack_serial == serial and game.hero.position.distance_to(hero_position)<0.01 and not game.hud.attack_held, "portrait inspection and zoom controls never move or attack with the playable warrior")

func _click(parent: Node,node_name: String) -> void:
	var button: Button = parent.find_child(node_name,true,false) as Button
	_check(is_instance_valid(button) and button.is_visible_in_tree(), "live inventory exposes "+node_name)
	if not is_instance_valid(button):
		return
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	for pressed: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _frames(3)

func _inspect_family(tier: int, portrait: Node3D, adapter: Node3D) -> void:
	var valid: bool = true
	var framed: bool = true
	var clipped_poses: Dictionary = {}
	var worst_floor: float = 0.0
	var sampled: int = 0
	var viewport_size: Vector2i = preview.preview_viewport.size
	var rect: Rect2 = Rect2(Vector2(1,1),Vector2(viewport_size)-Vector2(2,2))
	for pose: int in range(-2,6):
		var samples: Array[float] = [0.0,0.18,0.36,0.52,0.74,0.94]
		if pose == -2:
			samples = [0.0,0.25,0.5,0.75]
		elif pose == -1:
			samples = [0.0]
		for fraction: float in samples:
			_reset_pose(portrait)
			preview.preview_camera.size = preview.BODY_CAMERA_SIZE
			if pose == -2:
				portrait.tick(0.4+fraction,1.0)
			elif pose >= 0 and pose < 4:
				portrait.start_attack(pose,false)
				portrait.tick(portrait.attack_duration*fraction,0.0)
			elif pose == 4:
				portrait.start_fire_slam()
				portrait.tick(portrait.FIRE_SLAM_DURATION*fraction,0.0)
			elif pose == 5 and portrait.has_method("set_presentation_pose"):
				portrait.set_presentation_pose(true)
				portrait.tick(2.0*fraction,0.0)
			preview.update_framing(0.0)
			var points: PackedVector3Array = _visible_vertices(portrait,adapter)
			for point: Vector3 in points:
				valid = valid and point.is_finite() and point.length() < 6.0
			if pose == -1:
				for point: Vector3 in points:
					worst_floor = minf(worst_floor,point.y)
			for angle: int in range(0,360,45):
				preview.set_preview_yaw(angle)
				for point: Vector3 in points:
					var world: Vector3 = adapter.to_global(point)
					if preview.preview_camera.is_position_behind(world) or not rect.has_point(preview.preview_camera.unproject_position(world)):
						if not clipped_poses.has(pose):
							print("HD PORTRAIT CLIP: family=%d pose=%d fraction=%.2f yaw=%d projected=%s" % [tier,pose,fraction,angle,preview.preview_camera.unproject_position(world)])
						clipped_poses[pose] = true
						framed = false
						break
			sampled += 1
	_check(valid and sampled >= 35, "family %d real skinned vertices remain finite across idle, run, presentation, all four cuts and the full two-handed slam" % tier)
	_check(framed, "family %d actual deformed body, armor and blade stay in the portrait through every sampled pose and a full rotation" % tier)
	_check(worst_floor >= -0.04, "family %d idle equipment remains above the portrait floor" % tier)
	_reset_pose(portrait)
	portrait.start_attack(3,false)
	portrait.tick(0.25,0.0)
	var grip_error: float = portrait.left_wrist.global_position.distance_to(portrait.sword.to_global(Vector3(0,-0.14,0)))
	print("HD TWO-HANDED FINISHER family=%d support-hand error=%.5f m" % [tier,grip_error])
	_check(grip_error < 0.035, "family %d fourth power cut places the actual support hand on its sword hilt at contact" % tier)
	_reset_pose(portrait)
	preview.preview_camera.size = preview.BODY_CAMERA_SIZE
	preview.set_preview_yaw(0)
	preview.update_framing(0.0)
	_check(_clear_of_overlay(_visible_vertices(portrait,adapter),adapter), "family %d default full equipment remains visible above the portrait footer and outside overlay buttons" % tier)
	await _capture("family-%d-inventory-front" % tier)
	preview.set_preview_yaw(90)
	await _capture("family-%d-inventory-side" % tier)
	preview.set_preview_yaw(180)
	await _capture("family-%d-inventory-rear" % tier)
	preview.zoom_preview(0.6)
	preview.update_framing(1.0)
	preview.set_preview_yaw(-24)
	await _capture("family-%d-inventory-detail" % tier)
	preview.reset_view()

func _clear_of_overlay(points: PackedVector3Array,reference: Node3D) -> bool:
	var image_control: TextureRect = preview.find_child("PreviewPortrait",true,false) as TextureRect
	if image_control == null:
		return false
	var region: Rect2 = image_control.get_global_rect()
	var side: float = minf(region.size.x,region.size.y)
	var origin: Vector2 = region.get_center()-Vector2.ONE*side*0.5
	var view_size: Vector2 = Vector2(preview.preview_viewport.size)
	var buttons: Array[Node] = preview.find_children("Preview*","Button",true,false)
	for point: Vector3 in points:
		var pixel: Vector2 = preview.preview_camera.unproject_position(reference.to_global(point))
		var screen: Vector2 = origin+pixel/view_size*side
		for button: Button in buttons:
			if button.is_visible_in_tree() and button.get_global_rect().has_point(screen):
				print("HD PORTRAIT OVERLAY: button=",button.name," screen=",screen," modelpoint=",point)
				return false
	return true

func _reset_pose(actor: Node3D) -> void:
	actor.cancel_fire_slam()
	if actor.has_method("set_presentation_pose"):
		actor.set_presentation_pose(false)
	actor.attack_elapsed = -1.0
	actor.locomotion_blend = 0.0
	actor.tick(1.0,0.0)

func _meshes(node: Node) -> Array[Node]:
	var result: Array[Node] = node.find_children("*","MeshInstance3D",true,false)
	if node is MeshInstance3D:
		result.push_front(node)
	return result

func _atlas_usage(node: Node, prefix: String) -> Dictionary:
	var found: bool = false
	var cells: Dictionary = {}
	var material: Material
	for part: MeshInstance3D in _meshes(node):
		if part.mesh == null:
			continue
		for surface: int in range(part.mesh.get_surface_count()):
			var active: Material = part.get_active_material(surface)
			if active == null or not active.resource_name.begins_with(prefix):
				continue
			material = active
			var maps: Dictionary = _material_maps(active)
			var emission_key: String = "equipment_blade_emission" if prefix == BLADE_ATLAS_NAME else "equipment_emission"
			found = maps.has("equipment_color") and maps.has("equipment_normal") and maps.has("equipment_orm") and maps.has(emission_key)
			if active is BaseMaterial3D:
				found = found and active.normal_enabled and active.ao_enabled and active.metallic > 0.0
			if active is StandardMaterial3D:
				found = found and active.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN and active.metallic_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_BLUE and active.ao_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_RED
				found = found and active.roughness_texture == active.metallic_texture and active.roughness_texture == active.ao_texture
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			for point: Vector2 in uv:
				if not point.is_finite() or point.x < 0.0 or point.x > 1.0 or point.y < 0.0 or point.y > 1.0:
					found = false
				cells[Vector2i(mini(3,int(point.x*4.0)),mini(3,int(point.y*4.0)))] = true
	return {"bound":found,"uv_cells":cells.size(),"material":material}

func _material_maps(material: Material) -> Dictionary:
	var result: Dictionary = {}
	for property: Dictionary in material.get_property_list():
		var property_name: String = str(property.name)
		if not property_name.ends_with("_texture") or int(property.type) != TYPE_OBJECT:
			continue
		var texture: Texture2D = material.get(property_name) as Texture2D
		if texture == null:
			continue
		var path: String = texture.resource_path.to_lower()
		for atlas_name: String in EXPECTED_ATLAS:
			if path.contains(atlas_name):
				result[atlas_name] = texture
	return result

func _texture_stats(adapter: Node3D) -> Dictionary:
	var textures: Dictionary = {}
	var largest: int = 0
	var bytes: int = 0
	var transparent: int = 0
	for material: Material in adapter.get("materials"):
		if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			transparent += 1
		for property: Dictionary in material.get_property_list():
			if not str(property.name).ends_with("_texture") or int(property.type) != TYPE_OBJECT:
				continue
			var texture: Texture2D = material.get(property.name) as Texture2D
			if texture == null or textures.has(texture.get_instance_id()):
				continue
			textures[texture.get_instance_id()] = true
			largest = maxi(largest,maxi(texture.get_width(),texture.get_height()))
			bytes += texture.get_width()*texture.get_height()*4
	return {"count":textures.size(),"largest_dimension":largest,"transparent_materials":transparent,"rgba8_base_level_upper_bound_bytes":bytes,"rgba8_with_mips_upper_bound_bytes":ceili(float(bytes)*4.0/3.0)}

func _weight_quality(node: Node) -> Dictionary:
	var valid: bool = true
	var count: int = 0
	for part: MeshInstance3D in _meshes(node):
		if part.mesh == null or part.skin == null:
			valid = false
			continue
		for surface: int in range(part.mesh.get_surface_count()):
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var influences: int = int(float(weights.size())/maxi(vertices.size(),1))
			valid = valid and influences >= 1 and influences <= 4 and bones.size() == weights.size()
			for index: int in range(vertices.size()):
				var total: float = 0.0
				for influence: int in range(influences):
					var offset: int = index*influences+influence
					valid = valid and is_finite(weights[offset]) and weights[offset] >= 0.0 and bones[offset] >= 0 and bones[offset] < part.skin.get_bind_count()
					total += weights[offset]
				valid = valid and absf(total-1.0) < 0.015
			count += vertices.size()
	return {"valid":valid,"vertices":count}

func _geometry_signature(node: Node) -> String:
	var ids: Array[String] = []
	for part: MeshInstance3D in _meshes(node):
		if part.mesh != null:
			ids.append(str(part.mesh.get_instance_id()))
	return ",".join(ids)

func _visible_vertices(actor: Node3D, reference: Node3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	for part: MeshInstance3D in _meshes(actor):
		if not part.is_visible_in_tree() or part.mesh == null or part.name in ["Slash", "SpinRing"]:
			continue
		if part.skin != null:
			points.append_array(_skin_vertices(part,reference))
		elif part.is_ancestor_of(actor.get("sword")) or actor.get("model").is_ancestor_of(part) or actor.get("sword").is_ancestor_of(part):
			for surface: int in range(part.mesh.get_surface_count()):
				var arrays: Array = part.mesh.surface_get_arrays(surface)
				for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
					points.append(reference.to_local(part.to_global(point)))
	return points

func _skin_vertices(part: MeshInstance3D, reference: Node3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	var skeleton: Skeleton3D = part.get_node_or_null(part.skeleton) as Skeleton3D
	if skeleton == null or part.skin == null:
		return result
	skeleton.force_update_all_bone_transforms()
	var palette: Array[Transform3D] = []
	for bind: int in range(part.skin.get_bind_count()):
		var bone: int = part.skin.get_bind_bone(bind)
		if bone < 0:
			bone = skeleton.find_bone(part.skin.get_bind_name(bind))
		palette.append(reference.global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(bone)*part.skin.get_bind_pose(bind))
	for surface: int in range(part.mesh.get_surface_count()):
		var arrays: Array = part.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var influences: int = int(float(weights.size())/maxi(vertices.size(),1))
		for index: int in range(vertices.size()):
			var point: Vector3 = Vector3.ZERO
			for influence: int in range(influences):
				var offset: int = index*influences+influence
				if weights[offset] > 0.0:
					point += palette[bones[offset]]*vertices[index]*weights[offset]
			result.append(point)
	return result

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
	_check(root.get_texture().get_image().save_png(capture_dir.path_join(filename+".png")) == OK, "saved actual Godot HD render "+filename)

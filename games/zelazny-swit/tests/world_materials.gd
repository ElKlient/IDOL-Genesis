extends SceneTree
## Real village geometry/material budget; never opens a player save or network.
const WorldScript = preload("res://scripts/world.gd")
# Quantized transforms/shapes of the published 0.1.8 collision geometry.
const WALK_COLLISION_SIGNATURE: String = "92421f68d8e5795ab1ea39260d562c6c84f4a8cefd3cabd2f8702dc7ea2f2883"
const ROOF_COLLISION_SIGNATURE: String = "1b104a862c5fdfa229295fc0cd746a90cd8961b3ad03eaaeb6634be92c166fd1"
var checks: int = 0
var failures: int = 0

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
		push_error("Supply --test-isolated for disposable village material QA.")
		quit(2)
		return
	_check(not root.get_node("GameState").save_enabled and not root.get_node("Diagnostics").is_network_enabled(),"world QA disables player saving and diagnostic networking")
	var world: Node3D = WorldScript.new()
	root.add_child(world)
	await process_frame
	_check(world.spawn_position == Vector3(0,0,5) and world.npc_positions == {"merchant":Vector3(-6,0,0),"blacksmith":Vector3(6,0,0)},"village entrance and both vendors stay at their published positions")
	var enemy_positions: Array[Vector3] = [Vector3(-1.6,0,-20.2),Vector3(4.8,0,-23),Vector3(-6,0,-25),Vector3(8,0,-30),Vector3(-4,0,-33),Vector3(2.6,0,-37),Vector3(0,0,-41)]
	var spawns_unchanged: bool = world.enemy_spawns.size() == enemy_positions.size()
	for i: int in range(mini(world.enemy_spawns.size(),enemy_positions.size())):
		spawns_unchanged = spawns_unchanged and world.enemy_spawns[i].position == enemy_positions[i]
	_check(spawns_unchanged,"all seven combat clearings preserve their published spawn positions")
	_check(world._collision.get_child_count() == 136 and _collision_signature(world._collision) == WALK_COLLISION_SIGNATURE,"all 136 existing walking collision shapes and transforms match the published village")
	_check(world._camera_collision.get_child_count() == 11 and _collision_signature(world._camera_collision) == ROOF_COLLISION_SIGNATURE and world._camera_collision.collision_layer == 4,"all eleven camera-only roof collision prisms are unchanged")
	var maps: Dictionary = world._world_textures
	_check(maps.size() == 16,"eight shared texture families have one cached albedo and normal resource each")
	var texture_bytes: int = 0
	var correct_maps: bool = true
	for key: String in maps:
		var texture: Texture2D = maps[key]
		var image_data: Image = texture.get_image()
		var expected: int = 256 if key.ends_with("_normal") else 512
		correct_maps = correct_maps and image_data != null and texture.get_width() == expected and texture.get_height() == expected and image_data.has_mipmaps()
		texture_bytes += image_data.get_data().size()
	_check(correct_maps,"every world albedo is 512 px and normal is 256 px, with actual mipmaps")
	_check(texture_bytes <= 16*1024*1024,"shared world material images stay below sixteen MiB including mipmaps")
	_check(world._materials.wood.albedo_texture == world._materials.wood_dark.albedo_texture and world._materials.wood.normal_texture == world._materials.wood_light.normal_texture and world._materials.roof_blue.albedo_texture == world._materials.roof_rust.albedo_texture,"tinted timber and roof variants reuse immutable texture resources")
	var triangles: int = 0
	var surfaces: int = 0
	var channels_valid: bool = true
	var tangent_space_valid: bool = true
	for visual: Node in world.find_children("*","MeshInstance3D",true,false):
		if visual.mesh == null:
			continue
		for surface: int in range(visual.mesh.get_surface_count()):
			surfaces += 1
			var arrays: Array = visual.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			triangles += int(indices.size()/3) if not indices.is_empty() else int(vertices.size()/3)
			if not visual.name.begins_with("Scenery_"):
				continue
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
			var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
			var has_channels: bool = uvs.size() == vertices.size() and colors.size() == vertices.size() and normals.size() == vertices.size() and tangents.size() == vertices.size()*4
			channels_valid = channels_valid and has_channels
			if not has_channels:
				continue
			for i: int in range(vertices.size()):
				channels_valid = channels_valid and vertices[i].is_finite() and uvs[i].is_finite() and normals[i].is_finite()
				var tangent: Vector3 = Vector3(tangents[i*4],tangents[i*4+1],tangents[i*4+2])
				tangent_space_valid = tangent_space_valid and tangent.is_finite() and tangent.length_squared()>.95 and normals[i].length_squared()>.95 and absf(tangent.dot(normals[i]))<.025 and absf(tangents[i*4+3])>.95
	for visual: Node in world.find_children("*","MultiMeshInstance3D",true,false):
		var instances: MultiMesh = visual.multimesh
		if instances == null or instances.mesh == null:
			continue
		for surface: int in range(instances.mesh.get_surface_count()):
			surfaces += 1
			var arrays: Array = instances.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			triangles += (int(indices.size()/3) if not indices.is_empty() else int(vertices.size()/3))*instances.instance_count
	var embers: MultiMeshInstance3D = world.get_node_or_null("ForgeEmbers")
	_check(is_instance_valid(embers) and embers.multimesh.instance_count == 7,"all seven forge embers use one shared instanced mesh")
	_check(channels_valid,"every merged scenery mesh has finite vertices, UVs, colors and complete normal-map tangent channels")
	_check(tangent_space_valid,"actual tangent frames stay normalized and orthogonal on roofs, rocks, timber and curved foliage")
	_check(_planar_tangents_match_uv(world),"actual planar ground, wall and curved-roof tangent frames follow UV derivatives and Godot OpenGL handedness")
	var mountains: MeshInstance3D = world.get_node_or_null("Scenery_mountain")
	var mountain_triangles: int = 0
	if is_instance_valid(mountains) and mountains.mesh != null and mountains.mesh.get_surface_count() == 1:
		var mountain_data: Array = mountains.mesh.surface_get_arrays(0)
		mountain_triangles = int((mountain_data[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3)
	_check(mountain_triangles >= 1800 and mountain_triangles <= 2300 and world._materials.mountain.albedo_texture == null,"all eighteen asymmetric distant ridges are present in one bounded untextured surface")
	_check(triangles <= 60000 and surfaces <= 66,"the complete village stays within sixty thousand triangles and sixty-six material surfaces")
	var ground_shadows: bool = true
	for key: String in ["grass","grass_light","grass_dark","earth","path","path_edge","paving"]:
		var visual: MeshInstance3D = world.get_node_or_null("Scenery_"+key)
		ground_shadows = ground_shadows and is_instance_valid(visual) and visual.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and not world._materials[key].disable_receive_shadows
	_check(ground_shadows,"flat ground receives character shadows without casting its own shadow-map acne")
	var atmosphere: WorldEnvironment = world.get_node("GoldenValleyAtmosphere")
	var env: Environment = atmosphere.environment
	_check(env.sky != null and env.sky.radiance_size == Sky.RADIANCE_SIZE_128 and env.reflected_light_source == Environment.REFLECTION_SOURCE_SKY,"metal equipment receives a bounded 128 px static sky reflection environment")
	var material_ids: Array[int] = []
	for value: Material in world._materials.values():
		material_ids.append(value.get_instance_id())
	var texture_ids: Array[int] = []
	for texture: Texture2D in world._world_textures.values():
		texture_ids.append(texture.get_instance_id())
	world.set_low_quality(true)
	world.set_low_quality(false)
	var same_materials: bool = true
	var material_index: int = 0
	for value: Material in world._materials.values():
		same_materials = same_materials and value.get_instance_id() == material_ids[material_index]
		material_index += 1
	var same_textures: bool = world._world_textures.size() == texture_ids.size()
	var texture_index: int = 0
	for texture: Texture2D in world._world_textures.values():
		same_textures = same_textures and texture.get_instance_id() == texture_ids[texture_index]
		texture_index += 1
	_check(same_materials and same_textures,"quality changes retain the shared material and texture cache")
	var camera: Camera3D
	if DisplayServer.get_name() != "headless":
		camera = Camera3D.new()
		root.add_child(camera)
		camera.current = true
		camera.position = Vector3(-19,12,22)
		camera.look_at(Vector3(0,1.4,-4))
		await create_timer(.4).timeout
		await RenderingServer.frame_post_draw
		_check(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)>0,"real OpenGL renders the village material and water shader surfaces")
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--capture-dir="):
				var directory: String = arg.trim_prefix("--capture-dir=")
				DirAccess.make_dir_recursive_absolute(directory)
				root.get_texture().get_image().save_png(directory.path_join("world-materials-village.png"))
	print("WORLD BUDGET: triangles=%d surfaces=%d shared_texture_bytes=%d" % [triangles,surfaces,texture_bytes])
	print("WORLD MATERIAL QA: %d/%d passed" % [checks-failures,checks])
	world.queue_free()
	if is_instance_valid(camera):
		camera.queue_free()
	await create_timer(.3).timeout
	quit(0 if failures == 0 else 1)

func _q(v: Vector3) -> Array[int]:
	return [roundi(v.x*10000.0),roundi(v.y*10000.0),roundi(v.z*10000.0)]

func _collision_signature(body: StaticBody3D) -> String:
	var records: Array[String] = []
	for node: CollisionShape3D in body.get_children():
		var t: Transform3D = node.transform
		var row: Array = [node.shape.get_class(),_q(t.origin),_q(t.basis.x),_q(t.basis.y),_q(t.basis.z)]
		if node.shape is BoxShape3D:
			row.append(_q(node.shape.size))
		elif node.shape is CylinderShape3D:
			row.append([roundi(node.shape.radius*10000),roundi(node.shape.height*10000)])
		elif node.shape is SphereShape3D:
			row.append(roundi(node.shape.radius*10000))
		elif node.shape is ConvexPolygonShape3D:
			var points: Array[String] = []
			for p: Vector3 in node.shape.points:
				points.append(JSON.stringify(_q(p)))
			points.sort()
			row.append(points)
		records.append(JSON.stringify(row))
	records.sort()
	return JSON.stringify(records).sha256_text()

func _planar_tangents_match_uv(world: Node3D) -> bool:
	# Calibrate against Godot's own primitive: image +V on an upward PlaneMesh
	# travels +Z, while its OpenGL normal-map green binormal points toward -Z.
	var plane: PlaneMesh = PlaneMesh.new()
	var reference: Array = plane.surface_get_arrays(0)
	var normal: Vector3 = reference[Mesh.ARRAY_NORMAL][0]
	var values: PackedFloat32Array = reference[Mesh.ARRAY_TANGENT]
	var reference_t: Vector3 = Vector3(values[0],values[1],values[2])
	var reference_b: Vector3 = normal.cross(reference_t)*values[3]
	var calibrated: bool = reference_t.dot(Vector3.RIGHT)>.999 and reference_b.dot(Vector3.BACK)<-.999
	var checked: int = 0
	var reversed_binormals: int = 0
	var min_alignment: float = 1.0
	for visual: Node in world.get_children():
		if not visual is MeshInstance3D or not str(visual.name).begins_with("Scenery_") or visual.name == "Scenery_mountain":
			continue
		if visual.mesh == null or visual.mesh.get_surface_count() != 1:
			return false
		var arrays: Array = visual.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if uvs.size() != vertices.size() or normals.size() != vertices.size() or tangents.size() != vertices.size()*4:
			return false
		for index: int in range(0,indices.size(),3):
			var i0: int = indices[index]
			var i1: int = indices[index+1]
			var i2: int = indices[index+2]
			# Curved primitive sides retain their authored, interpolated frames.
			if normals[i0].distance_squared_to(normals[i1])>.00000001 or normals[i0].distance_squared_to(normals[i2])>.00000001:
				continue
			var e1: Vector3 = vertices[i1]-vertices[i0]
			var e2: Vector3 = vertices[i2]-vertices[i0]
			if e1.cross(e2).length_squared()<.0000000001:
				continue
			var t1: Vector2 = uvs[i1]-uvs[i0]
			var t2: Vector2 = uvs[i2]-uvs[i0]
			var determinant: float = t1.x*t2.y-t1.y*t2.x
			if absf(determinant)<.00000001:
				continue
			var du: Vector3 = (e1*t2.y-e2*t1.y)/determinant
			var dv: Vector3 = (e2*t1.x-e1*t2.x)/determinant
			for vertex: int in [i0,i1,i2]:
				var tangent: Vector3 = Vector3(tangents[vertex*4],tangents[vertex*4+1],tangents[vertex*4+2])
				var binormal: Vector3 = normals[vertex].cross(tangent)*tangents[vertex*4+3]
				min_alignment = minf(min_alignment,tangent.normalized().dot(du.normalized()))
				if binormal.dot(dv)>=0.0:
					reversed_binormals += 1
			checked += 1
	print("WORLD PLANAR UV: triangles=%d reversed_corner_binormals=%d min_tangent_alignment=%.8f" % [checked,reversed_binormals,min_alignment])
	return calibrated and checked>5000 and reversed_binormals == 0 and min_alignment>.9995

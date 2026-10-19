class_name VillageWorld
extends Node3D
## Original frontier village. Shared tileable material maps, vertex tint and
## merged scenery keep detail bounded on the Android Compatibility renderer.

var spawn_position: Vector3 = Vector3(0, 0, 5)
var npc_positions: Dictionary = {
	"merchant": Vector3(-6, 0, 0),
	"blacksmith": Vector3(6, 0, 0)
}
var enemy_spawns: Array[Dictionary] = [
	{"kind": 0, "position": Vector3(-1.6, 0, -20.2)},
	{"kind": 0, "position": Vector3(4.8, 0, -23)},
	{"kind": 0, "position": Vector3(-6, 0, -25)},
	{"kind": 1, "position": Vector3(8, 0, -30)},
	{"kind": 1, "position": Vector3(-4, 0, -33)},
	{"kind": 1, "position": Vector3(2.6, 0, -37)},
	{"kind": 2, "position": Vector3(0, 0, -41)}
]

var _materials: Dictionary = {}
var _batches: Dictionary = {}
var _collision: StaticBody3D
var _camera_collision: StaticBody3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _fire: Array[MeshInstance3D] = []
var _fire_light: OmniLight3D
var _embers: MultiMeshInstance3D
var _banners: Array[Node3D] = []
var _world_textures: Dictionary = {}
var _detail_textures: Dictionary = {}
var _clock: float = 0.0
var _terrain_material: ShaderMaterial

func _ready() -> void:
	_rng.seed = 51472026
	_palette()
	_collision = StaticBody3D.new()
	_collision.name = "SceneryCollision"
	add_child(_collision)
	# Separate camera-only geometry leaves the existing walking collision intact.
	_camera_collision = StaticBody3D.new()
	_camera_collision.name = "CameraRoofCollision"
	_camera_collision.collision_layer = 4
	_camera_collision.collision_mask = 0
	add_child(_camera_collision)
	_lighting()
	_landscape()
	_village()
	_forest()
	_gardens()
	_ground_cover()
	_terrain_surface()
	_flush_batches()
	_create_npc("Mira • Handel", npc_positions["merchant"], false)
	_create_npc("Born • Kowal", npc_positions["blacksmith"], true)
	_ambient_details()

func _palette() -> void:
	_material("grass", "667748")
	_material("grass_light", "7c8b55")
	_material("grass_dark", "5e7044")
	_material("earth", "ada087")
	_material("path", "bcad91")
	_material("path_edge", "b3a68c")
	_material("stone", "858782")
	_material("stone_light", "acafa1")
	_material("stone_dark", "5b6460")
	_material("plaster", "d8cebb")
	_material("plaster_light", "e4dfcd")
	_material("plaster_warm", "c8b394")
	_material("wood", "816047")
	_material("wood_dark", "514534")
	_material("wood_light", "ae8f63")
	_material("roof_blue", "45646b")
	_material("roof_blue_dark", "344e56")
	_material("roof_rust", "9d5741")
	_material("roof_rust_dark", "784234")
	_material("roof_straw", "aa884c")
	_material("cloth_teal", "388e8b")
	_material("cloth_cream", "eddbad")
	_material("cloth_red", "b0553c")
	_material("iron", "4d5658")
	_material("gold", "d8af4f")
	_material("pine", "355951")
	_material("pine_light", "4c7160")
	_material("leaf", "8b9450")
	_material("leaf_gold", "c2a34c")
	_material("leaf_orange", "bc7540")
	_material("skin", "d9ad83")
	_material("leather", "725439")
	_material("white", "f0dfbc")
	_material("water", "478e98")
	_material("water_light", "81bbb6")
	_material("ember", "d54e28", 1.0)
	_material("flame", "ffb74b", 1.7)
	_material("window", "ffc979", 0.65)
	_material("flower", "e8cf9c")
	_material("flower_blue", "839cbd")
	_material("mountain", "819198")
	_material("paving", "b4b2a4")
	_water_material()
	var needles: ShaderMaterial = ShaderMaterial.new()
	needles.shader = preload("res://assets/world/pine.gdshader")
	needles.set_shader_parameter("needles",_detail_texture("pine_spray"))
	_materials["pine_needles"] = needles

func _material(key: String, hex: String, emission: float = 0.0) -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color.html(hex)
	mat.roughness = 0.92
	mat.vertex_color_use_as_albedo = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var family: String = _material_family(key)
	if not family.is_empty():
		mat.albedo_texture = _world_texture(family+"_albedo", false)
		mat.normal_enabled = true
		mat.normal_texture = _world_texture(family+"_normal", true)
		mat.normal_scale = 0.44 if family != "roof" else 0.66
	if key in ["pine","pine_light","leaf","leaf_gold","leaf_orange"]:
		# Needle masses retain directional shading and cast on the ground while
		# avoiding coarse mobile shadow-map acne on their own thin layered tips.
		mat.disable_receive_shadows = true
	if key == "mountain":
		# Distant matte ridges use baked directional vertex tone and scene fog,
		# avoiding shiny rock, shadow work or a repeated close-range texture.
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if key == "iron":
		mat.metallic = 0.72
		mat.roughness = 0.48
	elif key == "gold":
		mat.metallic = 0.78
		mat.roughness = 0.37
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = Color.html(hex)
		mat.emission_energy_multiplier = emission
	_materials[key] = mat

# Eight immutable texture pairs shared by every material using the same family.
# Normals are 256 px; albedo is 512 px. All have mipmaps to avoid crawling detail.
func _world_texture(file: String, normal_map: bool) -> Texture2D:
	if _world_textures.has(file):
		return _world_textures[file]
	var source: Texture2D = load("res://assets/world/"+file+".png") as Texture2D
	if source == null:
		push_error("Missing imported world material: "+file)
		return null
	var image_data: Image = source.get_image()
	if image_data.is_compressed():
		image_data.decompress()
	if normal_map:
		image_data.resize(256,256,Image.INTERPOLATE_LANCZOS)
	if not image_data.has_mipmaps():
		image_data.generate_mipmaps(normal_map)
	var texture: ImageTexture = ImageTexture.create_from_image(image_data)
	_world_textures[file] = texture
	return texture

func _material_family(key: String) -> String:
	if key in ["earth", "path", "path_edge"]:
		return "earth"
	if key in ["grass", "grass_light", "grass_dark","pine","pine_light","leaf","leaf_gold","leaf_orange"]:
		return "grass"
	if key.begins_with("stone"):
		return "stone"
	if key == "paving":
		return "paving"
	if key.begins_with("plaster"):
		return "plaster"
	if key.begins_with("wood"):
		return "wood"
	if key.begins_with("roof"):
		return "roof"
	if key.begins_with("cloth"):
		return "cloth"
	return ""

func _detail_texture(file: String) -> Texture2D:
	if _detail_textures.has(file):
		return _detail_textures[file]
	var source: Texture2D = load("res://assets/world/"+file+".png") as Texture2D
	var pixels: Image = source.get_image()
	if pixels.is_compressed():
		pixels.decompress()
	if not pixels.has_mipmaps():
		pixels.generate_mipmaps()
	var result: ImageTexture = ImageTexture.create_from_image(pixels)
	_detail_textures[file] = result
	return result

func _water_material() -> void:
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_back, specular_schlick_ggx;
varying vec3 world_point;
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec2 p = world_point.xz;
    float swell = sin(p.x*1.5 + p.y*.65 + TIME*.32)*.5 + sin(p.y*2.2-p.x*.38-TIME*.24)*.5;
    float ripple = sin(p.x*3.4+p.y*.72+sin(p.y*2.1-p.x*.6+TIME*.21)*.65+TIME*.38);
    float ribbon = pow(max(0.0,ripple), 24.0) * (.55+sin(p.x*.7-p.y*.9-TIME*.11)*.35);
    ALBEDO = mix(vec3(.10,.28,.29),vec3(.16,.37,.36),swell*.5+.5) + ribbon*vec3(.055,.075,.068);
    ROUGHNESS = .32;
    METALLIC = .08;
    SPECULAR = .5;
}
"""
	var water: ShaderMaterial = ShaderMaterial.new()
	water.shader = shader
	_materials["water"] = water

func _lighting() -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.name = "GoldenValleyAtmosphere"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("6f91a6")
	sky_mat.sky_horizon_color = Color("d6d8c9")
	sky_mat.ground_bottom_color = Color("626f65")
	sky_mat.ground_horizon_color = Color("c3c9b6")
	sky.sky_material = sky_mat
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bbcdd9")
	env.ambient_light_energy = 0.40
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color("b7c8bf")
	env.fog_light_energy = 0.6
	env.fog_density = 0.0042
	environment.environment = env
	add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "WarmAfternoonSun"
	sun.rotation_degrees = Vector3(-53, -33, -8)
	sun.light_color = Color("fff0db")
	sun.light_energy = 1.02
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 48.0
	sun.directional_shadow_split_1 = 0.35
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias = 0.12
	sun.shadow_normal_bias = 1.2
	add_child(sun)
	# One unshadowed fill affects only the hero's meshes (visual layer 2),
	# revealing black armour and facial planes without relighting every tree.
	var character_fill: DirectionalLight3D = DirectionalLight3D.new()
	character_fill.name = "CharacterSoftFill"
	character_fill.rotation_degrees = Vector3(-30,145,0)
	character_fill.light_color = Color("c2d9e6")
	character_fill.light_energy = .38
	character_fill.light_cull_mask = 2
	character_fill.shadow_enabled = false
	add_child(character_fill)

func _landscape() -> void:
	_box(Vector3(0, -0.22, 0), Vector3(100, 0.44, 100), "grass")
	_solid_box(Vector3(0, -0.5, 0), Vector3(100, 1, 100))
	# Rounded compacted-earth square, overlapping surfaces suggest worn edges.
	_ground_patch(Vector3(0,0.029,2), Vector2(14.3,13.4), "earth", 40)
	_ground_patch(Vector3(0,0.043,2), Vector2(11.2,10.9), "path", 40)
	_road(Vector3(0, 0, 15), Vector3(0, 0, -18), 4.2)
	_road(Vector3(0, 0, -18), Vector3(-1, 0, -27), 3.3)
	_road(Vector3(-1, 0, -27), Vector3(1, 0, -36), 3.0)
	_road(Vector3(1, 0, -36), Vector3(0, 0, -43), 2.4)
	_road(Vector3(-10, 0, 0), Vector3(10, 0, 0), 3.2)
	for i: int in range(68):
		var pos: Vector3 = Vector3(_rng.randf_range(-43, 43), 0.018, _rng.randf_range(-46, 42))
		if absf(pos.x) < 15 and pos.z > -16 and pos.z < 16:
			continue
		_ground_patch(pos, Vector2(1.3,0.7)*_rng.randf_range(1.1,3.5), "grass_light" if i % 2 == 0 else "grass_dark", 10)
	# Dense hand-laid stone courtyard is one shared mesh surface, not hundreds
	# of separate cobbles. Loose edge stones remain in the material batch.
	_ground_patch(Vector3(0,.087,3.7),Vector2(4.4,4.0),"paving",36)
	for i: int in range(50):
		# Consume the same seeded samples as 0.1.8: distant trees and their
		# existing collision shapes must not shift when courtyard art changes.
		var a: float = float(i)*2.39996
		var old_radius: float = .7+sqrt(float(i)/50.0)*3.5
		var old_p: Vector3 = Vector3(sin(a)*old_radius,.075,cos(a)*old_radius+3.6)
		if old_p.distance_to(spawn_position) > 1.0:
			var stone_width: float = .32+_rng.randf()*.3
			var stone_depth: float = .23+_rng.randf()*.2
			var yaw: float = _rng.randf()*PI
			if i < 20:
				var radius: float = 4.1+sin(float(i)*1.7)*.5
				var p: Vector3 = Vector3(sin(a)*radius,.075,cos(a)*radius+3.7)
				_box(p,Vector3(stone_width*.8,.07,stone_depth*.8),"stone_light" if i%3 else "stone",yaw)
	# Mountains form a silhouette beyond the traversable map.
	for i: int in range(18):
		var angle: float = float(i) / 18.0 * TAU
		var p: Vector3 = Vector3(cos(angle) * 67, 0, sin(angle) * 67 - 5)
		_mountain(p, _rng.randf_range(10, 19), _rng.randf_range(12, 23), i % 2 == 0)
	# Physical boundaries hidden in the forest; no abrupt exit from terrain.
	_solid_box(Vector3(-48, 2, 0), Vector3(1, 6, 97))
	_solid_box(Vector3(48, 2, 0), Vector3(1, 6, 97))
	_solid_box(Vector3(0, 2, -48), Vector3(97, 6, 1))
	_solid_box(Vector3(0, 2, 48), Vector3(97, 6, 1))
	# Quiet teal pond and a small fisherman's jetty off the main trail.
	_disc(Vector3(-18, 0.04, -25), 5.4, 0.035, "path_edge", 22, Vector3(1, 1, 0.71))
	_disc(Vector3(-18, 0.08, -25), 4.8, 0.045, "water", 26, Vector3(1, 1, 0.69))
	for i: int in range(7):
		_box(Vector3(-17.0, 0.13, -21.2 - float(i) * 0.34), Vector3(1.7, 0.12, 0.29), "wood_light")
	for x: float in [-17.65, -16.35]:
		for z: float in [-21.0, -23.4]:
			_cylinder(Vector3(x, 0.15, z), 0.09, 0.9, "wood", 7)
	for i: int in range(11):
		var angle: float = _rng.randf() * TAU
		var p: Vector3 = Vector3(-18 + cos(angle) * 4.8, 0, -25 + sin(angle) * 3.4)
		for j: int in range(3):
			_cylinder(p + Vector3(float(j) * 0.09, 0.33, 0), 0.025, 0.65, "leaf", 4)
			_cylinder(p + Vector3(float(j) * 0.09, 0.72, 0), 0.055, 0.2, "wood", 5)

func _ground_patch(p: Vector3, radius: Vector2, key: String, segments: int) -> void:
	# Legacy base patches remain below the new continuous surface. Keep the
	# visible terrain below the measured 15.4 mm boot sole, not at the old
	# courtyard's 9 cm overlay height across the whole forest.
	p.y = .004
	# A broad intermediate ring avoids the old hard seven-sided colour stamps.
	for ring: int in range(2):
		var inner: float = float(ring)*0.67
		var outer: float = 0.67 if ring == 0 else 1.0
		for i: int in range(segments):
			var a: float = float(i)/float(segments)*TAU
			var b: float = float(i+1)/float(segments)*TAU
			var wa: float = 1.0+sin(a*5.0+p.x)*0.025+cos(a*7.0+p.z)*0.018
			var wb: float = 1.0+sin(b*5.0+p.x)*0.025+cos(b*7.0+p.z)*0.018
			var va: Vector3 = Vector3(cos(a)*radius.x*wa,0,sin(a)*radius.y*wa)
			var vb: Vector3 = Vector3(cos(b)*radius.x*wb,0,sin(b)*radius.y*wb)
			if ring == 0:
				_tri(p,p+va*outer,p+vb*outer,key)
			else:
				var edge_color: Color = _ground_edge_tint(key)
				_tri(p+va*inner,p+va*outer,p+vb*outer,key,PackedColorArray([Color.WHITE,edge_color,edge_color]))
				_tri(p+va*inner,p+vb*outer,p+vb*inner,key,PackedColorArray([Color.WHITE,edge_color,Color.WHITE]))

func _ground_edge_tint(key: String) -> Color:
	var base_key: String = "earth" if key in ["path","paving"] else "grass"
	var base: Color = (_materials[base_key] as StandardMaterial3D).albedo_color
	var own: Color = (_materials[key] as StandardMaterial3D).albedo_color
	return Color(base.r/maxf(own.r,0.001),base.g/maxf(own.g,0.001),base.b/maxf(own.b,0.001),1.0)

func _road(a: Vector3, b: Vector3, width: float) -> void:
	var side: Vector3 = Vector3(b.z-a.z,0,a.x-b.x).normalized()
	var segments: int = maxi(3,int(a.distance_to(b)/1.25))
	for edge: int in range(2):
		var half: float = (width+(0.64 if edge == 0 else 0.0))*0.5
		var key: String = "path_edge" if edge == 0 else "path"
		var lift: float = 0.006
		for i: int in range(segments):
			var q: Vector3 = a.lerp(b,float(i)/float(segments))+Vector3.UP*lift
			var r: Vector3 = a.lerp(b,float(i+1)/float(segments))+Vector3.UP*lift
			var q_wear: float = sin(q.x*1.7+q.z*1.1)*0.07
			var r_wear: float = sin(r.x*1.7+r.z*1.1)*0.07
			_quad(q-side*(half+q_wear),q+side*(half-q_wear),r+side*(half-r_wear),r-side*(half+r_wear),key)

func _village() -> void:
	# The two trades are deliberately on either side of the open central lane.
	_house(Vector3(-9, 0, -3.2), Vector3(5.1, 3.7, 4.7), "roof_blue", "plaster_light", 0.0, true)
	_house(Vector3(9.5, 0, -3.6), Vector3(5.4, 3.5, 5), "roof_rust", "plaster_warm", 0.0, false)
	_house(Vector3(-12.4, 0, 7.5), Vector3(4.8, 3.6, 5.1), "roof_rust", "plaster", 0.16, false)
	_house(Vector3(12.9, 0, 8), Vector3(5.1, 4.7, 5.4), "roof_blue", "plaster_light", -0.13, true)
	_house(Vector3(-12.8, 0, -10.5), Vector3(4.4, 3.1, 3.8), "roof_straw", "plaster_warm", -0.09, false)
	_house(Vector3(11.6, 0, -10.2), Vector3(4.4, 3.2, 3.7), "roof_rust", "plaster", 0.09, false)
	_market()
	_forge()
	_well(Vector3(-3.1, 0, 6.5))
	_cart(Vector3(8.7, 0, 6), -0.35)
	for p: Vector3 in [Vector3(-11,0,1), Vector3(-13,0,0.8), Vector3(12,0,1.2), Vector3(11,0,4.2), Vector3(-10,0,11)]:
		_barrel(p)
		_crate(p + Vector3(0.8, 0, 0.45), Vector3(0.65, 0.65, 0.65))
	for p: Vector3 in [Vector3(-4.1,0,-7.5), Vector3(4.4,0,-7.5), Vector3(-4,0,11.8), Vector3(4.1,0,11.8)]:
		_lantern(p)
	for p: Vector3 in [Vector3(-15.9,0,3.1), Vector3(16.2,0,2.3), Vector3(-15.8,0,11.9), Vector3(16.2,0,13.4)]:
		_tree(p, false, 1.05, true)
	# Gates frame the approach into the wilds. Side fences stay clear of shops.
	for x: float in [-18.0, 18.0]:
		_fence_line(Vector3(x,0,-14), Vector3(x,0,15), true)
	_fence_line(Vector3(-18,0,-14), Vector3(-3.3,0,-14), true)
	_fence_line(Vector3(3.3,0,-14), Vector3(18,0,-14), true)
	_gate_tower(Vector3(-4.2,0,-14))
	_gate_tower(Vector3(4.2,0,-14))
	_box(Vector3(0, 4.65, -14), Vector3(7.4, 0.38, 0.56), "wood_dark")
	_box(Vector3(0, 4.91, -14), Vector3(7.8, 0.13, 0.85), "roof_blue")
	_sign(Vector3(0, 4.35, -13.63), "ŻELAZNY ŚWIT", Color("ffe3aa"), 42, 0.012)
	_banner(Vector3(-3.0, 3.5, -13.5), "cloth_teal")
	_banner(Vector3(3.0, 3.5, -13.5), "cloth_teal")
	# Vegetable plot beside the inn, simple rows with tiny pumpkins.
	_box(Vector3(-11.7, 0.08, 13), Vector3(5, 0.12, 2.1), "earth")
	for x: float in [-13.5,-12.6,-11.7,-10.8,-9.9]:
		for z: float in [12.55,13.3]:
			_sphere(Vector3(x, 0.25, z), Vector3(0.30, 0.20, 0.30), "leaf_orange", 8, 4)
			_cylinder(Vector3(x, 0.45, z), 0.035, 0.15, "leaf", 5)
	_bench(Vector3(2.7,0,7.4), -0.5)
	_bench(Vector3(-5.4,0,9.0), 0.4)

func _house(p: Vector3, size: Vector3, roof: String, plaster: String, yaw: float, tall: bool) -> void:
	var w: float = size.x
	var h: float = size.y
	var d: float = size.z
	var t: Transform3D = Transform3D(Basis(Vector3.UP, yaw), p)
	_box_t(Vector3(0,0.22,0), Vector3(w + 0.25,0.44,d + 0.25), "stone", t)
	_box_t(Vector3(0,h * 0.5 + 0.2,0), Vector3(w,h,d), plaster, t)
	_solid_box_t(Vector3(0,h * 0.5,0), Vector3(w,h,d), t)
	var eave: float = h + 0.18
	var ridge: float = eave + w * 0.43
	_roof(t, w + 0.8, d + 0.9, eave, ridge, roof)
	# Timber grid, front and back beams; long beams read well on a phone.
	for x: float in [-w * 0.48, 0.0, w * 0.48]:
		for z: float in [-d * 0.505, d * 0.505]:
			_box_t(Vector3(x,h * 0.5 + 0.15,z), Vector3(0.16,h + 0.16,0.17), "wood_dark", t)
	for y: float in [0.5, h * 0.52, h + 0.13]:
		for z: float in [-d * 0.51,d * 0.51]:
			_box_t(Vector3(0,y,z), Vector3(w + 0.1,0.16,0.17), "wood", t)
		for x: float in [-w * 0.51,w * 0.51]:
			_box_t(Vector3(x,y,0), Vector3(0.17,0.16,d + 0.1), "wood", t)
	# Front door flanked by glowing window recesses and open shutters.
	_box_t(Vector3(-w * 0.2,1.02,d * 0.51 + 0.03), Vector3(0.93,1.72,0.10), "wood_dark", t)
	_box_t(Vector3(-w * 0.2,0.98,d * 0.51 + 0.1), Vector3(0.72,1.55,0.06), "wood", t)
	_sphere_t(Vector3(-w * 0.2 + 0.24,0.93,d * 0.51 + 0.16), Vector3(0.045,0.045,0.045), "gold", t, 6, 3)
	_box_t(Vector3(-w * 0.2,0.16,d * 0.5 + 0.42), Vector3(1.3,0.26,0.8), "stone_light", t)
	_window(t, Vector3(w * 0.27,1.55,d * 0.51 + 0.05), Vector2(0.92,0.9))
	if h > 3.8:
		_window(t, Vector3(-w * 0.25,3.25,d * 0.51 + 0.05), Vector2(0.83,0.9))
		_window(t, Vector3(w * 0.25,3.25,d * 0.51 + 0.05), Vector2(0.83,0.9))
	# Cream triangle and a small round-ish attic vent in the gable.
	_tri(t * Vector3(-w * 0.49,eave,d * 0.5 + 0.02),t * Vector3(0,ridge - 0.13,d * 0.5 + 0.02),t * Vector3(w * 0.49,eave,d * 0.5 + 0.02),plaster)
	_box_t(Vector3(0,(eave + ridge) * 0.5,d * 0.51 + 0.025), Vector3(0.14,ridge-eave,0.12), "wood_dark", t)
	_window(t, Vector3(0,eave + 0.42,d * 0.51 + 0.09), Vector2(0.6,0.58))
	# Stone chimney and cap; silhouetted and offset so roofs never look cloned.
	_box_t(Vector3(w * 0.29,ridge - 0.1,-d * 0.2), Vector3(0.62,1.95,0.68), "stone", t)
	_box_t(Vector3(w * 0.29,ridge + 0.88,-d * 0.2), Vector3(0.79,0.18,0.85), "stone_dark", t)
	if tall:
		# Small roof dormer creates a second scale in the silhouette.
		var dormer: Transform3D = Transform3D(t.basis,t * Vector3(w * 0.28,eave + 0.5, d * 0.06))
		_box_t(Vector3(0,0.25,0),Vector3(1.15,0.9,1.3),plaster,dormer)
		_roof(dormer,1.5,1.6,0.7,1.25,roof)
		_window(dormer,Vector3(0,0.27,0.68),Vector2(0.6,0.6))
	# Long-read architectural detail: masonry joints, door ironwork and carved
	# bracket silhouettes, all in existing material batches, no extra colliders.
	for side: float in [-1.0,1.0]:
		for row: int in range(4):
			var y: float = .45+float(row)*.27
			_box_t(Vector3(side*(w*.5+.025),y,d*.5-.15),Vector3(.26,.21,.42 if row%2 == 0 else .27),"stone_light",t)
		var bracket: Transform3D = t*Transform3D(Basis(Vector3.FORWARD,side*-.58),Vector3(side*w*.42,h-.1,d*.5+.23))
		_box_t(Vector3.ZERO,Vector3(.13,.72,.16),"wood_dark",bracket)
	for y: float in [.54,1.47]:
		_box_t(Vector3(-w*.2,y,d*.51+.145),Vector3(.69,.055,.025),"iron",t)
	# Foundation mortar is a shallow inset band, not a new row of physics boxes.
	for j: int in range(int(w/.55)):
		_box_t(Vector3(-w*.5+.28+float(j)*.55,.21,d*.5+.14),Vector3(.035,.29,.012),"stone_dark",t)

func _roof(t: Transform3D, width: float, depth: float, eave: float, ridge: float, key: String) -> void:
	var a: Vector3 = t * Vector3(-width*0.5,eave,-depth*0.5)
	var b: Vector3 = t * Vector3(-width*0.5,eave,depth*0.5)
	var c: Vector3 = t * Vector3(0,ridge,depth*0.5)
	var d: Vector3 = t * Vector3(0,ridge,-depth*0.5)
	var e: Vector3 = t * Vector3(width*0.5,eave,depth*0.5)
	var f: Vector3 = t * Vector3(width*0.5,eave,-depth*0.5)
	# Six local-to-world points exactly bound the triangular roof prism.
	var roof_shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	roof_shape.points = PackedVector3Array([a, b, c, d, e, f])
	var roof_collider: CollisionShape3D = CollisionShape3D.new()
	roof_collider.name = "Roof%02d" % _camera_collision.get_child_count()
	roof_collider.shape = roof_shape
	_camera_collision.add_child(roof_collider)
	# A subtly bowed tiled roof and lifted corners replace two flat roof slabs.
	# Six broad strips per side retain an inexpensive silhouette, not individual tiles.
	var dark_key: String = key+"_dark" if _materials.has(key+"_dark") else key
	for side: float in [-1.0,1.0]:
		for x_step: int in range(6):
			for z_step: int in range(4):
				var r0: float = float(x_step)/6.0
				var r1: float = float(x_step+1)/6.0
				var z0: float = float(z_step)/4.0*2.0-1.0
				var z1: float = float(z_step+1)/4.0*2.0-1.0
				var q0: Vector3 = _roof_point(t,width,depth,eave,ridge,side*r0,z0)
				var q1: Vector3 = _roof_point(t,width,depth,eave,ridge,side*r1,z0)
				var q2: Vector3 = _roof_point(t,width,depth,eave,ridge,side*r1,z1)
				var q3: Vector3 = _roof_point(t,width,depth,eave,ridge,side*r0,z1)
				if side < 0.0:
					_quad(q3,q2,q1,q0,key)
				else:
					_quad(q0,q1,q2,q3,dark_key)
		# Eave fascia is a continuous narrow curved strip, sharing roof material.
		for z_step: int in range(8):
			var z0: float = float(z_step)/8.0*2.0-1.0
			var z1: float = float(z_step+1)/8.0*2.0-1.0
			var q0: Vector3 = _roof_point(t,width,depth,eave,ridge,side,z0)
			var q1: Vector3 = _roof_point(t,width,depth,eave,ridge,side,z1)
			if side < 0.0:
				_quad(q1,q1-Vector3.UP*.13,q0-Vector3.UP*.13,q0,dark_key)
			else:
				_quad(q0,q0-Vector3.UP*.13,q1-Vector3.UP*.13,q1,dark_key)
	_box_t(Vector3(0,ridge+0.065,0),Vector3(0.20,0.14,depth+0.16),dark_key,t)
	# Short turned ridge caps read at village scale and use the existing batches.
	for end: float in [-1.0,1.0]:
		_box_t(Vector3(0,ridge+0.12,end*(depth*.5+.08)),Vector3(.24,.22,.26),dark_key,t)

func _roof_point(t: Transform3D, width: float, depth: float, eave: float, ridge: float, ratio: float, z_ratio: float) -> Vector3:
	var r: float = absf(ratio)
	var y: float = lerpf(ridge,eave,r)-sin(r*PI)*0.22+pow(r,5.0)*0.13
	y += pow(absf(z_ratio),4.0)*r*0.16
	return t*Vector3(width*.5*ratio,y,depth*.5*z_ratio)

func _window(t: Transform3D, p: Vector3, size: Vector2) -> void:
	_box_t(p,Vector3(size.x+0.17,size.y+0.17,0.09),"wood_dark",t)
	_box_t(p+Vector3(0,0,0.06),Vector3(size.x,size.y,0.035),"window",t)
	_box_t(p+Vector3(0,0,0.1),Vector3(0.065,size.y+0.1,0.06),"wood",t)
	_box_t(p+Vector3(0,0,0.1),Vector3(size.x+0.1,0.065,0.06),"wood",t)
	for side: float in [-1.0,1.0]:
		_box_t(p+Vector3(side*(size.x*0.5+0.24),0,0.04),Vector3(0.3,size.y+0.13,0.08),"wood_light",t)
	_box_t(p+Vector3(0,-size.y*0.5-0.15,0.05),Vector3(size.x+0.4,0.16,0.26),"wood",t)

func _market() -> void:
	var c: Vector3 = Vector3(-7.0,0,-1.05)
	for x: float in [-2.0,2.0]:
		for z: float in [-0.7,0.8]:
			_cylinder(c+Vector3(x,1.35,z),0.07,2.7,"wood",7)
	_box(c+Vector3(0,0.79,0.63),Vector3(4.1,0.22,1.04),"wood_light")
	_box(c+Vector3(0,0.37,0.65),Vector3(3.85,0.7,0.75),"wood")
	for i: int in range(8):
		var x: float = -2.1 + float(i)*0.6
		var mat: String = "cloth_teal" if i%2==0 else "cloth_cream"
		_quad(c+Vector3(x,2.6,-0.95),c+Vector3(x+0.59,2.6,-0.95),c+Vector3(x+0.59,2.27,1.32),c+Vector3(x,2.27,1.32),mat)
		_box(c+Vector3(x+0.29,2.13,1.32),Vector3(0.59,0.28,0.05),mat)
	for x: float in [-1.45,-0.75,0.0]:
		_crate(c+Vector3(x,0.9,0.55),Vector3(0.56,0.22,0.62))
		for j: int in range(4):
			_sphere(c+Vector3(x-0.16+float(j%2)*0.23,1.21,0.39+float(j/2)*0.22),Vector3(0.105,0.10,0.105),"leaf_orange" if x<0 else "leaf",7,4)
	for j: int in range(4):
		var p: Vector3 = c+Vector3(0.75+float(j)*0.31,1.07,0.57)
		_cylinder(p,0.10,0.3,"cloth_red" if j%2==0 else "water",7)
		_cylinder(p+Vector3(0,0.19,0),0.05,0.12,"gold",7)
	_sign(c+Vector3(0,2.85,-0.9),"KRAM MIRY",Color("f5e2b8"),31,0.009)
	_crate(Vector3(-9.4,0,2.3),Vector3(0.8,0.85,0.8))

func _forge() -> void:
	# Open lean-to attached to smithy, visible from the central lane.
	for p: Vector3 in [Vector3(5.6,1.4,-3.0),Vector3(8.8,1.4,-3.0),Vector3(8.8,1.4,-0.6)]:
		_cylinder(p,0.11,2.8,"wood_dark",7)
	_box(Vector3(7.3,2.94,-1.85),Vector3(3.7,0.18,2.8),"roof_rust",0.0,Vector3(0,0,0.07))
	_box(Vector3(8.4,0.4,-1.2),Vector3(1.65,0.8,1.5),"stone_dark")
	_box(Vector3(8.4,0.87,-1.2),Vector3(1.58,0.18,1.4),"stone")
	_box(Vector3(8.4,0.99,-1.2),Vector3(1.1,0.08,1.0),"ember")
	_box(Vector3(8.4,2.07,-1.78),Vector3(1.48,2.1,0.43),"stone")
	_box(Vector3(8.4,3.32,-1.78),Vector3(0.78,1.5,0.68),"stone_dark")
	_box(Vector3(8.4,4.03,-1.78),Vector3(1.0,0.16,0.9),"stone")
	_solid_box(Vector3(8.4,0.65,-1.3),Vector3(1.7,1.3,1.5))
	# Distinct anvil: waist, broad face and tapered horn.
	_cylinder(Vector3(6.4,0.30,1.9),0.40,0.6,"wood",9)
	_box(Vector3(6.4,0.65,1.9),Vector3(0.72,0.16,0.5),"iron")
	_box(Vector3(6.4,0.83,1.9),Vector3(0.34,0.26,0.34),"iron")
	_box(Vector3(6.4,1.02,1.9),Vector3(0.85,0.18,0.48),"iron")
	_cone(Vector3(5.85,1.02,1.9),0.24,0.65,"iron",6,Vector3(0,0,PI/2.0))
	# Rack of original blades behind the smith.
	_box(Vector3(10.8,1.45,0.5),Vector3(1.9,0.12,0.20),"wood_dark")
	for i: int in range(3):
		var x: float = 10.2+float(i)*0.56
		_box(Vector3(x,1.45,0.5),Vector3(0.09,1.45,0.08),"stone_light",0.0,Vector3(0,0,-0.13))
		_box(Vector3(x+0.07,0.87,0.5),Vector3(0.43,0.07,0.13),"gold")
		_box(Vector3(x+0.09,0.69,0.5),Vector3(0.10,0.3,0.10),"wood_dark")
	_barrel(Vector3(7.9,0,2.5))
	_sign(Vector3(7.3,3.29,-0.38),"KUŹNIA BORNA",Color("ffe1a2"),31,0.009)
	for i: int in range(5):
		var flame: MeshInstance3D = MeshInstance3D.new()
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius=0.18
		mesh.height=0.55
		mesh.radial_segments=7
		mesh.rings=4
		flame.mesh=mesh
		flame.material_override=_materials["flame" if i%2 else "ember"]
		flame.position=Vector3(8.1+float(i%3)*0.28,1.18,-1.4+float(i/3)*0.35)
		add_child(flame)
		_fire.append(flame)
	_fire_light=OmniLight3D.new()
	_fire_light.position=Vector3(8.3,1.6,-1.2)
	_fire_light.light_color=Color("ff923c")
	_fire_light.light_energy=1.6
	_fire_light.omni_range=4.0
	_fire_light.shadow_enabled=false
	add_child(_fire_light)

func _well(p: Vector3) -> void:
	_disc(p+Vector3.UP*0.08,1.28,0.16,"stone_light",12)
	_cylinder(p+Vector3.UP*0.46,0.9,0.85,"stone",12)
	_cylinder(p+Vector3.UP*0.89,0.77,0.08,"stone_dark",12)
	_cylinder(p+Vector3.UP*0.94,0.61,0.025,"water",12)
	for x: float in [-1.02,1.02]:
		_box(p+Vector3(x,1.39,0),Vector3(0.16,2.6,0.18),"wood_dark")
	var t: Transform3D=Transform3D(Basis.IDENTITY,p)
	_roof(t,2.7,2.05,2.57,3.36,"roof_blue")
	_cylinder(p+Vector3(0,2.02,0),0.09,2.15,"wood_light",8,Vector3(0,0,PI/2.0))
	_cylinder(p+Vector3(0,1.47,0),0.025,1.02,"wood_light",5)
	_cylinder(p+Vector3(0,1.08,0),0.18,0.29,"wood",8)
	_solid_box(p+Vector3.UP*0.5,Vector3(1.8,1.0,1.8))

func _gate_tower(p: Vector3) -> void:
	_box(p+Vector3.UP*0.33,Vector3(1.7,0.66,1.7),"stone_dark")
	_box(p+Vector3.UP*1.9,Vector3(1.25,3.8,1.25),"stone")
	_box(p+Vector3.UP*3.68,Vector3(1.6,0.23,1.6),"wood_dark")
	_box(p+Vector3.UP*4.1,Vector3(1.8,0.72,1.8),"wood")
	for x: float in [-0.78,0.78]:
		for z: float in [-0.78,0.78]:
			_box(p+Vector3(x,4.75,z),Vector3(0.14,1.4,0.14),"wood_dark")
	_roof(Transform3D(Basis.IDENTITY,p),2.35,2.35,5.15,6.25,"roof_blue")
	_solid_box(p+Vector3.UP*2.2,Vector3(1.6,4.4,1.6))

func _fence_line(a: Vector3,b: Vector3,solid: bool) -> void:
	var distance: float=a.distance_to(b)
	var steps: int=int(distance/0.55)
	var yaw: float=atan2(b.x-a.x,b.z-a.z)
	for i: int in range(steps+1):
		var p: Vector3=a.lerp(b,float(i)/float(steps))
		var height: float=1.6+_rng.randf()*0.28
		_cylinder(p+Vector3.UP*(height*0.5),0.15,height,"wood",6)
		_cone(p+Vector3.UP*(height+0.17),0.15,0.35,"wood_light",6)
	_box((a+b)*0.5+Vector3.UP*0.57,Vector3(0.17,0.14,distance),"wood_dark",yaw)
	_box((a+b)*0.5+Vector3.UP*1.24,Vector3(0.17,0.14,distance),"wood_dark",yaw)
	if solid:
		_solid_box((a+b)*0.5+Vector3.UP*0.8,Vector3(0.45,1.6,distance+0.4),yaw)

func _forest() -> void:
	# Deliberate gaps around the gate and enemy clearings keep combat readable.
	for i: int in range(116):
		var p: Vector3=Vector3(_rng.randf_range(-45,45),0,_rng.randf_range(-45,38))
		if absf(p.x)<19 and p.z>-17 and p.z<17:
			continue
		if absf(p.x)<9 and p.z < -16:
			continue
		if p.distance_to(Vector3(-18,0,-25))<7:
			continue
		_tree(p,i%4!=0,_rng.randf_range(0.75,1.45),true)
	# Near wilderness trees are placed as small silhouettes off the travel lane.
	for p: Vector3 in [Vector3(-10,0,-18),Vector3(12,0,-20),Vector3(-12,0,-33),Vector3(12,0,-38),Vector3(-9,0,-42),Vector3(9,0,-44)]:
		_tree(p,true,1.35,true)
	for i: int in range(60):
		var p: Vector3=Vector3(_rng.randf_range(-43,43),0,_rng.randf_range(-44,38))
		if absf(p.x)<17 and p.z>-16 and p.z<16:
			continue
		if absf(p.x)<4 and p.z<-16:
			continue
		if p.distance_to(Vector3(-18,0,-25))<6:
			continue
		_rock(p,_rng.randf_range(0.35,1.0))
	# The old watch-stone is a clear destination at the end of the first loop.
	_disc(Vector3(0,0.13,-42.3),3.2,0.22,"stone_dark",9)
	for i: int in range(5):
		var y: float=0.4+float(i)*0.61
		_box(Vector3(0,y,-43.3),Vector3(1.1-float(i)*0.1,0.6,0.9-float(i)*0.07),"stone" if i%2 else "stone_dark",float(i)*0.05)
	var rune: MeshInstance3D=MeshInstance3D.new()
	var rune_mesh: TorusMesh=TorusMesh.new()
	rune_mesh.inner_radius=0.42
	rune_mesh.outer_radius=0.54
	rune_mesh.rings=12
	rune_mesh.ring_segments=6
	rune.mesh=rune_mesh
	rune.material_override=_materials["gold"]
	rune.position=Vector3(0,2.35,-42.79)
	rune.rotation_degrees.x=90
	add_child(rune)
	# Ruined low pillars around the northern clearing.
	for p: Vector3 in [Vector3(-5,0,-41),Vector3(5,0,-41),Vector3(-5,0,-37.5),Vector3(5,0,-37.5)]:
		_box(p+Vector3.UP*0.18,Vector3(1.15,0.36,1.15),"stone_dark")
		_cylinder(p+Vector3.UP*0.95,0.33,1.55,"stone",7)
		_box(p+Vector3.UP*1.73,Vector3(0.83,0.18,0.83),"stone_light",0.13)
	# Tufts and tiny pale flowers, all packed into the same material batches.
	for i: int in range(240):
		var p: Vector3=Vector3(_rng.randf_range(-39,39),0.015,_rng.randf_range(-43,35))
		if absf(p.x)<17 and p.z>-16 and p.z<16:
			continue
		if absf(p.x)<3.2 and p.z<-16:
			continue
		if p.distance_to(Vector3(-18,0,-25))<5.5:
			continue
		for j: int in range(2):
			var h: float=_rng.randf_range(0.18,0.42)
			var a: float=_rng.randf()*TAU
			var v: Vector3=Vector3(cos(a)*0.14,0,sin(a)*0.14)
			_tri(p-v,p+v,p+Vector3(0,h,0),"grass_light" if i%4 else "leaf_gold")
		if i%7==0:
			_sphere(p+Vector3(0,0.3,0),Vector3(0.06,0.065,0.06),"flower",6,3)
	_signpost(Vector3(2.7,0,-17.4))
	_rock(Vector3(-3.7,0,-18.6),0.7)
	_rock(Vector3(4.5,0,-36),0.7)

func _gardens() -> void:
	# Bounded, opaque geometry: no particle simulation or alpha-card overdraw.
	# Separate RNG leaves every existing tree, collider and combat clearing fixed.
	var garden_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	garden_rng.seed = 8108514
	var beds: Array[Vector3] = [Vector3(-10.2,0,2.0),Vector3(-7.8,0,1.6),Vector3(11.0,0,2.8),Vector3(-6.4,0,8.6),Vector3(3.8,0,9.6),Vector3(-4.8,0,-12.4),Vector3(5.0,0,-12.4)]
	for bed: Vector3 in beds:
		for i: int in range(12):
			var p: Vector3 = bed+Vector3(garden_rng.randf_range(-.65,.65),.015,garden_rng.randf_range(-.4,.4))
			_grass_clump(p,garden_rng.randf_range(.16,.32),garden_rng.randf()*TAU)
			if i%6 == 0:
				_wildflower(p,.23+garden_rng.randf()*.08,"flower_blue" if i == 0 else "flower")
	# Soft reeds and wildflowers on the bank stay outside the travel lane.
	for i: int in range(56):
		var a: float = garden_rng.randf()*TAU
		var p: Vector3 = Vector3(-18+cos(a)*garden_rng.randf_range(5.15,5.8),.06,-25+sin(a)*garden_rng.randf_range(3.75,4.15))
		if p.distance_to(Vector3(-17,0,-22.0)) > 1.1:
			_grass_clump(p,garden_rng.randf_range(.23,.42),a)
			if i%10 == 0:
				_wildflower(p,.30,"flower")
	# Raised wooden planters beneath two windows; no walking collision is changed.
	for p: Vector3 in [Vector3(-7.65,.75,-.62),Vector3(11.0,.75,-.83)]:
		_box(p,Vector3(.82,.24,.35),"wood")
		_box(p+Vector3.UP*.13,Vector3(.70,.035,.24),"earth")
		for i: int in range(4):
			_wildflower(p+Vector3(-.29+float(i)*.19,.13,0),.23,"flower_blue" if i%2 == 0 else "flower")

func _grass_clump(p: Vector3, height: float, yaw: float) -> void:
	for blade: int in range(4):
		var a: float = yaw+float(blade)*2.39996
		var side: Vector3 = Vector3(cos(a),0,sin(a))*.04
		var lean: Vector3 = Vector3(-sin(a),0,cos(a))*height*.28
		var middle: Vector3 = p+Vector3.UP*height*.58+lean*.35
		var tip: Vector3 = p+Vector3.UP*height+lean
		_tri(p-side,p+side,middle+side*.58,"grass_dark")
		_tri(p-side,middle+side*.58,middle-side*.58,"grass_dark")
		_tri(middle-side*.58,middle+side*.58,tip,"grass_light")

func _terrain_surface() -> void:
	# One opaque surface blends the whole walkable map. Existing decorative
	# ground geometry stays for compatibility; its flat surfaces sit below this.
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(100,100)
	var surface: MeshInstance3D = MeshInstance3D.new()
	surface.name = "ValleyTerrain"
	surface.mesh = mesh
	surface.position.y = .012
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_terrain_material = ShaderMaterial.new()
	_terrain_material.shader = preload("res://assets/world/terrain.gdshader")
	_terrain_material.set_shader_parameter("control_map",_detail_texture("terrain_control"))
	for family: String in ["grass","earth","paving"]:
		_terrain_material.set_shader_parameter(family+"_map",_world_textures[family+"_albedo"])
		_terrain_material.set_shader_parameter(family+"_normal",_world_textures[family+"_normal"])
	surface.material_override = _terrain_material
	add_child(surface)

func _ground_cover() -> void:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://assets/world/meadow.gdshader")
	_materials["meadow"] = material
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 22051019
	for i: int in range(1250):
		var p: Vector3 = Vector3(rng.randf_range(-43,43),.015,rng.randf_range(-45,38))
		# Clear combat silhouettes and every established walking lane.
		if pow(p.x/13.1,2)+pow((p.z-2.0)/12.7,2) < 1.0:
			continue
		if absf(p.x) < 3.0 and p.z < 16.0:
			continue
		if p.distance_to(Vector3(-18,.015,-25)) < 5.8:
			continue
		var height: float = rng.randf_range(.16,.38)
		var yaw: float = rng.randf()*TAU
		for blade: int in range(4):
			var angle: float = yaw+float(blade)*2.39996
			var side: Vector3 = Vector3(cos(angle),0,sin(angle))*.033
			var lean: Vector3 = Vector3(-sin(angle),0,cos(angle))*height*.35
			var middle: Vector3 = p+Vector3.UP*height*.60+lean*.40
			var tip: Vector3 = p+Vector3.UP*height+lean
			var base_tint: Color = Color(1,1,1,0)
			var mid_tint: Color = Color(1,1,1,.6)
			var tip_tint: Color = Color(1,1,1,1)
			_tri(p-side,p+side,middle+side*.55,"meadow",PackedColorArray([base_tint,base_tint,mid_tint]))
			_tri(p-side,middle+side*.55,middle-side*.55,"meadow",PackedColorArray([base_tint,mid_tint,mid_tint]))
			_tri(middle-side*.55,middle+side*.55,tip,"meadow",PackedColorArray([mid_tint,mid_tint,tip_tint]))
	# Ferns have a distinct low silhouette beside the forest approach.
	for p: Vector3 in [Vector3(-7,.015,-18),Vector3(8.7,.015,-21),Vector3(-8,.015,-28),Vector3(10,.015,-34),Vector3(-14,.015,-21)]:
		for frond: int in range(7):
			var angle: float = float(frond)*TAU/7.0+p.x
			var direction: Vector3 = Vector3(cos(angle),0,sin(angle))
			var side: Vector3 = Vector3(-sin(angle),0,cos(angle))
			for pair: int in range(5):
				var u: float = float(pair+1)/6.0
				var center: Vector3 = p+direction*u*.70+Vector3.UP*sin(u*PI*.75)*.45
				for sign_value: float in [-1.0,1.0]:
					var tip: Vector3 = center+side*sign_value*(1.0-u)*.24+direction*.13
					_tri(center-direction*.06,center+direction*.08,tip,"meadow",PackedColorArray([Color(1,1,1,.3),Color(1,1,1,.6),Color(1,1,1,1)]))

func _wildflower(p: Vector3, height: float, key: String) -> void:
	_cylinder(p+Vector3.UP*height*.5,.012,height,"leaf",4)
	var center: Vector3 = p+Vector3.UP*height
	for petal: int in range(5):
		var a: float = float(petal)/5.0*TAU
		var direction: Vector3 = Vector3(cos(a),0,sin(a))
		var side: Vector3 = Vector3(-sin(a),0,cos(a))*.032
		_tri(center,center+direction*.092-side+Vector3.UP*.018,center+direction*.092+side+Vector3.UP*.018,key)
	_sphere(center+Vector3.UP*.015,Vector3(.025,.019,.025),"gold",5,2)

func _tree(p: Vector3,pine: bool,scale_factor: float,solid: bool) -> void:
	var s: float=scale_factor
	_cylinder(p+Vector3.UP*1.55*s,0.16*s,3.1*s,"wood",7)
	if pine:
		# Individual swept boughs replace three closed cone silhouettes. The seed
		# is spatial: visual detail never consumes the collision-layout RNG.
		var phase: float = p.x*.71+p.z*.43
		for tier: int in range(5):
			var y: float = (1.45+float(tier)*.57)*s
			var radius: float = (1.43-float(tier)*.24)*s
			for branch: int in range(8):
				var angle: float = float(branch)*TAU/8.0+phase+float(tier)*.61
				var direction: Vector3 = Vector3(cos(angle),0,sin(angle))
				var side: Vector3 = Vector3(-sin(angle),0,cos(angle))
				var length: float = radius*(.87+.13*sin(angle*3.0+phase))
				var root_point: Vector3 = p+Vector3.UP*(y+.43*s)
				var tip: Vector3 = p+direction*length+Vector3.UP*(y-.08*s)
				_needle_spray(root_point,tip,side*length*.41)
				# A second tilted spray fills the vertical outline when orbiting.
				_needle_spray(root_point,tip,(side*.45+Vector3.UP*.55)*length*.39)
		_cone(p+Vector3.UP*4.02*s,.30*s,.94*s,"pine_light",7)
	else:
		var key: String="leaf_gold" if int(absf(p.x)*7)%3==0 else ("leaf_orange" if int(absf(p.z)*5)%3==0 else "leaf")
		var lean: float = sin(p.x*1.7+p.z*.9)*.17
		for crown: int in range(7):
			var a: float = float(crown)*2.39996+p.x
			var r: float = .62 if crown < 6 else .30
			var y: float = 2.98+sin(float(crown)*1.7)*.32+(.47 if crown > 5 else 0.0)
			var at: Vector3 = Vector3(cos(a)*r,y+lean,sin(a)*r)
			_sphere(p+at*s,Vector3(.79,.61,.74)*s,key,8,3)
			# Small lobes break the octagonal outline without transparent cards.
			if crown%2 == 0:
				_sphere(p+(at+Vector3(cos(a)*.40,.06,sin(a)*.4))*s,Vector3(.40,.32,.40)*s,key,6,2)
		_cylinder(p+Vector3(-.27,2.13,.06)*s,.09*s,.96*s,"wood",5,Vector3(0,0,-.64))
		_cylinder(p+Vector3(.29,2.27,-.08)*s,.08*s,.88*s,"wood",5,Vector3(0,0,.67))
	if solid:
		var shape: CylinderShape3D=CylinderShape3D.new()
		shape.radius=0.25*s
		shape.height=2.0*s
		_add_collision(shape,Transform3D(Basis.IDENTITY,p+Vector3.UP*s))

func _rock(p: Vector3,s: float) -> void:
	_sphere(p+Vector3.UP*0.34*s,Vector3(0.9,0.65,0.74)*s,"stone" if int(p.x)%2 else "stone_dark",6,3)
	if s>0.72:
		var shape: SphereShape3D=SphereShape3D.new()
		shape.radius=0.57*s
		_add_collision(shape,Transform3D(Basis.IDENTITY,p+Vector3.UP*0.25*s))

func _needle_spray(base: Vector3,tip: Vector3,side: Vector3) -> void:
	# Explicit atlas UVs; ordinary world-projected UVs cannot describe a cutout.
	var key: String = "pine_needles"
	_ensure_batch(key)
	var batch: Dictionary = _batches[key]
	var vertices: PackedVector3Array = batch.vertices
	var normals: PackedVector3Array = batch.normals
	var uvs: PackedVector2Array = batch.uvs
	var colors: PackedColorArray = batch.colors
	var tangents: PackedFloat32Array = batch.tangents
	var indices: PackedInt32Array = batch.indices
	var offset: int = vertices.size()
	var points: Array[Vector3] = [base-side,base+side,tip+side,tip-side]
	var texcoords: Array[Vector2] = [Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]
	var normal: Vector3 = (points[2]-points[0]).cross(points[1]-points[0]).normalized()
	var tangent: Vector3 = side.normalized()
	for i: int in range(4):
		vertices.append(points[i])
		normals.append(normal)
		uvs.append(texcoords[i])
		colors.append(Color.WHITE*(.86+sin(base.x+base.z)*.08))
		tangents.append_array(PackedFloat32Array([tangent.x,tangent.y,tangent.z,-1.0]))
	indices.append_array(PackedInt32Array([offset,offset+1,offset+2,offset,offset+2,offset+3]))
	batch.vertices = vertices
	batch.normals = normals
	batch.uvs = uvs
	batch.colors = colors
	batch.tangents = tangents
	batch.indices = indices

func _mountain(p: Vector3,radius: float,height: float,light: bool) -> void:
	# Asymmetric ridges with secondary shoulders replace the old seven-triangle
	# pointed cones. A whole peak costs 208 triangles in the shared matte batch.
	var phase: float = p.x*.071+p.z*.037+(0.7 if light else 1.9)
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var tangents: PackedFloat32Array = PackedFloat32Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var rings: Array[float] = [0.0,.14,.28,.42,.56,.70,.84,1.0]
	var sectors: int = 16
	for ring: int in range(rings.size()):
		var count: int = 1 if ring == 0 else sectors
		for i: int in range(count):
			var angle: float = float(i)/float(sectors)*TAU
			var u: float = cos(angle)*rings[ring]
			var v: float = sin(angle)*rings[ring]
			var h: float = _ridge_height(u,v,height,phase)
			var slope_x: float = (_ridge_height(u+.012,v,height,phase)-_ridge_height(u-.012,v,height,phase))/(radius*.024)
			var slope_z: float = (_ridge_height(u,v+.012,height,phase)-_ridge_height(u,v-.012,height,phase))/(radius*.024)
			vertices.append(Vector3(u*radius,h,v*radius))
			var normal: Vector3 = Vector3(-slope_x,1.0,-slope_z).normalized()
			normals.append(normal)
			tangents.append_array(_world_tangent(normal))
			uvs.append(Vector2(u,v))
	for i: int in range(sectors):
		indices.append_array(PackedInt32Array([0,1+i,1+(i+1)%sectors]))
	for ring: int in range(1,rings.size()-1):
		var inner: int = 1+(ring-1)*sectors
		var outer: int = 1+ring*sectors
		for i: int in range(sectors):
			var next: int = (i+1)%sectors
			indices.append_array(PackedInt32Array([inner+i,outer+i,outer+next,inner+i,outer+next,inner+next]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	_add_mesh(mesh,Transform3D(Basis.IDENTITY,p),"mountain")

func _ridge_height(u: float,v: float,height: float,phase: float) -> float:
	var x: float = cos(phase)*u-sin(phase)*v
	var z: float = sin(phase)*u+cos(phase)*v
	var rim: float = pow(maxf(0.0,1.0-u*u-v*v),1.25)
	var main_peak: float = exp(-pow((x+.23)/.34,2.0)-pow((z+.12)/.31,2.0))
	var shoulder: float = exp(-pow((x-.38)/.30,2.0)-pow((z-.18)/.37,2.0))*.78
	var back_ridge: float = exp(-pow((x+.09)/.52,2.0)-pow((z-.48)/.23,2.0))*.48
	var rough: float = sin(x*11.0+phase)*sin(z*9.0-phase)*.035
	return maxf(0.0,rim*(.16+main_peak+shoulder+back_ridge+rough))*height*.74

func _crate(p: Vector3,size: Vector3) -> void:
	_box(p+Vector3.UP*size.y*0.5,size,"wood_light")
	for y: float in [0.12,size.y-0.08]:
		for z: float in [-size.z*0.52,size.z*0.52]:
			_box(p+Vector3(0,y,z),Vector3(size.x+0.04,0.09,0.06),"wood")
	for x: float in [-size.x*0.44,size.x*0.44]:
		_box(p+Vector3(x,size.y*0.5,size.z*0.52),Vector3(0.08,size.y,0.06),"wood")

func _barrel(p: Vector3) -> void:
	_cylinder(p+Vector3.UP*0.46,0.38,0.92,"wood",10)
	_cylinder(p+Vector3.UP*0.46,0.4,0.55,"wood_light",10)
	for y: float in [0.17,0.76]:
		_cylinder(p+Vector3.UP*y,0.414,0.085,"iron",10)
	_cylinder(p+Vector3.UP*0.94,0.36,0.04,"wood_dark",10)

func _cart(p: Vector3,yaw: float) -> void:
	var t: Transform3D=Transform3D(Basis(Vector3.UP,yaw),p)
	_box_t(Vector3(0,0.72,0),Vector3(1.45,0.18,2.15),"wood_light",t)
	for x: float in [-0.73,0.73]:
		_box_t(Vector3(x,1.04,0),Vector3(0.10,0.6,2.15),"wood",t)
		for z: float in [-0.76,0.76]:
			var wheel_t: Transform3D=t*Transform3D(Basis(Vector3.FORWARD,PI/2),Vector3(x*1.17,0.52,z))
			var torus: TorusMesh=TorusMesh.new()
			torus.inner_radius=0.35
			torus.outer_radius=0.46
			torus.rings=10
			torus.ring_segments=5
			_add_mesh(torus,wheel_t,"wood_dark")
			_box_t(Vector3(x*1.17,0.52,z),Vector3(0.09,0.72,0.09),"wood",t)
			_box_t(Vector3(x*1.17,0.52,z),Vector3(0.09,0.09,0.72),"wood",t)
		_box_t(Vector3(x*0.6,0.54,1.8),Vector3(0.1,0.1,1.9),"wood",t)
	_box_t(Vector3(0,0.94,-1.02),Vector3(1.45,0.6,0.10),"wood",t)
	_sphere_t(Vector3(0,1.1,0),Vector3(0.6,0.44,0.88),"cloth_cream",t,8,4)

func _bench(p: Vector3,yaw: float) -> void:
	var t: Transform3D=Transform3D(Basis(Vector3.UP,yaw),p)
	_box_t(Vector3(0,0.5,0),Vector3(1.9,0.13,0.48),"wood_light",t)
	for x: float in [-0.7,0.7]:
		_box_t(Vector3(x,0.24,0),Vector3(0.15,0.5,0.4),"wood",t)

func _lantern(p: Vector3) -> void:
	_cylinder(p+Vector3.UP*1.25,0.065,2.5,"wood_dark",7)
	_box(p+Vector3(0.20,2.47,0),Vector3(0.5,0.08,0.08),"wood_dark")
	_box(p+Vector3(0.39,2.23,0),Vector3(0.24,0.36,0.24),"iron")
	_box(p+Vector3(0.39,2.23,0.13),Vector3(0.16,0.24,0.025),"window")
	_cone(p+Vector3(0.39,2.47,0),0.23,0.19,"iron",4)

func _signpost(p: Vector3) -> void:
	_box(p+Vector3.UP*1.1,Vector3(0.13,2.2,0.15),"wood")
	_box(p+Vector3(0.2,1.7,0),Vector3(1.7,0.38,0.16),"wood_dark")
	_box(p+Vector3(-0.17,1.16,0),Vector3(1.5,0.38,0.16),"wood_dark")
	_sign(p+Vector3(0.2,1.72,0.11),"DZIKIE OSTĘPY",Color("f5e3bb"),24,0.007)
	_sign(p+Vector3(-0.17,1.18,0.11),"WIOSKA  ↓",Color("f5e3bb"),23,0.007)

func _banner(p: Vector3,key: String) -> void:
	var pivot: Node3D=Node3D.new()
	pivot.position=p
	add_child(pivot)
	var banner: MeshInstance3D=MeshInstance3D.new()
	var mesh: BoxMesh=BoxMesh.new()
	mesh.size=Vector3(0.78,1.28,0.055)
	banner.mesh=mesh
	banner.material_override=_materials[key]
	banner.position.y=-0.64
	pivot.add_child(banner)
	var sigil: Label3D=Label3D.new()
	sigil.text="✦"
	sigil.font_size=56
	sigil.pixel_size=0.009
	sigil.modulate=Color("e5c77f")
	sigil.position=Vector3(0,-0.6,0.043)
	pivot.add_child(sigil)
	_banners.append(pivot)

func _create_npc(title: String,p: Vector3,smith: bool) -> void:
	var npc: Node3D=Node3D.new()
	npc.name="SmithNPC" if smith else "MerchantNPC"
	npc.position=p
	add_child(npc)
	# A shaded stand and warm rim under each vendor draw the eye without UI clutter.
	_disc(p+Vector3.UP*0.095,0.77,0.09,"stone_dark",12)
	# Static NPC meshes go into their own small material groups as batches already
	# flushed; use the same batching helper, then flush only those new groups.
	for x: float in [-0.15,0.15]:
		_box(p+Vector3(x,0.35,0),Vector3(0.20,0.65,0.24),"wood_dark")
		_box(p+Vector3(x,0.10,0.08),Vector3(0.23,0.20,0.35),"leather")
	_sphere(p+Vector3.UP*1.02,Vector3(0.43,0.53,0.28),"leather" if smith else "cloth_teal",8,5)
	_box(p+Vector3(0,0.8,0.17),Vector3(0.6,0.7,0.1),"wood_dark" if smith else "cloth_cream")
	_cylinder(p+Vector3.UP*1.59,0.23,0.40,"skin",9)
	_sphere(p+Vector3(0,1.79,-0.03),Vector3(0.25,0.18,0.25),"wood_dark",8,4)
	if smith:
		_box(p+Vector3(0,1.43,0.19),Vector3(0.35,0.26,0.14),"wood_dark")
	else:
		_cylinder(p+Vector3.UP*1.77,0.35,0.09,"cloth_red",10)
		_cone(p+Vector3.UP*1.96,0.23,0.35,"cloth_red",8)
	for side: float in [-1.0,1.0]:
		_sphere(p+Vector3(side*0.43,1.13,0),Vector3(0.16,0.33,0.16),"skin",7,4)
		_sphere(p+Vector3(side*0.45,0.88,0.04),Vector3(0.13,0.14,0.13),"skin",7,4)
	if smith:
		_box(p+Vector3(0.45,0.93,0.17),Vector3(0.09,0.48,0.09),"wood")
		_box(p+Vector3(0.45,1.20,0.17),Vector3(0.38,0.18,0.22),"iron")
	var label: Label3D=Label3D.new()
	label.text=title
	label.position=Vector3(0,2.38,0)
	label.font_size=33
	label.pixel_size=0.009
	label.modulate=Color("f7dfa2")
	label.outline_modulate=Color("2c332d")
	label.outline_size=8
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=true
	npc.add_child(label)
	var small: Label3D=Label3D.new()
	small.text="ULEPSZANIE" if smith else "HANDEL"
	small.position=Vector3(0,2.09,0)
	small.font_size=23
	small.pixel_size=0.008
	small.modulate=Color("bde5dc")
	small.outline_modulate=Color("2c332d")
	small.outline_size=7
	small.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	npc.add_child(small)
	_flush_batches()

func _ambient_details() -> void:
	# Seven drifting opaque sparks share one tiny mesh and one draw call.
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = .026
	mesh.height = .052
	mesh.radial_segments = 5
	mesh.rings = 3
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = 7
	_embers = MultiMeshInstance3D.new()
	_embers.name = "ForgeEmbers"
	_embers.multimesh = instances
	_embers.material_override = _materials["flame"]
	_embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_embers)
	_update_embers()

func _update_embers() -> void:
	if not is_instance_valid(_embers):
		return
	for i: int in range(7):
		var phase: float = float(i)*.41
		var travel: float = fmod(_clock*.55+phase,2.0)
		var at: Vector3 = Vector3(8.3+sin(travel*4+phase)*.22,1.25+travel,-1.2+cos(travel*3+phase)*.2)
		var size: Vector3 = Vector3.ONE*(1.0-travel*.4)
		_embers.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(size),at))

func set_low_quality(enabled: bool) -> void:
	if _terrain_material != null:
		_terrain_material.set_shader_parameter("detailed_normals",not enabled)
	var meadow: MeshInstance3D = get_node_or_null("Scenery_meadow")
	if meadow != null:
		meadow.visible = not enabled
	for child: Node in get_children():
		if child is DirectionalLight3D:
			(child as DirectionalLight3D).shadow_enabled = not enabled and child.name != "CharacterSoftFill"
	if is_instance_valid(_fire_light):
		_fire_light.visible = not enabled

func _process(delta: float) -> void:
	_clock+=delta
	for i: int in range(_fire.size()):
		var flame: MeshInstance3D=_fire[i]
		flame.scale=Vector3(0.9+sin(_clock*5+float(i))*0.12,0.85+sin(_clock*7+float(i)*2)*0.2,0.9)
	for i: int in range(_banners.size()):
		_banners[i].rotation.x=sin(_clock*1.8+float(i))*0.075
		_banners[i].rotation.z=sin(_clock*1.3+float(i))*0.025
	if is_instance_valid(_fire_light):
		_fire_light.light_energy=1.4+sin(_clock*9)*0.18+sin(_clock*13)*0.09
	_update_embers()

func _sign(p: Vector3,text: String,color: Color,font_size: int,pixel: float) -> void:
	var sign_label: Label3D=Label3D.new()
	sign_label.text=text
	sign_label.position=p
	sign_label.font_size=font_size
	sign_label.pixel_size=pixel
	sign_label.modulate=color
	sign_label.outline_modulate=Color("393e34")
	sign_label.outline_size=5
	add_child(sign_label)

# Geometry primitives. The mesh surface arrays are merged per material and all
# expensive construction happens once when entering the village.
func _box(p: Vector3,size: Vector3,key: String,yaw: float=0.0,rotation: Vector3=Vector3.ZERO) -> void:
	var mesh: BoxMesh=BoxMesh.new()
	mesh.size=size
	var basis: Basis=Basis.from_euler(rotation)
	basis=Basis(Vector3.UP,yaw)*basis
	_add_mesh(mesh,Transform3D(basis,p),key)

func _box_t(p: Vector3,size: Vector3,key: String,t: Transform3D) -> void:
	var mesh: BoxMesh=BoxMesh.new()
	mesh.size=size
	_add_mesh(mesh,t*Transform3D(Basis.IDENTITY,p),key)

func _disc(p: Vector3,radius: float,height: float,key: String,sides: int=12,stretch: Vector3=Vector3.ONE) -> void:
	var mesh: CylinderMesh=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=sides
	mesh.rings=1
	_add_mesh(mesh,Transform3D(Basis.IDENTITY.scaled(stretch),p),key)

func _cylinder(p: Vector3,radius: float,height: float,key: String,sides: int=8,rotation: Vector3=Vector3.ZERO) -> void:
	var mesh: CylinderMesh=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=sides
	mesh.rings=1
	_add_mesh(mesh,Transform3D(Basis.from_euler(rotation),p),key)

func _cone(p: Vector3,radius: float,height: float,key: String,sides: int=8,rotation: Vector3=Vector3.ZERO) -> void:
	var mesh: CylinderMesh=CylinderMesh.new()
	mesh.top_radius=0.0
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=sides
	mesh.rings=1
	_add_mesh(mesh,Transform3D(Basis.from_euler(rotation),p),key)

func _sphere(p: Vector3,scale_v: Vector3,key: String,sides: int=8,rings: int=4) -> void:
	_sphere_t(p,scale_v,key,Transform3D.IDENTITY,sides,rings)

func _sphere_t(p: Vector3,scale_v: Vector3,key: String,t: Transform3D,sides: int=8,rings: int=4) -> void:
	var mesh: SphereMesh=SphereMesh.new()
	mesh.radius=1.0
	mesh.height=2.0
	mesh.radial_segments=sides
	mesh.rings=rings
	_add_mesh(mesh,t*Transform3D(Basis.IDENTITY.scaled(scale_v),p),key)

func _ensure_batch(key: String) -> void:
	if not _batches.has(key):
		_batches[key]={"vertices":PackedVector3Array(),"normals":PackedVector3Array(),"uvs":PackedVector2Array(),"colors":PackedColorArray(),"tangents":PackedFloat32Array(),"indices":PackedInt32Array()}

func _world_uv(p: Vector3, n: Vector3, key: String) -> Vector2:
	var tile: float = 1.7
	if key.begins_with("roof"):
		tile = 2.4
	elif key.begins_with("stone"):
		tile = 1.25
	elif key == "paving":
		tile = 2.4
	elif key in ["earth","path","path_edge","grass","grass_light","grass_dark"]:
		tile = 1.8
	if maxf(absf(p.x),absf(p.z)) > 52.0:
		tile = 18.0
	if absf(n.y) >= absf(n.x) and absf(n.y) >= absf(n.z):
		return Vector2(p.x,p.z)/tile
	if absf(n.x) >= absf(n.z):
		return Vector2(p.z,p.y)/tile
	return Vector2(p.x,p.y)/tile

func _world_tangent(n: Vector3) -> PackedFloat32Array:
	var u: Vector3 = Vector3.RIGHT
	var v: Vector3 = Vector3.UP
	if absf(n.y) >= absf(n.x) and absf(n.y) >= absf(n.z):
		v = Vector3.BACK
	elif absf(n.x) >= absf(n.z):
		u = Vector3.BACK
	# Exact dP/du keeps V constant even on a roof sloping in both axes.
	var tangent: Vector3 = v.cross(n).normalized()
	if tangent.dot(u) < 0.0:
		tangent = -tangent
	# Godot OpenGL normal maps use a binormal opposite texture +V.
	var handedness: float = -1.0 if n.cross(tangent).dot(v) >= 0.0 else 1.0
	return PackedFloat32Array([tangent.x,tangent.y,tangent.z,handedness])

func _vertex_tint(p: Vector3, center: Vector3, key: String) -> Color:
	if key == "mountain":
		var altitude: float = clampf(p.y/24.0,0.0,1.0)
		return Color(.76+altitude*.22,.83+altitude*.15,.89+altitude*.09,1.0)
	var grain: float = sin(center.x*3.17+center.z*2.13+center.y*7.31)
	var value: float = 0.97+grain*0.035
	if key in ["grass","grass_light","grass_dark","earth","path","path_edge"]:
		value = 0.97+sin(p.x*.77+p.z*.51)*0.035+cos(p.x*.29-p.z*.83)*0.025
	return Color(value,value,value,1.0)

func _add_mesh(mesh: Mesh,t: Transform3D,key: String) -> void:
	_ensure_batch(key)
	var batch: Dictionary=_batches[key]
	var vertices: PackedVector3Array=batch["vertices"]
	var normals: PackedVector3Array=batch["normals"]
	var indices: PackedInt32Array=batch["indices"]
	var uvs: PackedVector2Array=batch["uvs"]
	var colors: PackedColorArray=batch["colors"]
	var tangents: PackedFloat32Array=batch["tangents"]
	var arrays: Array=mesh.surface_get_arrays(0)
	var source_v: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var source_n: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var source_i: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var source_uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var source_tangent: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
	var curved: bool = (mesh is CylinderMesh or mesh is SphereMesh) and source_uv.size() == source_v.size() and source_tangent.size() == source_v.size()*4
	var dimensions: Vector3 = mesh.get_aabb().size*t.basis.get_scale()
	var curved_uv_scale: Vector2 = Vector2(maxf(dimensions.x,dimensions.z)*PI/1.7,dimensions.y/1.7)
	var offset: int=vertices.size()
	var normal_basis: Basis=t.basis.inverse().transposed()
	for i: int in range(source_v.size()):
		var point: Vector3 = t*source_v[i]
		var normal: Vector3 = (normal_basis*source_n[i]).normalized()
		vertices.append(point)
		normals.append(normal)
		if curved and (mesh is SphereMesh or absf(source_n[i].y)<.95):
			# Preserve continuous cylindrical/spherical UV and its tangent on curved
			# objects. A per-vertex planar projection tears between dominant axes.
			uvs.append(source_uv[i]*curved_uv_scale)
			var tangent: Vector3 = t.basis*Vector3(source_tangent[i*4],source_tangent[i*4+1],source_tangent[i*4+2])
			tangent = (tangent-normal*normal.dot(tangent)).normalized()
			tangents.append_array(PackedFloat32Array([tangent.x,tangent.y,tangent.z,source_tangent[i*4+3]]))
		else:
			uvs.append(_world_uv(point,normal,key))
			tangents.append_array(_world_tangent(normal))
		var vertex_color: Color = _vertex_tint(point,t.origin,key)
		if key == "mountain":
			vertex_color *= .62+maxf(0.0,normal.dot(Vector3(-.40,.78,.47).normalized()))*.38
		colors.append(vertex_color)
	if source_i.is_empty():
		for i: int in range(source_v.size()):
			indices.append(offset+i)
	else:
		for index: int in source_i:
			indices.append(offset+index)
	batch["vertices"]=vertices
	batch["normals"]=normals
	batch["indices"]=indices
	batch["uvs"]=uvs
	batch["colors"]=colors
	batch["tangents"]=tangents

func _tri(a: Vector3,b: Vector3,c: Vector3,key: String,tints: PackedColorArray=PackedColorArray()) -> void:
	_ensure_batch(key)
	var batch: Dictionary=_batches[key]
	var vertices: PackedVector3Array=batch["vertices"]
	var normals: PackedVector3Array=batch["normals"]
	var indices: PackedInt32Array=batch["indices"]
	var uvs: PackedVector2Array=batch["uvs"]
	var colors: PackedColorArray=batch["colors"]
	var tangents: PackedFloat32Array=batch["tangents"]
	var offset: int=vertices.size()
	# Godot's triangle front faces use clockwise winding.
	var normal: Vector3=(c-a).cross(b-a).normalized()
	var triangle_points: Array[Vector3] = [a,b,c]
	for corner: int in range(3):
		var v: Vector3 = triangle_points[corner]
		vertices.append(v)
		normals.append(normal)
		uvs.append(_world_uv(v,normal,key))
		colors.append(_vertex_tint(v,(a+b+c)/3.0,key)*(tints[corner] if tints.size() == 3 else Color.WHITE))
		tangents.append_array(_world_tangent(normal))
	indices.append_array(PackedInt32Array([offset,offset+1,offset+2]))
	batch["vertices"]=vertices
	batch["normals"]=normals
	batch["indices"]=indices
	batch["uvs"]=uvs
	batch["colors"]=colors
	batch["tangents"]=tangents

func _quad(a: Vector3,b: Vector3,c: Vector3,d: Vector3,key: String) -> void:
	_tri(a,b,c,key)
	_tri(a,c,d,key)

func _flush_batches() -> void:
	for key: String in _batches:
		var batch: Dictionary=_batches[key]
		var vertices: PackedVector3Array=batch["vertices"]
		if vertices.is_empty():
			continue
		var arrays: Array=[]
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_NORMAL]=batch["normals"]
		arrays[Mesh.ARRAY_TEX_UV]=batch["uvs"]
		arrays[Mesh.ARRAY_COLOR]=batch["colors"]
		arrays[Mesh.ARRAY_TANGENT]=batch["tangents"]
		arrays[Mesh.ARRAY_INDEX]=batch["indices"]
		var mesh: ArrayMesh=ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var visual: MeshInstance3D=MeshInstance3D.new()
		visual.name="Scenery_"+key
		visual.mesh=mesh
		visual.material_override=_materials[key]
		if key in ["grass","grass_light","grass_dark","earth","path","path_edge","paving","mountain","water","meadow"]:
			visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(visual)
	_batches.clear()

func _solid_box(p: Vector3,size: Vector3,yaw: float=0.0) -> void:
	var shape: BoxShape3D=BoxShape3D.new()
	shape.size=size
	_add_collision(shape,Transform3D(Basis(Vector3.UP,yaw),p))

func _solid_box_t(p: Vector3,size: Vector3,t: Transform3D) -> void:
	var shape: BoxShape3D=BoxShape3D.new()
	shape.size=size
	_add_collision(shape,t*Transform3D(Basis.IDENTITY,p))

func _add_collision(shape: Shape3D,t: Transform3D) -> void:
	var collider: CollisionShape3D=CollisionShape3D.new()
	collider.shape=shape
	collider.transform=t
	_collision.add_child(collider)

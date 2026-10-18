class_name VillageWorld
extends Node3D
## Original hand-built low-poly frontier village. All scenery shares a handful
## of batched meshes so the Android Compatibility renderer stays inexpensive.

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
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _fire: Array[MeshInstance3D] = []
var _fire_light: OmniLight3D
var _banners: Array[Node3D] = []
var _water: MeshInstance3D
var _clock: float = 0.0

func _ready() -> void:
	_rng.seed = 51472026
	_palette()
	_collision = StaticBody3D.new()
	_collision.name = "SceneryCollision"
	add_child(_collision)
	_lighting()
	_landscape()
	_village()
	_forest()
	_flush_batches()
	_create_npc("Mira • Handel", npc_positions["merchant"], false)
	_create_npc("Born • Kowal", npc_positions["blacksmith"], true)
	_ambient_details()

func _palette() -> void:
	_material("grass", "697f45")
	_material("grass_light", "7f8e4b")
	_material("grass_dark", "526741")
	_material("earth", "ae9569")
	_material("path", "c4ab7b")
	_material("path_edge", "b69b6d")
	_material("stone", "777b77")
	_material("stone_light", "9a9b8a")
	_material("stone_dark", "505c59")
	_material("plaster", "e2cba2")
	_material("plaster_light", "efddba")
	_material("plaster_warm", "d4b080")
	_material("wood", "75523b")
	_material("wood_dark", "493d31")
	_material("wood_light", "ae8754")
	_material("roof_blue", "426c73")
	_material("roof_blue_dark", "34545d")
	_material("roof_rust", "a95237")
	_material("roof_rust_dark", "89402e")
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
	_material("flower", "ddb27b")

func _material(key: String, hex: String, emission: float = 0.0) -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color.html(hex)
	mat.roughness = 0.94
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = Color.html(hex)
		mat.emission_energy_multiplier = emission
	_materials[key] = mat

func _lighting() -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.name = "GoldenValleyAtmosphere"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("658da3")
	sky_mat.sky_horizon_color = Color("e9d8b8")
	sky_mat.ground_bottom_color = Color("64705e")
	sky_mat.ground_horizon_color = Color("e1cfab")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c2cfcd")
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color("c1c6ac")
	env.fog_light_energy = 0.6
	env.fog_density = 0.0035
	environment.environment = env
	add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "WarmAfternoonSun"
	sun.rotation_degrees = Vector3(-53, -33, -8)
	sun.light_color = Color("fff0dc")
	sun.light_energy = 0.78
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias = 0.05
	add_child(sun)

func _landscape() -> void:
	_box(Vector3(0, -0.22, 0), Vector3(100, 0.44, 100), "grass")
	_solid_box(Vector3(0, -0.5, 0), Vector3(100, 1, 100))
	# Rounded compacted-earth square, overlapping surfaces suggest worn edges.
	_disc(Vector3(0, 0.014, 2), 14.3, 0.025, "earth", 28, Vector3(1.0, 1.0, 0.94))
	_disc(Vector3(0, 0.03, 2), 11.2, 0.025, "path", 24, Vector3(1.0, 1.0, 0.98))
	_road(Vector3(0, 0, 15), Vector3(0, 0, -18), 4.2)
	_road(Vector3(0, 0, -18), Vector3(-1, 0, -27), 3.3)
	_road(Vector3(-1, 0, -27), Vector3(1, 0, -36), 3.0)
	_road(Vector3(1, 0, -36), Vector3(0, 0, -43), 2.4)
	_road(Vector3(-10, 0, 0), Vector3(10, 0, 0), 3.2)
	for i: int in range(68):
		var pos: Vector3 = Vector3(_rng.randf_range(-43, 43), 0.018, _rng.randf_range(-46, 42))
		if absf(pos.x) < 15 and pos.z > -16 and pos.z < 16:
			continue
		_disc(pos, _rng.randf_range(1.1, 3.5), 0.018, "grass_light" if i % 2 == 0 else "grass_dark", 7, Vector3(1.3, 1, 0.7))
	# Worn cobbles around the village well and the two craft areas.
	for i: int in range(50):
		var a: float = float(i) * 2.39996
		var radius: float = 0.7 + sqrt(float(i) / 50.0) * 3.5
		var p: Vector3 = Vector3(sin(a) * radius, 0.075, cos(a) * radius + 3.6)
		if p.distance_to(spawn_position) > 1.0:
			_box(p, Vector3(0.32 + _rng.randf() * 0.3, 0.07, 0.23 + _rng.randf() * 0.2), "stone_light" if i % 3 else "stone", _rng.randf() * PI)
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

func _road(a: Vector3, b: Vector3, width: float) -> void:
	var middle: Vector3 = (a + b) * 0.5
	var length: float = a.distance_to(b)
	var yaw: float = atan2(b.x - a.x, b.z - a.z)
	_box(middle + Vector3.UP * 0.037, Vector3(width + 0.7, 0.035, length + 0.4), "path_edge", yaw)
	_box(middle + Vector3.UP * 0.059, Vector3(width, 0.035, length + 0.35), "path", yaw)

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

func _roof(t: Transform3D, width: float, depth: float, eave: float, ridge: float, key: String) -> void:
	var a: Vector3 = t * Vector3(-width*0.5,eave,-depth*0.5)
	var b: Vector3 = t * Vector3(-width*0.5,eave,depth*0.5)
	var c: Vector3 = t * Vector3(0,ridge,depth*0.5)
	var d: Vector3 = t * Vector3(0,ridge,-depth*0.5)
	var e: Vector3 = t * Vector3(width*0.5,eave,depth*0.5)
	var f: Vector3 = t * Vector3(width*0.5,eave,-depth*0.5)
	_quad(a,d,c,b,key)
	_quad(d,f,e,c,key + "_dark" if _materials.has(key + "_dark") else key)
	_box_t(Vector3(0,ridge+0.01,0),Vector3(0.18,0.17,depth+0.12),"wood_dark",t)
	# Roof seams become subtle large graphic strokes, not expensive tiny tiles.
	for j: int in range(1,5):
		var ratio: float = float(j)/5.0
		for side: float in [-1.0,1.0]:
			var x: float = width*0.5*ratio*side
			var y: float = lerpf(ridge,eave,ratio)+0.025
			_box_t(Vector3(x,y,0),Vector3(0.035,0.04,depth),key + "_dark" if _materials.has(key + "_dark") else "wood_light",t)

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
		var p: Vector3=Vector3(_rng.randf_range(-39,39),0.09,_rng.randf_range(-43,35))
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

func _tree(p: Vector3,pine: bool,scale_factor: float,solid: bool) -> void:
	var s: float=scale_factor
	_cylinder(p+Vector3.UP*1.55*s,0.16*s,3.1*s,"wood",7)
	if pine:
		for i: int in range(3):
			_cone(p+Vector3.UP*(2.2+float(i)*0.78)*s,(1.3-float(i)*0.27)*s,2.0*s,"pine" if i%2==0 else "pine_light",7)
	else:
		var key: String="leaf_gold" if int(absf(p.x)*7)%3==0 else ("leaf_orange" if int(absf(p.z)*5)%3==0 else "leaf")
		_sphere(p+Vector3(0,3.0,0)*s,Vector3(1.5,1.2,1.3)*s,key,7,4)
		_sphere(p+Vector3(-0.8,2.8,0.18)*s,Vector3(1.0,0.9,0.95)*s,key,7,4)
		_sphere(p+Vector3(0.7,3.2,-0.2)*s,Vector3(1.0,1.05,1.0)*s,key,7,4)
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

func _mountain(p: Vector3,radius: float,height: float,light: bool) -> void:
	var points: Array[Vector3]=[]
	for i: int in range(7):
		var a: float=float(i)/7.0*TAU
		points.append(p+Vector3(cos(a)*radius,0,sin(a)*radius))
	var top: Vector3=p+Vector3(radius*0.12,height,-radius*0.15)
	for i: int in range(7):
		_tri(points[i],points[(i+1)%7],top,"stone_dark" if (i%3==0 or not light) else "stone")

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
	# Gentle looping embers, no particle simulation or transparent fill cost.
	for i: int in range(7):
		var spark: MeshInstance3D=MeshInstance3D.new()
		var mesh: SphereMesh=SphereMesh.new()
		mesh.radius=0.026
		mesh.height=0.052
		mesh.radial_segments=5
		mesh.rings=3
		spark.mesh=mesh
		spark.material_override=_materials["flame"]
		spark.position=Vector3(8.25,1.5+float(i)*0.18,-1.2)
		spark.set_meta("phase",float(i)*0.41)
		spark.add_to_group("village_embers")
		add_child(spark)

func set_low_quality(enabled: bool) -> void:
	for child: Node in get_children():
		if child is DirectionalLight3D:
			(child as DirectionalLight3D).shadow_enabled = not enabled
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
	for node: Node in get_tree().get_nodes_in_group("village_embers"):
		var ember: Node3D=node as Node3D
		var phase: float=float(ember.get_meta("phase"))
		var travel: float=fmod(_clock*0.55+phase,2.0)
		ember.position=Vector3(8.3+sin(travel*4+phase)*0.22,1.25+travel,-1.2+cos(travel*3+phase)*0.2)
		ember.scale=Vector3.ONE*(1.0-travel*0.4)

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
		_batches[key]={"vertices":PackedVector3Array(),"normals":PackedVector3Array(),"indices":PackedInt32Array()}

func _add_mesh(mesh: Mesh,t: Transform3D,key: String) -> void:
	_ensure_batch(key)
	var batch: Dictionary=_batches[key]
	var vertices: PackedVector3Array=batch["vertices"]
	var normals: PackedVector3Array=batch["normals"]
	var indices: PackedInt32Array=batch["indices"]
	var arrays: Array=mesh.surface_get_arrays(0)
	var source_v: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var source_n: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var source_i: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var offset: int=vertices.size()
	var normal_basis: Basis=t.basis.inverse().transposed()
	for i: int in range(source_v.size()):
		vertices.append(t*source_v[i])
		normals.append((normal_basis*source_n[i]).normalized())
	if source_i.is_empty():
		for i: int in range(source_v.size()):
			indices.append(offset+i)
	else:
		for index: int in source_i:
			indices.append(offset+index)
	batch["vertices"]=vertices
	batch["normals"]=normals
	batch["indices"]=indices

func _tri(a: Vector3,b: Vector3,c: Vector3,key: String) -> void:
	_ensure_batch(key)
	var batch: Dictionary=_batches[key]
	var vertices: PackedVector3Array=batch["vertices"]
	var normals: PackedVector3Array=batch["normals"]
	var indices: PackedInt32Array=batch["indices"]
	var offset: int=vertices.size()
	# Godot's triangle front faces use clockwise winding.
	var normal: Vector3=(c-a).cross(b-a).normalized()
	for v: Vector3 in [a,b,c]:
		vertices.append(v)
		normals.append(normal)
	indices.append_array(PackedInt32Array([offset,offset+1,offset+2]))
	batch["vertices"]=vertices
	batch["normals"]=normals
	batch["indices"]=indices

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
		arrays[Mesh.ARRAY_INDEX]=batch["indices"]
		var mesh: ArrayMesh=ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var visual: MeshInstance3D=MeshInstance3D.new()
		visual.name="Scenery_"+key
		visual.mesh=mesh
		visual.material_override=_materials[key]
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

extends Node3D
const FEMALE=preload("res://assets/characters/Superhero_Female_FullBody.gltf")
const MALE=preload("res://assets/characters/Superhero_Male_FullBody.gltf")
const CRATE=preload("res://assets/village/Prop_Crate.gltf")
const FENCE=preload("res://assets/village/Prop_WoodenFence_Single.gltf")
const WAGON=preload("res://assets/village/Prop_Wagon.gltf")
const WALL=preload("res://assets/village/Wall_Plaster_Straight.gltf")
const DOOR=preload("res://assets/village/Wall_Plaster_Door_Round.gltf")
const ROOF=preload("res://assets/village/Roof_RoundTiles_6x6.gltf")
const RETARGETER=preload("res://scripts/retargeter.gd")
const VERSION_TITLE="IDOL — GENESIS 0.8.16 ARM AIM"
const CAMERA_MIN_DISTANCE=5.5
const CAMERA_MAX_DISTANCE=88.0
const CAMERA_HEIGHT_RATIO=0.61
const CAMERA_MIN_HEIGHT=4.2
const CAMERA_MAX_HEIGHT=48.0
const CAMERA_FOCUS_LIMIT=32.0
const STICK_RADIUS=54.0
const STICK_THUMB_RADIUS=27.0
const STICK_DEADZONE=0.14
const BUILD_COST_STICKS=5
const BUILD_COST_STONE=5
const WORKSHOP_COST_STICKS=8
const WORKSHOP_COST_STONE=6
const BUILD_WORK=8.0
const WORKSHOP_BUILD_WORK=11.0
const MAX_BUILD_PLANS=4
const HOME_CAPACITY=4
const CHAPTER_HOUSES_GOAL=3
const CHAPTER_GRANARIES_GOAL=1
const CHAPTER_WORKSHOPS_GOAL=1
const USE_PROCEDURAL_BONE_POSE=true
const STOCKPILE_POS=Vector3(-5.8,0,3.6)
const RESEARCH_POS=Vector3(2.75,0,2.25)
const PAIR_BOND_THRESHOLD=.62
const SELECT_TAP_MAX_MOVE=22.0
const SELECT_SCREEN_RADIUS=92.0
const POPULATION_LIMIT=18
const CHILD_FOOD_COST=12
const LIFE_PROGRESS_GOAL=8.0
const FAMILY_BOND_THRESHOLD=.68
const PERSONAL_SPACE_ADULT=.62
const PERSONAL_SPACE_CHILD=.42
const USE_RETARGETED_ANIMATIONS=false
const USE_PROXY_SETTLER_BODY=false
const USE_SETTLER_ROOT_GEAR=false
const USE_FLOATING_CARGO=false
const USE_HEAD_FACE_ATTACHMENTS=false
const HUMAN_FEMALE_ADULT_SCALE=1.16
const HUMAN_MALE_ADULT_SCALE=1.22
const HUMAN_CHILD_SCALE=.74
const WALK_TURN_SPEED=7.5
const OBSTACLE_CLEARANCE=.62
const CROWD_AVOID_WEIGHT=.7
const OBSTACLE_AVOID_WEIGHT=.74
const OBSTACLE_PUSH_STRENGTH=.42
const STUCK_REPATH_TIME=1.35
const STUCK_MOVE_EPS=.018
const CHAT_INTERVAL_MIN=5.8
const CHAT_INTERVAL_MAX=11.2
const CHAT_GLOBAL_COOLDOWN=2.9
const CHAT_REPLY_COOLDOWN=4.4
const SPEECH_TIME=4.4
const LANGUAGE_GROWTH_PER_CHAT=.055
const SPEECH_LINE_LIMIT=44

var rng=RandomNumberGenerator.new()
var people=[]
var material_cache={}
var stock={"sticks":4,"stone":3,"berries":24}
var buildings={"houses":2,"granaries":0,"workshops":0}
var build_plans=[]
var build_spots=[]
var home_spots=[]
var obstacle_points=[]
var stick_sources=[]
var stone_sources=[]
var berry_sources=[]
var hearth_pos=Vector3(-2.8,0,2.6)
var social_bond=34.0
var discoveries={"OGIEŃ":false,"NARZĘDZIA":false,"MAGAZYN":false,"WIĘZI":false,"OSADA":false,"RODZINA":false}
var discovery_sequence=["OGIEŃ","NARZĘDZIA","MAGAZYN","WIĘZI","OSADA","RODZINA"]
var insight_progress=0.0
var life_progress=0.0
var children_born=0
var global_chat_cd=2.0
var world_env:WorldEnvironment
var sun:DirectionalLight3D
var day_clock=0.22
var tech_points=0
var idol_will=72.0
var order="AUTO"
var selected=0
var notice=""
var notice_timer=0.0
var cam:Camera3D
var cam_focus=Vector3.ZERO
var cam_distance=28.0
var cam_height=17.0
var cam_yaw=0.70
var cam_pitch=0.58
var touches={}
var touch_start={}
var touch_gesture_had_multi=false
var last_pinch_dist=0.0
var last_pinch_angle=0.0
var retargeter
var anim_ready=false
var hud:Label
var info:Label
var chat_feed:Label
var chat_lines=[]
var speech_back_texture
var selected_marker:Node3D
var move_stick=Vector2.ZERO
var rotate_stick=Vector2.ZERO
var move_stick_touch=-1
var rotate_stick_touch=-1
var rotate_stick_panel=Rect2(Vector2(22,520),Vector2(220,176))
var move_stick_panel=Rect2(Vector2(1038,520),Vector2(220,176))
var rotate_stick_center=Vector2(132,608)
var move_stick_center=Vector2(1148,608)
var move_stick_thumb:Control
var rotate_stick_thumb:Control
var names=["Alda","Sela","Mira","Nara","Ena","Eryk","Oren","Bran","Tovan","Milan"]
var child_names=["Lira","Ari","Tala","Nim","Rin","Oda","Uma","Leno"]
var traits=["Pracowita","Odważna","Ciekawska","Śpioch","Spokojna","Silny","Uparty","Myśliciel","Zwinny","Towarzyski"]
var settler_likes=["ogień","rzekę","ciepły dom","zbieranie jagód","ciszę przy drzewach","pracę z kamieniem","budowanie","rozmowy przy ognisku","porządek w składzie","znaki Idola"]
var settler_worries=["głód","noc","ciasne ścieżki","brak wolnego domu","zimno","hałas przy budowie","pusty skład","samotność","kamienie na drodze","gniew Idola"]

func mat(c):
	var key=str(c)
	if material_cache.has(key):
		return material_cache[key]
	var m=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=.95
	if c.a<1.0:
		m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material_cache[key]=m
	return m
func box(p,s,c):
	var n=MeshInstance3D.new(); var b=BoxMesh.new(); b.size=s; n.mesh=b; n.position=p; n.material_override=mat(c); add_child(n); return n
func box_in(parent,p,s,c):
	var n=MeshInstance3D.new(); var b=BoxMesh.new(); b.size=s; n.mesh=b; n.position=p; n.material_override=mat(c); parent.add_child(n); return n
func cyl(p,r,h,c):
	var n=MeshInstance3D.new(); var m=CylinderMesh.new(); m.top_radius=r; m.bottom_radius=r; m.height=h; n.mesh=m; n.position=p; n.material_override=mat(c); add_child(n); return n
func cyl_in(parent,p,r,h,c):
	var n=MeshInstance3D.new(); var m=CylinderMesh.new(); m.top_radius=r; m.bottom_radius=r; m.height=h; n.mesh=m; n.position=p; n.material_override=mat(c); parent.add_child(n); return n
func cone_in(parent,p,r,h,c):
	var n=MeshInstance3D.new(); var m=CylinderMesh.new(); m.top_radius=.02; m.bottom_radius=r; m.height=h; n.mesh=m; n.position=p; n.material_override=mat(c); parent.add_child(n); return n
func sphere(p,r,c):
	var n=MeshInstance3D.new(); var m=SphereMesh.new(); m.radius=r; m.height=r*2.0; n.mesh=m; n.position=p; n.material_override=mat(c); add_child(n); return n
func sphere_in(parent,p,r,c):
	var n=MeshInstance3D.new(); var m=SphereMesh.new(); m.radius=r; m.height=r*2.0; n.mesh=m; n.position=p; n.material_override=mat(c); parent.add_child(n); return n

func add_obstacle(p,radius):
	obstacle_points.append({"pos":p,"radius":radius})

func _ready():
	rng.seed=5302026
	process_priority=80
	world_env=WorldEnvironment.new(); var e=Environment.new()
	e.background_mode=Environment.BG_COLOR; e.background_color=Color("#9fb8bf")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color("#fff0d5"); e.ambient_light_energy=.52
	world_env.environment=e; add_child(world_env)
	sun=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-55,-35,0); sun.light_energy=1.42; sun.shadow_enabled=true; add_child(sun)

	var ground=MeshInstance3D.new(); var pm=PlaneMesh.new(); pm.size=Vector2(68,68); ground.mesh=pm; ground.material_override=mat(Color("#52683d")); add_child(ground)
	make_terrain_layers()
	make_river()
	for i in range(42):
		var p=Vector3(rng.randf_range(-31,31),0,rng.randf_range(-31,31))
		if p.length()<10: continue
		make_tree(p,rng.randf_range(.85,1.22))
	for i in range(26):
		var p=Vector3(rng.randf_range(-30,30),.25,rng.randf_range(-30,30))
		make_rock(p,rng.randf_range(.65,1.25))

	make_idol()
	make_memory_flower()
	make_hearth()
	make_stockpile()
	make_research_stones()
	var home_a=Vector3(-9,0,-7)
	var home_b=Vector3(8,0,-8)
	make_house(home_a,8)
	register_home_spot(home_a)
	make_house(home_b,-12)
	register_home_spot(home_b)
	var wagon=WAGON.instantiate(); wagon.position=Vector3(9,0,3); add_child(wagon)
	for p in [Vector3(-9,0,4),Vector3(-8,0,5.5),Vector3(7,0,6)]:
		var c=CRATE.instantiate(); c.position=p; add_child(c)
	for i in range(7):
		var f=FENCE.instantiate(); f.position=Vector3(-9+i*2.4,0,10); add_child(f)
	make_world_details(home_a,home_b)
	make_camp_clutter()

	for i in range(10): make_person(i)
	make_selection_marker()

	retargeter=RETARGETER.new()
	add_child(retargeter)
	anim_ready=USE_RETARGETED_ANIMATIONS and retargeter.initialize()
	if anim_ready:
		for v in people:
			attach_person_animation(v)

	cam=Camera3D.new(); cam.fov=52; add_child(cam); cam.current=true
	update_camera()
	make_ui()

func make_river():
	for z in range(-30,31,3):
		var x=river_x_at_z(z)
		box(Vector3(x,.02,z),Vector3(6.4,.08,3.25),Color("#5798a5"))
		box(Vector3(x-3.55,.035,z),Vector3(.72,.06,3.1),Color("#74684a"))
		box(Vector3(x+3.55,.035,z),Vector3(.72,.06,3.1),Color("#74684a"))
		if z%9==0:
			make_river_ripple(Vector3(x+rng.randf_range(-1.65,1.65),.09,z+rng.randf_range(-1.0,1.0)),rng.randf_range(-18,18))
		if z%6==0:
			make_rock(Vector3(x-3.95,.18,z+rng.randf_range(-.9,.9)),.45)
			make_rock(Vector3(x+3.95,.18,z+rng.randf_range(-.9,.9)),.42)
		if z%3==0:
			make_reeds(Vector3(x-3.8,.08,z+rng.randf_range(-1.1,1.1)))
			make_reeds(Vector3(x+3.8,.08,z+rng.randf_range(-1.1,1.1)))

func make_tree(p,scale):
	add_obstacle(p,.82*scale)
	var trunk=cyl(p+Vector3(0,1.35*scale,0),.18*scale,2.7*scale,Color("#5f422c"))
	trunk.rotation_degrees=Vector3(rng.randf_range(-3,3),rng.randf_range(0,180),rng.randf_range(-4,4))
	var crown=sphere(p+Vector3(0,3.0*scale,0),.88*scale,Color("#274f2c"))
	crown.scale=Vector3(1.1,.72,1.05)
	var side=sphere(p+Vector3(.32*scale,3.34*scale,-.18*scale),.6*scale,Color("#326238"))
	side.scale=Vector3(.95,.68,.95)
	var top=sphere(p+Vector3(-.2*scale,3.72*scale,.18*scale),.5*scale,Color("#3a743f"))
	top.scale=Vector3(.9,.68,.9)
	top.rotation_degrees.y=rng.randf_range(0,180)
	for a in [0.0,120.0,240.0]:
		var root=box(p+Vector3(cos(deg_to_rad(a))*.28*scale,.12,sin(deg_to_rad(a))*.28*scale),Vector3(.11*scale,.12*scale,.72*scale),Color("#563a27"))
		root.rotation_degrees.y=a+rng.randf_range(-12,12)

func make_rock(p,scale):
	var rock_cols=[Color("#777a72"),Color("#696d68"),Color("#858277"),Color("#6d7069")]
	var r=box(p,Vector3(.75*scale,.38*scale,.62*scale),rock_cols[rng.randi_range(0,rock_cols.size()-1)])
	r.rotation_degrees=Vector3(rng.randf_range(-6,6),rng.randf_range(0,180),rng.randf_range(-5,5))
	return r

func make_ground_patch(p,size,c,rot=0.0):
	var patch=box(Vector3(p.x,.032,p.z),Vector3(size.x,.035,size.y),c)
	patch.rotation_degrees.y=rot
	return patch

func make_terrain_layers():
	var cols=[Color("#5d7046"),Color("#49613b"),Color("#61754b"),Color("#6b6648"),Color("#4d653c")]
	for i in range(38):
		var p=Vector3(rng.randf_range(-31,31),0,rng.randf_range(-31,31))
		if abs(p.x-river_x_at_z(p.z))<4.1:
			continue
		make_ground_patch(p,Vector2(rng.randf_range(4.5,10.0),rng.randf_range(2.8,7.6)),cols[i%cols.size()],rng.randf_range(0,180))
	make_ground_patch(Vector3(-2,0,2),Vector2(11.0,8.0),Color("#665d3f"),8)
	make_ground_patch(Vector3(-6,0,4),Vector2(7.5,5.0),Color("#5d5339"),-13)
	make_ground_patch(Vector3(7,0,-7),Vector2(8.4,5.2),Color("#6a6042"),17)

func make_river_ripple(p,rot):
	var ripple=box(p,Vector3(rng.randf_range(.85,1.7),.018,.045),Color("#b8d8d8"))
	ripple.rotation_degrees.y=rot

func make_reeds(p):
	for i in range(4):
		var blade=cyl(p+Vector3(rng.randf_range(-.18,.18),.36,rng.randf_range(-.18,.18)),.015,.72,Color("#4f6f37"))
		blade.rotation_degrees=Vector3(rng.randf_range(-9,9),rng.randf_range(0,180),rng.randf_range(-7,7))
	if rng.randf()<.45:
		var seed=cyl(p+Vector3(rng.randf_range(-.12,.12),.72,rng.randf_range(-.12,.12)),.028,.18,Color("#6e4d2e"))
		seed.rotation_degrees.x=90

func make_grass_clump(p,scale=1.0):
	var shades=[Color("#6f8a4f"),Color("#78935a"),Color("#5f7c45"),Color("#7f9460")]
	for i in range(rng.randi_range(3,5)):
		var blade=box(p+Vector3(rng.randf_range(-.16,.16),.16*scale,rng.randf_range(-.16,.16)),Vector3(.045*scale,rng.randf_range(.22,.42)*scale,.045*scale),shades[rng.randi_range(0,shades.size()-1)])
		blade.rotation_degrees=Vector3(rng.randf_range(-16,16),rng.randf_range(0,180),rng.randf_range(-16,16))

func make_wildflower(p):
	var stem=cyl(p+Vector3(0,.24,0),.018,.48,Color("#2f7d3d"))
	stem.rotation_degrees.z=rng.randf_range(-5,5)
	var colors=[Color("#e9d76a"),Color("#df6f79"),Color("#f8f2d0")]
	sphere(p+Vector3(0,.52,0),.045,colors[rng.randi_range(0,colors.size()-1)])

func make_path(a,b,width):
	var d=b-a
	var length=max(.1,Vector2(d.x,d.z).length())
	var mid=(a+b)*.5
	var path=box(Vector3(mid.x,.045,mid.z),Vector3(width,.05,length),Color("#756849"))
	path.rotation_degrees.y=rad_to_deg(atan2(d.x,d.z))
	return path

func make_hearth():
	var h=Node3D.new()
	h.name="Krąg wspólnoty"
	h.position=hearth_pos
	add_child(h)
	add_obstacle(hearth_pos,1.45)
	box_in(h,Vector3(0,.04,0),Vector3(4.1,.08,3.7),Color("#65583d"))
	for i in range(10):
		var a=TAU*float(i)/10.0
		var stone=box_in(h,Vector3(cos(a)*1.65,.16,sin(a)*1.38),Vector3(.42,.25,.36),Color("#77776f"))
		stone.rotation_degrees.y=rad_to_deg(a)
	for a in [0.0,90.0]:
		var log=box_in(h,Vector3(0,.24,0),Vector3(.28,.22,1.9),Color("#6b4328"))
		log.rotation_degrees.y=a
	cone_in(h,Vector3(0,.72,0),.42,.95,Color("#d96c2c"))
	cone_in(h,Vector3(.08,.88,.04),.25,.7,Color("#ffd06a"))
	var light=OmniLight3D.new()
	light.position=Vector3(0,1.4,0)
	light.light_color=Color("#ffb05c")
	light.light_energy=.55
	light.omni_range=7.0
	light.shadow_enabled=false
	h.add_child(light)

func make_stockpile():
	var s=Node3D.new()
	s.name="Skład osady"
	s.position=STOCKPILE_POS
	add_child(s)
	add_obstacle(STOCKPILE_POS,2.2)
	box_in(s,Vector3(0,.045,0),Vector3(4.8,.09,3.2),Color("#5f5138"))
	for i in range(4):
		var rack=box_in(s,Vector3(-1.75+i*.45,.32,-.78),Vector3(.12,.25,1.55),Color("#725031"))
		rack.rotation_degrees.y=8*i
	for i in range(6):
		var stick=box_in(s,Vector3(-1.7+i*.45,.55,-.82+rng.randf_range(-.12,.12)),Vector3(.12,.12,1.35),Color("#875d34"))
		stick.rotation_degrees.y=rng.randf_range(-8,8)
	for i in range(5):
		var stone=box_in(s,Vector3(.75+rng.randf_range(-.55,.55),.2,.7+rng.randf_range(-.38,.38)),Vector3(.42,.28,.38),Color("#777a72"))
		stone.rotation_degrees=Vector3(rng.randf_range(-7,7),rng.randf_range(0,180),rng.randf_range(-7,7))
	for x in [-1.05,.05]:
		var basket=cyl_in(s,Vector3(x,.32,.82),.34,.42,Color("#6f4b2c"))
		basket.scale.x=1.25
		for j in range(5):
			sphere_in(s,Vector3(x+rng.randf_range(-.23,.23),.6,rng.randf_range(.66,.98)),.075,Color("#96253d"))
	box_in(s,Vector3(1.78,.88,-.95),Vector3(.12,1.2,.12),Color("#4d3625"))
	box_in(s,Vector3(1.78,1.52,-.95),Vector3(1.15,.52,.1),Color("#c2aa74"))

func make_research_stones():
	var r=Node3D.new()
	r.name="Kamienie odkryć"
	r.position=RESEARCH_POS
	add_child(r)
	add_obstacle(RESEARCH_POS,1.55)
	box_in(r,Vector3(0,.04,0),Vector3(3.1,.08,2.2),Color("#696144"))
	for i in range(4):
		var a=TAU*float(i)/4.0+PI*.25
		var slab=box_in(r,Vector3(cos(a)*1.1,.42,sin(a)*.78),Vector3(.42,.78,.18),Color("#85867b"))
		slab.rotation_degrees.y=rad_to_deg(a)
	for i in range(3):
		var marker=box_in(r,Vector3(-.55+i*.55,.22,-.88),Vector3(.28,.24,.2),Color("#c0a66b"))
		marker.rotation_degrees.y=rng.randf_range(-12,12)
	cone_in(r,Vector3(.08,.82,.1),.23,.52,Color("#e27b36"))
	cone_in(r,Vector3(.08,1.04,.1),.12,.3,Color("#ffd36b"))

func make_workshop(p):
	var w=Node3D.new()
	w.name="Warsztat kamienny"
	w.position=p
	w.rotation_degrees.y=rng.randf_range(-160,160)
	add_child(w)
	add_obstacle(p,3.05)
	box_in(w,Vector3(0,.08,0),Vector3(4.8,.16,3.8),Color("#65573c"))
	for x in [-1.9,1.9]:
		for z in [-1.45,1.45]:
			cyl_in(w,Vector3(x,.82,z),.12,1.65,Color("#5d3d28"))
	var roof_a=box_in(w,Vector3(-.95,1.84,0),Vector3(2.35,.2,4.2),Color("#7a3e22"))
	roof_a.rotation_degrees.z=14
	var roof_b=box_in(w,Vector3(.95,1.84,0),Vector3(2.35,.2,4.2),Color("#7a3e22"))
	roof_b.rotation_degrees.z=-14
	box_in(w,Vector3(-1.15,.38,.75),Vector3(1.6,.38,.75),Color("#755333"))
	for i in range(5):
		var stone=box_in(w,Vector3(.65+rng.randf_range(-.65,.65),.34,.62+rng.randf_range(-.35,.35)),Vector3(.34,.24,.26),Color("#777a72"))
		stone.rotation_degrees=Vector3(rng.randf_range(-8,8),rng.randf_range(0,180),rng.randf_range(-8,8))
	for i in range(4):
		var tool=box_in(w,Vector3(-1.45+i*.38,.72,-.96),Vector3(.08,.08,.82),Color("#604027"))
		tool.rotation_degrees=Vector3(0,rng.randf_range(-18,18),rng.randf_range(18,34))
	box_in(w,Vector3(1.55,.72,-1.06),Vector3(.8,.5,.08),Color("#c5ae78"))
func add_stick_source(p):
	var root=Node3D.new()
	root.name="Patyki"
	root.position=p
	add_child(root)
	for i in range(8):
		var stick=box_in(root,Vector3(rng.randf_range(-.95,.95),.12,rng.randf_range(-.8,.8)),Vector3(.13,.12,rng.randf_range(.85,1.55)),Color("#76512f"))
		stick.rotation_degrees.y=rng.randf_range(0,180)
	sphere_in(root,Vector3(-.75,.3,.55),.18,Color("#3e7c37"))
	stick_sources.append({"pos":p,"node":root})

func add_stone_source(p):
	var root=Node3D.new()
	root.name="Kamienie"
	root.position=p
	add_child(root)
	for i in range(7):
		var stone=box_in(root,Vector3(rng.randf_range(-.85,.85),.17,rng.randf_range(-.75,.75)),Vector3(rng.randf_range(.35,.75),rng.randf_range(.25,.48),rng.randf_range(.35,.72)),Color("#75786f"))
		stone.rotation_degrees=Vector3(rng.randf_range(-9,9),rng.randf_range(0,180),rng.randf_range(-9,9))
	stone_sources.append({"pos":p,"node":root})

func add_berry_source(p):
	var root=Node3D.new()
	root.name="Krzak jagód"
	root.position=p
	add_child(root)
	for i in range(3):
		var bush=cyl_in(root,Vector3(rng.randf_range(-.45,.45),.42,rng.randf_range(-.38,.38)),.42,.72,Color("#2f6730"))
		bush.rotation_degrees.y=rng.randf_range(0,180)
	for i in range(9):
		sphere_in(root,Vector3(rng.randf_range(-.65,.65),rng.randf_range(.62,1.0),rng.randf_range(-.55,.55)),.08,Color("#91233b"))
	berry_sources.append({"pos":p,"node":root})

func make_world_details(home_a,home_b):
	make_path(Vector3.ZERO,hearth_pos,.9)
	make_path(Vector3.ZERO,home_a,1.05)
	make_path(Vector3.ZERO,home_b,1.05)
	make_path(Vector3.ZERO,Vector3(9,0,3),.7)
	make_path(hearth_pos,STOCKPILE_POS,.72)
	make_path(hearth_pos,RESEARCH_POS,.62)
	for p in [Vector3(-19,0,9),Vector3(-17,0,-18),Vector3(18,0,-6),Vector3(4,0,22)]:
		add_stick_source(p)
	for p in [Vector3(15,0,-14),Vector3(18,0,13),Vector3(-22,0,-7),Vector3(3,0,18)]:
		add_stone_source(p)
	for p in [Vector3(-14,0,2),Vector3(15,0,8),Vector3(-5,0,-21),Vector3(21,0,18)]:
		add_berry_source(p)
	for i in range(128):
		var p=Vector3(rng.randf_range(-31,31),.08,rng.randf_range(-31,31))
		if p.length()<4.0 or abs(p.x-river_x_at_z(p.z))<3.9:
			continue
		make_grass_clump(p,rng.randf_range(.72,1.18))
	for i in range(34):
		var p=Vector3(rng.randf_range(-28,28),.08,rng.randf_range(-28,28))
		if p.length()<5.0 or abs(p.x-river_x_at_z(p.z))<4.2:
			continue
		make_wildflower(p)

func make_camp_clutter():
	for i in range(8):
		var a=TAU*float(i)/8.0
		var seat=box(hearth_pos+Vector3(cos(a)*3.25,.18,sin(a)*2.7),Vector3(.58,.24,.24),Color("#68472c"))
		seat.rotation_degrees.y=rad_to_deg(a)+90
	for i in range(7):
		var p=STOCKPILE_POS+Vector3(rng.randf_range(-2.1,2.1),.14,rng.randf_range(-1.55,1.55))
		var scrap=box(p,Vector3(rng.randf_range(.45,.95),.11,.13),Color("#7a5634"))
		scrap.rotation_degrees.y=rng.randf_range(0,180)
	var rack=Node3D.new()
	rack.name="Suszarnia skór"
	rack.position=Vector3(-6.8,0,7.0)
	rack.rotation_degrees.y=-18
	add_child(rack)
	for x in [-.85,.85]:
		var post=box_in(rack,Vector3(x,.75,0),Vector3(.13,1.5,.13),Color("#5b3d28"))
		post.rotation_degrees.z=6*x
	box_in(rack,Vector3(0,1.45,0),Vector3(1.95,.12,.12),Color("#62422b"))
	var hide=box_in(rack,Vector3(0,.86,.03),Vector3(1.35,.8,.055),Color("#7c5b3d"))
	hide.rotation_degrees.z=4
	for p in [Vector3(-4.0,0,6.5),Vector3(-5.2,0,1.1),Vector3(2.4,0,3.0)]:
		cyl(p+Vector3(0,.34,0),.035,.68,Color("#4d3625"))
		cone_in(self,p+Vector3(0,.86,0),.16,.36,Color("#d56a2c"))

func make_idol():
	add_obstacle(Vector3.ZERO,2.35)
	box(Vector3(0,.18,0),Vector3(3.0,.36,2.35),Color("#5f615b"))
	box(Vector3(0,.58,0),Vector3(2.35,.42,1.75),Color("#707167"))
	box(Vector3(0,2.05,0),Vector3(1.45,3.0,1.05),Color("#77786f"))
	box(Vector3(0,3.78,0),Vector3(1.12,.82,.9),Color("#85867b"))
	box(Vector3(-.38,3.88,-.49),Vector3(.18,.16,.08),Color("#20231e"))
	box(Vector3(.38,3.88,-.49),Vector3(.18,.16,.08),Color("#20231e"))
	box(Vector3(0,3.54,-.5),Vector3(.58,.08,.06),Color("#34352f"))
	for y in [1.15,1.75,2.35]:
		var scar=box(Vector3(rng.randf_range(-.42,.42),y,-.54),Vector3(.08,.55,.055),Color("#575951"))
		scar.rotation_degrees.z=rng.randf_range(-22,22)
	for i in range(12):
		var a=TAU*float(i)/12.0
		var stone=box(Vector3(cos(a)*2.15,.12,sin(a)*1.72),Vector3(.42,.24,.34),Color("#686b64"))
		stone.rotation_degrees.y=rad_to_deg(a)
	var glow=OmniLight3D.new()
	glow.position=Vector3(0,2.8,-.7)
	glow.light_color=Color("#f0d28a")
	glow.light_energy=.22
	glow.omni_range=4.4
	glow.shadow_enabled=false
	add_child(glow)

func make_memory_flower():
	var root=Vector3(1.55,0,-1.25)
	cyl(root+Vector3(0,.38,0),.035,.76,Color("#2f7d3d"))
	var leaf=box(root+Vector3(.12,.28,0),Vector3(.24,.055,.08),Color("#3a8f46"))
	leaf.rotation_degrees.z=-25
	var head=root+Vector3(0,.86,0)
	sphere(head, .07, Color("#f0c957"))
	sphere(head+Vector3(-.11,.065,0), .095, Color("#f8f8f4"))
	sphere(head+Vector3(.11,.065,0), .095, Color("#f8f8f4"))
	sphere(head+Vector3(-.11,-.085,0), .095, Color("#c92232"))
	sphere(head+Vector3(.11,-.085,0), .095, Color("#c92232"))

func make_selection_marker():
	selected_marker=Node3D.new()
	selected_marker.name="Znacznik wybranego"
	add_child(selected_marker)
	var disk=cyl_in(selected_marker,Vector3(0,.035,0),.92,.045,Color("#d9bd58"))
	disk.scale.x=1.25
	var core=cyl_in(selected_marker,Vector3(0,.07,0),.24,.05,Color("#f2e59a"))
	core.scale.x=1.25
	update_selection_marker()

func update_selection_marker():
	if not selected_marker or people.is_empty():
		return
	selected=int(clamp(selected,0,people.size()-1))
	var n:Node3D=people[selected].node
	selected_marker.position=Vector3(n.position.x,.04,n.position.z)
	selected_marker.rotation_degrees.y+=1.2

func select_person_at_screen(pos):
	if not cam or people.is_empty():
		return false
	var best=-1
	var best_dist=SELECT_SCREEN_RADIUS
	for i in range(people.size()):
		var n:Node3D=people[i].node
		var world=n.global_position+Vector3(0,1.25,0)
		if cam.is_position_behind(world):
			continue
		var screen=cam.unproject_position(world)
		var dist=screen.distance_to(pos)
		if dist<best_dist:
			best=i
			best_dist=dist
	if best>=0:
		selected=best
		var v=people[selected]
		set_notice("Dotyk Idola: %s — %s" % [v.name,v.trait])
		update_selection_marker()
		return true
	return false

func make_house(p,rot):
	var h=Node3D.new(); h.position=p; h.rotation_degrees.y=rot; h.scale=Vector3(1.05,1.05,1.05); add_child(h)
	add_obstacle(p,3.15)
	box_in(h,Vector3(0,.08,-.42),Vector3(4.9,.16,4.35),Color("#65583d"))
	var a=WALL.instantiate(); a.position=Vector3(-1.8,0,0); h.add_child(a)
	var b=WALL.instantiate(); b.position=Vector3(1.8,0,0); h.add_child(b)
	var d=DOOR.instantiate(); d.position=Vector3(0,0,-3.5); d.rotation_degrees.y=180; h.add_child(d)
	var r=ROOF.instantiate(); r.position=Vector3(0,3,-1.5); r.scale=Vector3(.65,.65,.65); h.add_child(r)
	box_in(h,Vector3(0,3.63,-1.5),Vector3(.16,.18,4.3),Color("#5b3924"))
	for x in [-2.25,2.25]:
		box_in(h,Vector3(x,1.1,-2.7),Vector3(.14,2.0,.14),Color("#5d3d28"))
	box_in(h,Vector3(0,.16,-3.92),Vector3(1.85,.22,.72),Color("#766b54"))
	box_in(h,Vector3(0,.5,-3.98),Vector3(1.35,.2,.18),Color("#4d3423"))
	for i in range(4):
		var pebble=box_in(h,Vector3(rng.randf_range(-2.1,2.1),.2,rng.randf_range(-2.5,1.65)),Vector3(.28,.16,.24),Color("#75776d"))
		pebble.rotation_degrees.y=rng.randf_range(0,180)
	return h

func make_granary(p):
	add_obstacle(p,2.9)
	box(p+Vector3(0,.18,0),Vector3(4.4,.35,3.4),Color("#6b5034"))
	for x in [-1.8,1.8]:
		for z in [-1.35,1.35]:
			cyl(p+Vector3(x,.95,z),.12,1.9,Color("#5b3924"))
	var roof_a=box(p+Vector3(-.9,2.15,0),Vector3(2.2,.22,3.9),Color("#8a3f22"))
	roof_a.rotation_degrees.z=18
	var roof_b=box(p+Vector3(.9,2.15,0),Vector3(2.2,.22,3.9),Color("#8a3f22"))
	roof_b.rotation_degrees.z=-18
	for i in range(4):
		var c=CRATE.instantiate(); c.position=p+Vector3(-1.35+i*.9,.36,.25); c.scale=Vector3(.8,.8,.8); add_child(c)
	box(p+Vector3(0,1.2,-1.75),Vector3(2.0,.75,.22),Color("#c9b27a"))
	box(p+Vector3(0,1.2,-1.89),Vector3(1.7,.12,.08),Color("#3d2a1b"))

func make_build_site(p,kind):
	var site=Node3D.new()
	site.name="Plan budowy "+kind
	site.position=p
	add_child(site)
	add_obstacle(p,2.65)
	box_in(site,Vector3(0,.05,0),Vector3(4.7,.1,3.9),Color("#9b875e"))
	box_in(site,Vector3(-2.0,.22,-1.5),Vector3(.55,.35,.55),Color("#686a64"))
	box_in(site,Vector3(2.0,.22,1.5),Vector3(.55,.35,.55),Color("#686a64"))
	box_in(site,Vector3(-.7,.18,1.55),Vector3(1.2,.2,.35),Color("#6b4328"))
	box_in(site,Vector3(.75,.18,-1.55),Vector3(1.3,.2,.35),Color("#6b4328"))
	box_in(site,Vector3(0,.26,0),Vector3(3.7,.08,.16),Color("#dfd0a4"))
	box_in(site,Vector3(0,.26,.42),Vector3(2.6,.08,.16),Color("#dfd0a4"))
	var bar_bg=box_in(site,Vector3(0,.42,-2.15),Vector3(3.8,.11,.16),Color("#2e2c24"))
	bar_bg.name="ProgressBg"
	var bar=box_in(site,Vector3(-1.8,.5,-2.15),Vector3(3.6,.13,.2),Color("#f0d45a"))
	bar.name="ProgressBar"
	bar.scale.x=.04
	var frame_a=box_in(site,Vector3(-1.65,.85,0),Vector3(.18,1.25,.18),Color("#6b4328"))
	frame_a.name="StagePostA"
	frame_a.visible=false
	var frame_b=box_in(site,Vector3(1.65,.85,0),Vector3(.18,1.25,.18),Color("#6b4328"))
	frame_b.name="StagePostB"
	frame_b.visible=false
	var beam=box_in(site,Vector3(0,1.52,0),Vector3(3.7,.18,.2),Color("#7f5330"))
	beam.name="StageBeam"
	beam.visible=false
	if kind=="WARSZTAT":
		box_in(site,Vector3(1.35,.2,.95),Vector3(1.0,.22,.55),Color("#6a6d67"))
		box_in(site,Vector3(-1.32,.24,-.86),Vector3(1.2,.18,.22),Color("#7c5430"))
		for i in range(3):
			var tool=box_in(site,Vector3(-.4+i*.34,.36,-.9),Vector3(.08,.08,.7),Color("#5c402a"))
			tool.rotation_degrees.z=25
	elif kind=="SPICHLERZ":
		cyl_in(site,Vector3(1.2,.3,.82),.28,.36,Color("#6f4b2c"))
		cyl_in(site,Vector3(1.62,.3,.76),.24,.34,Color("#6f4b2c"))
	return site

func find_skeleton(n:Node)->Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var x=find_skeleton(c)
		if x:
			return x
	return null

func cache_pose_bones(sk:Skeleton3D):
	var bones={}
	if not sk:
		return bones
	for bone_name in ["spine_01","spine_02","spine_03","neck_01","Head","clavicle_l","clavicle_r","upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","hand_l","hand_r","thigh_l","thigh_r","calf_l","calf_r","foot_l","foot_r","ball_l","ball_r"]:
		bones[bone_name]=sk.find_bone(bone_name)
	return bones

func cache_pose_bone_rotations(sk:Skeleton3D,bones:Dictionary):
	var rotations={}
	if not sk:
		return rotations
	for bone_name in bones.keys():
		var idx=int(bones[bone_name])
		if idx>=0:
			rotations[bone_name]=sk.get_bone_pose_rotation(idx)
	return rotations

func make_person_label(parent,text,pos,font_size,color,pixel_size=.00305,outline_size=4,fixed_size=false):
	var l=Label3D.new()
	l.text=text
	l.position=pos
	l.font_size=font_size
	l.pixel_size=pixel_size
	l.modulate=color
	l.outline_size=outline_size
	l.outline_modulate=Color(0,0,0,.96)
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test=true
	l.fixed_size=fixed_size
	parent.add_child(l)
	return l

func get_speech_back_texture():
	if speech_back_texture:
		return speech_back_texture
	var w=340
	var h=78
	var img=Image.create(w,h,false,Image.FORMAT_RGBA8)
	var fill=Color(.075,.085,.082,.74)
	var border=Color(.92,.96,.88,.38)
	for y in range(h):
		for x in range(w):
			var edge=x<3 or y<3 or x>=w-3 or y>=h-3
			var pad=x<6 or y<6 or x>=w-6 or y>=h-6
			img.set_pixel(x,y,border if edge else (fill if not pad else fill.darkened(.08)))
	speech_back_texture=ImageTexture.create_from_image(img)
	return speech_back_texture

func make_speech_backdrop(parent,pos):
	var n=Sprite3D.new()
	n.texture=get_speech_back_texture()
	n.position=pos+Vector3(0,0,.012)
	n.pixel_size=.0043
	n.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	n.no_depth_test=true
	n.fixed_size=false
	n.visible=false
	parent.add_child(n)
	return n

func short_speech(actor,msg):
	var text="%s: %s" % [actor.name,msg]
	var limit=SPEECH_LINE_LIMIT if is_adult(actor) else SPEECH_LINE_LIMIT-6
	if text.length()>limit:
		text=text.substr(0,limit-3)+"..."
	var wrap_at=24
	if text.length()>wrap_at:
		var cut=text.rfind(" ",wrap_at)
		if cut>10:
			text=text.substr(0,cut)+"\n"+text.substr(cut+1)
	return text

func speech_lane_offset(seed:int):
	var lane=seed%4
	if lane==0:
		return Vector3(-.18,0,0)
	if lane==1:
		return Vector3(.18,.12,0)
	if lane==2:
		return Vector3(-.1,.24,0)
	return Vector3(.1,.36,0)

func hide_imported_visuals(root):
	for c in root.get_children():
		if c is MeshInstance3D:
			c.visible=false
		hide_imported_visuals(c)

func make_limb(parent,pos,radius,height,color):
	var limb=cyl_in(parent,pos,radius,height,color)
	return limb

func make_settler_body(parent,i,is_child=false):
	var body=Node3D.new()
	body.name="Ciało osadnika"
	parent.add_child(body)
	var skin=Color("#c98d62") if i%2==0 else Color("#d0a078")
	var skin_dark=Color("#a77351")
	var cloth=Color("#262b30") if i%2==0 else Color("#2f3034")
	var body_scale=1.0
	body.scale=Vector3(body_scale,body_scale,body_scale)
	var hips=box_in(body,Vector3(0,.58,0),Vector3(.34,.22,.22),cloth)
	hips.name="hips"
	var torso=cyl_in(body,Vector3(0,1.0,0),.18,.68,skin)
	torso.name="torso"
	torso.scale.x=1.18
	var chest=box_in(body,Vector3(0,1.05,-.06),Vector3(.42,.48,.12),skin)
	chest.name="chest"
	var neck=cyl_in(body,Vector3(0,1.36,0),.055,.16,skin_dark)
	neck.name="neck"
	var head=sphere_in(body,Vector3(0,1.52,-.035),.16,skin)
	head.name="head"
	head.scale=Vector3(.92,1.05,.86)
	var arm_l=make_limb(body,Vector3(-.29,.94,0),.04,.72,skin)
	arm_l.name="arm_l"
	arm_l.rotation_degrees=Vector3(0,0,-11)
	var arm_r=make_limb(body,Vector3(.29,.94,0),.04,.72,skin)
	arm_r.name="arm_r"
	arm_r.rotation_degrees=Vector3(0,0,11)
	var hand_l=sphere_in(body,Vector3(-.37,.54,-.02),.055,skin)
	hand_l.name="hand_l"
	var hand_r=sphere_in(body,Vector3(.37,.54,-.02),.055,skin)
	hand_r.name="hand_r"
	var leg_l=make_limb(body,Vector3(-.105,.24,0),.052,.58,skin)
	leg_l.name="leg_l"
	var leg_r=make_limb(body,Vector3(.105,.24,0),.052,.58,skin)
	leg_r.name="leg_r"
	var foot_l=box_in(body,Vector3(-.105,-.06,-.07),Vector3(.12,.055,.22),skin_dark)
	foot_l.name="foot_l"
	var foot_r=box_in(body,Vector3(.105,-.06,-.07),Vector3(.12,.055,.22),skin_dark)
	foot_r.name="foot_r"
	var skirt=box_in(body,Vector3(0,.47,-.025),Vector3(.46,.22,.16),cloth.darkened(.08))
	skirt.name="lower_cloth"
	return {"body":body,"torso":torso,"head":head,"arm_l":arm_l,"arm_r":arm_r,"hand_l":hand_l,"hand_r":hand_r,"leg_l":leg_l,"leg_r":leg_r,"foot_l":foot_l,"foot_r":foot_r}

func make_settler_face(parent,i):
	var skin_shadow=Color("#9d6a48")
	var dark=Color("#191613")
	var eye_y=1.45
	var face_z=-.235
	var left_eye=sphere_in(parent,Vector3(-.055,eye_y,face_z),.024,dark)
	left_eye.scale=Vector3(.8,.58,.36)
	var right_eye=sphere_in(parent,Vector3(.055,eye_y,face_z),.024,dark)
	right_eye.scale=Vector3(.8,.58,.36)
	var nose=box_in(parent,Vector3(0,1.39,face_z-.018),Vector3(.028,.075,.024),skin_shadow)
	nose.rotation_degrees.x=-8
	var mouth=box_in(parent,Vector3(0,1.325,face_z-.02),Vector3(.09,.014,.018),Color("#4a241d"))
	if i%2==0:
		mouth.rotation_degrees.z=3
	else:
		mouth.rotation_degrees.z=-3

func make_head_face(sk:Skeleton3D,i):
	if not sk or sk.find_bone("Head")<0:
		return
	var face=BoneAttachment3D.new()
	face.name="Twarz"
	face.bone_name="Head"
	sk.add_child(face)
	var skin_shadow=Color("#a8704f")
	var dark=Color("#14110f")
	var eye_l=sphere_in(face,Vector3(-.038,.022,-.118),.012,dark)
	eye_l.scale=Vector3(1.05,.72,.5)
	var eye_r=sphere_in(face,Vector3(.038,.022,-.118),.012,dark)
	eye_r.scale=Vector3(1.05,.72,.5)
	var nose=box_in(face,Vector3(0,-.018,-.128),Vector3(.018,.048,.014),skin_shadow)
	nose.rotation_degrees.x=-6
	var mouth=box_in(face,Vector3(0,-.064,-.126),Vector3(.054,.008,.012),Color("#40201a"))
	mouth.rotation_degrees.z=2 if i%2==0 else -2

func make_settler_gear(parent,i):
	var gear=Node3D.new()
	gear.name="Ubranie osadnika"
	parent.add_child(gear)
	var cloth_cols=[Color("#7c5b38"),Color("#6b6740"),Color("#8a6a3c"),Color("#6d5841"),Color("#7d4f35")]
	var col=cloth_cols[i%cloth_cols.size()]
	var hair_cols=[Color("#2d211a"),Color("#4a2f1e"),Color("#6b4628"),Color("#1f1b18")]
	var hair=hair_cols[i%hair_cols.size()]
	var belt=cyl_in(gear,Vector3(0,.64,0),.18,.055,Color("#3b2a1f"))
	belt.rotation_degrees.y=rng.randf_range(-18,18)
	var strap=box_in(gear,Vector3(.04,.93,-.18),Vector3(.058,.62,.046),Color("#3f2b1d"))
	strap.rotation_degrees.z=-23 if i%2==0 else 23
	box_in(gear,Vector3(0,.52,-.15),Vector3(.34,.35,.045),col)
	box_in(gear,Vector3(0,.38,-.13),Vector3(.28,.28,.05),col.darkened(.12))
	var pouch=box_in(gear,Vector3(.17,.58,-.18),Vector3(.095,.12,.05),Color("#4e3523"))
	pouch.rotation_degrees.z=-8
	make_settler_face(gear,i)
	var hair_cap=sphere_in(gear,Vector3(0,1.525,-.035),.095,hair)
	hair_cap.scale=Vector3(1.05,.36,.78)
	if i%3==0:
		var tail=sphere_in(gear,Vector3(0,1.37,.13),.052,hair)
		tail.scale=Vector3(.76,1.18,.72)
	if i%4==0:
		cyl_in(gear,Vector3(0,1.47,-.18),.095,.026,Color("#d5c083"))

func make_carry_node(parent):
	var cargo=Node3D.new()
	cargo.name="Ładunek"
	cargo.position=Vector3(.19,.69,-.2)
	cargo.scale=Vector3(.72,.72,.72)
	parent.add_child(cargo)
	if not USE_FLOATING_CARGO:
		cargo.visible=false
		return cargo
	var sticks=Node3D.new()
	sticks.name="sticks"
	cargo.add_child(sticks)
	for i in range(2):
		var stick=box_in(sticks,Vector3(0,.035*i,0),Vector3(.045,.045,.46),Color("#8a5c32"))
		stick.rotation_degrees=Vector3(0,-15+i*22,0)
	var stone=Node3D.new()
	stone.name="stone"
	cargo.add_child(stone)
	var rock=box_in(stone,Vector3(0,.04,0),Vector3(.18,.13,.16),Color("#7b7d76"))
	rock.rotation_degrees=Vector3(-7,28,5)
	var berries=Node3D.new()
	berries.name="berries"
	cargo.add_child(berries)
	cyl_in(berries,Vector3(0,.02,0),.11,.08,Color("#6f4b2c"))
	for i in range(3):
		sphere_in(berries,Vector3(-.05+i*.05,.085,0),.028,Color("#98243d"))
	set_carry_visual(cargo,"")
	return cargo

func set_carry_visual(cargo,kind):
	if not cargo:
		return
	if not USE_FLOATING_CARGO:
		cargo.visible=false
		return
	cargo.visible=kind!=""
	for c in cargo.get_children():
		c.visible=String(c.name)==kind

func make_person(i):
	var sex="K" if i<5 else "M"
	var n=(FEMALE if sex=="K" else MALE).instantiate()
	var scale_value=HUMAN_FEMALE_ADULT_SCALE if sex=="K" else HUMAN_MALE_ADULT_SCALE
	var base_scale=Vector3(scale_value,scale_value,scale_value)
	n.scale=base_scale
	var a=TAU*i/10.0; n.position=Vector3(cos(a)*rng.randf_range(5,10),0,sin(a)*rng.randf_range(5,10)); add_child(n)
	var body_parts={}
	if USE_PROXY_SETTLER_BODY:
		hide_imported_visuals(n)
		body_parts=make_settler_body(n,i,false)
	if USE_SETTLER_ROOT_GEAR:
		make_settler_gear(n,i)
	var sk=find_skeleton(n)
	var bones=cache_pose_bones(sk)
	var pose_bases=cache_pose_bone_rotations(sk,bones)
	if USE_HEAD_FACE_ATTACHMENTS:
		make_head_face(sk,i)
	var lane=speech_lane_offset(i)
	var label_y=1.88+lane.y*.25
	var speech_y=2.08+lane.y
	var name_label=make_person_label(n,names[i],Vector3(lane.x*.45,label_y,0),15,Color("#fff0bc"),.00305,4,false)
	var speech_back=make_speech_backdrop(n,Vector3(lane.x,speech_y,0))
	var speech_label=make_person_label(n,"",Vector3(lane.x,speech_y-.005,-.02),16,Color("#ffffff"),.0032,7,false)
	speech_label.visible=false
	var cargo=make_carry_node(n)
	var v={"node":n,"skeleton":sk,"bones":bones,"pose_bases":pose_bases,"base_scale":base_scale,"phase":rng.randf_range(0,TAU),"pose_style":rng.randf_range(-1.0,1.0),"work_timer":0.0,"rest_time":rng.randf_range(1.5,3.6),"name":names[i],"trait":traits[i],"like":settler_likes[i%settler_likes.size()],"worry":settler_worries[(i*3)%settler_worries.size()],"sex":sex,"age":rng.randi_range(18,34),"adult":true,"parent_a":-1,"parent_b":-1,"family_cd":rng.randf_range(8.0,18.0),"bond":rng.randf_range(.28,.62),"partner":-1,"str":rng.randi_range(3,9),"dex":rng.randi_range(3,9),"int":rng.randi_range(3,9),"hunger":rng.randf_range(5,25),"energy":rng.randf_range(72,100),"wood":0.0,"gather":0.0,"build":0.0,"knowledge":0.0,"language":rng.randf_range(.28,.46),"last_xz":Vector2(n.position.x,n.position.z),"stuck_time":0.0,"job":"IDLE","carry":"","cargo":cargo,"target":n.position}
	v["body_parts"]=body_parts
	v["name_label"]=name_label
	v["speech_back"]=speech_back
	v["speech_label"]=speech_label
	v["speech_timer"]=0.0
	v["chat_cd"]=rng.randf_range(CHAT_INTERVAL_MIN,CHAT_INTERVAL_MAX)
	people.append(v)
	return v

func attach_person_animation(v):
	if anim_ready and retargeter and v.has("node"):
		v["anim"]=retargeter.attach(v.node)

func next_child_name():
	var base=child_names[children_born%child_names.size()]
	if children_born>=child_names.size():
		return "%s %d" % [base,int(children_born/child_names.size())+2]
	return base

func make_birth_marker(pos,child_name):
	var root=Node3D.new()
	root.name="Kołyska "+child_name
	root.position=pos+Vector3(.65,0,.35)
	add_child(root)
	box_in(root,Vector3(0,.13,0),Vector3(.9,.18,.48),Color("#6a472d"))
	box_in(root,Vector3(-.48,.3,0),Vector3(.08,.42,.52),Color("#7b5636"))
	box_in(root,Vector3(.48,.3,0),Vector3(.08,.42,.52),Color("#7b5636"))
	box_in(root,Vector3(0,.37,0),Vector3(.72,.08,.38),Color("#d8c08a"))
	sphere_in(root,Vector3(-.2,.49,-.02),.13,Color("#d1a071"))
	var flag=box_in(root,Vector3(.52,.7,.18),Vector3(.05,.7,.05),Color("#4b3324"))
	flag.rotation_degrees.z=-6
	box_in(root,Vector3(.72,.95,.18),Vector3(.34,.2,.04),Color("#f5f0d2"))

func spawn_child(parent_a_idx,parent_b_idx):
	if parent_a_idx<0 or parent_b_idx<0 or parent_a_idx>=people.size() or parent_b_idx>=people.size():
		return null
	if people.size()>=POPULATION_LIMIT or stock.berries<CHILD_FOOD_COST:
		return null
	var parent_a=people[parent_a_idx]
	var parent_b=people[parent_b_idx]
	var sex="K" if rng.randf()<.5 else "M"
	var n=(FEMALE if sex=="K" else MALE).instantiate()
	var base_scale=Vector3(HUMAN_CHILD_SCALE,HUMAN_CHILD_SCALE,HUMAN_CHILD_SCALE)
	n.scale=base_scale
	var center=(parent_a.node.position+parent_b.node.position)*.5
	n.position=center+Vector3(rng.randf_range(-.75,.75),0,rng.randf_range(-.75,.75))
	add_child(n)
	var body_parts={}
	if USE_PROXY_SETTLER_BODY:
		hide_imported_visuals(n)
		body_parts=make_settler_body(n,children_born+2,true)
	var child_name=next_child_name()
	if USE_SETTLER_ROOT_GEAR:
		make_settler_gear(n,children_born+2)
	var sk=find_skeleton(n)
	var bones=cache_pose_bones(sk)
	var pose_bases=cache_pose_bone_rotations(sk,bones)
	if USE_HEAD_FACE_ATTACHMENTS:
		make_head_face(sk,children_born+2)
	var lane=speech_lane_offset(children_born+2)
	var label_y=1.84+lane.y*.25
	var speech_y=2.04+lane.y
	var name_label=make_person_label(n,child_name,Vector3(lane.x*.45,label_y,0),13,Color("#fff0bc"),.00305,4,false)
	var speech_back=make_speech_backdrop(n,Vector3(lane.x,speech_y,0))
	var speech_label=make_person_label(n,"",Vector3(lane.x,speech_y-.005,-.02),15,Color("#ffffff"),.00315,6,false)
	speech_label.visible=false
	var cargo=make_carry_node(n)
	var v={"node":n,"skeleton":sk,"bones":bones,"pose_bases":pose_bases,"base_scale":base_scale,"phase":rng.randf_range(0,TAU),"pose_style":rng.randf_range(-.8,.8),"work_timer":0.0,"rest_time":rng.randf_range(1.8,3.8),"name":child_name,"trait":"Dziecko osady","like":settler_likes[(children_born+4)%settler_likes.size()],"worry":settler_worries[(children_born+5)%settler_worries.size()],"sex":sex,"age":1,"adult":false,"parent_a":parent_a_idx,"parent_b":parent_b_idx,"family_cd":0.0,"bond":rng.randf_range(.62,.78),"partner":-1,"str":rng.randi_range(1,3),"dex":rng.randi_range(2,5),"int":rng.randi_range(2,5),"hunger":rng.randf_range(0,12),"energy":rng.randf_range(82,100),"wood":0.0,"gather":0.0,"build":0.0,"knowledge":0.0,"language":rng.randf_range(.22,.38),"last_xz":Vector2(n.position.x,n.position.z),"stuck_time":0.0,"job":"DZIECKO","carry":"","cargo":cargo,"target":n.position}
	v["body_parts"]=body_parts
	v["name_label"]=name_label
	v["speech_back"]=speech_back
	v["speech_label"]=speech_label
	v["speech_timer"]=0.0
	v["chat_cd"]=rng.randf_range(CHAT_INTERVAL_MIN,CHAT_INTERVAL_MAX)
	people.append(v)
	children_born+=1
	stock.berries=max(0,stock.berries-CHILD_FOOD_COST)
	parent_a.family_cd=42.0
	parent_b.family_cd=42.0
	parent_a.bond=min(1.0,parent_a.bond+.05)
	parent_b.bond=min(1.0,parent_b.bond+.05)
	social_bond=min(100.0,social_bond+4.5)
	attach_person_animation(v)
	assign_job(v,"DZIECKO",family_point(v))
	make_birth_marker(n.position,child_name)
	selected=people.size()-1
	update_selection_marker()
	check_discoveries()
	set_notice("Narodziny: %s. Osada ma nowe pokolenie." % child_name)
	return v

func layout_camera_sticks():
	var vp=get_viewport().get_visible_rect().size
	var panel_w=clamp(float(vp.x)*.172,206.0,224.0)
	var panel_h=clamp(float(vp.y)*.244,164.0,182.0)
	var margin=22.0
	var y=float(vp.y)-panel_h-18.0
	rotate_stick_panel=Rect2(Vector2(margin,y),Vector2(panel_w,panel_h))
	move_stick_panel=Rect2(Vector2(float(vp.x)-panel_w-margin,y),Vector2(panel_w,panel_h))
	rotate_stick_center=rotate_stick_panel.position+rotate_stick_panel.size*.5
	move_stick_center=move_stick_panel.position+move_stick_panel.size*.5

func make_ui():
	layout_camera_sticks()
	var layer=CanvasLayer.new(); add_child(layer)
	var bg=ColorRect.new(); bg.position=Vector2(14,14); bg.size=Vector2(520,132); bg.color=Color(0.02,0.02,0.015,.82); layer.add_child(bg)
	hud=Label.new(); hud.position=Vector2(27,25); hud.add_theme_font_size_override("font_size",12); layer.add_child(hud)
	var vp=get_viewport().get_visible_rect().size
	var menu_w=356.0
	var menu=VBoxContainer.new(); menu.position=Vector2(float(vp.x)-menu_w-22.0,16); menu.size=Vector2(menu_w,258); menu.add_theme_constant_override("separation",3); layer.add_child(menu)
	var title=Label.new(); title.text="ROZKAZY I MOCE IDOLA"; title.add_theme_font_size_override("font_size",15); menu.add_child(title)
	var grid=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",5); grid.add_theme_constant_override("v_separation",2); menu.add_child(grid)
	for s in ["AUTO","PATYKI","KAMIEŃ","JAGODY","ZGROMADZENIE","ODKRYCIA","DOM 5/5","SPICHLERZ 5/5","WARSZTAT 8/6"]:
		var cmd=s
		var b=Button.new(); b.text=cmd; b.custom_minimum_size=Vector2(172,24); b.pressed.connect(func(): set_order(cmd)); grid.add_child(b)
	var next_btn=Button.new(); next_btn.text="OSOBA +"; next_btn.custom_minimum_size=Vector2(172,24); next_btn.pressed.connect(func(): cycle_selected()); grid.add_child(next_btn)
	for s in ["KAMERA OS.","PRZYWOŁAJ","BŁOGOSŁAW","WIĘŹ +","KRĄG ŻYCIA"]:
		var action=s
		var b=Button.new(); b.text=action; b.custom_minimum_size=Vector2(172,24); b.pressed.connect(func(): handle_idol_action(action)); grid.add_child(b)
	var ibg=ColorRect.new(); ibg.position=Vector2(14,158); ibg.size=Vector2(430,192); ibg.color=Color(0.02,0.02,0.015,.66); layer.add_child(ibg)
	info=Label.new(); info.position=Vector2(28,168); info.add_theme_font_size_override("font_size",11); layer.add_child(info)
	var chat_bg=ColorRect.new(); chat_bg.position=Vector2(float(vp.x)*.282,float(vp.y)-156.0); chat_bg.size=Vector2(float(vp.x)*.436,130); chat_bg.color=Color(0.035,0.04,0.036,.76); layer.add_child(chat_bg)
	chat_feed=Label.new(); chat_feed.position=chat_bg.position+Vector2(12,7); chat_feed.size=chat_bg.size-Vector2(22,12); chat_feed.add_theme_font_size_override("font_size",13); chat_feed.add_theme_color_override("font_color",Color("#f7fff6")); chat_feed.add_theme_constant_override("outline_size",1); chat_feed.add_theme_color_override("font_outline_color",Color(0,0,0,.96)); chat_feed.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; chat_feed.clip_text=true; chat_feed.text="ROZMOWY OSADY\n..."; layer.add_child(chat_feed)
	make_camera_sticks(layer)

func make_round_panel(pos,size,fill,border):
	var p=Panel.new()
	p.position=pos
	p.size=size
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var st=StyleBoxFlat.new()
	st.bg_color=fill
	st.border_color=border
	st.border_width_left=2
	st.border_width_top=2
	st.border_width_right=2
	st.border_width_bottom=2
	st.corner_radius_top_left=int(size.x*.5)
	st.corner_radius_top_right=int(size.x*.5)
	st.corner_radius_bottom_left=int(size.x*.5)
	st.corner_radius_bottom_right=int(size.x*.5)
	p.add_theme_stylebox_override("panel",st)
	return p

func make_touch_panel(pos,size):
	var p=Panel.new()
	p.position=pos
	p.size=size
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var st=StyleBoxFlat.new()
	st.bg_color=Color(0.02,0.02,0.015,.34)
	st.border_color=Color(1,1,1,.24)
	st.border_width_left=2
	st.border_width_top=2
	st.border_width_right=2
	st.border_width_bottom=2
	st.corner_radius_top_left=18
	st.corner_radius_top_right=18
	st.corner_radius_bottom_left=18
	st.corner_radius_bottom_right=18
	p.add_theme_stylebox_override("panel",st)
	return p

func make_stick_label(layer,center,text):
	var l=Label.new()
	l.text=text
	l.position=center+Vector2(-88,59)
	l.size=Vector2(176,22)
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",13)
	l.modulate=Color(1,1,1,.86)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(l)

func make_camera_sticks(layer):
	layer.add_child(make_touch_panel(rotate_stick_panel.position,rotate_stick_panel.size))
	layer.add_child(make_round_panel(rotate_stick_center-Vector2(62,62),Vector2(124,124),Color(0.02,0.02,0.015,.23),Color(1,1,1,.22)))
	rotate_stick_thumb=make_round_panel(rotate_stick_center-Vector2(STICK_THUMB_RADIUS,STICK_THUMB_RADIUS),Vector2(STICK_THUMB_RADIUS*2.0,STICK_THUMB_RADIUS*2.0),Color(1,1,1,.42),Color(1,1,1,.68))
	layer.add_child(rotate_stick_thumb)
	make_stick_label(layer,rotate_stick_center,"OBRÓT KAMERY")
	layer.add_child(make_touch_panel(move_stick_panel.position,move_stick_panel.size))
	layer.add_child(make_round_panel(move_stick_center-Vector2(62,62),Vector2(124,124),Color(0.02,0.02,0.015,.23),Color(1,1,1,.22)))
	move_stick_thumb=make_round_panel(move_stick_center-Vector2(STICK_THUMB_RADIUS,STICK_THUMB_RADIUS),Vector2(STICK_THUMB_RADIUS*2.0,STICK_THUMB_RADIUS*2.0),Color(1,1,1,.42),Color(1,1,1,.68))
	layer.add_child(move_stick_thumb)
	make_stick_label(layer,move_stick_center,"PORUSZANIE")

func open_plan_count():
	var count=0
	for p in build_plans:
		if not p.done:
			count+=1
	return count

func set_notice(msg):
	notice=msg
	notice_timer=3.0

func cycle_selected():
	if people.is_empty():
		return
	selected=(selected+1)%people.size()
	var v=people[selected]
	set_notice("Wybrano: %s — %s" % [v.name,v.trait])
	update_selection_marker()

func selected_person():
	if people.is_empty():
		return null
	selected=int(clamp(selected,0,people.size()-1))
	return people[selected]

func spend_will(cost,label):
	if idol_will<cost:
		set_notice("%s wymaga Woli %.0f" % [label,cost])
		return false
	idol_will=max(0.0,idol_will-cost)
	return true

func handle_idol_action(action):
	if action=="KAMERA OS.":
		focus_selected_person()
	elif action=="PRZYWOŁAJ":
		recall_selected_person()
	elif action=="BŁOGOSŁAW":
		bless_selected_person()
	elif action=="WIĘŹ +":
		nudge_selected_bond()
	elif action=="KRĄG ŻYCIA":
		kindle_life_circle()

func focus_selected_person():
	var v=selected_person()
	if v==null:
		return
	var n:Node3D=v.node
	cam_focus=Vector3(n.position.x,0,n.position.z)
	update_camera()
	set_notice("Kamera śledzi: %s" % v.name)

func recall_selected_person():
	var v=selected_person()
	if v==null or not spend_will(7.0,"Przywołanie"):
		return
	v.carry=""
	set_carry_visual(v.cargo,"")
	assign_job(v,"WSPÓLNOTA",meeting_point(v))
	v.bond=min(1.0,v.bond+.025)
	set_notice("%s słyszy wezwanie Idola" % v.name)

func bless_selected_person():
	var v=selected_person()
	if v==null or not spend_will(16.0,"Błogosławieństwo"):
		return
	v.energy=min(100.0,v.energy+28.0)
	v.hunger=max(0.0,v.hunger-24.0)
	v.bond=min(1.0,v.bond+.035)
	v.knowledge+=.06
	set_notice("%s dostaje siłę od Idola" % v.name)

func nudge_selected_bond():
	var v=selected_person()
	if v==null or not spend_will(20.0,"Wpływ na więź"):
		return
	v.bond=min(1.0,v.bond+.13)
	assign_job(v,"WSPÓLNOTA",meeting_point(v))
	var candidate_idx=find_pair_candidate(v)
	if candidate_idx>=0:
		var other=people[candidate_idx]
		other.bond=min(1.0,other.bond+.08)
	try_form_pair(v)
	set_notice("Idol wzmacnia więź: %s" % v.name)

func kindle_life_circle():
	if count_pairs()<1:
		set_notice("Krąg życia wymaga pierwszej pary")
		return
	if not spend_will(30.0,"Krąg życia"):
		return
	for v in people:
		if is_adult(v) and v.partner!=-1:
			v.bond=min(1.0,v.bond+.035)
			assign_job(v,"WSPÓLNOTA",meeting_point(v))
	social_bond=min(100.0,social_bond+3.0)
	life_progress=min(LIFE_PROGRESS_GOAL,life_progress+2.6)
	var pair=find_family_pair()
	if can_raise_child() and not pair.is_empty() and life_progress>=LIFE_PROGRESS_GOAL:
		life_progress=0.0
		spawn_child(pair[0],pair[1])
	else:
		set_notice("Krąg życia wzmacnia rodziny. %s" % family_summary())

func building_cost(kind):
	if kind=="WARSZTAT":
		return {"sticks":WORKSHOP_COST_STICKS,"stone":WORKSHOP_COST_STONE,"work":WORKSHOP_BUILD_WORK}
	return {"sticks":BUILD_COST_STICKS,"stone":BUILD_COST_STONE,"work":BUILD_WORK}

func resource_capacity(kind):
	var cap=34+buildings.granaries*18
	if discoveries["MAGAZYN"]:
		cap+=18
	if kind=="berries":
		cap+=10
	return cap

func add_stock(kind,amount):
	stock[kind]=min(resource_capacity(kind),stock[kind]+amount)

func discovery_text():
	var unlocked=PackedStringArray()
	for key in discovery_sequence:
		if discoveries[key]:
			unlocked.append(key)
	if unlocked.size()==0:
		return "brak"
	return ", ".join(unlocked)

func unlock_discovery(key,msg):
	if discoveries[key]:
		return
	discoveries[key]=true
	tech_points+=1
	make_discovery_marker(key)
	set_notice(msg)

func make_discovery_marker(key):
	var idx=discovery_sequence.find(key)
	var a=TAU*float(max(idx,0))/float(discovery_sequence.size())
	var p=RESEARCH_POS+Vector3(cos(a)*1.55,0,sin(a)*1.1)
	var col=Color("#f2d36b")
	if key=="NARZĘDZIA":
		col=Color("#b8c4c8")
	elif key=="MAGAZYN":
		col=Color("#c99a54")
	elif key=="WIĘZI":
		col=Color("#d46f75")
	elif key=="OSADA":
		col=Color("#7fc37d")
	elif key=="RODZINA":
		col=Color("#f2a3b3")
	cyl(p+Vector3(0,.28,0),.08,.55,Color("#4f3828"))
	sphere(p+Vector3(0,.66,0),.18,col)

func check_discoveries():
	if not discoveries["OGIEŃ"] and social_bond>=42.0:
		unlock_discovery("OGIEŃ","Odkrycie: wspólny ogień. Ludzie lepiej odpoczywają.")
	if not discoveries["NARZĘDZIA"] and (insight_progress>=6.0 or buildings.workshops>0):
		unlock_discovery("NARZĘDZIA","Odkrycie: narzędzia kamienne. Zbiory i budowa są sprawniejsze.")
	if not discoveries["MAGAZYN"] and buildings.granaries>=1:
		unlock_discovery("MAGAZYN","Odkrycie: magazynowanie. Skład mieści więcej zapasów.")
	if not discoveries["WIĘZI"] and count_pairs()>=1:
		unlock_discovery("WIĘZI","Odkrycie: pierwsze pary. Osada zaczyna mieć pamięć relacji.")
	if not discoveries["OSADA"] and buildings.houses>=CHAPTER_HOUSES_GOAL and buildings.granaries>=CHAPTER_GRANARIES_GOAL and buildings.workshops>=CHAPTER_WORKSHOPS_GOAL:
		unlock_discovery("OSADA","Rozdział I ustabilizowany: domy, zapas i warsztat działają.")
	if not discoveries["RODZINA"] and children_born>=1:
		unlock_discovery("RODZINA","Odkrycie: rodzina. Osada ma pierwsze nowe pokolenie.")

func active_plan_number(plan):
	var count=0
	for p in build_plans:
		if not p.done:
			count+=1
			if p==plan:
				return count
	return 0

func get_active_plan():
	for p in build_plans:
		if not p.done:
			return p
	return null

func get_active_funded_plan():
	for p in build_plans:
		if not p.done and p.funded:
			return p
	return null

func count_workers(job_name):
	var count=0
	for v in people:
		if v.has("job") and v.job==job_name:
			count+=1
	return count

func worker_summary():
	return "Załoga: P%d K%d J%d B%d D%d W%d O%d R%d Dz%d" % [count_workers("PATYKI"),count_workers("KAMIEŃ"),count_workers("JAGODY"),count_workers("BUDOWA"),count_workers("DOSTAWA"),count_workers("WSPÓLNOTA"),count_workers("ODKRYCIA"),count_workers("ODPOCZYNEK"),count_workers("DZIECKO")]

func shelter_capacity():
	return buildings.houses*HOME_CAPACITY

func sheltered_people():
	return min(people.size(),shelter_capacity())

func average_bond():
	if people.is_empty():
		return 0.0
	var total=0.0
	for v in people:
		total+=v.bond
	return total/float(people.size())

func count_pairs():
	var pairs=0
	for v in people:
		if v.partner!=-1:
			pairs+=1
	return int(pairs/2)

func is_adult(v):
	return (not v.has("adult")) or v.adult

func count_adults():
	var count=0
	for v in people:
		if is_adult(v):
			count+=1
	return count

func count_children():
	var count=0
	for v in people:
		if not is_adult(v):
			count+=1
	return count

func life_progress_percent():
	return int(round(clamp(life_progress/LIFE_PROGRESS_GOAL,0.0,1.0)*100.0))

func person_name_at(idx):
	if idx>=0 and idx<people.size():
		return people[idx].name
	return "brak"

func partner_name(v):
	if v.partner>=0 and v.partner<people.size():
		return person_name_at(v.partner)
	return "brak"

func family_label(v):
	if is_adult(v):
		return "Para: "+partner_name(v)
	return "Rodzice: %s + %s" % [person_name_at(v.parent_a),person_name_at(v.parent_b)]

func carry_label(kind):
	if kind=="sticks":
		return "patyki"
	if kind=="stone":
		return "kamień"
	if kind=="berries":
		return "jagody"
	return "brak"

func flat_actor_distance(a,b):
	var pa:Vector3=a.node.position
	var pb:Vector3=b.node.position
	return Vector2(pa.x,pa.z).distance_to(Vector2(pb.x,pb.z))

func actor_language(v):
	return clamp(float(v.get("language",.1)),0.0,1.0)

func actor_like(v):
	return String(v.get("like","ogień"))

func actor_worry(v):
	return String(v.get("worry","głód"))

func language_stage(a,b):
	var speech=(actor_language(a)+actor_language(b))*.5
	if speech<.18:
		return 0
	if speech<.42:
		return 1
	if speech<.68:
		return 2
	return 3

func remembered_place(v):
	if v.job=="PATYKI":
		return "przy drzewach"
	if v.job=="KAMIEŃ":
		return "na kamienisku"
	if v.job=="JAGODY":
		return "przy krzakach jagód"
	if v.job=="BUDOWA":
		return "na budowie"
	if v.job=="ODKRYCIA":
		return "przy kamieniach odkryć"
	if v.job=="WSPÓLNOTA":
		return "przy ognisku"
	return "w środku osady"

func task_word(job):
	if job=="PATYKI":
		return "patyki"
	if job=="KAMIEŃ":
		return "kamień"
	if job=="JAGODY":
		return "jagody"
	if job=="BUDOWA":
		return "budowę"
	if job=="ODKRYCIA":
		return "znaki"
	if job=="WSPÓLNOTA":
		return "ognisko"
	if job=="ODPOCZYNEK":
		return "odpoczynek"
	return "osadę"

func speech_topic(a,b):
	var topics=[
		"%s lubi %s, a %s woli %s" % [a.name,actor_like(a),b.name,actor_like(b)],
		"%s martwi się o %s" % [a.name,actor_worry(a)],
		"zapas w składzie",
		"drogę bez tłoku",
		"dom przed nocą",
		"znaki Idola",
		"podział pracy"
	]
	return topics[rng.randi_range(0,topics.size()-1)]

func advanced_agreement_line(a,b):
	var lines=[
		"Lubię %s, ale dziś pilnuję: %s." % [actor_like(a),task_word(a.job)],
		"Ty lubisz %s, ja %s. Po pracy spotkajmy się przy ogniu." % [actor_like(b),actor_like(a)],
		"Jeśli %s nas blokuje, zmieńmy trasę i nie wchodźmy sobie pod nogi." % actor_worry(a),
		"Zapamiętajmy: %s ma pierwszeństwo, potem %s." % [task_word(a.job),task_word(b.job)],
		"Widzę, że %s pomaga osadzie; zróbmy to spokojnie." % actor_like(b),
		"Najpierw zapas, potem dom. Głodni ludzie gorzej myślą.",
		"Przy %s jest mniej tłoku, tam pójdę następnym razem." % remembered_place(a),
		"Niech każde z nas weźmie inną drogę, wtedy skład szybciej się napełni."
	]
	return lines[rng.randi_range(0,lines.size()-1)]

func advanced_friction_line(a,b):
	var lines=[
		"Nie zgadzam się: %s robi tu za duży tłok." % remembered_place(b),
		"Boisz się o %s, a ja o %s. Musimy wybrać ważniejsze." % [actor_worry(a),actor_worry(b)],
		"Rozkaz Idola jest dobry, ale kolejność pracy blokuje przejście.",
		"Nie stój przy budowie, gdy ktoś niesie kamień. Tracimy czas.",
		"Jeśli każdy idzie po %s, zabraknie rąk do reszty." % task_word(a.job),
		"Nie rozumiem twojego planu. Powiedz krócej: kto niesie, kto buduje?"
	]
	return lines[rng.randi_range(0,lines.size()-1)]

func improve_language(a,b,positive):
	var relation_boost=.65+average_bond()*.55
	var gain=LANGUAGE_GROWTH_PER_CHAT*(1.0 if positive else .38)*relation_boost
	a.language=clamp(actor_language(a)+gain*(.78+float(a.int)*.025),0.0,1.0)
	b.language=clamp(actor_language(b)+gain*(.64+float(b.int)*.02),0.0,1.0)

func chat_partner_for(v):
	if v.partner>=0 and v.partner<people.size():
		var partner=people[v.partner]
		if flat_actor_distance(v,partner)<7.5:
			return partner
	var best=null
	var best_dist=5.8
	for other in people:
		if other.node==v.node:
			continue
		var dist=flat_actor_distance(v,other)
		if dist<best_dist:
			best=other
			best_dist=dist
	return best

func chat_line_for(a,b,positive):
	var stage=language_stage(a,b)
	if not positive:
		var friction=[]
		if stage==0:
			friction=["Nie tędy.","Stop. Za blisko.","Nie rozum.","Kamień boli."]
		elif stage==1:
			friction=["Nie tak. Zróbmy inaczej.","Za ciasno tu, odsuń się.","Nie rozumiem tego zadania.","Idol patrzy, ale ja mam wątpliwość."]
		elif stage==2:
			friction=["Jeśli wszyscy idą w środek, nikt nie kończy pracy.","Najpierw zróbmy miejsce, potem nośmy zapas.","Nie zgadzam się: ten plan blokuje drogę.","Rozkaz Idola dobry, ale kolejność pracy zła."]
		else:
			return advanced_friction_line(a,b)
		return friction[rng.randi_range(0,friction.size()-1)]
	if a.job==b.job and a.job!="IDLE":
		if a.job=="BUDOWA":
			if stage==0:
				return "Ty belka. Ja kamień."
			if stage==1:
				return "Ty trzymaj belki, ja układam kamień."
			if stage==2:
				return "Najpierw fundament, potem ściana. Tak dom stanie mocniej."
			return "Ja pilnuję fundamentu, ty zostaw przejście na kamień i patyki."
		if a.job in ["PATYKI","KAMIEŃ","JAGODY"]:
			if stage==0:
				return "Bierz. Do składu."
			if stage==1:
				return "Zbierzmy to razem i zanieśmy do składu."
			if stage==2:
				return "Zrobimy dwa kursy: ty bliżej rzeki, ja przy drzewach."
			return "Ta robota mi pasuje, bo lubię %s. Ty sprawdź drugą stronę." % actor_like(a)
		if a.job=="WSPÓLNOTA":
			return "Ogień trzyma ludzi razem." if stage<2 else ("Przy ogniu ustalimy, kto buduje, a kto niesie zapas." if stage==2 else "Przy ogniu pogadamy o %s i wybierzemy lepszy podział." % speech_topic(a,b))
		if a.job=="ODKRYCIA":
			return "Patrz na znaki." if stage==0 else ("Może kamień pomaga patykom." if stage==1 else ("Jeśli kamień ostrzy patyk, praca będzie szybsza." if stage==2 else "Nazwijmy to narzędziem: pamięć osady będzie wiedzieć, po co ostrzymy kamień."))
	if a.carry!="":
		return "%s do składu." % carry_label(a.carry).capitalize() if stage==0 else ("Niosę %s. Zrób mi przejście." % carry_label(a.carry) if stage<3 else "Niosę %s do składu; jeśli droga jest pełna, obejdę przez %s." % [carry_label(a.carry),remembered_place(a)])
	if not is_adult(a):
		return "Uczę się." if stage==0 else ("Patrzę i uczę się osady." if stage<3 else "Słucham was i zapamiętuję, że %s jest ważne." % actor_like(a))
	if a.partner==people.find(b):
		return "Razem." if stage==0 else ("Trzymajmy się razem." if stage==1 else ("Ty i ja mamy dom do zbudowania, ale najpierw zapas." if stage==2 else "Chcę domu blisko %s, z tobą i spokojnym zapasem na noc." % actor_like(a)))
	var lines=[]
	if stage==0:
		lines=["Ja tu. Ty tam.","Patyk. Kamień. Dom.","Idol mówi.","Razem łatwiej."]
	elif stage==1:
		lines=["Ja biorę jedną robotę, ty drugą.","Osada rośnie, musimy się dzielić pracą.","Najpierw zapas, potem domy.","Słyszałeś rozkaz Idola?"]
	elif stage==2:
		lines=["Jeśli rozdzielimy pracę, dom powstanie przed nocą.","Najpierw nakarmimy głodnych, potem ruszymy z budową.","Widzę dobrą drogę obok rzeki, tam będzie mniej tłoku.","Uczymy się mówić prościej, żeby praca szła szybciej."]
	else:
		return advanced_agreement_line(a,b)
	return lines[rng.randi_range(0,lines.size()-1)]

func refresh_chat_feed():
	if not chat_feed:
		return
	if chat_lines.is_empty():
		chat_feed.text="ROZMOWY OSADY\n..."
		return
	var packed=PackedStringArray()
	for line in chat_lines:
		packed.append(line)
	chat_feed.text="ROZMOWY OSADY\n"+"\n".join(packed)

func hide_speech_bubble(v):
	if v.has("speech_label") and is_instance_valid(v.speech_label):
		v.speech_label.visible=false
	if v.has("speech_back") and is_instance_valid(v.speech_back):
		v.speech_back.visible=false
	v.speech_timer=0.0

func clear_other_speech_bubbles(active):
	for v in people:
		if v!=active:
			hide_speech_bubble(v)

func post_chat(a,b,msg,positive):
	var state="zgoda" if positive else "spór"
	var line="%s -> %s [%s]: %s" % [a.name,b.name,state,msg]
	if line.length()>108:
		line=line.substr(0,105)+"..."
	chat_lines.insert(0,line)
	while chat_lines.size()>5:
		chat_lines.pop_back()
	clear_other_speech_bubbles(a)
	if a.has("speech_label") and is_instance_valid(a.speech_label):
		a.speech_label.text=short_speech(a,msg)
		a.speech_label.visible=true
		a.speech_timer=SPEECH_TIME
	if a.has("speech_back") and is_instance_valid(a.speech_back):
		a.speech_back.visible=true
	b.chat_cd=max(float(b.get("chat_cd",0.0)),CHAT_REPLY_COOLDOWN)
	if positive:
		a.bond=min(1.0,a.bond+.01)
		b.bond=min(1.0,b.bond+.008)
		social_bond=min(100.0,social_bond+.08)
	else:
		social_bond=max(0.0,social_bond-.035)
	improve_language(a,b,positive)
	refresh_chat_feed()

func update_settler_chat(d):
	if global_chat_cd>0.0:
		global_chat_cd=max(0.0,global_chat_cd-d)
	for v in people:
		if not v.has("chat_cd"):
			v.chat_cd=rng.randf_range(CHAT_INTERVAL_MIN,CHAT_INTERVAL_MAX)
		if v.has("speech_timer") and v.speech_timer>0.0:
			v.speech_timer=max(0.0,v.speech_timer-d)
			if v.speech_timer<=0.0 and v.has("speech_label") and is_instance_valid(v.speech_label):
				v.speech_label.visible=false
				if v.has("speech_back") and is_instance_valid(v.speech_back):
					v.speech_back.visible=false
		v.chat_cd-=d
		if v.chat_cd<=0.0 and global_chat_cd<=0.0:
			var partner=chat_partner_for(v)
			if partner!=null:
				var same_job=v.job==partner.job and v.job!="IDLE"
				var chance=clamp(.48+v.bond*.26+social_bond*.002+( .12 if same_job else 0.0),.18,.92)
				var positive=rng.randf()<chance
				post_chat(v,partner,chat_line_for(v,partner,positive),positive)
				global_chat_cd=CHAT_GLOBAL_COOLDOWN
			v.chat_cd=rng.randf_range(CHAT_INTERVAL_MIN,CHAT_INTERVAL_MAX)

func family_point(v):
	var idx=people.find(v)
	var base=hearth_pos
	if not is_adult(v) and v.parent_a>=0 and v.parent_b>=0 and v.parent_a<people.size() and v.parent_b<people.size():
		base=(people[v.parent_a].node.position+people[v.parent_b].node.position)*.5
	elif is_adult(v) and v.partner>=0 and v.partner<people.size():
		base=(v.node.position+people[v.partner].node.position)*.5
	elif not home_spots.is_empty():
		base=home_spots[max(0,idx)%home_spots.size()]
	var a=TAU*float(max(0,idx))/max(1.0,float(people.size()))
	return base+Vector3(cos(a)*1.35,0,sin(a)*1.05)

func find_family_pair():
	var best=[]
	var best_score=-1.0
	for i in range(people.size()):
		var a=people[i]
		if not is_adult(a) or a.partner<0:
			continue
		var j=int(a.partner)
		if j<=i or j>=people.size():
			continue
		var b=people[j]
		if not is_adult(b):
			continue
		if a.family_cd>0.0 or b.family_cd>0.0:
			continue
		var bond=(a.bond+b.bond)*.5
		if bond<FAMILY_BOND_THRESHOLD:
			continue
		var score=bond+float(a.int+b.int)*.012
		if score>best_score:
			best_score=score
			best=[i,j]
	return best

func can_raise_child():
	if not discoveries["WIĘZI"]:
		return false
	if people.size()>=POPULATION_LIMIT:
		return false
	if shelter_capacity()<=people.size():
		return false
	if stock.berries<CHILD_FOOD_COST:
		return false
	if social_bond<56.0:
		return false
	return count_pairs()>0

func family_summary():
	var state="gotowe"
	if count_pairs()<1:
		state="brak pary"
	elif shelter_capacity()<=people.size():
		state="brak miejsca w domu"
	elif stock.berries<CHILD_FOOD_COST:
		state="mało jagód"
	elif social_bond<56.0:
		state="słaba wspólnota"
	elif find_family_pair().is_empty():
		state="para potrzebuje czasu"
	return "Rodzina: dzieci %d/%d | życie %d%% | %s" % [count_children(),POPULATION_LIMIT-count_adults(),life_progress_percent(),state]

func update_life_growth(d):
	for v in people:
		if is_adult(v) and v.family_cd>0.0:
			v.family_cd=max(0.0,v.family_cd-d)
	if not can_raise_child():
		life_progress=max(0.0,life_progress-d*.1)
		return
	var pair=find_family_pair()
	if pair.is_empty():
		life_progress=max(0.0,life_progress-d*.035)
		return
	var a=people[pair[0]]
	var b=people[pair[1]]
	var warmth=(a.bond+b.bond)*.5+social_bond/100.0+float(count_pairs())*.08
	if order=="ZGROMADZENIE":
		warmth+=.16
	life_progress+=d*warmth*.22
	if life_progress>=LIFE_PROGRESS_GOAL:
		life_progress=0.0
		spawn_child(pair[0],pair[1])

func chapter_goal():
	if buildings.houses<CHAPTER_HOUSES_GOAL:
		return "Cel: postaw 3 domy i 1 spichlerz"
	if buildings.granaries<CHAPTER_GRANARIES_GOAL:
		return "Cel: zbuduj pierwszy spichlerz"
	if not discoveries["NARZĘDZIA"]:
		return "Cel: odkryj narzędzia kamienne"
	if buildings.workshops<CHAPTER_WORKSHOPS_GOAL:
		return "Cel: zbuduj pierwszy warsztat"
	if children_born<1:
		return "Cel: utrzymaj parę, wolny dom i 12 jagód dla dziecka"
	return "Cel rozdziału: pierwsza rodzina, zapas i narzędzia"

func register_build_spot(p):
	build_spots.append(p)

func register_home_spot(p):
	home_spots.append(p)
	register_build_spot(p)

func river_x_at_z(z):
	return 8+sin(z*.17)*5

func is_build_pos_clear(p):
	if p.length()<7.5:
		return false
	if abs(p.x-river_x_at_z(p.z))<4.8:
		return false
	for spot in build_spots:
		if Vector2(spot.x,spot.z).distance_to(Vector2(p.x,p.z))<7.0:
			return false
	for plan in build_plans:
		if not plan.done and Vector2(plan.pos.x,plan.pos.z).distance_to(Vector2(p.x,p.z))<6.5:
			return false
	return true

func pick_source_point(sources,radius):
	if sources.is_empty():
		return Vector3(rng.randf_range(-18,18),0,rng.randf_range(-18,18))
	var source=sources[rng.randi_range(0,sources.size()-1)]
	var a=rng.randf_range(0,TAU)
	var r=rng.randf_range(.25,radius)
	return source.pos+Vector3(cos(a)*r,0,sin(a)*r)

func person_index(v):
	return max(0,people.find(v))

func keep_point_outside_obstacles(p,extra=.45):
	var result=p
	for ob in obstacle_points:
		var center:Vector3=ob.pos
		var delta=Vector3(result.x-center.x,0,result.z-center.z)
		var dist=delta.length()
		var limit=float(ob.radius)+extra
		if dist<.001:
			delta=Vector3(1,0,0)
			dist=1.0
		if dist<limit:
			var pushed=center+delta.normalized()*limit
			result.x=pushed.x
			result.z=pushed.z
	return result

func spaced_ring_point(base,idx,rx,rz,twist=0.0):
	var safe_idx=max(0,idx)
	var ring=int(floor(float(safe_idx)/8.0))
	var slot=safe_idx%8
	var a=TAU*float(slot)/8.0+twist+float(ring)*.37
	var ring_rx=rx+float(ring)*.78
	var ring_rz=rz+float(ring)*.56
	return keep_point_outside_obstacles(base+Vector3(cos(a)*ring_rx,0,sin(a)*ring_rz))

func meeting_point(v):
	return spaced_ring_point(hearth_pos,person_index(v),2.75,2.25,.15)

func depot_point(v):
	return spaced_ring_point(STOCKPILE_POS,person_index(v),3.05,2.15,.55)

func research_point(v):
	return spaced_ring_point(RESEARCH_POS,person_index(v),2.35,1.75,.9)

func rest_point(v):
	var idx=person_index(v)
	if not home_spots.is_empty():
		var home=home_spots[idx%home_spots.size()]
		return spaced_ring_point(home,idx,3.45,2.45,.3)
	return meeting_point(v)

func build_work_point(v,plan):
	return spaced_ring_point(plan.pos,person_index(v),3.2,2.25,.25)

func find_pair_candidate(v):
	if v.partner!=-1:
		return -1
	var idx=people.find(v)
	for i in range(people.size()):
		if i==idx:
			continue
		var other=people[i]
		if other.partner==-1 and other.sex!=v.sex and other.bond>=PAIR_BOND_THRESHOLD*.88:
			return i
	return -1

func make_pair_marker(a_name,b_name):
	var offset=count_pairs()*.34
	var p=hearth_pos+Vector3(-1.05+offset,.02,-2.05)
	cyl(p+Vector3(0,.22,0),.055,.44,Color("#385c38"))
	sphere(p+Vector3(-.11,.5,0),.11,Color("#f8f8f4"))
	sphere(p+Vector3(.11,.5,0),.11,Color("#c92232"))
	box(p+Vector3(0,.06,.18),Vector3(.88,.12,.18),Color("#4d3928"))

func try_form_pair(v):
	if v.partner!=-1 or v.bond<PAIR_BOND_THRESHOLD or social_bond<48.0:
		return
	var candidate_idx=find_pair_candidate(v)
	if candidate_idx<0:
		return
	var idx=people.find(v)
	var other=people[candidate_idx]
	v.partner=candidate_idx
	other.partner=idx
	v.bond=min(1.0,v.bond+.16)
	other.bond=min(1.0,other.bond+.16)
	make_pair_marker(v.name,other.name)
	life_progress=min(LIFE_PROGRESS_GOAL,life_progress+1.0)
	set_notice("%s i %s tworzą parę osady" % [v.name,other.name])
	check_discoveries()

func random_field_point(job_name):
	if job_name=="PATYKI":
		return pick_source_point(stick_sources,1.4)
	if job_name=="KAMIEŃ":
		return pick_source_point(stone_sources,1.25)
	if job_name=="JAGODY":
		return pick_source_point(berry_sources,1.2)
	var a=rng.randf_range(0,TAU)
	var r=rng.randf_range(4,12)
	return Vector3(cos(a)*r,0,sin(a)*r)

func pick_build_pos(kind):
	var idx=build_plans.size()+buildings.houses+buildings.granaries+buildings.workshops
	for attempt in range(32):
		var a=(idx+attempt)*1.41+rng.randf_range(-.42,.42)
		var r=rng.randf_range(10,18)
		if kind=="SPICHLERZ":
			r+=2
		elif kind=="WARSZTAT":
			r+=1
		var p=Vector3(cos(a)*r,0,sin(a)*r)
		if is_build_pos_clear(p):
			return p
	return Vector3(rng.randf_range(-18,-10),0,rng.randf_range(8,18))

func queue_build_plan(kind):
	if open_plan_count()>=MAX_BUILD_PLANS:
		set_notice("Kolejka budowy pełna: max %d" % MAX_BUILD_PLANS)
		redirect_people()
		return
	var cost=building_cost(kind)
	var p=pick_build_pos(kind)
	build_plans.append({"kind":kind,"need_sticks":cost.sticks,"need_stone":cost.stone,"stored_sticks":0,"stored_stone":0,"funded":false,"done":false,"progress":0.0,"work":cost.work,"pos":p,"site":make_build_site(p,kind)})
	order="BUDUJ "+kind
	set_notice("Plan %s dodany do kolejki" % kind)
	try_fund_plans()
	redirect_people()

func fund_plan(plan):
	if not plan.funded and stock.sticks>=plan.need_sticks and stock.stone>=plan.need_stone:
		stock.sticks-=plan.need_sticks
		stock.stone-=plan.need_stone
		plan.stored_sticks=plan.need_sticks
		plan.stored_stone=plan.need_stone
		plan.funded=true
		update_build_site(plan)
		set_notice("Materiały dla %s opłacone na budowie" % plan.kind)
		return true
	return false

func try_fund_plans():
	for plan in build_plans:
		if plan.done:
			continue
		if not plan.funded:
			fund_plan(plan)
			return

func update_build_site(plan):
	if plan.done or not plan.has("site") or not is_instance_valid(plan.site):
		return
	var pct=clamp(plan.progress/plan.work,0.0,1.0) if plan.funded else 0.0
	var bar=plan.site.get_node_or_null("ProgressBar")
	if bar:
		bar.scale.x=max(.04,pct)
		bar.position.x=-1.8+(1.8*pct)
	var post_a=plan.site.get_node_or_null("StagePostA")
	var post_b=plan.site.get_node_or_null("StagePostB")
	var beam=plan.site.get_node_or_null("StageBeam")
	if post_a:
		post_a.visible=plan.funded and pct>.18
	if post_b:
		post_b.visible=plan.funded and pct>.36
	if beam:
		beam.visible=plan.funded and pct>.58

func update_build_sites():
	for plan in build_plans:
		update_build_site(plan)

func complete_build(plan):
	if plan.done:
		return
	plan.done=true
	if plan.has("site") and is_instance_valid(plan.site):
		plan.site.queue_free()
	if plan.kind=="DOM":
		make_house(plan.pos,rng.randf_range(-180,180))
		buildings.houses+=1
		register_home_spot(plan.pos)
	elif plan.kind=="SPICHLERZ":
		make_granary(plan.pos)
		buildings.granaries+=1
		register_build_spot(plan.pos)
	elif plan.kind=="WARSZTAT":
		make_workshop(plan.pos)
		buildings.workshops+=1
		register_build_spot(plan.pos)
	tech_points+=1
	check_discoveries()
	set_notice("%s ukończony. Tech +1" % plan.kind)
	if open_plan_count()==0:
		order="AUTO"

func assign_job(v,job_name,target):
	v.job=job_name
	v.target=target
	v.work_timer=0.0
	if job_name=="IDLE":
		v.rest_time=rng.randf_range(1.4,3.8)

func start_delivery(v,kind):
	v.carry=kind
	set_carry_visual(v.cargo,kind)
	v.job="DOSTAWA"
	v.target=depot_point(v)
	v.work_timer=0.0

func carry_yield(v,kind):
	var amount=1
	if discoveries["NARZĘDZIA"] and kind!="berries" and rng.randf()<.34:
		amount+=1
	if discoveries["OGIEŃ"] and kind=="berries" and rng.randf()<.22:
		amount+=1
	if buildings.workshops>0 and rng.randf()<.12:
		amount+=1
	return amount

func deposit_carry(v):
	if v.carry=="":
		return
	add_stock(v.carry,carry_yield(v,v.carry))
	v.carry=""
	set_carry_visual(v.cargo,"")
	try_fund_plans()
	check_discoveries()

func job_duration(v):
	if v.job=="DZIECKO":
		return 1.8
	if v.job=="BUDOWA":
		var build_time=.92
		if discoveries["NARZĘDZIA"]:
			build_time*=.86
		if buildings.workshops>0:
			build_time*=.9
		return build_time
	if v.job=="WSPÓLNOTA":
		return 1.6
	if v.job=="ODKRYCIA":
		return 1.35
	if v.job=="ODPOCZYNEK":
		return 1.05
	if v.job=="DOSTAWA":
		return .22
	if v.job=="IDLE":
		return v.rest_time
	var gather_time=1.15
	if discoveries["NARZĘDZIA"] and v.job in ["PATYKI","KAMIEŃ"]:
		gather_time*=.86
	if discoveries["OGIEŃ"] and v.job=="JAGODY":
		gather_time*=.92
	return gather_time

func assign_for_plan(v,plan):
	if not plan.funded:
		var real_missing_sticks=max(0,plan.need_sticks-stock.sticks)
		var real_missing_stone=max(0,plan.need_stone-stock.stone)
		var missing_sticks=max(0,real_missing_sticks-count_workers("PATYKI"))
		var missing_stone=max(0,real_missing_stone-count_workers("KAMIEŃ"))
		if real_missing_sticks==0 and real_missing_stone==0:
			fund_plan(plan)
		elif missing_sticks>0 and (missing_sticks>=missing_stone or rng.randf()<.55):
			assign_job(v,"PATYKI",random_field_point("PATYKI"))
			return
		elif missing_stone>0:
			assign_job(v,"KAMIEŃ",random_field_point("KAMIEŃ"))
			return
		else:
			assign_job(v,"JAGODY",random_field_point("JAGODY"))
			return
	if plan.funded:
		if count_workers("BUDOWA")<4:
			assign_job(v,"BUDOWA",build_work_point(v,plan))
		elif stock.sticks<7:
			assign_job(v,"PATYKI",random_field_point("PATYKI"))
		elif stock.stone<7:
			assign_job(v,"KAMIEŃ",random_field_point("KAMIEŃ"))
		else:
			assign_job(v,"JAGODY",random_field_point("JAGODY"))

func choose_work(v):
	if not is_adult(v):
		assign_job(v,"DZIECKO",family_point(v))
		return
	if v.carry!="":
		start_delivery(v,v.carry)
		return
	if v.energy<18.0:
		assign_job(v,"ODPOCZYNEK",rest_point(v))
		return
	if order=="ZGROMADZENIE":
		assign_job(v,"WSPÓLNOTA",meeting_point(v))
		return
	if order=="ODKRYCIA":
		assign_job(v,"ODKRYCIA",research_point(v))
		return
	var plan=get_active_plan()
	if plan!=null:
		assign_for_plan(v,plan)
		return
	if order=="PATYKI":
		assign_job(v,"PATYKI",random_field_point("PATYKI"))
	elif order=="KAMIEŃ":
		assign_job(v,"KAMIEŃ",random_field_point("KAMIEŃ"))
	elif order=="JAGODY":
		assign_job(v,"JAGODY",random_field_point("JAGODY"))
	elif stock.berries<18:
		assign_job(v,"JAGODY",random_field_point("JAGODY"))
	elif not discoveries["OGIEŃ"] and count_workers("WSPÓLNOTA")<3:
		assign_job(v,"WSPÓLNOTA",meeting_point(v))
	elif not discoveries["NARZĘDZIA"] and count_workers("ODKRYCIA")<2:
		assign_job(v,"ODKRYCIA",research_point(v))
	elif stock.sticks<8:
		assign_job(v,"PATYKI",random_field_point("PATYKI"))
	elif stock.stone<8:
		assign_job(v,"KAMIEŃ",random_field_point("KAMIEŃ"))
	else:
		assign_job(v,"IDLE",random_field_point("IDLE"))

func redirect_people():
	for v in people:
		choose_work(v)

func finish_job(v):
	if v.job=="PATYKI":
		start_delivery(v,"sticks")
		v.wood+=.1
		return true
	elif v.job=="KAMIEŃ":
		start_delivery(v,"stone")
		v.gather+=.1
		return true
	elif v.job=="JAGODY":
		start_delivery(v,"berries")
		v.gather+=.1
		return true
	elif v.job=="DOSTAWA":
		deposit_carry(v)
	elif v.job=="BUDOWA":
		var plan=get_active_funded_plan()
		if plan!=null:
			var gain=.38+float(v.str+v.dex)*.018
			if discoveries["NARZĘDZIA"]:
				gain*=1.18
			if buildings.workshops>0:
				gain*=1.1
			plan.progress+=gain
			v.build+=.12
			update_build_site(plan)
			if plan.progress>=plan.work:
				complete_build(plan)
	elif v.job=="WSPÓLNOTA":
		v.bond=min(1.0,v.bond+.035)
		social_bond=min(100.0,social_bond+.18+float(v.int)*.012)
		try_form_pair(v)
		check_discoveries()
	elif v.job=="ODKRYCIA":
		insight_progress+=.34+float(v.int)*.035
		v.knowledge+=.16
		if insight_progress>=6.0:
			insight_progress-=6.0
			if not discoveries["NARZĘDZIA"]:
				unlock_discovery("NARZĘDZIA","Odkrycie: narzędzia kamienne. Zbiory i budowa są sprawniejsze.")
			else:
				tech_points+=1
				set_notice("Odkrywcy osady zebrali wiedzę. Tech +1")
		check_discoveries()
	elif v.job=="ODPOCZYNEK":
		var rest_gain=10.0
		if discoveries["OGIEŃ"]:
			rest_gain+=4.0
		if sheltered_people()>=people.size():
			rest_gain+=3.0
		v.energy=min(100.0,v.energy+rest_gain)
		v.hunger=min(100.0,v.hunger+1.5)
	elif v.job=="DZIECKO":
		v.bond=min(1.0,v.bond+.012)
		v.energy=min(100.0,v.energy+1.8)
		social_bond=min(100.0,social_bond+.035)
		v.target=family_point(v)
		check_discoveries()
	return false

func plan_brief():
	var plan=get_active_plan()
	if plan==null:
		return "Plan: brak"
	var nr=active_plan_number(plan)
	var total=open_plan_count()
	if not plan.funded:
		return "Plan %d/%d %s: materiały %d/%d P, %d/%d K" % [nr,total,plan.kind,stock.sticks,plan.need_sticks,stock.stone,plan.need_stone]
	var pct=int(round(clamp(plan.progress/plan.work,0.0,1.0)*100.0))
	return "Plan %d/%d %s: budowa %d%%" % [nr,total,plan.kind,pct]

func plan_summary():
	var plan=get_active_plan()
	if plan==null:
		return "Plan: brak aktywnej budowy\n"+worker_summary()
	var nr=active_plan_number(plan)
	var total=open_plan_count()
	if not plan.funded:
		return "Plan %d/%d %s: zbierz %d/%d patyków i %d/%d kamieni\n%s" % [nr,total,plan.kind,stock.sticks,plan.need_sticks,stock.stone,plan.need_stone,worker_summary()]
	var pct=int(round(clamp(plan.progress/plan.work,0.0,1.0)*100.0))
	return "Plan %d/%d %s: budowa %d%%\nMateriały na budowie: %d/%d patyków, %d/%d kamieni\n%s" % [nr,total,plan.kind,pct,plan.stored_sticks,plan.need_sticks,plan.stored_stone,plan.need_stone,worker_summary()]

func set_order(s):
	if s=="DOM 5/5":
		queue_build_plan("DOM")
		return
	if s=="SPICHLERZ 5/5":
		queue_build_plan("SPICHLERZ")
		return
	if s=="WARSZTAT 8/6":
		queue_build_plan("WARSZTAT")
		return
	order=s
	if s=="ZGROMADZENIE":
		set_notice("Idol zwołuje mieszkańców do ogniska")
	elif s=="ODKRYCIA":
		set_notice("Idol kieruje ciekawych do kamieni odkryć")
	redirect_people()

func reset_human_pose(v):
	var sk=v.skeleton
	if sk:
		sk.reset_bone_poses()

func pose_bone_delta(v,bone_name,rot):
	var sk=v.skeleton
	if not sk:
		return
	var bones=v.bones
	var idx=bones.get(bone_name,-1)
	if idx<0:
		return
	var base=sk.get_bone_pose_rotation(idx)
	if v.has("pose_bases") and v.pose_bases.has(bone_name):
		base=v.pose_bases[bone_name]
	sk.set_bone_pose_rotation(idx,base*Quaternion.from_euler(rot))

func pose_bone_delta_quat(v,bone_name,q:Quaternion):
	var sk=v.skeleton
	if not sk:
		return
	var bones=v.bones
	var idx=bones.get(bone_name,-1)
	if idx<0:
		return
	var base=sk.get_bone_pose_rotation(idx)
	if v.has("pose_bases") and v.pose_bases.has(bone_name):
		base=v.pose_bases[bone_name]
	sk.set_bone_pose_rotation(idx,base*q)

func quat_xform(q:Quaternion,vec:Vector3):
	return Basis(q)*vec

func pose_bone_base_rotation(v,bone_name):
	var sk=v.skeleton
	if not sk:
		return Quaternion(0,0,0,1)
	var bones=v.bones
	var idx=bones.get(bone_name,-1)
	if idx<0:
		return Quaternion(0,0,0,1)
	var base=sk.get_bone_pose_rotation(idx)
	if v.has("pose_bases") and v.pose_bases.has(bone_name):
		base=v.pose_bases[bone_name]
	return base

func bone_child_axis(v,child_name):
	var sk=v.skeleton
	if not sk:
		return Vector3(0,1,0)
	var bones=v.bones
	var child_idx=bones.get(child_name,-1)
	if child_idx<0:
		return Vector3(0,1,0)
	var axis=sk.get_bone_rest(child_idx).origin
	if axis.length()<.001:
		return Vector3(0,1,0)
	return axis.normalized()

func pose_bone_aim_child(v,bone_name,child_name,target_dir:Vector3):
	var sk=v.skeleton
	if not sk or target_dir.length()<.001:
		return
	var bones=v.bones
	var idx=bones.get(bone_name,-1)
	if idx<0:
		return
	var base=pose_bone_base_rotation(v,bone_name)
	var axis=bone_child_axis(v,child_name)
	var base_dir=quat_xform(base,axis)
	if base_dir.length()<.001:
		return
	var aim_q=Quaternion(base_dir.normalized(),target_dir.normalized())
	sk.set_bone_pose_rotation(idx,aim_q*base)

func pose_walk_arm(v,left:bool,arm_swing:float,elbow_swing:float,drop:float):
	var upper_name="upperarm_l" if left else "upperarm_r"
	var lower_name="lowerarm_l" if left else "lowerarm_r"
	var hand_name="hand_l" if left else "hand_r"
	var side=-1.0 if left else 1.0
	var upper_base=pose_bone_base_rotation(v,upper_name)
	var upper_axis=bone_child_axis(v,lower_name)
	var drop_q=Quaternion.from_euler(Vector3(0,0,side*drop))
	var side_dir=quat_xform(upper_base,upper_axis)
	var down_dir=quat_xform(upper_base*drop_q,upper_axis)
	if side_dir.length()<.001 or down_dir.length()<.001:
		pose_bone_delta_quat(v,upper_name,drop_q)
		return
	side_dir=side_dir.normalized()
	down_dir=down_dir.normalized()
	var forward_dir=side_dir.cross(down_dir)
	if forward_dir.length()<.001:
		forward_dir=Vector3(0,0,1)
	else:
		forward_dir=forward_dir.normalized()
	var target_dir=(down_dir+forward_dir*arm_swing).normalized()
	pose_bone_aim_child(v,upper_name,lower_name,target_dir)
	pose_bone_delta(v,lower_name,Vector3(0,0,side*(.035+abs(elbow_swing)*.05)))
	pose_bone_delta(v,hand_name,Vector3.ZERO)

func has_retarget_motion(v):
	return USE_RETARGETED_ANIMATIONS and anim_ready and v.has("anim") and not v.anim.is_empty()

func animation_state_for(v,moving):
	if moving:
		return "walk"
	if v.job=="PATYKI":
		return "chop"
	if v.job in ["KAMIEŃ","JAGODY"]:
		return "gather"
	if v.job=="BUDOWA":
		return "work"
	return "idle"

func apply_bone_pose(v,moving):
	var sk=v.skeleton
	if not sk:
		return
	var step=sin(v.phase)
	var arm_step=sin(v.phase+.22)
	var work=sin(v.phase*2.4)
	var style=float(v.get("pose_style",0.0))
	var use_anim_lower=has_retarget_motion(v)
	var arm_drop=1.36+style*.025
	var shoulder_drop=.035+style*.006
	reset_human_pose(v)
	pose_bone_delta(v,"neck_01",Vector3(.012+sin(v.phase*.42)*.008,0,0))
	pose_bone_delta(v,"Head",Vector3(.006,sin(v.phase*.35+style)*.025,0))
	pose_bone_delta(v,"clavicle_l",Vector3(-.006,0,-shoulder_drop))
	pose_bone_delta(v,"clavicle_r",Vector3(-.006,0,shoulder_drop))
	if not is_adult(v):
		var child_arm=arm_step*.52
		pose_bone_delta(v,"spine_01",Vector3(.018+sin(v.phase*.7)*.01,0,0))
		pose_walk_arm(v,true,child_arm,child_arm*.24,1.18)
		pose_walk_arm(v,false,child_arm,child_arm*.24,1.18)
		if not use_anim_lower:
			pose_bone_delta(v,"thigh_l",Vector3(-step*.27,0,0))
			pose_bone_delta(v,"thigh_r",Vector3(step*.27,0,0))
			pose_bone_delta(v,"calf_l",Vector3(max(0.0,step)*.21,0,0))
			pose_bone_delta(v,"calf_r",Vector3(max(0.0,-step)*.21,0,0))
		return
	if not moving and not use_anim_lower:
		pose_bone_delta(v,"thigh_l",Vector3.ZERO)
		pose_bone_delta(v,"thigh_r",Vector3.ZERO)
		pose_bone_delta(v,"calf_l",Vector3.ZERO)
		pose_bone_delta(v,"calf_r",Vector3.ZERO)
		pose_bone_delta(v,"foot_l",Vector3.ZERO)
		pose_bone_delta(v,"foot_r",Vector3.ZERO)
	if moving:
		var arm_swing=arm_step*.82
		var elbow_swing=arm_step*.24
		pose_bone_delta(v,"spine_01",Vector3(-.012,0,0))
		pose_bone_delta(v,"clavicle_l",Vector3(-.01+arm_step*.055,0,-shoulder_drop-arm_step*.018))
		pose_bone_delta(v,"clavicle_r",Vector3(-.01-arm_step*.055,0,shoulder_drop-arm_step*.018))
		pose_walk_arm(v,true,arm_swing,elbow_swing,arm_drop-abs(arm_step)*.035)
		pose_walk_arm(v,false,arm_swing,elbow_swing,arm_drop-abs(arm_step)*.035)
		if not use_anim_lower:
			pose_bone_delta(v,"thigh_l",Vector3(-step*.46,0,0))
			pose_bone_delta(v,"thigh_r",Vector3(step*.46,0,0))
			pose_bone_delta(v,"calf_l",Vector3(max(0.0,step)*.42,0,0))
			pose_bone_delta(v,"calf_r",Vector3(max(0.0,-step)*.42,0,0))
			pose_bone_delta(v,"foot_l",Vector3(-max(0.0,step)*.16,0,0))
			pose_bone_delta(v,"foot_r",Vector3(-max(0.0,-step)*.16,0,0))
	elif v.job=="BUDOWA":
		pose_bone_delta(v,"spine_01",Vector3(-.055+work*.018,0,0))
		pose_bone_delta(v,"upperarm_l",Vector3(-.08+work*.045,0,-1.12))
		pose_bone_delta(v,"upperarm_r",Vector3(-.08-work*.045,0,1.12))
		pose_bone_delta(v,"lowerarm_l",Vector3(.28,0,-.02))
		pose_bone_delta(v,"lowerarm_r",Vector3(.28,0,.02))
		if not use_anim_lower:
			pose_bone_delta(v,"thigh_l",Vector3(.035,0,0))
			pose_bone_delta(v,"thigh_r",Vector3(-.035,0,0))
	elif v.job in ["PATYKI","KAMIEŃ","JAGODY"]:
		pose_bone_delta(v,"spine_01",Vector3(-.06+work*.016,0,0))
		pose_bone_delta(v,"upperarm_l",Vector3(-.06+work*.035,0,-1.18))
		pose_bone_delta(v,"upperarm_r",Vector3(-.06-work*.035,0,1.18))
		pose_bone_delta(v,"lowerarm_l",Vector3(.24,0,-.025))
		pose_bone_delta(v,"lowerarm_r",Vector3(.24,0,.025))
		if not use_anim_lower:
			pose_bone_delta(v,"thigh_l",Vector3(.045,0,0))
			pose_bone_delta(v,"thigh_r",Vector3(-.025,0,0))
	elif v.job=="WSPÓLNOTA":
		pose_bone_delta(v,"spine_01",Vector3(.012+work*.015,0,0))
		pose_bone_delta(v,"upperarm_l",Vector3(.035+work*.04,0,-1.3))
		pose_bone_delta(v,"upperarm_r",Vector3(.035-work*.04,0,1.3))
		pose_bone_delta(v,"lowerarm_l",Vector3(.14+work*.03,0,-.04))
		pose_bone_delta(v,"lowerarm_r",Vector3(.14-work*.03,0,.04))
	else:
		pose_bone_delta(v,"spine_01",Vector3(sin(v.phase*.7)*.01,0,0))
		pose_bone_delta(v,"upperarm_l",Vector3(.015,0,-1.38))
		pose_bone_delta(v,"upperarm_r",Vector3(.015,0,1.38))
		pose_bone_delta(v,"lowerarm_l",Vector3(.12,0,-.025))
		pose_bone_delta(v,"lowerarm_r",Vector3(.12,0,.025))
		if not use_anim_lower:
			pose_bone_delta(v,"thigh_l",Vector3.ZERO)
			pose_bone_delta(v,"thigh_r",Vector3.ZERO)
			pose_bone_delta(v,"calf_l",Vector3.ZERO)
			pose_bone_delta(v,"calf_r",Vector3.ZERO)

func actor_space_radius(v):
	return PERSONAL_SPACE_ADULT if is_adult(v) else PERSONAL_SPACE_CHILD

func push_out_of_zone(v,center,radius,strength=1.0):
	var n:Node3D=v.node
	var delta=Vector3(n.position.x-center.x,0,n.position.z-center.z)
	var dist=delta.length()
	if dist<.001:
		var idx=person_index(v)
		var a=TAU*float(idx)/max(1.0,float(people.size()))
		delta=Vector3(cos(a),0,sin(a))
		dist=1.0
	if dist<radius:
		var push=delta.normalized()*(radius-dist)*strength
		n.position.x+=push.x
		n.position.z+=push.z

func obstacle_avoidance(v):
	var n:Node3D=v.node
	var steer=Vector3.ZERO
	for ob in obstacle_points:
		var center:Vector3=ob.pos
		var delta=Vector3(n.position.x-center.x,0,n.position.z-center.z)
		var dist=delta.length()
		var limit=float(ob.radius)+OBSTACLE_CLEARANCE
		if dist<.001:
			var idx=person_index(v)
			var a=TAU*float(idx+1)/max(1.0,float(people.size()))
			delta=Vector3(cos(a),0,sin(a))
			dist=1.0
		if dist<limit:
			steer+=delta.normalized()*((limit-dist)/limit)
	return steer

func crowd_avoidance(v):
	var n:Node3D=v.node
	var steer=Vector3.ZERO
	for other in people:
		if other.node==v.node:
			continue
		var delta=Vector3(n.position.x-other.node.position.x,0,n.position.z-other.node.position.z)
		var dist=delta.length()
		var limit=actor_space_radius(v)+actor_space_radius(other)
		if dist>.001 and dist<limit:
			steer+=delta.normalized()*((limit-dist)/limit)
	return steer

func desired_move_direction(v,dir):
	if dir.length()<.001:
		return Vector3.ZERO
	var desired=dir.normalized()
	var steer=desired+crowd_avoidance(v)*CROWD_AVOID_WEIGHT+obstacle_avoidance(v)*OBSTACLE_AVOID_WEIGHT
	if steer.length()<.05:
		return desired
	return steer.normalized()

func update_stuck_escape(v,d,moving,desired):
	var n:Node3D=v.node
	var current=Vector2(n.position.x,n.position.z)
	if not v.has("last_xz"):
		v.last_xz=current
		v.stuck_time=0.0
		return
	if moving:
		var moved=current.distance_to(v.last_xz)
		if moved<STUCK_MOVE_EPS:
			v.stuck_time=float(v.get("stuck_time",0.0))+d
		else:
			v.stuck_time=max(0.0,float(v.get("stuck_time",0.0))-d*1.2)
		if v.stuck_time>STUCK_REPATH_TIME:
			var forward=desired.normalized() if desired.length()>.05 else Vector3.ZERO
			var side=Vector3(-forward.z,0,forward.x)
			if side.length()<.05:
				var ang=rng.randf_range(0,TAU)
				side=Vector3(cos(ang),0,sin(ang))
			if rng.randf()<.5:
				side=-side
			v.target=keep_point_outside_obstacles(n.position+forward*rng.randf_range(1.0,1.8)+side.normalized()*rng.randf_range(1.5,2.7),.25)
			v.stuck_time=0.0
	else:
		v.stuck_time=0.0
	v.last_xz=current

func smooth_face_direction(n,dir,d):
	if dir.length()<.05:
		return
	var target_yaw=atan2(dir.x,dir.z)
	n.rotation.y=lerp_angle(n.rotation.y,target_yaw,clamp(d*WALK_TURN_SPEED,0.0,1.0))

func apply_settlement_spacing():
	for v in people:
		for ob in obstacle_points:
			push_out_of_zone(v,ob.pos,float(ob.radius)+actor_space_radius(v)*.12,OBSTACLE_PUSH_STRENGTH)
	for i in range(people.size()):
		var a=people[i]
		var na:Node3D=a.node
		for j in range(i+1,people.size()):
			var b=people[j]
			var nb:Node3D=b.node
			var delta=Vector3(na.position.x-nb.position.x,0,na.position.z-nb.position.z)
			var dist=delta.length()
			var min_dist=(actor_space_radius(a)+actor_space_radius(b))*.82
			if dist<.001:
				var ang=TAU*float(i+j+1)/max(1.0,float(people.size()))
				delta=Vector3(cos(ang),0,sin(ang))
				dist=1.0
			if dist<min_dist:
				var strength=(min_dist-dist)*.35
				var dir=delta.normalized()
				na.position.x+=dir.x*strength
				na.position.z+=dir.z*strength
				nb.position.x-=dir.x*strength
				nb.position.z-=dir.z*strength

func set_body_part_rotation(parts,key,rot):
	if parts.has(key) and is_instance_valid(parts[key]):
		parts[key].rotation_degrees=rot

func set_body_part_position(parts,key,pos):
	if parts.has(key) and is_instance_valid(parts[key]):
		parts[key].position=pos

func apply_body_proxy_pose(v,moving):
	if not v.has("body_parts"):
		return
	var parts=v.body_parts
	var step=sin(v.phase)
	var work=max(0.0,sin(v.phase*2.2))
	var arm_swing=step*10.0 if moving else sin(v.phase*.8)*2.2
	var leg_swing=step*15.0 if moving else 0.0
	var job=String(v.job)
	var arm_l=Vector3(arm_swing,0,-10)
	var arm_r=Vector3(-arm_swing,0,10)
	var hand_l=Vector3(-.37,.54,-.02-step*.035)
	var hand_r=Vector3(.37,.54,-.02+step*.035)
	if job=="BUDOWA":
		arm_l=Vector3(-18+work*8,0,-12)
		arm_r=Vector3(-16-work*8,0,12)
		hand_l=Vector3(-.34,.68,-.18)
		hand_r=Vector3(.34,.68,-.18)
	elif job in ["PATYKI","KAMIEŃ","JAGODY"]:
		arm_l=Vector3(-12+work*5,0,-11)
		arm_r=Vector3(-11-work*5,0,11)
		hand_l=Vector3(-.35,.6,-.16)
		hand_r=Vector3(.35,.6,-.16)
	elif job=="WSPÓLNOTA":
		arm_l=Vector3(sin(v.phase*.75)*3,0,-9)
		arm_r=Vector3(-sin(v.phase*.75)*3,0,9)
	elif job=="ODPOCZYNEK":
		arm_l=Vector3(2,0,-8)
		arm_r=Vector3(2,0,8)
	set_body_part_rotation(parts,"arm_l",arm_l)
	set_body_part_rotation(parts,"arm_r",arm_r)
	set_body_part_rotation(parts,"leg_l",Vector3(leg_swing,0,0))
	set_body_part_rotation(parts,"leg_r",Vector3(-leg_swing,0,0))
	set_body_part_position(parts,"hand_l",hand_l)
	set_body_part_position(parts,"hand_r",hand_r)
	set_body_part_position(parts,"foot_l",Vector3(-.105,-.06,-.07-step*.045 if moving else -.07))
	set_body_part_position(parts,"foot_r",Vector3(.105,-.06,-.07+step*.045 if moving else -.07))
	set_body_part_rotation(parts,"torso",Vector3(( -3.0 if moving else 0.0)+sin(v.phase*.7)*1.2,0,0))
	set_body_part_rotation(parts,"head",Vector3(sin(v.phase*.55)*1.8,sin(v.phase*.35)*2.0,0))

func apply_living_pose(v,d,moving,flat_dir):
	v.phase+=d*(4.6 if not is_adult(v) else (5.25 if moving else (2.45 if v.job!="IDLE" else .92)))
	var n:Node3D=v.node
	if not moving and v.job=="DZIECKO":
		var look=family_point(v)-n.position
		look.y=0
		if look.length()>.2:
			smooth_face_direction(n,look,d)
	elif not moving and v.job=="WSPÓLNOTA":
		var look=hearth_pos-n.position
		look.y=0
		if look.length()>.2:
			smooth_face_direction(n,look,d)
	elif not moving and v.job=="ODKRYCIA":
		var look=RESEARCH_POS-n.position
		look.y=0
		if look.length()>.2:
			smooth_face_direction(n,look,d)
	var bob=0.0
	var pitch=0.0
	var roll=0.0
	if moving:
		bob=abs(sin(v.phase))*0.045
		pitch=sin(v.phase*2.0)*.55
		roll=sin(v.phase)*.55
		if v.carry!="":
			pitch+=.35
			roll*=.72
		if not is_adult(v):
			bob*=.72
			pitch*=.72
			roll*=.72
	elif v.job=="BUDOWA":
		bob=max(0.0,sin(v.phase*2.2))*0.028
		pitch=-2.1+sin(v.phase*2.2)*.75
		roll=sin(v.phase)*.35
	elif v.job=="DZIECKO":
		bob=abs(sin(v.phase*1.4))*0.018
		pitch=sin(v.phase*.9)*.55
		roll=sin(v.phase*.7)*.5
	elif v.job in ["PATYKI","KAMIEŃ","JAGODY"]:
		bob=max(0.0,sin(v.phase*2.0))*0.024
		pitch=-2.4+sin(v.phase*2.0)*.75
	elif v.job=="ODKRYCIA":
		bob=sin(v.phase*.9)*0.012
		pitch=-1.1+sin(v.phase*.8)*.42
	elif v.job=="ODPOCZYNEK":
		bob=sin(v.phase*.45)*0.009
		pitch=.6
	elif v.job=="WSPÓLNOTA":
		bob=sin(v.phase*.8)*0.015
		roll=sin(v.phase*.55)*.42
	else:
		bob=sin(v.phase*.72)*0.012
		roll=sin(v.phase*.5)*.25
	n.position.y=bob
	var yaw=n.rotation_degrees.y
	n.rotation_degrees=Vector3(pitch,yaw,roll)
	var breath=1.0+sin(v.phase*.7)*.006
	n.scale=Vector3(v.base_scale.x,v.base_scale.y*breath,v.base_scale.z)
	apply_body_proxy_pose(v,moving)
	if USE_PROCEDURAL_BONE_POSE:
		apply_bone_pose(v,moving)

func update_world_lighting(d):
	day_clock=fposmod(day_clock+d*.006,1.0)
	var arc=sin(day_clock*TAU)
	var warm=(arc+1.0)*.5
	if sun:
		sun.rotation_degrees=Vector3(-48.0+arc*8.0,-60.0+day_clock*120.0,0)
		sun.light_energy=1.05+warm*.28
	if world_env and world_env.environment:
		world_env.environment.background_color=Color("#8199a3").lerp(Color("#a9c1c7"),warm)
		world_env.environment.ambient_light_energy=.56+warm*.18

func _process(d):
	update_world_lighting(d)
	idol_will=min(100.0,idol_will+d*1.15)
	for v in people:
		var n:Node3D=v.node
		var adult=is_adult(v)
		var hunger_rate=.04 if adult else .027
		var energy_rate=.017 if adult else .01
		v.hunger=min(100.0,v.hunger+d*hunger_rate); v.energy=max(0.0,v.energy-d*energy_rate)
		if not adult and v.job=="DZIECKO":
			v.target=family_point(v)
		if v.hunger>92.0 and stock.berries<=0:
			v.energy=max(0.0,v.energy-d*.08)
		if v.hunger>82.0 and stock.berries>0:
			stock.berries-=1
			v.hunger=max(0.0,v.hunger-(34.0 if adult else 42.0))
			v.energy=min(100.0,v.energy+(7.0 if adult else 10.0))
		var dir=Vector3(v.target.x-n.position.x,0,v.target.z-n.position.z)
		var moving=dir.length()>.55
		if moving:
			v.work_timer=0.0
			var speed=(.8+v.dex*.04)*(1.0 if adult else .72)
			var move_dir=desired_move_direction(v,dir)
			n.position+=move_dir*d*speed
			smooth_face_direction(n,move_dir,d)
			update_stuck_escape(v,d,true,dir)
			if anim_ready and v.has("anim"): retargeter.play(v.anim,animation_state_for(v,true),d)
			apply_living_pose(v,d,true,move_dir)
		else:
			update_stuck_escape(v,d,false,dir)
			v.work_timer+=d
			if v.job!="IDLE":
				if anim_ready and v.has("anim"): retargeter.play(v.anim,animation_state_for(v,false),d)
				apply_living_pose(v,d,false,dir)
				if v.work_timer>=job_duration(v):
					var keep_job=finish_job(v)
					if not keep_job:
						v.job="IDLE"
						choose_work(v)
			else:
				if anim_ready and v.has("anim"): retargeter.play(v.anim,animation_state_for(v,false),d)
				apply_living_pose(v,d,false,dir)
				if v.work_timer>=job_duration(v):
					choose_work(v)
	apply_settlement_spacing()
	update_life_growth(d)
	update_build_sites()
	update_settler_chat(d)
	update_selection_marker()
	apply_camera_sticks(d)
	if notice_timer>0.0:
		notice_timer=max(0.0,notice_timer-d)
	var status=(notice if notice_timer>0.0 else plan_brief())
	hud.text="%s\nEpoka kamienia | Wola %.0f%% | Życie %d%% | Tech %d\n%s | Ludzie %d (D%d Dz%d) | Pary %d | Schron. %d/%d | Więź %.0f%%\nP %d/%d  K %d/%d  J %d/%d | D %d  S %d  W %d\n%s\n%s" % [VERSION_TITLE,idol_will,life_progress_percent(),tech_points,order,people.size(),count_adults(),count_children(),count_pairs(),sheltered_people(),people.size(),average_bond()*100.0,stock.sticks,resource_capacity("sticks"),stock.stone,resource_capacity("stone"),stock.berries,resource_capacity("berries"),buildings.houses,buildings.granaries,buildings.workshops,status,chapter_goal()]
	var v=people[selected]
	info.text="%s — %s, %d lat | %s\nPraca: %s | %s | Więź %.0f%% | Mowa %.0f%%\nLubi: %s | Obawa: %s\nGłód %.0f  Energia %.0f | S%d Z%d I%d\nUmiej.: drw %.1f  zb %.1f  bud %.1f  odk %.1f\n%s\n%s" % [v.name,v.trait,v.age,family_label(v),v.job,carry_label(v.carry),v.bond*100.0,actor_language(v)*100.0,actor_like(v),actor_worry(v),v.hunger,v.energy,v.str,v.dex,v.int,v.wood,v.gather,v.build,v.knowledge,plan_brief(),worker_summary()]

func set_camera_distance(value):
	cam_distance=clamp(value,CAMERA_MIN_DISTANCE,CAMERA_MAX_DISTANCE)
	cam_height=clamp(cam_distance*CAMERA_HEIGHT_RATIO,CAMERA_MIN_HEIGHT,CAMERA_MAX_HEIGHT)

func get_camera_right():
	var right=cam.global_transform.basis.x
	right.y=0
	return right.normalized()

func get_camera_forward():
	var forward=-cam.global_transform.basis.z
	forward.y=0
	return forward.normalized()

func update_camera():
	cam_focus.x=clamp(cam_focus.x,-CAMERA_FOCUS_LIMIT,CAMERA_FOCUS_LIMIT)
	cam_focus.z=clamp(cam_focus.z,-CAMERA_FOCUS_LIMIT,CAMERA_FOCUS_LIMIT)
	var horizontal=Vector3(sin(cam_yaw),0,cos(cam_yaw))*cam_distance
	cam.position=cam_focus+horizontal+Vector3(0,cam_height,0)
	cam.look_at(cam_focus+Vector3(0,1.2,0),Vector3.UP)

func stick_strength(v):
	var l=v.length()
	if l<=STICK_DEADZONE:
		return Vector2.ZERO
	return v.normalized()*((l-STICK_DEADZONE)/(1.0-STICK_DEADZONE))

func update_stick(pos,center,thumb):
	var v=(pos-center)/STICK_RADIUS
	if v.length()>1.0:
		v=v.normalized()
	thumb.position=center+v*STICK_RADIUS-Vector2(STICK_THUMB_RADIUS,STICK_THUMB_RADIUS)
	return v

func reset_stick(center,thumb):
	thumb.position=center-Vector2(STICK_THUMB_RADIUS,STICK_THUMB_RADIUS)
	return Vector2.ZERO

func apply_camera_sticks(d):
	if not cam:
		return
	var changed=false
	var move=stick_strength(move_stick)
	if move!=Vector2.ZERO:
		var speed=clamp(cam_distance*.72,12.0,55.0)
		cam_focus += (get_camera_right()*move.x-get_camera_forward()*move.y)*speed*d
		changed=true
	var rotate=stick_strength(rotate_stick)
	if rotate!=Vector2.ZERO:
		cam_yaw+=rotate.x*2.15*d
		changed=true
	if changed:
		update_camera()

func is_in_panel(pos,panel):
	return panel.has_point(pos)

func _unhandled_input(e):
	if e is InputEventScreenTouch:
		if e.pressed:
			if rotate_stick_touch==-1 and is_in_panel(e.position,rotate_stick_panel):
				rotate_stick_touch=e.index
				rotate_stick=update_stick(e.position,rotate_stick_center,rotate_stick_thumb)
				return
			if move_stick_touch==-1 and is_in_panel(e.position,move_stick_panel):
				move_stick_touch=e.index
				move_stick=update_stick(e.position,move_stick_center,move_stick_thumb)
				return
			touch_start[e.index]=e.position
			touches[e.index]=e.position
			if touches.size()>=2:
				touch_gesture_had_multi=true
			if touches.size()<2:
				last_pinch_dist=0.0
				last_pinch_angle=0.0
		else:
			if e.index==move_stick_touch:
				move_stick_touch=-1
				move_stick=reset_stick(move_stick_center,move_stick_thumb)
				return
			if e.index==rotate_stick_touch:
				rotate_stick_touch=-1
				rotate_stick=reset_stick(rotate_stick_center,rotate_stick_thumb)
				return
			var start=touch_start.get(e.index,e.position)
			var was_single=touches.size()<=1
			touches.erase(e.index)
			touch_start.erase(e.index)
			if was_single and not touch_gesture_had_multi and start.distance_to(e.position)<=SELECT_TAP_MAX_MOVE and select_person_at_screen(e.position):
				update_camera()
				return
			if touches.is_empty():
				touch_gesture_had_multi=false
			last_pinch_dist=0.0
			last_pinch_angle=0.0
		update_camera()
		return

	if e is InputEventScreenDrag:
		if e.index==rotate_stick_touch:
			rotate_stick=update_stick(e.position,rotate_stick_center,rotate_stick_thumb)
			return
		if e.index==move_stick_touch:
			move_stick=update_stick(e.position,move_stick_center,move_stick_thumb)
			return
		touches[e.index]=e.position
		if touches.size()==1:
			var right=get_camera_right()
			var forward=get_camera_forward()
			var pan_speed=clamp(cam_distance*.00115,.008,.075)
			cam_focus += (-right*e.relative.x+forward*e.relative.y)*pan_speed
		elif touches.size()>=2:
			var ids=touches.keys()
			ids.sort()
			var a:Vector2=touches[ids[0]]
			var b:Vector2=touches[ids[1]]
			var dist=a.distance_to(b)
			var ang=(b-a).angle()
			touch_gesture_had_multi=true
			if last_pinch_dist>0.0:
				var ratio=dist/max(last_pinch_dist,1.0)
				set_camera_distance(cam_distance/ratio)
				var da=wrapf(ang-last_pinch_angle,-PI,PI)
				cam_yaw+=da
			last_pinch_dist=dist
			last_pinch_angle=ang
		update_camera()

	if e is InputEventMouseButton:
		if e.button_index==MOUSE_BUTTON_WHEEL_UP:
			set_camera_distance(cam_distance-3.0)
		elif e.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			set_camera_distance(cam_distance+3.0)
		elif e.button_index==MOUSE_BUTTON_LEFT and not e.pressed:
			select_person_at_screen(e.position)
		update_camera()

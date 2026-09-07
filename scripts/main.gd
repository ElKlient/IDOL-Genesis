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
const VERSION_TITLE="IDOL — GENESIS 0.7.2 LIFE SPARK"
const CAMERA_MIN_DISTANCE=5.5
const CAMERA_MAX_DISTANCE=88.0
const CAMERA_HEIGHT_RATIO=0.61
const CAMERA_MIN_HEIGHT=4.2
const CAMERA_MAX_HEIGHT=48.0
const CAMERA_FOCUS_LIMIT=32.0
const STICK_RADIUS=62.0
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

var rng=RandomNumberGenerator.new()
var people=[]
var material_cache={}
var stock={"sticks":4,"stone":3,"berries":24}
var buildings={"houses":2,"granaries":0,"workshops":0}
var build_plans=[]
var build_spots=[]
var home_spots=[]
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
var selected_marker:Node3D
var move_stick=Vector2.ZERO
var rotate_stick=Vector2.ZERO
var move_stick_touch=-1
var rotate_stick_touch=-1
var rotate_stick_panel=Rect2(Vector2(24,470),Vector2(260,220))
var move_stick_panel=Rect2(Vector2(996,470),Vector2(260,220))
var rotate_stick_center=Vector2(155,585)
var move_stick_center=Vector2(1125,585)
var move_stick_thumb:Control
var rotate_stick_thumb:Control
var names=["Alda","Sela","Mira","Nara","Ena","Eryk","Oren","Bran","Tovan","Milan"]
var child_names=["Lira","Ari","Tala","Nim","Rin","Oda","Uma","Leno"]
var traits=["Pracowita","Odważna","Ciekawska","Śpioch","Spokojna","Silny","Uparty","Myśliciel","Zwinny","Towarzyski"]

func mat(c):
	var key=str(c)
	if material_cache.has(key):
		return material_cache[key]
	var m=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=.95
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

func _ready():
	rng.seed=5302026
	world_env=WorldEnvironment.new(); var e=Environment.new()
	e.background_mode=Environment.BG_COLOR; e.background_color=Color("#8fa9b3")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color("#fff0d5"); e.ambient_light_energy=.68
	world_env.environment=e; add_child(world_env)
	sun=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-55,-35,0); sun.light_energy=1.35; sun.shadow_enabled=false; add_child(sun)

	var ground=MeshInstance3D.new(); var pm=PlaneMesh.new(); pm.size=Vector2(55,55); ground.mesh=pm; ground.material_override=mat(Color("#5b7045")); add_child(ground)
	make_river()
	for i in range(30):
		var p=Vector3(rng.randf_range(-25,25),0,rng.randf_range(-25,25))
		if p.length()<10: continue
		make_tree(p,rng.randf_range(.85,1.22))
	for i in range(16):
		var p=Vector3(rng.randf_range(-24,24),.25,rng.randf_range(-24,24))
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

	for i in range(10): make_person(i)
	make_selection_marker()

	retargeter=RETARGETER.new()
	add_child(retargeter)
	anim_ready=retargeter.initialize()
	if anim_ready:
		for v in people:
			attach_person_animation(v)

	cam=Camera3D.new(); cam.fov=52; add_child(cam); cam.current=true
	update_camera()
	make_ui()

func make_river():
	for z in range(-30,31,3):
		var x=river_x_at_z(z)
		box(Vector3(x,.02,z),Vector3(6.4,.08,3.25),Color("#4f8d9a"))
		box(Vector3(x-3.55,.035,z),Vector3(.58,.06,3.1),Color("#746f4d"))
		box(Vector3(x+3.55,.035,z),Vector3(.58,.06,3.1),Color("#746f4d"))
		if z%6==0:
			make_rock(Vector3(x-3.95,.18,z+rng.randf_range(-.9,.9)),.45)
			make_rock(Vector3(x+3.95,.18,z+rng.randf_range(-.9,.9)),.42)

func make_tree(p,scale):
	cyl(p+Vector3(0,1.35*scale,0),.18*scale,2.7*scale,Color("#65472f"))
	cyl(p+Vector3(0,2.9*scale,0),.78*scale,1.45*scale,Color("#244b29"))
	var top=cyl(p+Vector3(0,3.55*scale,0),.55*scale,.75*scale,Color("#2f6134"))
	top.rotation_degrees.y=rng.randf_range(0,180)

func make_rock(p,scale):
	var r=box(p,Vector3(.75*scale,.38*scale,.62*scale),Color("#777a72"))
	r.rotation_degrees=Vector3(rng.randf_range(-6,6),rng.randf_range(0,180),rng.randf_range(-5,5))
	return r

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
	for i in range(52):
		var p=Vector3(rng.randf_range(-26,26),.16,rng.randf_range(-26,26))
		if p.length()<4.0 or abs(p.x-river_x_at_z(p.z))<3.6:
			continue
		var grass=box(p,Vector3(.07,.34,.07),Color("#6f8a4f"))
		grass.rotation_degrees=Vector3(rng.randf_range(-14,14),rng.randf_range(0,180),rng.randf_range(-14,14))

func make_idol():
	box(Vector3(0,2,0),Vector3(1.7,4,1.25),Color("#77776f"))
	box(Vector3(-.38,2.45,-.66),Vector3(.18,.18,.08),Color("#242620"))
	box(Vector3(.38,2.45,-.66),Vector3(.18,.18,.08),Color("#242620"))

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
	var a=WALL.instantiate(); a.position=Vector3(-1.8,0,0); h.add_child(a)
	var b=WALL.instantiate(); b.position=Vector3(1.8,0,0); h.add_child(b)
	var d=DOOR.instantiate(); d.position=Vector3(0,0,-3.5); d.rotation_degrees.y=180; h.add_child(d)
	var r=ROOF.instantiate(); r.position=Vector3(0,3,-1.5); r.scale=Vector3(.65,.65,.65); h.add_child(r)

func make_granary(p):
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
	for bone_name in ["spine_01","spine_02","upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","thigh_l","thigh_r","calf_l","calf_r","foot_l","foot_r"]:
		bones[bone_name]=sk.find_bone(bone_name)
	return bones

func make_settler_gear(parent,i):
	var gear=Node3D.new()
	gear.name="Ubranie osadnika"
	parent.add_child(gear)
	var cloth_cols=[Color("#7c5b38"),Color("#6b6740"),Color("#8a6a3c"),Color("#6d5841"),Color("#7d4f35")]
	var col=cloth_cols[i%cloth_cols.size()]
	var belt=cyl_in(gear,Vector3(0,.66,0),.22,.08,Color("#3b2a1f"))
	belt.rotation_degrees.y=rng.randf_range(-18,18)
	box_in(gear,Vector3(0,.52,-.15),Vector3(.34,.35,.045),col)
	box_in(gear,Vector3(0,.38,-.13),Vector3(.28,.28,.05),col.darkened(.12))
	var pouch=box_in(gear,Vector3(.19,.6,-.18),Vector3(.12,.15,.055),Color("#4e3523"))
	pouch.rotation_degrees.z=-8

func make_carry_node(parent):
	var cargo=Node3D.new()
	cargo.name="Ładunek"
	cargo.position=Vector3(.27,.83,-.28)
	parent.add_child(cargo)
	var sticks=Node3D.new()
	sticks.name="sticks"
	cargo.add_child(sticks)
	for i in range(3):
		var stick=box_in(sticks,Vector3(0,.03*i,0),Vector3(.055,.055,.58),Color("#8a5c32"))
		stick.rotation_degrees=Vector3(0,-22+i*20,0)
	var stone=Node3D.new()
	stone.name="stone"
	cargo.add_child(stone)
	for i in range(3):
		var rock=box_in(stone,Vector3(rng.randf_range(-.09,.09),.03*i,rng.randf_range(-.08,.08)),Vector3(.16,.11,.14),Color("#7b7d76"))
		rock.rotation_degrees=Vector3(rng.randf_range(-8,8),rng.randf_range(0,180),rng.randf_range(-8,8))
	var berries=Node3D.new()
	berries.name="berries"
	cargo.add_child(berries)
	cyl_in(berries,Vector3(0,.02,0),.16,.12,Color("#6f4b2c"))
	for i in range(5):
		sphere_in(berries,Vector3(rng.randf_range(-.1,.1),.11,rng.randf_range(-.09,.09)),.035,Color("#98243d"))
	set_carry_visual(cargo,"")
	return cargo

func set_carry_visual(cargo,kind):
	if not cargo:
		return
	cargo.visible=kind!=""
	for c in cargo.get_children():
		c.visible=String(c.name)==kind

func make_person(i):
	var n=(FEMALE if i<5 else MALE).instantiate()
	# Diagnostic showed source character is tiny. Correct source-to-world scale here.
	var base_scale=Vector3(2.15,2.15,2.15)
	n.scale=base_scale
	var a=TAU*i/10.0; n.position=Vector3(cos(a)*rng.randf_range(5,10),0,sin(a)*rng.randf_range(5,10)); add_child(n)
	make_settler_gear(n,i)
	var cargo=make_carry_node(n)
	var sk=find_skeleton(n)
	var v={"node":n,"skeleton":sk,"bones":cache_pose_bones(sk),"base_scale":base_scale,"phase":rng.randf_range(0,TAU),"work_timer":0.0,"rest_time":rng.randf_range(1.5,3.6),"name":names[i],"trait":traits[i],"sex":"K" if i<5 else "M","age":rng.randi_range(18,34),"adult":true,"parent_a":-1,"parent_b":-1,"family_cd":rng.randf_range(8.0,18.0),"bond":rng.randf_range(.28,.62),"partner":-1,"str":rng.randi_range(3,9),"dex":rng.randi_range(3,9),"int":rng.randi_range(3,9),"hunger":rng.randf_range(5,25),"energy":rng.randf_range(72,100),"wood":0.0,"gather":0.0,"build":0.0,"knowledge":0.0,"job":"IDLE","carry":"","cargo":cargo,"target":n.position}
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
	var base_scale=Vector3(1.08,1.08,1.08)
	n.scale=base_scale
	var center=(parent_a.node.position+parent_b.node.position)*.5
	n.position=center+Vector3(rng.randf_range(-.75,.75),0,rng.randf_range(-.75,.75))
	add_child(n)
	make_settler_gear(n,children_born+2)
	var cargo=make_carry_node(n)
	var sk=find_skeleton(n)
	var child_name=next_child_name()
	var v={"node":n,"skeleton":sk,"bones":cache_pose_bones(sk),"base_scale":base_scale,"phase":rng.randf_range(0,TAU),"work_timer":0.0,"rest_time":rng.randf_range(1.8,3.8),"name":child_name,"trait":"Dziecko osady","sex":sex,"age":1,"adult":false,"parent_a":parent_a_idx,"parent_b":parent_b_idx,"family_cd":0.0,"bond":rng.randf_range(.62,.78),"partner":-1,"str":rng.randi_range(1,3),"dex":rng.randi_range(2,5),"int":rng.randi_range(2,5),"hunger":rng.randf_range(0,12),"energy":rng.randf_range(82,100),"wood":0.0,"gather":0.0,"build":0.0,"knowledge":0.0,"job":"DZIECKO","carry":"","cargo":cargo,"target":n.position}
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

func make_ui():
	var layer=CanvasLayer.new(); add_child(layer)
	var bg=ColorRect.new(); bg.position=Vector2(14,14); bg.size=Vector2(574,174); bg.color=Color(0.02,0.02,0.015,.87); layer.add_child(bg)
	hud=Label.new(); hud.position=Vector2(29,27); hud.add_theme_font_size_override("font_size",14); layer.add_child(hud)
	var menu=VBoxContainer.new(); menu.position=Vector2(1005,18); menu.size=Vector2(250,430); menu.add_theme_constant_override("separation",2); layer.add_child(menu)
	var title=Label.new(); title.text="ROZKAZY IDOLA"; title.add_theme_font_size_override("font_size",17); menu.add_child(title)
	for s in ["AUTO","PATYKI","KAMIEŃ","JAGODY","ZGROMADZENIE","ODKRYCIA","DOM 5/5","SPICHLERZ 5/5","WARSZTAT 8/6"]:
		var cmd=s
		var b=Button.new(); b.text=cmd; b.custom_minimum_size=Vector2(240,25); b.pressed.connect(func(): set_order(cmd)); menu.add_child(b)
	var next_btn=Button.new(); next_btn.text="OSOBA +"; next_btn.custom_minimum_size=Vector2(240,25); next_btn.pressed.connect(func(): cycle_selected()); menu.add_child(next_btn)
	for s in ["KAMERA OS.","PRZYWOŁAJ","BŁOGOSŁAW","WIĘŹ +","KRĄG ŻYCIA"]:
		var action=s
		var b=Button.new(); b.text=action; b.custom_minimum_size=Vector2(240,22); b.pressed.connect(func(): handle_idol_action(action)); menu.add_child(b)
	var ibg=ColorRect.new(); ibg.position=Vector2(14,194); ibg.size=Vector2(430,262); ibg.color=Color(0.02,0.02,0.015,.72); layer.add_child(ibg)
	info=Label.new(); info.position=Vector2(30,206); info.add_theme_font_size_override("font_size",12); layer.add_child(info)
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
	l.position=center+Vector2(-96,73)
	l.size=Vector2(192,24)
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",15)
	l.modulate=Color(1,1,1,.86)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(l)

func make_camera_sticks(layer):
	layer.add_child(make_touch_panel(rotate_stick_panel.position,rotate_stick_panel.size))
	layer.add_child(make_round_panel(rotate_stick_center-Vector2(72,72),Vector2(144,144),Color(0.02,0.02,0.015,.23),Color(1,1,1,.22)))
	rotate_stick_thumb=make_round_panel(rotate_stick_center-Vector2(29,29),Vector2(58,58),Color(1,1,1,.42),Color(1,1,1,.68))
	layer.add_child(rotate_stick_thumb)
	make_stick_label(layer,rotate_stick_center,"OBRÓT KAMERY")
	layer.add_child(make_touch_panel(move_stick_panel.position,move_stick_panel.size))
	layer.add_child(make_round_panel(move_stick_center-Vector2(72,72),Vector2(144,144),Color(0.02,0.02,0.015,.23),Color(1,1,1,.22)))
	move_stick_thumb=make_round_panel(move_stick_center-Vector2(29,29),Vector2(58,58),Color(1,1,1,.42),Color(1,1,1,.68))
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

func meeting_point(v):
	var idx=people.find(v)
	var a=TAU*float(max(0,idx))/max(1.0,float(people.size()))
	return hearth_pos+Vector3(cos(a)*1.8,0,sin(a)*1.45)

func depot_point(v):
	var idx=people.find(v)
	var a=TAU*float(max(0,idx))/max(1.0,float(people.size()))
	return STOCKPILE_POS+Vector3(cos(a)*1.45,0,sin(a)*1.05)

func research_point(v):
	var idx=people.find(v)
	var a=TAU*float(max(0,idx))/max(1.0,float(people.size()))
	return RESEARCH_POS+Vector3(cos(a)*1.35,0,sin(a)*.95)

func rest_point(v):
	var idx=people.find(v)
	if not home_spots.is_empty():
		var home=home_spots[idx%home_spots.size()]
		var a=TAU*float(idx%4)/4.0
		return home+Vector3(cos(a)*1.9,0,sin(a)*1.45)
	return meeting_point(v)

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
			assign_job(v,"BUDOWA",plan.pos+Vector3(rng.randf_range(-1.7,1.7),0,rng.randf_range(-1.25,1.25)))
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

func pose_bone(sk,bones,bone_name,rot):
	if not sk:
		return
	var idx=bones.get(bone_name,-1)
	if idx>=0:
		sk.set_bone_pose_rotation(idx,Quaternion.from_euler(rot))

func apply_bone_pose(v,moving):
	var sk=v.skeleton
	if not sk:
		return
	var bones=v.bones
	var step=sin(v.phase)
	var work=sin(v.phase*2.4)
	var arm_drop=.92
	if not is_adult(v):
		pose_bone(sk,bones,"spine_01",Vector3(.04+sin(v.phase*.7)*.018,0,0))
		pose_bone(sk,bones,"upperarm_l",Vector3(.12,0,-.82))
		pose_bone(sk,bones,"upperarm_r",Vector3(.12,0,.82))
		pose_bone(sk,bones,"lowerarm_l",Vector3(.2+step*.05,0,-.16))
		pose_bone(sk,bones,"lowerarm_r",Vector3(.2-step*.05,0,.16))
		pose_bone(sk,bones,"thigh_l",Vector3.ZERO)
		pose_bone(sk,bones,"thigh_r",Vector3.ZERO)
		pose_bone(sk,bones,"calf_l",Vector3.ZERO)
		pose_bone(sk,bones,"calf_r",Vector3.ZERO)
		return
	if not moving:
		pose_bone(sk,bones,"thigh_l",Vector3.ZERO)
		pose_bone(sk,bones,"thigh_r",Vector3.ZERO)
		pose_bone(sk,bones,"calf_l",Vector3.ZERO)
		pose_bone(sk,bones,"calf_r",Vector3.ZERO)
		pose_bone(sk,bones,"foot_l",Vector3.ZERO)
		pose_bone(sk,bones,"foot_r",Vector3.ZERO)
	if moving:
		pose_bone(sk,bones,"spine_01",Vector3(-.04,0,0))
		pose_bone(sk,bones,"upperarm_l",Vector3(step*.34,0,-arm_drop))
		pose_bone(sk,bones,"upperarm_r",Vector3(-step*.34,0,arm_drop))
		pose_bone(sk,bones,"lowerarm_l",Vector3(.12+max(0.0,-step)*.28,0,-.08))
		pose_bone(sk,bones,"lowerarm_r",Vector3(.12+max(0.0,step)*.28,0,.08))
		pose_bone(sk,bones,"thigh_l",Vector3(-step*.38,0,0))
		pose_bone(sk,bones,"thigh_r",Vector3(step*.38,0,0))
		pose_bone(sk,bones,"calf_l",Vector3(max(0.0,step)*.42,0,0))
		pose_bone(sk,bones,"calf_r",Vector3(max(0.0,-step)*.42,0,0))
		pose_bone(sk,bones,"foot_l",Vector3(-max(0.0,step)*.18,0,0))
		pose_bone(sk,bones,"foot_r",Vector3(-max(0.0,-step)*.18,0,0))
	elif v.job=="BUDOWA":
		pose_bone(sk,bones,"spine_01",Vector3(-.18+work*.05,0,0))
		pose_bone(sk,bones,"upperarm_l",Vector3(-.44+work*.2,0,-.72))
		pose_bone(sk,bones,"upperarm_r",Vector3(-.32-work*.2,0,.72))
		pose_bone(sk,bones,"lowerarm_l",Vector3(.72,0,-.08))
		pose_bone(sk,bones,"lowerarm_r",Vector3(.72,0,.08))
		pose_bone(sk,bones,"thigh_l",Vector3(.08,0,0))
		pose_bone(sk,bones,"thigh_r",Vector3(-.08,0,0))
	elif v.job in ["PATYKI","KAMIEŃ","JAGODY"]:
		pose_bone(sk,bones,"spine_01",Vector3(-.23+work*.04,0,0))
		pose_bone(sk,bones,"upperarm_l",Vector3(-.24+work*.16,0,-.78))
		pose_bone(sk,bones,"upperarm_r",Vector3(-.18-work*.16,0,.78))
		pose_bone(sk,bones,"lowerarm_l",Vector3(.52,0,-.1))
		pose_bone(sk,bones,"lowerarm_r",Vector3(.52,0,.1))
		pose_bone(sk,bones,"thigh_l",Vector3(.12,0,0))
		pose_bone(sk,bones,"thigh_r",Vector3(-.05,0,0))
	elif v.job=="WSPÓLNOTA":
		pose_bone(sk,bones,"spine_01",Vector3(.02+work*.025,0,0))
		pose_bone(sk,bones,"upperarm_l",Vector3(.08,0,-1.05))
		pose_bone(sk,bones,"upperarm_r",Vector3(.08,0,1.05))
		pose_bone(sk,bones,"lowerarm_l",Vector3(.18+work*.08,0,-.18))
		pose_bone(sk,bones,"lowerarm_r",Vector3(.18-work*.08,0,.18))
	else:
		pose_bone(sk,bones,"spine_01",Vector3(sin(v.phase*.7)*.018,0,0))
		pose_bone(sk,bones,"upperarm_l",Vector3(.06,0,-1.0))
		pose_bone(sk,bones,"upperarm_r",Vector3(.06,0,1.0))
		pose_bone(sk,bones,"lowerarm_l",Vector3(.1,0,-.12))
		pose_bone(sk,bones,"lowerarm_r",Vector3(.1,0,.12))
		pose_bone(sk,bones,"thigh_l",Vector3.ZERO)
		pose_bone(sk,bones,"thigh_r",Vector3.ZERO)
		pose_bone(sk,bones,"calf_l",Vector3.ZERO)
		pose_bone(sk,bones,"calf_r",Vector3.ZERO)

func apply_living_pose(v,d,moving,flat_dir):
	v.phase+=d*(5.4 if not is_adult(v) else (6.4 if moving else (3.6 if v.job!="IDLE" else 1.05)))
	var n:Node3D=v.node
	if not moving and v.job=="DZIECKO":
		var look=family_point(v)-n.position
		look.y=0
		if look.length()>.2:
			n.look_at(n.position+look,Vector3.UP)
	elif not moving and v.job=="WSPÓLNOTA":
		var look=hearth_pos-n.position
		look.y=0
		if look.length()>.2:
			n.look_at(n.position+look,Vector3.UP)
	elif not moving and v.job=="ODKRYCIA":
		var look=RESEARCH_POS-n.position
		look.y=0
		if look.length()>.2:
			n.look_at(n.position+look,Vector3.UP)
	var bob=0.0
	var pitch=0.0
	var roll=0.0
	if moving:
		bob=abs(sin(v.phase))*0.09
		pitch=sin(v.phase*2.0)*1.8
		roll=sin(v.phase)*2.1
		if v.carry!="":
			pitch+=2.2
			roll*=.55
		if not is_adult(v):
			bob*=.72
			pitch*=.72
			roll*=.72
	elif v.job=="BUDOWA":
		bob=max(0.0,sin(v.phase*2.4))*0.055
		pitch=-5.0+sin(v.phase*2.4)*2.0
		roll=sin(v.phase)*1.3
	elif v.job=="DZIECKO":
		bob=abs(sin(v.phase*1.4))*0.028
		pitch=sin(v.phase*.9)*1.2
		roll=sin(v.phase*.7)*1.4
	elif v.job in ["PATYKI","KAMIEŃ","JAGODY"]:
		bob=max(0.0,sin(v.phase*2.2))*0.045
		pitch=-7.0+sin(v.phase*2.2)*1.7
	elif v.job=="ODKRYCIA":
		bob=sin(v.phase*.9)*0.018
		pitch=-2.0+sin(v.phase*.8)*.9
	elif v.job=="ODPOCZYNEK":
		bob=sin(v.phase*.45)*0.012
		pitch=1.5
	elif v.job=="WSPÓLNOTA":
		bob=sin(v.phase*.8)*0.022
		roll=sin(v.phase*.55)*1.2
	else:
		bob=sin(v.phase*.72)*0.018
		roll=sin(v.phase*.5)*.7
	n.position.y=bob
	var yaw=n.rotation_degrees.y
	n.rotation_degrees=Vector3(pitch,yaw,roll)
	var breath=1.0+sin(v.phase*.7)*.006
	n.scale=Vector3(v.base_scale.x,v.base_scale.y*breath,v.base_scale.z)
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
			n.position+=dir.normalized()*d*speed
			n.look_at(n.position+dir,Vector3.UP)
			if anim_ready and v.has("anim"): retargeter.play(v.anim,"walk")
			apply_living_pose(v,d,true,dir)
		else:
			v.work_timer+=d
			if v.job!="IDLE":
				if anim_ready and v.has("anim"): retargeter.play(v.anim,"idle" if v.job=="DZIECKO" else "work")
				apply_living_pose(v,d,false,dir)
				if v.work_timer>=job_duration(v):
					var keep_job=finish_job(v)
					if not keep_job:
						v.job="IDLE"
						choose_work(v)
			else:
				if anim_ready and v.has("anim"): retargeter.play(v.anim,"idle")
				apply_living_pose(v,d,false,dir)
				if v.work_timer>=job_duration(v):
					choose_work(v)
	update_life_growth(d)
	update_build_sites()
	update_selection_marker()
	apply_camera_sticks(d)
	if notice_timer>0.0:
		notice_timer=max(0.0,notice_timer-d)
	var status=(notice if notice_timer>0.0 else plan_brief())
	hud.text="%s\nRozdział I: epoka kamienia łupanego | Wola %.0f%% | Życie %d%%\nRozkaz %s | Ludzie %d (D%d Dz%d) | Pary %d | Schronienie %d/%d | Więź %.0f%%\nP %d/%d  K %d/%d  J %d/%d | Domy %d  Spich. %d  Warszt. %d  Tech %d\n%s\n%s\n%s\nOdkrycia: %s" % [VERSION_TITLE,idol_will,life_progress_percent(),order,people.size(),count_adults(),count_children(),count_pairs(),sheltered_people(),people.size(),average_bond()*100.0,stock.sticks,resource_capacity("sticks"),stock.stone,resource_capacity("stone"),stock.berries,resource_capacity("berries"),buildings.houses,buildings.granaries,buildings.workshops,tech_points,status,chapter_goal(),family_summary(),discovery_text()]
	var v=people[selected]
	info.text="%s — %s, %d lat\n%s | Praca: %s | Ładunek: %s\nWięź %.0f%% | Głód %.0f | Energia %.0f\nSIŁA %d   ZRĘCZNOŚĆ %d   INT %d\nUmiej.: drwal %.1f  zbier %.1f  bud %.1f  odk %.1f\n\n%s\n%s\nMoce: kamera, przywołaj, błogosław, więź +, krąg życia" % [v.name,v.trait,v.age,family_label(v),v.job,carry_label(v.carry),v.bond*100.0,v.hunger,v.energy,v.str,v.dex,v.int,v.wood,v.gather,v.build,v.knowledge,plan_summary(),family_summary()]

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
	thumb.position=center+v*STICK_RADIUS-Vector2(29,29)
	return v

func reset_stick(center,thumb):
	thumb.position=center-Vector2(29,29)
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

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
const CAMERA_MIN_DISTANCE=5.5
const CAMERA_MAX_DISTANCE=76.0
const CAMERA_HEIGHT_RATIO=0.61
const CAMERA_MIN_HEIGHT=4.2
const CAMERA_MAX_HEIGHT=48.0
const CAMERA_FOCUS_LIMIT=32.0

var rng=RandomNumberGenerator.new()
var people=[]
var stock={"wood":30,"stone":18,"berries":25}
var order="AUTO"
var selected=0
var cam:Camera3D
var cam_focus=Vector3.ZERO
var cam_distance=28.0
var cam_height=17.0
var cam_yaw=0.70
var cam_pitch=0.58
var touches={}
var last_pinch_dist=0.0
var last_pinch_angle=0.0
var retargeter
var anim_ready=false
var hud:Label
var info:Label
var names=["Alda","Sela","Mira","Nara","Ena","Eryk","Oren","Bran","Tovan","Milan"]
var traits=["Pracowita","Odważna","Ciekawska","Śpioch","Spokojna","Silny","Uparty","Myśliciel","Zwinny","Towarzyski"]

func mat(c):
	var m=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=.95; return m
func box(p,s,c):
	var n=MeshInstance3D.new(); var b=BoxMesh.new(); b.size=s; n.mesh=b; n.position=p; n.material_override=mat(c); add_child(n); return n
func cyl(p,r,h,c):
	var n=MeshInstance3D.new(); var m=CylinderMesh.new(); m.top_radius=r; m.bottom_radius=r; m.height=h; n.mesh=m; n.position=p; n.material_override=mat(c); add_child(n); return n
func sphere(p,r,c):
	var n=MeshInstance3D.new(); var m=SphereMesh.new(); m.radius=r; m.height=r*2.0; n.mesh=m; n.position=p; n.material_override=mat(c); add_child(n); return n

func _ready():
	rng.seed=5302026
	var env=WorldEnvironment.new(); var e=Environment.new()
	e.background_mode=Environment.BG_COLOR; e.background_color=Color("#8fa9b3")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color("#fff0d5"); e.ambient_light_energy=.68
	env.environment=e; add_child(env)
	var sun=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-55,-35,0); sun.light_energy=1.35; sun.shadow_enabled=false; add_child(sun)

	var ground=MeshInstance3D.new(); var pm=PlaneMesh.new(); pm.size=Vector2(55,55); ground.mesh=pm; ground.material_override=mat(Color("#536b42")); add_child(ground)
	# river, only 18 segments
	for z in range(-27,28,3):
		var x=8+sin(z*.17)*5
		box(Vector3(x,.02,z),Vector3(6,.08,3.2),Color("#4e8492"))
	# modest vegetation, enough to look like a world without freezing startup
	for i in range(26):
		var p=Vector3(rng.randf_range(-25,25),0,rng.randf_range(-25,25))
		if p.length()<10: continue
		cyl(p+Vector3(0,1.4,0),.22,2.8,Color("#60452d"))
		cyl(p+Vector3(0,3.1,0),.95,2.0,Color("#27512c"))
	for i in range(12):
		var p=Vector3(rng.randf_range(-24,24),.25,rng.randf_range(-24,24))
		box(p,Vector3(.8,.5,.7),Color("#73756f"))

	make_idol()
	make_memory_flower()
	make_house(Vector3(-9,0,-7),8)
	make_house(Vector3(8,0,-8),-12)
	var wagon=WAGON.instantiate(); wagon.position=Vector3(9,0,3); add_child(wagon)
	for p in [Vector3(-9,0,4),Vector3(-8,0,5.5),Vector3(7,0,6)]:
		var c=CRATE.instantiate(); c.position=p; add_child(c)
	for i in range(7):
		var f=FENCE.instantiate(); f.position=Vector3(-9+i*2.4,0,10); add_child(f)

	for i in range(10): make_person(i)

	retargeter=RETARGETER.new()
	add_child(retargeter)
	anim_ready=retargeter.initialize()
	if anim_ready:
		for v in people:
			v["anim"]=retargeter.attach(v.node)

	cam=Camera3D.new(); cam.fov=52; add_child(cam); cam.current=true
	update_camera()
	make_ui()

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

func make_house(p,rot):
	var h=Node3D.new(); h.position=p; h.rotation_degrees.y=rot; h.scale=Vector3(1.05,1.05,1.05); add_child(h)
	var a=WALL.instantiate(); a.position=Vector3(-1.8,0,0); h.add_child(a)
	var b=WALL.instantiate(); b.position=Vector3(1.8,0,0); h.add_child(b)
	var d=DOOR.instantiate(); d.position=Vector3(0,0,-3.5); d.rotation_degrees.y=180; h.add_child(d)
	var r=ROOF.instantiate(); r.position=Vector3(0,3,-1.5); r.scale=Vector3(.65,.65,.65); h.add_child(r)

func make_person(i):
	var n=(FEMALE if i<5 else MALE).instantiate()
	# Diagnostic showed source character is tiny. Correct source-to-world scale here.
	n.scale=Vector3(2.15,2.15,2.15)
	var a=TAU*i/10.0; n.position=Vector3(cos(a)*rng.randf_range(5,10),0,sin(a)*rng.randf_range(5,10)); add_child(n)
	people.append({"node":n,"name":names[i],"trait":traits[i],"str":rng.randi_range(3,9),"dex":rng.randi_range(3,9),"int":rng.randi_range(3,9),"hunger":rng.randf_range(5,25),"energy":rng.randf_range(72,100),"wood":0.0,"gather":0.0,"build":0.0,"target":n.position})

func make_ui():
	var layer=CanvasLayer.new(); add_child(layer)
	var bg=ColorRect.new(); bg.position=Vector2(14,14); bg.size=Vector2(400,135); bg.color=Color(0.02,0.02,0.015,.87); layer.add_child(bg)
	hud=Label.new(); hud.position=Vector2(29,27); hud.add_theme_font_size_override("font_size",17); layer.add_child(hud)
	var menu=VBoxContainer.new(); menu.position=Vector2(1020,18); menu.size=Vector2(235,310); layer.add_child(menu)
	var title=Label.new(); title.text="ROZKAZY IDOLA"; title.add_theme_font_size_override("font_size",19); menu.add_child(title)
	for s in ["AUTO","DREWNO","KAMIEŃ","JAGODY","SZAŁAS","SPICHLERZ","WARSZTAT"]:
		var b=Button.new(); b.text=s; b.custom_minimum_size=Vector2(225,34); b.pressed.connect(func(): set_order(s)); menu.add_child(b)
	var ibg=ColorRect.new(); ibg.position=Vector2(930,430); ibg.size=Vector2(325,260); ibg.color=Color(0.02,0.02,0.015,.87); layer.add_child(ibg)
	info=Label.new(); info.position=Vector2(948,446); info.add_theme_font_size_override("font_size",15); layer.add_child(info)

func set_order(s):
	order=s
	if s=="SZAŁAS" and stock.wood>=18:
		stock.wood-=18; make_house(Vector3(rng.randf_range(-10,10),0,rng.randf_range(-10,10)),rng.randf_range(-180,180))
	elif s=="SPICHLERZ" and stock.wood>=25 and stock.stone>=8:
		stock.wood-=25; stock.stone-=8
		for j in range(3):
			var c=CRATE.instantiate(); c.position=Vector3(-3+j*1.3,0,9); c.scale=Vector3(1.3,1.3,1.3); add_child(c)
	elif s=="WARSZTAT" and stock.wood>=30 and stock.stone>=12:
		stock.wood-=30; stock.stone-=12
		var w=WAGON.instantiate(); w.position=Vector3(-10,0,-1); add_child(w)

func _process(d):
	for v in people:
		var n:Node3D=v.node
		v.hunger=min(100.0,v.hunger+d*.04); v.energy=max(0.0,v.energy-d*.017)
		if n.position.distance_to(v.target)<.65:
			var a=rng.randf_range(0,TAU); var r=rng.randf_range(4,12); v.target=Vector3(cos(a)*r,0,sin(a)*r)
			if order=="DREWNO": stock.wood+=1; v.wood+=.1
			elif order=="KAMIEŃ": stock.stone+=1; v.gather+=.1
			elif order=="JAGODY": stock.berries+=1; v.gather+=.1
			elif order=="AUTO":
				if stock.berries<22: stock.berries+=1; v.gather+=.05
				elif stock.wood<35: stock.wood+=1; v.wood+=.05
		var dir=v.target-n.position
		if dir.length()>.35:
			n.position+=dir.normalized()*d*(.75+v.dex*.035)
			n.look_at(n.position+dir,Vector3.UP)
			if anim_ready and v.has("anim"): retargeter.play(v.anim,"walk")
		else:
			if anim_ready and v.has("anim"): retargeter.play(v.anim,"idle")
	hud.text="IDOL — GENESIS 0.6.3 CAMERA FIX\nLudzie 10   Tryb: %s\nDrewno %d   Kamień %d   Jagody %d\n10 ludzi • retarget animacji • kamera RTS 2.1" % [order,stock.wood,stock.stone,stock.berries]
	var v=people[selected]
	info.text="%s — %s\n\nSIŁA %d   ZRĘCZNOŚĆ %d   INT %d\nGłód %.0f   Energia %.0f\n\nDrwalstwo %.1f\nZbieranie %.1f\nBudowanie %.1f\n\nKamera: 1 palec chwyta mapę • 2 palce zoom/obrót" % [v.name,v.trait,v.str,v.dex,v.int,v.hunger,v.energy,v.wood,v.gather,v.build]

func set_camera_distance(value):
	cam_distance=clamp(value,CAMERA_MIN_DISTANCE,CAMERA_MAX_DISTANCE)
	cam_height=clamp(cam_distance*CAMERA_HEIGHT_RATIO,CAMERA_MIN_HEIGHT,CAMERA_MAX_HEIGHT)

func update_camera():
	cam_focus.x=clamp(cam_focus.x,-CAMERA_FOCUS_LIMIT,CAMERA_FOCUS_LIMIT)
	cam_focus.z=clamp(cam_focus.z,-CAMERA_FOCUS_LIMIT,CAMERA_FOCUS_LIMIT)
	var horizontal=Vector3(sin(cam_yaw),0,cos(cam_yaw))*cam_distance
	cam.position=cam_focus+horizontal+Vector3(0,cam_height,0)
	cam.look_at(cam_focus+Vector3(0,1.2,0),Vector3.UP)

func _unhandled_input(e):
	if e is InputEventScreenTouch:
		if e.pressed:
			touches[e.index]=e.position
			if touches.size()<2:
				last_pinch_dist=0.0
				last_pinch_angle=0.0
		else:
			touches.erase(e.index)
			last_pinch_dist=0.0
			last_pinch_angle=0.0
		update_camera()
		return

	if e is InputEventScreenDrag:
		touches[e.index]=e.position
		if touches.size()==1:
			var right=cam.global_transform.basis.x
			right.y=0
			right=right.normalized()
			var forward=-cam.global_transform.basis.z
			forward.y=0
			forward=forward.normalized()
			var pan_speed=clamp(cam_distance*.00115,.008,.075)
			cam_focus += (-right*e.relative.x+forward*e.relative.y)*pan_speed
		elif touches.size()>=2:
			var ids=touches.keys()
			ids.sort()
			var a:Vector2=touches[ids[0]]
			var b:Vector2=touches[ids[1]]
			var dist=a.distance_to(b)
			var ang=(b-a).angle()
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
		update_camera()

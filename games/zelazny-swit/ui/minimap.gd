extends Control
class_name RPGMinimap

var hero_position: Vector3 = Vector3.ZERO
var enemy_positions: Array = []
var npc_positions: Dictionary = {"merchant":Vector3(-6,0,0),"blacksmith":Vector3(6,0,0)}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO,size)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(0.055,0.105,0.12,0.92)
	box.border_color = Color("927c52")
	box.set_border_width_all(1)
	box.set_corner_radius_all(12)
	draw_style_box(box,rect)
	var p: Vector2 = size*0.5
	var scale_map: float = size.x/65.0
	draw_line(p+Vector2(0,55),p+Vector2(0,-45),Color("62705a"),7,true)
	draw_line(p+Vector2(-41,5),p+Vector2(40,5),Color("62705a"),5,true)
	for house: Vector2 in [Vector2(-18,13),Vector2(18,15),Vector2(-16,-8),Vector2(18,-10)]:
		draw_rect(Rect2(p+house*scale_map-Vector2(7,5),Vector2(14,10)),Color("4d625c"))
	for key: Variant in npc_positions:
		var pos: Vector3 = npc_positions[key]
		var pt: Vector2 = p+Vector2(pos.x,pos.z)*scale_map
		draw_circle(pt,4,Color("e3bc70"))
	for v: Variant in enemy_positions:
		var pos: Vector3 = v if v is Vector3 else (v.global_position if is_instance_valid(v) and v is Node3D else Vector3.ZERO)
		var pt: Vector2 = p+Vector2(pos.x,pos.z)*scale_map
		if pt.x>8 and pt.x<size.x-8 and pt.y>8 and pt.y<size.y-8:
			draw_circle(pt,2.5,Color("d77866"))
	var hero: Vector2 = (Vector2(hero_position.x,hero_position.z)*scale_map).limit_length(size.x*0.45)+p
	draw_circle(hero,6,Color(0.35,0.95,0.79,0.2))
	draw_colored_polygon(PackedVector2Array([hero+Vector2(0,-6),hero+Vector2(-4,5),hero+Vector2(0,3),hero+Vector2(4,5)]),Color("c3f6df"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x*0.5-5,15),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e3bc70"))

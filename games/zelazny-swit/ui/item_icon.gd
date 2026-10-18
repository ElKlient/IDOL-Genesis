extends Control
class_name RPGItemIcon

var kind: String = "weapon"
var tier: int = 1
var accent: Color = Color("b8d3d9")
var icon_scale: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var p: Vector2 = size * 0.5
	var u: float = s / 80.0 * icon_scale
	if u <= 0.0:
		return
	draw_set_transform(p, -0.45 if kind == "weapon" else 0.0, Vector2(u, u))
	match kind:
		"weapon", "sword":
			var length: float = 26.0 + tier * 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 10), Vector2(-5, -length + 8), Vector2(0, -length), Vector2(5, -length + 8), Vector2(5, 10)]), accent)
			draw_colored_polygon(PackedVector2Array([Vector2(0, 10), Vector2(0, -length), Vector2(5, -length + 8), Vector2(5, 10)]), accent.darkened(0.28))
			draw_line(Vector2(-2, 6), Vector2(-2, -length + 9), Color("edf7f4"), 1.3, true)
			draw_style_box(_box(Color("9b713a"), 2), Rect2(-14, 8, 28, 6))
			draw_rect(Rect2(-3, 14, 6, 15), Color("704d32"))
			for y in range(16, 28, 4):
				draw_line(Vector2(-3, y), Vector2(3, y + 2), Color("bb9454"), 1.5, true)
			draw_circle(Vector2(0, 30), 4.5, Color("d4b875"))
			if tier >= 3:
				draw_circle(Vector2(0, 11), 3.5, Color("52cbb2"))
		"armor":
			draw_colored_polygon(PackedVector2Array([Vector2(-10,-26),Vector2(-25,-18),Vector2(-30,-4),Vector2(-20,0),Vector2(-16,-7),Vector2(-14,27),Vector2(14,27),Vector2(16,-7),Vector2(20,0),Vector2(30,-4),Vector2(25,-18),Vector2(10,-26),Vector2(7,-16),Vector2(-7,-16)]), accent)
			draw_colored_polygon(PackedVector2Array([Vector2(0,-15),Vector2(14,-20),Vector2(16,-7),Vector2(14,27),Vector2(0,27)]), accent.darkened(0.24))
			draw_polyline(PackedVector2Array([Vector2(-10,-26),Vector2(-7,-16),Vector2(7,-16),Vector2(10,-26)]), Color("dcc38b"), 3, true)
			draw_line(Vector2(-12,17),Vector2(12,17),Color("725337"),5,true)
			draw_rect(Rect2(-4,14,8,6),Color("dec38b"),false,2)
			if tier >= 2:
				draw_polyline(PackedVector2Array([Vector2(-10,-5),Vector2(0,7),Vector2(10,-5)]),Color("e4d2a4"),2,true)
		"potion":
			draw_rect(Rect2(-7,-28,14,11),Color("c39b60"))
			draw_style_box(_box(Color("acc8cc"),5),Rect2(-10,-21,20,10))
			draw_circle(Vector2(0,8),21,Color("4a6671"))
			draw_circle(Vector2(0,10),17,Color("a73e58"))
			draw_colored_polygon(PackedVector2Array([Vector2(-16,4),Vector2(16,4),Vector2(18,12),Vector2(11,24),Vector2(-11,24),Vector2(-18,12)]),Color("d0576b"))
			draw_arc(Vector2(0,8),19,3.1,4.2,10,Color("d9eff0"),2,true)
			draw_line(Vector2(-7,12),Vector2(7,12),Color("ffe7cb"),4,true)
			draw_line(Vector2(0,5),Vector2(0,19),Color("ffe7cb"),4,true)
		"stone":
			draw_colored_polygon(PackedVector2Array([Vector2(0,-29),Vector2(21,-7),Vector2(14,23),Vector2(-12,27),Vector2(-24,-2)]),Color("45b8bb"))
			draw_colored_polygon(PackedVector2Array([Vector2(0,-29),Vector2(4,0),Vector2(-12,27),Vector2(-24,-2)]),Color("78e0cf"))
			draw_colored_polygon(PackedVector2Array([Vector2(4,0),Vector2(21,-7),Vector2(14,23),Vector2(-12,27)]),Color("2c758a"))
			draw_polyline(PackedVector2Array([Vector2(0,-29),Vector2(4,0),Vector2(14,23)]),Color("b5fff0"),1.8,true)
		"bag":
			draw_arc(Vector2(0,-13),12,PI,TAU,16,accent,4,true)
			draw_style_box(_box(accent.darkened(0.2),7),Rect2(-24,-13,48,43))
			draw_line(Vector2(-21,0),Vector2(21,0),accent,3,true)
			draw_rect(Rect2(-4,-4,8,12),Color("e8cf8b"))
		"skill":
			var points: PackedVector2Array = PackedVector2Array()
			for i in range(16):
				var a: float = float(i) * PI / 8.0 - PI * 0.5
				points.append(Vector2(cos(a),sin(a))*(29.0 if i%2 == 0 else 12.0))
			draw_colored_polygon(points,accent)
			draw_circle(Vector2.ZERO,7,Color("e9f5db"))
		"forge":
			draw_colored_polygon(PackedVector2Array([Vector2(-29,0),Vector2(28,0),Vector2(19,11),Vector2(8,13),Vector2(9,24),Vector2(22,28),Vector2(-22,28),Vector2(-9,24),Vector2(-8,13),Vector2(-20,11)]),accent)
			draw_line(Vector2(4,-9),Vector2(-5,-29),Color("b5834d"),7,true)
			draw_line(Vector2(-17,-23),Vector2(7,-35),Color("d3d9cd"),10,true)
		"interact":
			draw_arc(Vector2.ZERO,24,0.2,TAU-0.2,32,accent,3,true)
			draw_circle(Vector2(-8,-3),2.5,accent)
			draw_circle(Vector2(0,-3),2.5,accent)
			draw_circle(Vector2(8,-3),2.5,accent)
			draw_polyline(PackedVector2Array([Vector2(-13,21),Vector2(-20,28),Vector2(-19,14)]),accent,3,true)
		"menu":
			for y in [-14,0,14]:
				draw_line(Vector2(-23,y),Vector2(23,y),accent,4,true)
	draw_set_transform(Vector2.ZERO)

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	return b

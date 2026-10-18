extends Control
class_name RPGTouchPad

signal pressed
signal released

var glyph: String = "weapon"
var accent: Color = Color("e8c17f")
var is_down: bool = false
var enabled: bool = true
var finger: int = -999
var caption: String = ""
var cooldown_ratio: float = 0.0
var icon: RPGItemIcon

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon = RPGItemIcon.new()
	icon.kind = glyph
	icon.accent = accent
	add_child(icon)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if is_instance_valid(icon):
		icon.position = size * 0.2
		icon.size = size * 0.6
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree():
		if is_down:
			_release()
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -999 and _contains(event.position):
			finger = event.index
			is_down = true
			pressed.emit()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and finger == -999 and _contains(event.position):
			finger = -2
			is_down = true
			pressed.emit()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not event.pressed and finger == -2:
			_release()

func _contains(point: Vector2) -> bool:
	return point.distance_to(global_position + size*0.5) <= minf(size.x,size.y)*0.5

func _release() -> void:
	finger = -999
	is_down = false
	released.emit()
	queue_redraw()

func _draw() -> void:
	var r: float = minf(size.x,size.y)*0.5-2.0
	var p: Vector2 = size*0.5
	draw_circle(p,r,Color(0.055,0.105,0.13,0.9) if not is_down else Color("23474c"))
	draw_arc(p,r,0,TAU,60,accent if is_down else Color(accent,0.65),2,true)
	draw_arc(p,r-6,0,TAU,60,Color(accent,0.12),1,true)
	if is_down:
		draw_circle(p,r-9,Color(accent,0.1))
	if cooldown_ratio > 0.01:
		draw_arc(p,r-3,-PI*0.5,-PI*0.5+TAU*cooldown_ratio,48,Color("9fd7c4"),5,true)
		icon.modulate.a = 0.35
	else:
		icon.modulate.a = 1.0

extends Control
class_name RPGJoystick

var vector: Vector2 = Vector2.ZERO
var enabled: bool = true:
	set(value):
		enabled = value
		if not value:
			_reset()
var finger: int = -999
var stick: Vector2 = Vector2.ZERO
var _mouse_guard_until: int = 0
var _application_focused: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_application_focused = false
		_reset()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_application_focused = true
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_reset()

func _input(event: InputEvent) -> void:
	if not enabled or not _application_focused or not is_visible_in_tree():
		_reset()
		return
	var center: Vector2 = global_position + size*0.5
	if event is InputEventScreenTouch:
		if event.canceled:
			if event.index == finger:
				_reset()
				get_viewport().set_input_as_handled()
			return
		if event.pressed and finger == -999 and event.position.distance_to(center) < size.x*0.6:
			finger = event.index
			_mouse_guard_until = Time.get_ticks_msec()+250
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			_reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		_update_stick(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Godot can emit the synthetic mouse press before the original touch.
		# It must not steal the real finger needed for simultaneous camera drag.
		if event.device < 0 or finger >= 0 or Time.get_ticks_msec() < _mouse_guard_until:
			return
		if event.pressed and finger == -999 and event.position.distance_to(center) < size.x*0.6:
			finger = -2
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and finger == -2:
			_reset()
	elif event is InputEventMouseMotion and finger == -2:
		if event.device < 0 or Time.get_ticks_msec() < _mouse_guard_until:
			return
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
			_reset()
			return
		_update_stick(event.position)

func _update_stick(point: Vector2) -> void:
	stick = (point-global_position-size*0.5).limit_length(size.x*0.34)
	vector = stick/(size.x*0.34)
	if vector.length() < 0.12:
		vector = Vector2.ZERO
	queue_redraw()

func _reset() -> void:
	if finger >= 0:
		_mouse_guard_until = Time.get_ticks_msec()+250
	if finger == -999 and vector == Vector2.ZERO:
		return
	finger = -999
	stick = Vector2.ZERO
	vector = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var p: Vector2 = size*0.5
	var r: float = size.x*0.46
	draw_circle(p,r,Color(0.04,0.09,0.11,0.48))
	draw_arc(p,r,0,TAU,64,Color(0.74,0.82,0.73,0.3),1.5,true)
	draw_arc(p,r*0.63,0,TAU,48,Color(0.74,0.82,0.73,0.12),1,true)
	for v: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		draw_line(p+v*r*0.78,p+v*r*0.88,Color(0.8,0.86,0.77,0.45),2,true)
	draw_circle(p+stick,r*0.37,Color(0.13,0.24,0.26,0.96))
	draw_arc(p+stick,r*0.37,0,TAU,48,Color("a7bca9"),2,true)
	draw_circle(p+stick,r*0.25,Color(0.75,0.82,0.72,0.1))

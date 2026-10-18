extends Control
class_name CameraOrbitPad
## Captures one pointer while the other hand remains free to move the hero.

signal orbit_requested(delta: Vector2)

const MOUSE_GUARD_MSEC: int = 250

var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			cancel_drag()
		queue_redraw()
var finger: int = -1
var mouse_dragging: bool = false
var _last_pointer: Vector2 = Vector2.ZERO
var _ignore_mouse_until: int = 0
var _application_focused: bool = true
var _frame: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_frame = StyleBoxFlat.new()
	_frame.bg_color = Color(0.04,0.09,0.11,0.70)
	_frame.border_color = Color(0.64,0.74,0.67,0.40)
	_frame.set_border_width_all(1)
	_frame.set_corner_radius_all(12)
	var title: Label = Label.new()
	title.text = "KAMERA"
	title.add_theme_font_size_override("font_size",13)
	title.add_theme_color_override("font_color",Color("e5d7b4"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.position = Vector2(49,11)
	add_child(title)
	var hint: Label = Label.new()
	hint.text = "PRZECIĄGNIJ"
	hint.add_theme_font_size_override("font_size",9)
	hint.add_theme_color_override("font_color",Color(0.78,0.85,0.79,0.72))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -21
	hint.offset_bottom = -5
	add_child(hint)
	resized.connect(queue_redraw)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_application_focused = false
		cancel_drag()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_application_focused = true
	elif what == NOTIFICATION_VISIBILITY_CHANGED:
		if not is_visible_in_tree():
			cancel_drag()

func cancel_drag() -> void:
	if finger >= 0:
		_ignore_mouse_until = Time.get_ticks_msec()+MOUSE_GUARD_MSEC
	finger = -1
	mouse_dragging = false
	_last_pointer = Vector2.ZERO
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled or not _application_focused or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.canceled:
			if event.index == finger:
				cancel_drag()
				get_viewport().set_input_as_handled()
			return
		if event.pressed:
			if get_global_rect().has_point(event.position):
				if finger < 0 and not mouse_dragging:
					finger = event.index
					_last_pointer = event.position
					_ignore_mouse_until = Time.get_ticks_msec()+MOUSE_GUARD_MSEC
					queue_redraw()
				# A second finger in this field cannot select a world target.
				get_viewport().set_input_as_handled()
		elif event.index == finger:
			cancel_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		_move_pointer(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device < 0 or finger >= 0 or Time.get_ticks_msec() < _ignore_mouse_until:
			return
		if event.pressed:
			if get_global_rect().has_point(event.position):
				mouse_dragging = true
				_last_pointer = event.position
				queue_redraw()
				get_viewport().set_input_as_handled()
		elif mouse_dragging:
			cancel_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_dragging:
		if event.device < 0 or finger >= 0 or Time.get_ticks_msec() < _ignore_mouse_until:
			return
		if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			cancel_drag()
			return
		_move_pointer(event.position)
		get_viewport().set_input_as_handled()

func _move_pointer(point: Vector2) -> void:
	var delta: Vector2 = point-_last_pointer
	_last_pointer = point
	if delta.is_finite() and not delta.is_zero_approx():
		orbit_requested.emit(delta.limit_length(160.0))
	queue_redraw()

func _draw() -> void:
	if _frame == null:
		return
	draw_style_box(_frame,Rect2(Vector2.ZERO,size))
	var ink: Color = Color("b9c9b7") if enabled else Color("63766a")
	# Original camera glyph and a quiet four-way drag marker.
	draw_style_box(_rounded_box(Color(ink,0.75),3),Rect2(18,17,24,15))
	draw_rect(Rect2(23,13,11,5),ink)
	draw_circle(Vector2(30,24.5),4.5,Color("152c31"))
	draw_arc(Vector2(30,24.5),4.5,0,TAU,18,ink,1.2,true)
	var center: Vector2 = Vector2(size.x*0.5,58)
	draw_line(center+Vector2(-27,0),center+Vector2(27,0),Color(ink,0.50),1.5,true)
	draw_line(center+Vector2(0,-13),center+Vector2(0,13),Color(ink,0.50),1.5,true)
	for direction: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var length: float = 27.0 if direction.x != 0 else 13.0
		var end: Vector2 = center+direction*length
		var side: Vector2 = direction.orthogonal()*3.5
		draw_polyline(PackedVector2Array([end-direction*4+side,end,end-direction*4-side]),ink,1.3,true)
	draw_circle(center,3,Color(ink,0.85))
	if finger >= 0 or mouse_dragging:
		var local_pointer: Vector2 = (_last_pointer-global_position).clamp(Vector2(8,8),size-Vector2(8,8))
		draw_circle(local_pointer,10,Color(1.0,0.85,0.52,0.12))
		draw_arc(local_pointer,10,0,TAU,24,Color("e4bd77"),1.5,true)

func _rounded_box(color: Color,radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.045, 0.050))
	draw_rect(Rect2(Vector2(0, 0), Vector2(w, h * 0.55)), Color(0.055, 0.075, 0.085, 0.70))
	draw_rect(Rect2(Vector2(0, h * 0.45), Vector2(w, h * 0.55)), Color(0.030, 0.038, 0.036, 0.86))
	draw_rect(Rect2(Vector2(0, h * 0.31), Vector2(w, h * 0.20)), Color(0.12, 0.18, 0.17, 0.10))

	var road := PackedVector2Array([
		Vector2(w * 0.05, h),
		Vector2(w * 0.36, h * 0.48),
		Vector2(w * 0.58, h * 0.48),
		Vector2(w * 0.96, h),
	])
	draw_colored_polygon(road, Color(0.09, 0.095, 0.092, 0.92))

	var line_left := Vector2(w * 0.45, h * 0.56)
	var line_right := Vector2(w * 0.56, h)
	draw_line(line_left, line_right, Color(0.78, 0.70, 0.48, 0.28), maxf(2.0, w * 0.006))
	for dash_index in range(4):
		var y1: float = h * (0.60 + float(dash_index) * 0.10)
		var y2: float = y1 + h * 0.045
		var x1: float = w * (0.48 + float(dash_index) * 0.012)
		var x2: float = w * (0.50 + float(dash_index) * 0.018)
		draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.84, 0.78, 0.55, 0.18), maxf(2.0, w * 0.004))

	var truck_origin := Vector2(w * 0.14, h * 0.64)
	var truck_w := w * 0.72
	var truck_h := h * 0.14
	var body := Rect2(truck_origin + Vector2(truck_w * 0.22, truck_h * 0.18), Vector2(truck_w * 0.56, truck_h * 0.42))
	var cabin := Rect2(truck_origin + Vector2(truck_w * 0.04, 0), Vector2(truck_w * 0.22, truck_h * 0.60))
	var trailer := Rect2(truck_origin + Vector2(truck_w * 0.28, truck_h * 0.04), Vector2(truck_w * 0.58, truck_h * 0.44))

	draw_rect(trailer, Color(0.78, 0.84, 0.82, 0.10))
	draw_rect(body, Color(0.12, 0.16, 0.16, 0.62))
	draw_rect(cabin, Color(0.15, 0.20, 0.21, 0.68))
	draw_line(cabin.position + Vector2(cabin.size.x * 0.72, 0), cabin.position + Vector2(cabin.size.x * 0.92, cabin.size.y), Color(0.78, 0.84, 0.82, 0.18), 3.0)
	draw_rect(Rect2(cabin.position + Vector2(cabin.size.x * 0.12, cabin.size.y * 0.18), Vector2(cabin.size.x * 0.42, cabin.size.y * 0.24)), Color(0.72, 0.84, 0.90, 0.14))
	draw_circle(truck_origin + Vector2(truck_w * 0.07, truck_h * 0.48), truck_h * 0.055, Color(1.0, 0.82, 0.48, 0.30))
	draw_line(truck_origin + Vector2(truck_w * 0.06, truck_h * 0.50), truck_origin + Vector2(-truck_w * 0.12, truck_h * 0.62), Color(1.0, 0.76, 0.35, 0.08), maxf(5.0, w * 0.010))
	draw_circle(truck_origin + Vector2(truck_w * 0.22, truck_h * 0.68), truck_h * 0.16, Color(0.02, 0.025, 0.025, 0.75))
	draw_circle(truck_origin + Vector2(truck_w * 0.70, truck_h * 0.68), truck_h * 0.16, Color(0.02, 0.025, 0.025, 0.75))

	draw_circle(Vector2(w * 0.82, h * 0.14), w * 0.19, Color(0.82, 0.64, 0.35, 0.055))
	draw_circle(Vector2(w * 0.15, h * 0.22), w * 0.28, Color(0.24, 0.42, 0.38, 0.045))
	draw_rect(Rect2(Vector2(0, 0), Vector2(w, h * 0.18)), Color(0.0, 0.0, 0.0, 0.16))
	draw_rect(Rect2(Vector2(0, h * 0.82), Vector2(w, h * 0.18)), Color(0.0, 0.0, 0.0, 0.20))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.22))

	var font := get_theme_default_font()
	if font != null:
		var sign_width := trailer.size.x * 0.68
		var sign_x := trailer.position.x + trailer.size.x * 0.15
		var sign_y := trailer.position.y + trailer.size.y * 0.48
		var sign_color := Color(1.0, 1.0, 1.0, 0.52)
		draw_string(font, Vector2(sign_x, sign_y), "Dasko", HORIZONTAL_ALIGNMENT_CENTER, sign_width, max(12, int(w * 0.026)), sign_color)
		draw_string(font, Vector2(sign_x, sign_y + h * 0.025), "Always too late", HORIZONTAL_ALIGNMENT_CENTER, sign_width, max(8, int(w * 0.014)), sign_color)

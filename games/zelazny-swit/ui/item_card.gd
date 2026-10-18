extends PanelContainer
class_name RPGItemCard

signal selected(uid: int)
signal catalog_selected(id: String)

var item: Dictionary = {}
var draggable: bool = false
var catalog_entry: bool = false
var chosen: bool = false
var equipped: bool = false
var compact: bool = false
var drag_started: bool = false
var accent: Color = Color("e0c08a")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(_on_input)
	_build()

func _build() -> void:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = Color("213d43") if chosen else Color("162b32")
	var family_color: Color = item.get("color",Color("a7bbb4"))
	b.border_color = Color("d6b577") if chosen else (family_color.darkened(0.55) if item.has("set_name") else Color("39504e"))
	b.set_border_width_all(2 if chosen else 1)
	b.set_corner_radius_all(9)
	b.content_margin_left = 12
	b.content_margin_right = 12
	b.content_margin_top = 9
	b.content_margin_bottom = 9
	add_theme_stylebox_override("panel",b)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var icon: RPGItemIcon = RPGItemIcon.new()
	icon.kind = str(item.get("icon",item.get("kind","weapon")))
	icon.tier = int(item.get("tier",1))
	icon.accent = item.get("color",Color("b8d3d9"))
	icon.custom_minimum_size = Vector2(54,64 if compact else 72)
	row.add_child(icon)
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation",4)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var family: String = str(item.get("set_name",""))
	if not family.is_empty():
		var family_label := Label.new()
		family_label.text = family.to_upper()
		family_label.add_theme_font_size_override("font_size",10)
		family_label.add_theme_color_override("font_color",family_color)
		family_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(family_label)
	var title: Label = Label.new()
	title.text = str(item.get("name","Przedmiot"))
	if not catalog_entry and int(item.get("upgrade",0)) > 0:
		title.text += " +%d" % int(item.get("upgrade",0))
	title.add_theme_font_size_override("font_size",17 if compact else 18)
	title.add_theme_color_override("font_color",Color("f3e4c6"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(title)
	var detail: Label = Label.new()
	var kind: String = str(item.get("kind","weapon"))
	if kind == "weapon" or kind == "armor":
		var p: int = int(item.get("power",0))
		if not catalog_entry:
			p = GameState.item_power(item)
		detail.text = ("ATAK  " if kind == "weapon" else "OBRONA  ") + str(p)
	else:
		detail.text = str(item.get("description","Przedmiot użytkowy"))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size",14)
	detail.add_theme_color_override("font_color",Color("a2b8b0"))
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(detail)
	if catalog_entry or equipped:
		var note: Label = Label.new()
		note.text = "%d złota" % int(item.get("price",0)) if catalog_entry else "ZAŁOŻONO"
		note.add_theme_font_size_override("font_size",15 if catalog_entry else 12)
		note.add_theme_color_override("font_color",Color("e3bc70") if catalog_entry else Color("70c9ad"))
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(note)

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if drag_started:
			drag_started = false
			return
		if catalog_entry:
			catalog_selected.emit(str(item.get("id","")))
		else:
			selected.emit(int(item.get("uid",0)))

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable:
		return null
	drag_started = true
	var preview: PanelContainer = PanelContainer.new()
	preview.custom_minimum_size = Vector2(160,70)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("25464a")
	box.border_color = Color("ddbe7d")
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	preview.add_theme_stylebox_override("panel",box)
	var label: Label = Label.new()
	label.text = str(item.get("name",""))
	label.add_theme_font_size_override("font_size",18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(label)
	set_drag_preview(preview)
	return {"item_uid":int(item.get("uid",0))}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_started = false

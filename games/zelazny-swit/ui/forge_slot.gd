extends PanelContainer
class_name RPGForgeSlot

signal item_dropped(uid: int)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item_uid")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(int(data["item_uid"]))

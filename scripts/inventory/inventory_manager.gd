extends Node

signal item_added(item: ItemData)
signal item_removed(item_id: String)
signal inventory_changed()

var _items: Dictionary = {}

func add_item(item: ItemData) -> bool:
	if item == null or item.id.is_empty():
		push_warning("InventoryManager: попытка добавить пустой предмет!")
		return false
	_items[item.id] = item
	item_added.emit(item)
	inventory_changed.emit()
	return true

func remove_item(item_id: String) -> bool:
	if _items.has(item_id):
		_items.erase(item_id)
		item_removed.emit(item_id)
		inventory_changed.emit()
		return true
	return false

func has_item(item_id: String) -> bool:
	return _items.has(item_id)

func get_item(item_id: String) -> ItemData:
	return _items.get(item_id, null)

func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for key in _items:
		result.append(_items[key])
	return result

func clear() -> void:
	_items.clear()
	inventory_changed.emit()

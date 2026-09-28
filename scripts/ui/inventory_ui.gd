class_name InventoryUI
extends CanvasLayer

signal inventory_opened()
signal inventory_closed()

const SLOT_COUNT: int = 12

@onready var root_panel: Control = $Root
@onready var grid_container: GridContainer = $Root/PanelContainer/MarginContainer/HBoxContainer/LeftBox/GridContainer
@onready var detail_panel: Control = $Root/PanelContainer/MarginContainer/HBoxContainer/RightBox
@onready var detail_name: Label = $Root/PanelContainer/MarginContainer/HBoxContainer/RightBox/ItemName
@onready var detail_icon: TextureRect = $Root/PanelContainer/MarginContainer/HBoxContainer/RightBox/ItemIcon
@onready var detail_desc: Label = $Root/PanelContainer/MarginContainer/HBoxContainer/RightBox/ItemDesc
@onready var detail_type: Label = $Root/PanelContainer/MarginContainer/HBoxContainer/RightBox/ItemType

var is_open: bool = false
var _selected_item: ItemData = null

func _ready() -> void:
	root_panel.visible = false
	is_open = false
	
	if InventoryManager:
		InventoryManager.inventory_changed.connect(refresh_inventory)
	
	_clear_detail()
	refresh_inventory()

func _input(event: InputEvent) -> void:
	var toggle_pressed = event.is_action_pressed("inventory")
	
	# Hardware keycode fallback (TAB or I)
	if not toggle_pressed and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB or event.physical_keycode == KEY_I:
			toggle_pressed = true
	
	if toggle_pressed:
		get_viewport().set_input_as_handled()
		toggle()
	elif is_open and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	is_open = true
	root_panel.visible = true
	refresh_inventory()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	inventory_opened.emit()

func close() -> void:
	is_open = false
	root_panel.visible = false
	_clear_detail()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	inventory_closed.emit()

func refresh_inventory() -> void:
	if grid_container == null:
		return
	
	# Clear existing slot children
	for child in grid_container.get_children():
		child.queue_free()
	
	var items = InventoryManager.get_all_items() if InventoryManager else []
	
	for i in range(SLOT_COUNT):
		if i < items.size():
			var item = items[i]
			grid_container.add_child(_create_item_slot(item))
		else:
			grid_container.add_child(_create_empty_slot())
	
	# Re-select previous item or clear detail
	if _selected_item and InventoryManager and InventoryManager.has_item(_selected_item.id):
		_show_item_detail(_selected_item)
	elif not items.is_empty():
		_show_item_detail(items[0])
	else:
		_clear_detail()

func _create_item_slot(item: ItemData) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 96)
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Custom styled slot
	var slot_panel := PanelContainer.new()
	slot_panel.custom_minimum_size = Vector2(96, 96)
	slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_theme_stylebox_override("panel", _create_slot_style(
		Color(0.12, 0.10, 0.08, 0.95),
		Color(0.85, 0.65, 0.28, 0.95),
		2
	))
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(44, 44)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = item.icon
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_rect)
	
	var label := Label.new()
	label.text = item.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.modulate = Color(0.95, 0.9, 0.8, 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)
	
	btn.add_child(slot_panel)
	
	# Connect click and hover
	btn.pressed.connect(func(): _show_item_detail(item))
	btn.mouse_entered.connect(func(): _show_item_detail(item))
	
	return btn

func _create_empty_slot() -> Control:
	var slot_panel := PanelContainer.new()
	slot_panel.custom_minimum_size = Vector2(96, 96)
	slot_panel.add_theme_stylebox_override("panel", _create_slot_style(
		Color(0.06, 0.05, 0.05, 0.7),
		Color(0.25, 0.22, 0.18, 0.5),
		1
	))
	return slot_panel

func _create_slot_style(bg_col: Color, border_col: Color, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 4
	return sb

func _show_item_detail(item: ItemData) -> void:
	_selected_item = item
	if item == null:
		_clear_detail()
		return
	
	detail_panel.visible = true
	detail_name.text = item.name
	detail_desc.text = item.description if not item.description.is_empty() else "Предмет не содержит описания."
	detail_type.text = "Тип: " + item.type.capitalize()
	
	if item.icon:
		detail_icon.texture = item.icon
		detail_icon.visible = true
	else:
		detail_icon.visible = false

func _clear_detail() -> void:
	if detail_name:
		detail_name.text = "Выберите предмет"
	if detail_desc:
		detail_desc.text = "Наведите курсор или кликните по предмету в сетке инвентаря."
	if detail_type:
		detail_type.text = ""
	if detail_icon:
		detail_icon.texture = null
		detail_icon.visible = false

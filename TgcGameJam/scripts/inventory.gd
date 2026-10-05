extends CanvasLayer


@onready var panel: PanelContainer = $Panel
@onready var slots: Array = $Panel/VBox/Slots.get_children()
const slot_count = 3


func _ready() -> void:
	panel.visible = false
	refresh()


func toggle() -> void:
	panel.visible = not panel.visible
	GameState.gameState.inventory_open = panel.visible
	if panel.visible:
		refresh()


func refresh() -> void:
	for i in slot_count:
		var icon: TextureRect = slots[i].get_node("Frame/Icon")
		var label: Label = slots[i].get_node("Name")
		if i < GameState.items.size():
			var item: Dictionary = GameState.items[i]
			icon.texture = load(item.image) if ResourceLoader.exists(item.image) else null
			label.text = item.name
		else:
			icon.texture = null
			label.text = ""

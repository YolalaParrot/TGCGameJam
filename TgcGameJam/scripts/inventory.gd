extends CanvasLayer


@onready var panel: PanelContainer = $Panel
@onready var slots: Array = $Panel/VBox/Slots.get_children()
@onready var task_separator: HSeparator = $Panel/VBox/Separator
@onready var task_label: Label = $Panel/VBox/Task
@onready var comet_label: Label = $Panel/VBox/Comet
@onready var side_quest_label: Label = $Panel/VBox/SideQuests
const slot_count = 3


func _ready() -> void:
	panel.visible = false
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if panel.visible and event.is_action_pressed("ui_close_dialog"):
		get_viewport().set_input_as_handled()
		toggle()


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

	var task := GameState.get_current_tasks()
	task_label.visible = not task.is_empty()
	task_separator.visible = task_label.visible
	task_label.text = "Task: " + task.get("name", "")
	comet_label.text = GameState.comet_text()
	comet_label.visible = comet_label.text != ""

	var quests := GameState.side_quest_lines()
	side_quest_label.visible = not quests.is_empty()
	side_quest_label.text = "Side quests:\n" + "\n".join(quests)

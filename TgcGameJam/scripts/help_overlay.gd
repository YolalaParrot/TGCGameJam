extends CanvasLayer

@onready var panel: PanelContainer = $Panel


func _ready() -> void:
	panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("help"):
		get_viewport().set_input_as_handled()
		panel.visible = not panel.visible
	elif panel.visible and event.is_action_pressed("ui_close_dialog"):
		get_viewport().set_input_as_handled()
		panel.visible = false

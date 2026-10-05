extends Control

@export var scroll_time := 15.0

@onready var credits_text: RichTextLabel = $CreditsText

var done := false


func _ready() -> void:
	Inventory.panel.visible = false
	TaskOverlay.get_node("Panel").visible = false
	await get_tree().process_frame
	var screen := get_viewport_rect().size
	credits_text.position.y = screen.y
	var tween := create_tween()
	tween.tween_property(credits_text, "position:y", (screen.y - credits_text.size.y) / 2.0, scroll_time)
	tween.tween_callback(func(): done = true)


func _unhandled_input(event: InputEvent) -> void:
	if done and event.is_pressed():
		get_tree().quit()

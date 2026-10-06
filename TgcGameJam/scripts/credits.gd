extends Control

@export var scroll_time := 15.0
@export var achievement_time := 2.5

@onready var credits_text: RichTextLabel = $CreditsText

var done := false


func _ready() -> void:
	Inventory.panel.visible = false
	TaskOverlay.get_node("Panel").visible = false
	await get_tree().process_frame
	var screen := get_viewport_rect().size
	credits_text.position.y = screen.y
	await show_achievements()
	var tween := create_tween()
	tween.tween_property(credits_text, "position:y", (screen.y - credits_text.size.y) / 2.0, scroll_time)
	tween.tween_callback(func(): done = true)


func _unhandled_input(event: InputEvent) -> void:
	if done and event.is_pressed():
		get_tree().quit()


func show_achievements() -> void:
	var unlocked := []
	for id in GameState.achievements:
		if GameState.flags.get("achievement_" + id, false):
			unlocked.append(GameState.achievements[id].name)
	var line := Label.new()
	line.text = "Achievements %d/%d" % [unlocked.size(), GameState.achievements.size()]
	line.text += ("  -  " + ", ".join(unlocked)) if not unlocked.is_empty() else "  -  someone was left behind..."
	line.add_theme_font_override("font", credits_text.get_theme_font("normal_font"))
	line.add_theme_font_size_override("font_size", 16)
	line.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.modulate.a = 0.0
	add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 1.0, 0.5)
	tween.tween_interval(achievement_time)
	tween.tween_property(line, "modulate:a", 0.0, 0.5)
	await tween.finished
	line.queue_free()

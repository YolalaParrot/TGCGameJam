extends CanvasLayer

const fade := 0.25

@onready var root: Control = $Root
@onready var glow: TextureRect = $Root/Glow
@onready var icon: TextureRect = $Root/Icon


func _ready() -> void:
	root.visible = false


func show_item(texture: Texture2D, show_time: float) -> void:
	icon.texture = texture
	root.visible = true
	root.modulate.a = 0.0
	glow.pivot_offset = glow.size / 2.0
	glow.scale = Vector2(0.7, 0.7)
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, fade)
	tween.parallel().tween_property(glow, "scale", Vector2.ONE, fade)
	tween.tween_interval(show_time)
	tween.tween_property(root, "modulate:a", 0.0, fade)
	await tween.finished
	root.visible = false

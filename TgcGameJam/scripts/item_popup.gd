extends CanvasLayer

const FADE := 0.25

@onready var root: Control = $Root
@onready var glow: TextureRect = $Root/Glow
@onready var icon: TextureRect = $Root/Icon


func _ready() -> void:
	root.visible = false


# Shows an item at its own size in the middle of the screen with a soft light behind it.
# Fades in, stays for show_time, fades out. Await it to know when it is gone.
func show_item(texture: Texture2D, show_time: float) -> void:
	icon.texture = texture
	root.visible = true
	root.modulate.a = 0.0
	glow.pivot_offset = glow.size / 2.0
	glow.scale = Vector2(0.7, 0.7)
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, FADE)
	tween.parallel().tween_property(glow, "scale", Vector2.ONE, FADE)
	tween.tween_interval(show_time)
	tween.tween_property(root, "modulate:a", 0.0, FADE)
	await tween.finished
	root.visible = false

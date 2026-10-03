extends CanvasLayer


@onready var fade_rect: ColorRect = $FullScreen/Fade


func _ready() -> void:
	if fade_rect == null:
		push_error("FADE NODE NOT FOUND!")
		return

	fade_rect.modulate.a = 0.0


func fade_out(duration: float = 0.2) -> void:
	var tween := create_tween()

	tween.tween_property(
		fade_rect,
		"modulate:a",
		1.0,
		duration
	)

	await tween.finished


func fade_in(duration: float = 0.2) -> void:
	var tween := create_tween()

	tween.tween_property(
		fade_rect,
		"modulate:a",
		0.0,
		duration
	)

	await tween.finished

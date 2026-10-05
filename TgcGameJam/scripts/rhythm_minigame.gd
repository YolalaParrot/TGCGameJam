extends CanvasLayer

const design_size := Vector2(1152, 648)

@onready var container: Control = $Container


func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var screen := get_viewport().get_visible_rect().size
	var factor := minf(screen.x / design_size.x, screen.y / design_size.y)
	container.scale = Vector2(factor, factor)
	container.position = (screen - design_size * factor) / 2.0

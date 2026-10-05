extends CanvasLayer

# The minigame is laid out for a 1152x648 screen. It runs in its own SubViewport, so the
# main game's stretch scale does not affect it.
const DESIGN_SIZE := Vector2(1152, 648)

@onready var container: Control = $Container


func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit()


# Scales the minigame to fit the screen and centres it.
func _fit() -> void:
	var screen := get_viewport().get_visible_rect().size
	var factor := minf(screen.x / DESIGN_SIZE.x, screen.y / DESIGN_SIZE.y)
	container.scale = Vector2(factor, factor)
	container.position = (screen - DESIGN_SIZE * factor) / 2.0

extends CanvasLayer

signal finished

@onready var top_panel: TextureRect = $Page/PageContent/TopPanel
@onready var bottom_panel: TextureRect = $Page/PageContent/BottomPanel

var current_index := 0

var sequence: Array[Dictionary] = [
	{
		"panel": "res://assets-temp/hitler_gamejam.jpeg"
	},
	{
		"panel": "res://icon.svg"
	},
	{
		"panel": "res://icon.svg"
	},
	{
		"panel": "res://assets-temp/hitler_gamejam.jpeg"
	}
]


func play() -> void:
	current_index = 0

	_clear_panels()
	_show_current()

	await finished


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("advance_cutscene"):
		_advance()


func _clear_panels() -> void:
	top_panel.texture = null
	bottom_panel.texture = null


func _show_current() -> void:
	if current_index >= sequence.size():
		finished.emit()
		return

	if current_index % 2 == 0:
		top_panel.texture = null
		bottom_panel.texture = null

	var panel_path: String = sequence[current_index]["panel"]

	var texture := load(panel_path)

	if texture == null:
		push_error("FAILED TO LOAD COMIC PANEL: " + panel_path)
		return

	if current_index % 2 == 0:
		top_panel.texture = texture
	else:
		bottom_panel.texture = texture


func _advance() -> void:
	current_index += 1

	if current_index >= sequence.size():
		finished.emit()
		return

	_show_current()

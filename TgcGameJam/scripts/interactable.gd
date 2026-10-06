extends Area2D

@onready var label: Label = get_node_or_null("Label")
@onready var parent = $".."
@onready var is_npc: bool = parent.is_in_group("npc")

const outline_color := Color(1.0, 0.88, 0.45, 0.55)
const outline_width := 2.0

signal interacted

var focused := false
var outlined := false


func _ready() -> void:
	if not is_npc:
		GameState.flag_changed.connect(_on_flag_changed)
		GameState.task_changed.connect(refresh_label)
		refresh_label()


func focus():
	focused = true
	refresh_label()

func unfocus():
	focused = false
	refresh_label()


func refresh_label():
	if is_npc:
		if focused and parent.can_interact():
			label.text = "Talk"
		else:
			label.text = parent.marker_text()
	else:
		var available: bool = not parent.has_method("can_interact") or parent.can_interact()
		var task_target: bool = GameState.get_current_tasks().get("target", "") == parent.name
		set_outline(available and (focused or task_target))

func interact():
	interacted.emit()


func _on_flag_changed(_flag: String, _value) -> void:
	refresh_label()


func set_outline(on: bool) -> void:
	outlined = on
	queue_redraw()


func _draw() -> void:
	if is_npc or not outlined:
		return
	for child in get_children():
		if child is CollisionShape2D:
			var shape: Shape2D = child.shape
			if shape is RectangleShape2D:
				draw_rect(Rect2(child.position - shape.size / 2.0, shape.size), outline_color, false, outline_width)
			elif shape is CircleShape2D:
				draw_arc(child.position, shape.radius, 0.0, TAU, 48, outline_color, outline_width)

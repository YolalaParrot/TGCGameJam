extends Area2D

@onready var label: Label = get_node_or_null("Label")
@onready var parent = $".."
@onready var is_npc: bool = parent.is_in_group("npc")

const GLOW_COLOR := Color(1.0, 0.85, 0.25)
const GLOW_MIN := 0.2
const GLOW_MAX := 0.7
const GLOW_PERIOD := 0.9

signal interacted

var focused := false
var glow_tween: Tween


func _ready() -> void:
	if not is_npc:
		modulate.a = 0.0
		GameState.flag_changed.connect(_on_flag_changed)


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
		set_glow(focused and (not parent.has_method("can_interact") or parent.can_interact()))

func interact():
	interacted.emit()


func _on_flag_changed(_flag: String, _value) -> void:
	refresh_label()


func set_glow(on: bool) -> void:
	if glow_tween:
		glow_tween.kill()
	if not on:
		modulate.a = 0.0
		return
	modulate.a = GLOW_MIN
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property(self, "modulate:a", GLOW_MAX, GLOW_PERIOD / 2.0)
	glow_tween.tween_property(self, "modulate:a", GLOW_MIN, GLOW_PERIOD / 2.0)


func _draw() -> void:
	if is_npc:
		return
	for child in get_children():
		if child is CollisionShape2D:
			var shape: Shape2D = child.shape
			if shape is RectangleShape2D:
				draw_rect(Rect2(child.position - shape.size / 2.0, shape.size), GLOW_COLOR)
			elif shape is CircleShape2D:
				draw_circle(child.position, shape.radius, GLOW_COLOR)

extends AnimatedSprite2D

## "press": does the move of the arrow the player presses. "note": does the move of the arrow that just appeared.
@export_enum("press", "note") var follow := "press"

const moves := {"button_left": "dance1", "button_down": "dance2", "button_up": "dance3", "button_right": "dance4"}


func _ready() -> void:
	play("idle")
	animation_finished.connect(_on_move_finished)
	if follow == "press":
		Signals.KeyListenerPress.connect(_on_key_pressed)
	else:
		Signals.CreateFallingKey.connect(_on_note_shown)


func _on_key_pressed(button_name: String, _array_num: int) -> void:
	dance(button_name)


func _on_note_shown(button_name: String) -> void:
	dance(button_name)


func dance(button_name: String) -> void:
	if not moves.has(button_name):
		return
	stop()
	play(moves[button_name])


func _on_move_finished() -> void:
	play("idle")

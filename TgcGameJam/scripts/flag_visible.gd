extends Node2D

## Only shown while this GameState flag is true (e.g. the rocket appears once the wood is delivered).
@export var show_flag := "wood_delivered"


func _ready() -> void:
	visible = GameState.flags.get(show_flag, false) == true
	GameState.flag_changed.connect(_on_flag_changed)


func _on_flag_changed(flag: String, value) -> void:
	if flag == show_flag:
		visible = value == true

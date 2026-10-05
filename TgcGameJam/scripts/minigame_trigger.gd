extends Area2D

@export_file("*.tscn") var minigame_scene := "res://scenes/rhythm_minigame.tscn"
@export var result_flag := "dance_battle"
@export var requires := {}
@export var forbids := {}
@export var on_won := {}
@export var on_lost := {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func can_interact() -> bool:
	return GameState.conditions_met({"requires": requires, "forbids": forbids})


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not can_interact():
		return
	MinigameManager.play(minigame_scene, result_flag, on_won, on_lost)

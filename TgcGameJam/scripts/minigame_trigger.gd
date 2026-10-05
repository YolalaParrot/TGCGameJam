extends Area2D

# Starts a minigame when the player walks into this area, once requires/forbids pass.
@export_file("*.tscn") var minigame_scene := "res://scenes/rhythm_minigame.tscn"
## GameState flag that becomes "won" or "lost".
@export var result_flag := "dance_battle"
@export var requires := {}
@export var forbids := {}
## Extra effects after the result flag is set, as on_finish dictionaries, e.g. {"set": {"got_wood": true}}.
@export var on_won := {}
@export var on_lost := {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)


# Also read by the Interactable child, which only glows while this is true.
func can_interact() -> bool:
	return GameState.conditions_met({"requires": requires, "forbids": forbids})


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not can_interact():
		return
	MinigameManager.play(minigame_scene, result_flag, on_won, on_lost)

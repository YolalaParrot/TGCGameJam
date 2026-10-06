extends Area2D

@export var flag := "found_blueprint_1"
@export var item_name := "Rocket Blueprint"
@export_multiline var line := "A rocket blueprint!"

const image := "res://assets-temp/blueprint.png"


func _ready() -> void:
	if GameState.flags.get(flag, false):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	GameState.flag_changed.connect(_on_flag_changed)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or GameState.flags.get(flag, false):
		return
	if GameState.gameState.in_dialogue or GameState.gameState.inventory_open or CutsceneManager.playing:
		return
	DialogueBox.show_dialogues("Player", [{"Player": line}],
		{"set": {flag: true}, "give": [{"name": item_name, "image": image}]})


func _on_flag_changed(changed: String, value) -> void:
	if changed == flag and value == true:
		queue_free()

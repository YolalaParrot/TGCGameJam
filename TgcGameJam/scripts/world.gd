extends Area2D

@export_file("*.tscn") var destination_scene: String
@export var destination_spawn_id: String = ""

var teleporting := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if teleporting:
		return

	if not body is CharacterBody2D:
		return

	teleporting = true

	Global.set_player_spawn(destination_spawn_id)

	get_tree().change_scene_to_file(destination_scene)

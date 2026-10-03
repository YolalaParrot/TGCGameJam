extends Area2D


@export_file("*.tscn") var destination_scene: String
@export var destination_spawn: String = ""

var teleporting := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if teleporting:
		return

	if not body.is_in_group("player"):
		return

	teleporting = true

	Global.teleport_player(
		destination_scene,
		destination_spawn
	)

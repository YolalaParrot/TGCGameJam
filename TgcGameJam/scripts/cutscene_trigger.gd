extends Area2D


@export var cutscene_id: String = ""
@export var required_cutscene_id: String = ""
@export var play_once := true

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if triggered:
		return

	# Check prerequisite.
	if required_cutscene_id != "":
		if not GameState.cutscene_seen(required_cutscene_id):
			return

	# Prevent replay if this cutscene is one-time.
	if play_once and GameState.cutscene_seen(cutscene_id):
		return

	triggered = true

	await CutsceneManager.play_cutscene(cutscene_id)

	triggered = false

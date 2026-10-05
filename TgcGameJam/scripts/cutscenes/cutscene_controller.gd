extends Node2D

@onready var comic_cutscene = $ComicCutscene

func play() -> void:
	print("Cutscene started: ", get_parent().name)

	await comic_cutscene.play()

	print("Cutscene finished: ", get_parent().name)

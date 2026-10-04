extends Node2D


func play() -> void:
	print("Cutscene started: ", get_parent().name)

	await get_tree().create_timer(2.0).timeout

	print("Cutscene finished: ", get_parent().name)

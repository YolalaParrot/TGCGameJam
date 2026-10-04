extends Node


var playing := false


func play_cutscene(cutscene_id: String) -> void:
	if playing:
		return

	if not CutsceneRegistry.has_cutscene(cutscene_id):
		push_error("CUTSCENE NOT FOUND: " + cutscene_id)
		return

	playing = true

	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("CUTSCENE: PLAYER NOT FOUND")
		playing = false
		return

	player.set_physics_process(false)

	var cutscene_data := CutsceneRegistry.get_cutscene(cutscene_id)
	var scene_path: String = cutscene_data.get("scene", "")

	if scene_path == "":
		push_error("CUTSCENE HAS NO SCENE: " + cutscene_id)
		player.set_physics_process(true)
		playing = false
		return

	var cutscene_scene := load(scene_path)

	if cutscene_scene == null:
		push_error("FAILED TO LOAD CUTSCENE: " + scene_path)
		player.set_physics_process(true)
		playing = false
		return

	var cutscene_instance: Node = cutscene_scene.instantiate()

	get_tree().current_scene.add_child(cutscene_instance)

	await cutscene_instance.get_node("CutsceneController").play()

	cutscene_instance.queue_free()

	player.set_physics_process(true)

	playing = false

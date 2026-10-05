extends Node

var playing := false


func play_cutscene(cutscene_id: String, extra_on_finish: Dictionary = {}, faded := false) -> void:
	if playing or GameState.gameState.inventory_open or GameState.gameState.in_dialogue:
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

	if not faded:
		await Transition.fade_out(0.8)

	var cutscene_data := CutsceneRegistry.get_cutscene(cutscene_id)
	var scene_path: String = cutscene_data.get("scene", "")

	if scene_path == "":
		push_error("CUTSCENE HAS NO SCENE: " + cutscene_id)
		player.set_physics_process(true)
		playing = false
		await Transition.fade_in(0.8)
		return

	var cutscene_scene := load(scene_path)

	if cutscene_scene == null:
		push_error("FAILED TO LOAD CUTSCENE: " + scene_path)
		player.set_physics_process(true)
		playing = false
		await Transition.fade_in(0.8)
		return

	var cutscene_instance: Node = cutscene_scene.instantiate()

	get_tree().current_scene.add_child(cutscene_instance)

	await cutscene_instance.get_node("CutsceneController").play()

	cutscene_instance.queue_free()

	GameState.mark_cutscene_seen(cutscene_id)
	GameState.execute(cutscene_data.get("on_finish", {}))
	GameState.execute(extra_on_finish)

	var next: String = cutscene_data.get("on_finish", {}).get("next", "")
	if next != "":
		playing = false
		await play_cutscene(next, {}, true)
		return

	await Transition.fade_in(0.8)

	if is_instance_valid(player):
		player.set_physics_process(true)

	playing = false

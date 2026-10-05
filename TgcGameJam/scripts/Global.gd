	
extends Node

func teleport_player(scene_path: String, spawn_marker_name: String) -> void:
	print("================================")
	print("TELEPORT REQUEST")
	print("Destination scene: ", scene_path)
	print("Destination marker: ", spawn_marker_name)

	call_deferred("_do_teleport", scene_path, spawn_marker_name)


func _do_teleport(scene_path: String, spawn_marker_name: String) -> void:

	print("Starting fade out...")

	await Transition.fade_out(0.2)

	print("Fade out complete.")
	print("Changing scene...")

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("SCENE CHANGE FAILED. Error: " + str(error))

		print("Starting fade in because scene change failed...")
		await Transition.fade_in(0.2)

		return

	await get_tree().scene_changed

	var current_scene := get_tree().current_scene

	print("Scene loaded: ", current_scene.name)


	var player := current_scene.get_node_or_null("player")

	if player == null:
		push_error("PLAYER NOT FOUND")

		print("Starting fade in because player was not found...")
		await Transition.fade_in(0.2)

		return

	print("Player found.")


	var spawn_marker := current_scene.find_child(
		spawn_marker_name,
		true,
		false
	)

	if spawn_marker == null:
		push_error(
			"SPAWN MARKER NOT FOUND: "
			+ spawn_marker_name
		)

		print("Starting fade in because spawn marker was not found...")
		await Transition.fade_in(0.2)

		return

	print("Spawn marker found.")
	print("Spawn position: ", spawn_marker.global_position)


	player.global_position = spawn_marker.global_position

	print("Player moved to: ", player.global_position)


	print("Starting fade in...")

	await Transition.fade_in(0.2)

	print("Fade in complete.")
	print("================================")

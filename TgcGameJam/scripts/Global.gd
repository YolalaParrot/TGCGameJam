#this is the correct code when marker2D is a direct child to scene Node
#extends Node
#
#
#func teleport_player(scene_path: String, spawn_marker_name: String) -> void:
	#get_tree().change_scene_to_file(scene_path)
#
	#await get_tree().scene_changed
#
	#var current_scene := get_tree().current_scene
#
	#var player := current_scene.get_node_or_null("player")
	#var spawn_marker := current_scene.get_node_or_null(spawn_marker_name)
#
	#if player == null:
		#push_error("Player node not found in destination scene.")
		#return
#
	#if spawn_marker == null:
		#push_error("Spawn marker not found: " + spawn_marker_name)
		#return
#
	#player.global_position = spawn_marker.global_position
	#
	#
	
#this is the correct code to recursively search for a child node marker2D
#when it is not a direct child to scene Node
#extends Node
#
#
#func teleport_player(scene_path: String, spawn_marker_name: String) -> void:
	#get_tree().change_scene_to_file(scene_path)
#
	#await get_tree().scene_changed
#
	#var current_scene := get_tree().current_scene
#
	#var player := current_scene.get_node_or_null("player")
	#var spawn_marker := current_scene.find_child(spawn_marker_name, true, false)
#
	#if player == null:
		#push_error("Player node not found in destination scene.")
		#return
#
	#if spawn_marker == null:
		#push_error("Spawn marker not found: " + spawn_marker_name)
		#return
#
	#player.global_position = spawn_marker.global_position
	#

extends Node


func teleport_player(scene_path: String, spawn_marker_name: String) -> void:
	print("================================")
	print("TELEPORT REQUEST")
	print("Destination scene: ", scene_path)
	print("Destination marker: ", spawn_marker_name)

	call_deferred("_do_teleport", scene_path, spawn_marker_name)


func _do_teleport(scene_path: String, spawn_marker_name: String) -> void:
	print("Changing scene...")

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("SCENE CHANGE FAILED. Error: " + str(error))
		return

	await get_tree().scene_changed

	var current_scene := get_tree().current_scene

	print("Scene loaded: ", current_scene.name)

	var player := current_scene.get_node_or_null("player")
	var spawn_marker := current_scene.find_child(spawn_marker_name, true, false)

	if player == null:
		push_error("PLAYER NOT FOUND")
		return

	print("Player found.")

	if spawn_marker == null:
		push_error("SPAWN MARKER NOT FOUND: " + spawn_marker_name)
		return

	print("Spawn marker found.")
	print("Spawn position: ", spawn_marker.global_position)

	player.global_position = spawn_marker.global_position

	print("Player moved to: ", player.global_position)
	print("================================")

extends Node

var playing := false

const result_pause := 2.5
const fade_time := 0.5


func play(scene_path: String, result_flag: String, on_won: Dictionary = {}, on_lost: Dictionary = {}) -> void:
	if playing or CutsceneManager.playing:
		return
	if GameState.gameState.in_dialogue or GameState.gameState.inventory_open:
		return

	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("MINIGAME NOT FOUND: " + scene_path)
		return

	playing = true
	GameState.gameState.in_minigame = true

	await Transition.fade_out(0.5)
	var paused_music := pause_map_music()

	var minigame: Node = scene.instantiate()
	var host: Node = minigame if minigame is CanvasLayer else in_own_viewport(minigame)
	get_tree().root.add_child(host)
	var cover := black_cover()
	await fade(cover, 0.0)

	var passed: bool = await Signals.GameOver
	await get_tree().create_timer(result_pause).timeout

	await fade(cover, 1.0)
	host.queue_free()
	cover.get_parent().queue_free()
	for player in paused_music:
		if is_instance_valid(player):
			player.stream_paused = false
	Engine.time_scale = 1.0
	GameState.gameState.in_minigame = false

	await Transition.fade_in(0.5)

	var on_finish: Dictionary = (on_won if passed else on_lost).duplicate(true)
	var to_set := {result_flag: "won" if passed else "lost"}
	to_set.merge(on_finish.get("set", {}))
	on_finish["set"] = to_set
	GameState.execute(on_finish)

	playing = false


func in_own_viewport(minigame: Node) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 10
	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var viewport := SubViewport.new()
	layer.add_child(container)
	container.add_child(viewport)
	viewport.add_child(minigame)
	return layer


func black_cover() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 40
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	get_tree().root.add_child(layer)
	return rect


func fade(cover: ColorRect, alpha: float) -> void:
	var tween := cover.create_tween()
	tween.tween_property(cover, "modulate:a", alpha, fade_time)
	await tween.finished


func pause_map_music() -> Array:
	var paused := []
	var scene := get_tree().current_scene
	if scene == null:
		return paused
	for player in scene.find_children("*", "AudioStreamPlayer", true, false):
		if player.playing and not player.stream_paused:
			player.stream_paused = true
			paused.append(player)
	return paused

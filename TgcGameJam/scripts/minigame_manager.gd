extends Node

var playing := false

const RESULT_PAUSE := 2.5  # how long the STAGE CLEAR / FAILED text stays up


# Plays a minigame scene and stores how it went in GameState: result_flag becomes "won" or "lost",
# then on_won or on_lost (on_finish dictionaries, like dialogues and cutscenes) is run.
# The scene must end by emitting Signals.GameOver(passed).
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

	var minigame: Node = scene.instantiate()
	get_tree().root.add_child(minigame)

	var passed: bool = await Signals.GameOver
	await get_tree().create_timer(RESULT_PAUSE).timeout

	minigame.queue_free()
	Engine.time_scale = 1.0

	GameState.gameState.in_minigame = false
	GameState.execute({"set": {result_flag: "won" if passed else "lost"}})
	GameState.execute(on_won if passed else on_lost)

	await Transition.fade_in(0.5)

	playing = false

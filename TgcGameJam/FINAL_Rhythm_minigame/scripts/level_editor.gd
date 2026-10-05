extends Node2D

@export_group("Playback Settings")
@export var game_speed: float = 1.0
@export var beep_interval: float = 1.0
@export var delay_before_go: float = 0.0

@export_group("Node References")
@onready var countdown_sfx: AudioStreamPlayer = get_node_or_null("CountdownSFX")
@onready var music_player: AudioStreamPlayer = get_node_or_null("MusicPlayer")

var sfx_3: AudioStream = preload("res://music/beep1.wav")
var sfx_2: AudioStream = preload("res://music/beep2.wav")
var sfx_1: AudioStream = preload("res://music/beep3.wav")
var sfx_go: AudioStream = preload("res://music/beep4.wav")

const in_edit_mode: bool = false
var current_level_name: String = "RHYTHM_HELL"

var fk_fall_time: float = 2.2
var countdown_duration: float = 3.0
var fk_output_arr: Array = [[], [], [], []]

var level_info: Dictionary = {
	"RHYTHM_HELL": {
		"fk_times": "[[2.52533321380615, 6.55733375549316, 10.5573337554932, 14.5040004730225, 14.6533325195313, 15.5493324279785, 15.6986663818359, 15.9333332061768, 16.0719993591309, 19.76266746521, 22.8666675567627, 27.2293327331543, 30.823998260498, 34.5786674499512, 34.7173316955566, 35.0159996032715, 35.282666015625, 35.4640014648437, 35.6453330993652, 35.9333351135254, 36.1466682434082, 36.2533348083496, 36.3706672668457, 40.4133346557617], [3.03733329772949, 7.0586669921875, 7.28266696929932, 11.5600002288818, 11.8053329467773, 14.9200008392334, 15.0479991912842, 15.282666015625, 15.5813339233398, 16.296000289917, 18.8026664733887, 19.9119995117188, 20.0826671600342, 23.2080009460449, 23.346667098999, 23.9226673126221, 24.3279998779297, 26.792000579834, 27.7200000762939, 28.1253326416016, 31.1759994506836, 31.858666229248, 34.8453338623047, 34.9839981079102, 35.1546676635742, 35.3999984741211, 35.5706680297852, 35.741333770752, 35.8693321228027, 36.0186660766602, 36.1359985351562, 36.2533348083496], [3.56000022888184, 7.54933338165283, 10.7919996261597, 11.0266664505005, 14.5040004730225, 14.6533325195313, 15.5600002288818, 15.7093341827393, 15.9333332061768, 16.0826671600342, 19.0373332977295, 19.1973331451416, 19.3893325805664, 20.274666595459, 20.4026668548584, 23.5493324279785, 23.7093341827393, 24.1146667480469, 27.0159996032715, 27.9333332061768, 31.5280006408691, 32.231999206543], [4.07199983596802, 8.06133346557617, 12.0613334655762, 26.5893333435059, 27.4639995574951]]",
		"music": load("res://music/rhythm_hell.wav")
	}
}

func _ready() -> void:
	Engine.time_scale = game_speed
	countdown_duration = (beep_interval * 3.0) + delay_before_go
	
	if music_player:
		music_player.pitch_scale = game_speed
		music_player.stream = level_info.get(current_level_name).get("music")

	start_countdown()

	if in_edit_mode:
		Signals.KeyListenerPress.connect(KeyListenerPress)
	else:
		_queue_all_notes()

func _queue_all_notes() -> void:
	var fk_times_raw: String = level_info.get(current_level_name).get("fk_times")
	var fk_times_arr: Array = str_to_var(fk_times_raw)
	
	var lane_index: int = 0
	for lane in fk_times_arr:
		var button_name: String = ""
		match lane_index:
			0: button_name = "button_left"
			1: button_name = "button_down"
			2: button_name = "button_up"
			3: button_name = "button_right"
		
		for timestamp in lane:
			var spawn_delay: float = countdown_duration + timestamp - fk_fall_time
			if spawn_delay > 0.0:
				SpawnFallingKey(button_name, spawn_delay)
			else:
				Signals.CreateFallingKey.emit(button_name)
		
		lane_index += 1

func SpawnFallingKey(button_name: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	Signals.CreateFallingKey.emit(button_name)

func KeyListenerPress(button_name: String, array_num: int) -> void:
	if music_player:
		var current_playback_time: float = music_player.get_playback_position()
		var relative_timestamp: float = current_playback_time - fk_fall_time
		fk_output_arr[array_num].append(relative_timestamp)

func _on_music_player_finished() -> void:
	if in_edit_mode:
		print("--- RECORDED CHART TIMESTAMPS ---")
		print(fk_output_arr)
	
	Signals.LevelFinished.emit()

func _play_beep(stream: AudioStream) -> void:
	if countdown_sfx and stream:
		countdown_sfx.stop()
		countdown_sfx.stream = stream
		countdown_sfx.play()
		
func start_countdown() -> void:
	Signals.UpdateCountdown.emit("3")
	_play_beep(sfx_3)
	await get_tree().create_timer(beep_interval).timeout
	
	Signals.UpdateCountdown.emit("2")
	_play_beep(sfx_2)
	await get_tree().create_timer(beep_interval).timeout
	
	Signals.UpdateCountdown.emit("1")
	_play_beep(sfx_1)
	await get_tree().create_timer(beep_interval).timeout
	
	if delay_before_go > 0.0:
		await get_tree().create_timer(delay_before_go).timeout
	
	Signals.UpdateCountdown.emit("GO!")
	_play_beep(sfx_go)
	if music_player:
		music_player.play()
		
	# Hide after 0.5 seconds
	await get_tree().create_timer(0.5).timeout
	Signals.UpdateCountdown.emit("")

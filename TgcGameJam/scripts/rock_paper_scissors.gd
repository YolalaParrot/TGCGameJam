extends Control

enum Choice { ROCK, PAPER, SCISSORS }

@export_range(0, 100) var player_win_chance: int = 65
@export_range(0, 100) var player_lose_chance: int = 25
@export_range(0, 100) var tie_chance: int = 10

@export var hands_spritesheet: Texture2D

@export var player_rock_region: Rect2 = Rect2(0, 50, 33.33, 50)
@export var player_paper_region: Rect2 = Rect2(33.33, 50, 33.33, 50)
@export var player_scissors_region: Rect2 = Rect2(66.66, 50, 33.33, 50)

@export var bob_rock_region: Rect2 = Rect2(0, 0, 33.33, 50)
@export var bob_paper_region: Rect2 = Rect2(33.33, 0, 33.33, 50)
@export var bob_scissors_region: Rect2 = Rect2(66.66, 0, 33.33, 50)

var player_textures: Dictionary = {}
var bob_textures: Dictionary = {}

const beaten_by = {
	Choice.ROCK: Choice.SCISSORS,
	Choice.PAPER: Choice.ROCK,
	Choice.SCISSORS: Choice.PAPER
}

const beats = {
	Choice.ROCK: Choice.PAPER,
	Choice.PAPER: Choice.SCISSORS,
	Choice.SCISSORS: Choice.ROCK
}

const choice_names = {
	Choice.ROCK: "Rock",
	Choice.PAPER: "Paper",
	Choice.SCISSORS: "Scissors"
}

const wins_needed: int = 2
var player_wins: int = 0
var bob_wins: int = 0
var match_over: bool = false
var is_round_in_progress: bool = false

var pending_player_choice: Choice
var pending_bob_choice: Choice

@onready var rock_button: Button = $MainContainer/ChoiceButtons/RockButton
@onready var paper_button: Button = $MainContainer/ChoiceButtons/PaperButton
@onready var scissors_button: Button = $MainContainer/ChoiceButtons/ScissorsButton
@onready var reset_button: Button = $MainContainer/ResetButton

@onready var player_choice_label: Label = $MainContainer/DisplayPanel/PlayerSide/PlayerChoiceLabel
@onready var bob_choice_label: Label = $MainContainer/DisplayPanel/ComputerSide/ComputerChoiceLabel
@onready var player_hand_texture: TextureRect = $MainContainer/DisplayPanel/PlayerHandHolder/PlayerHandTexture
@onready var bob_hand_texture: TextureRect = $MainContainer/DisplayPanel/ComputerHandHolder/ComputerHandTexture

@onready var result_label: Label = $MainContainer/ResultLabel
@onready var score_label: Label = $MainContainer/ScoreLabel
@onready var reveal_timer: Timer = $RevealTimer

var victory_overlay: CenterContainer
var victory_label: Label


func _ready() -> void:
	setup_button_labels()
	create_victory_overlay_in_code()
	setup_atlas_textures()
	apply_initial_label_colors()
	
	rock_button.pressed.connect(_on_choice_pressed.bind(Choice.ROCK))
	paper_button.pressed.connect(_on_choice_pressed.bind(Choice.PAPER))
	scissors_button.pressed.connect(_on_choice_pressed.bind(Choice.SCISSORS))
	reset_button.pressed.connect(reset_match)
	
	reveal_timer.timeout.connect(_on_reveal_timer_timeout)
	
	reset_match()


func setup_button_labels() -> void:
	rock_button.text = "Rock"
	paper_button.text = "Paper"
	scissors_button.text = "Scissors"
	reset_button.text = "Play Again"


func create_victory_overlay_in_code() -> void:
	victory_overlay = CenterContainer.new()
	victory_overlay.name = "DynamicVictoryOverlay"
	victory_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	victory_label = Label.new()
	victory_label.name = "DynamicVictoryLabel"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	victory_label.add_theme_font_size_override("font_size", 56)
	victory_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	victory_label.add_theme_color_override("font_outline_color", Color.BLACK)
	victory_label.add_theme_constant_override("outline_size", 10)
	
	victory_overlay.add_child(victory_label)
	add_child(victory_overlay)


func setup_atlas_textures() -> void:
	if hands_spritesheet == null:
		push_error("Hands Spritesheet is not assigned in the Inspector!")
		return
		
	player_textures[Choice.ROCK] = create_atlas(player_rock_region)
	player_textures[Choice.PAPER] = create_atlas(player_paper_region)
	player_textures[Choice.SCISSORS] = create_atlas(player_scissors_region)
	
	bob_textures[Choice.ROCK] = create_atlas(bob_rock_region)
	bob_textures[Choice.PAPER] = create_atlas(bob_paper_region)
	bob_textures[Choice.SCISSORS] = create_atlas(bob_scissors_region)


func create_atlas(region: Rect2) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = hands_spritesheet
	atlas.region = region
	return atlas


func apply_initial_label_colors() -> void:
	bob_choice_label.add_theme_color_override("font_color", Color(0.12, 0.56, 1.0))
	
	player_choice_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))


func reset_match() -> void:
	player_wins = 0
	bob_wins = 0
	match_over = false
	is_round_in_progress = false
	
	player_choice_label.text = "-"
	bob_choice_label.text = "-"
	player_hand_texture.texture = null
	bob_hand_texture.texture = null
	
	result_label.text = "First to 2 wins!"
	result_label.add_theme_color_override("font_color", Color.WHITE)
	
	victory_overlay.visible = false
	victory_label.text = ""
	
	update_score_display()
	set_move_buttons_enabled(true)
	reset_button.visible = false


func _on_choice_pressed(player_choice: Choice) -> void:
	if is_round_in_progress or match_over:
		return
		
	is_round_in_progress = true
	set_move_buttons_enabled(false)
	
	pending_player_choice = player_choice
	pending_bob_choice = calculate_bob_choice_option_a(player_choice)
	
	player_hand_texture.texture = null
	bob_hand_texture.texture = null
	player_choice_label.text = "..."
	bob_choice_label.text = "..."
	
	result_label.text = "1... 2... 3... Shoot!"
	result_label.add_theme_color_override("font_color", Color.WHITE)
	
	reveal_timer.start()


func calculate_bob_choice_option_a(player_choice: Choice) -> Choice:
	var roll = randi_range(1, 100)
	
	if roll <= player_win_chance:
		return beaten_by[player_choice]
	elif roll <= (player_win_chance + player_lose_chance):
		return beats[player_choice]
	else:
		return player_choice


func _on_reveal_timer_timeout() -> void:
	player_choice_label.text = choice_names[pending_player_choice]
	bob_choice_label.text = choice_names[pending_bob_choice]
	
	player_hand_texture.texture = player_textures[pending_player_choice]
	bob_hand_texture.texture = bob_textures[pending_bob_choice]
	
	if pending_player_choice == pending_bob_choice:
		result_label.text = "ROUND TIE!"
		result_label.add_theme_color_override("font_color", Color.YELLOW)
	elif beaten_by[pending_player_choice] == pending_bob_choice:
		result_label.text = "ROUND WIN!"
		result_label.add_theme_color_override("font_color", Color.GREEN)
		player_wins += 1
	else:
		result_label.text = "ROUND LOSS!"
		result_label.add_theme_color_override("font_color", Color.RED)
		bob_wins += 1
		
	update_score_display()
	check_match_verdict()


func check_match_verdict() -> void:
	if player_wins >= wins_needed:
		victory_label.text = "YOU WON THE GAME!"
		victory_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		match_over = true
	elif bob_wins >= wins_needed:
		victory_label.text = "BOB WON THE GAME!"
		victory_label.add_theme_color_override("font_color", Color.RED)
		match_over = true
		
	if match_over:
		victory_overlay.visible = true
		set_move_buttons_enabled(false)
		reset_button.visible = get_tree().current_scene == self
		Signals.GameOver.emit(player_wins >= wins_needed)
	else:
		set_move_buttons_enabled(true)
		
	is_round_in_progress = false


func update_score_display() -> void:
	score_label.text = "Player Wins: %d / %d  |  Bob Wins: %d / %d" % [
		player_wins, wins_needed, bob_wins, wins_needed
	]


func set_move_buttons_enabled(enabled: bool) -> void:
	rock_button.disabled = !enabled
	paper_button.disabled = !enabled
	scissors_button.disabled = !enabled

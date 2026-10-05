extends Control

var score: int = 0
var combo_count: int = 0

# Track total notes hit and the accumulated rating points
var total_notes: int = 0
var total_rating_points: float = 0.0

# Numerical weight for each rating judgment
const RATING_WEIGHTS = {
	"PERFECT": 4.0,
	"GREAT":   3.0,
	"GOOD":    2.0,
	"OK":      1.0,
	"MISS":    0.0
}

# Average threshold needed to pass (GOOD average = 2.0)
@export var target_average_score: float = 2.0

var custom_font = preload("res://art/PixelOperator8.ttf") 
var custom_font2 = preload("res://art/Atop-R99O3.ttf")

var score_node: Control
var combo_node: Control
var result_node: Control

func _ready():
	Signals.IncrementScore.connect(IncrementScore)
	Signals.IncrementCombo.connect(IncrementCombo)
	Signals.ResetCombo.connect(ResetCombo)
	
	Signals.NoteHit.connect(_on_note_hit)
	Signals.LevelFinished.connect(_on_level_finished)
	Signals.UpdateCountdown.connect(_on_update_countdown)
	
	score_node = get_node_or_null("%ScoreLabel") if get_node_or_null("%ScoreLabel") else get_node_or_null("ScoreLabel")
	combo_node = get_node_or_null("%ComboLabel") if get_node_or_null("%ComboLabel") else get_node_or_null("ComboLabel")

	# Updated to look for CountdownLabel
	result_node = get_node_or_null("%CountdownLabel")
	if result_node == null:
		result_node = get_node_or_null("CountdownLabel")
	
	_apply_font(score_node, custom_font, 24)
	_apply_font(combo_node, custom_font2, 20)
	_apply_font(result_node, custom_font, 36)
		
	if result_node:
		result_node.visible = false
		
	ResetCombo()
	
func _on_update_countdown(text: String) -> void:
	if result_node: # result_node references CountdownLabel
		if text == "":
			result_node.visible = false
		else:
			result_node.visible = true
			result_node.text = text
			result_node.modulate = Color.WHITE # Ensure normal text color during countdown

func _apply_font(node: Control, font: Font, size: int):
	if node == null:
		return
		
	if node is Label:
		node.add_theme_font_override("font", font)
		node.add_theme_font_size_override("font_size", size)
	elif node is RichTextLabel:
		node.add_theme_font_override("normal_font", font)
		node.add_theme_font_size_override("normal_font_size", size)

func IncrementScore(incr: int):
	score += incr
	if score_node:
		score_node.text = " " + str(score) + " pts"

func IncrementCombo():
	combo_count += 1
	if combo_node:
		combo_node.text = " " + str(combo_count) + "x combo"

func ResetCombo():
	combo_count = 0
	if combo_node:
		combo_node.text = ""

# --- Average Rating Calculation & UI Display ---

func _on_note_hit(rating: String):
	if RATING_WEIGHTS.has(rating):
		total_notes += 1
		total_rating_points += RATING_WEIGHTS[rating]

func _on_level_finished():
	print("--- LEVEL FINISHED SIGNAL RECEIVED ---")
	
	var average_score: float = 0.0
	if total_notes > 0:
		average_score = total_rating_points / total_notes

	var passed: bool = average_score >= target_average_score
	var formatted_avg: String = "%.2f" % average_score
	
	if result_node:
		result_node.visible = true
		if passed:
			result_node.text = "STAGE CLEAR!"
			result_node.modulate = Color("25e24b") # Green
		else:
			result_node.text = "STAGE FAILED!"
			result_node.modulate = Color("e22525") # Red
	else:
		print("ERROR: Could not find CountdownLabel node!")

	Signals.GameOver.emit(passed)

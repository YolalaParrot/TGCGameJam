extends Control

var score: int = 0
var combo_count: int = 0

var total_notes: int = 0
var total_rating_points: float = 0.0

const rating_weights = {
	"PERFECT": 4.0,
	"GREAT":   3.0,
	"GOOD":    2.0,
	"OK":      1.0,
	"MISS":    0.0
}

@export var target_average_score: float = 2.0

var custom_font = preload("res://art/PixelOperator8.ttf") 
var custom_font2 = preload("res://art/Atop-R99O3.ttf")

var score_node: Control
var combo_node: Control
var result_node: Control
var best_node: Label

const high_score_key := "dance"

func _ready():
	Signals.IncrementScore.connect(IncrementScore)
	Signals.IncrementCombo.connect(IncrementCombo)
	Signals.ResetCombo.connect(ResetCombo)
	
	Signals.NoteHit.connect(_on_note_hit)
	Signals.LevelFinished.connect(_on_level_finished)
	Signals.UpdateCountdown.connect(_on_update_countdown)
	
	score_node = get_node_or_null("%ScoreLabel") if get_node_or_null("%ScoreLabel") else get_node_or_null("ScoreLabel")
	combo_node = get_node_or_null("%ComboLabel") if get_node_or_null("%ComboLabel") else get_node_or_null("ComboLabel")

	result_node = get_node_or_null("%CountdownLabel")
	if result_node == null:
		result_node = get_node_or_null("CountdownLabel")
	
	_apply_font(score_node, custom_font, 24)
	_apply_font(combo_node, custom_font2, 20)
	_apply_font(result_node, custom_font, 36)
		
	if result_node:
		result_node.visible = false

	add_best_label()
	ResetCombo()


func add_best_label() -> void:
	if score_node == null:
		return
	best_node = Label.new()
	best_node.text = " Best: %d pts" % GameState.get_high_score(high_score_key)
	best_node.add_theme_font_override("font", custom_font)
	best_node.add_theme_font_size_override("font_size", 18)
	best_node.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	best_node.add_theme_color_override("font_outline_color", Color.BLACK)
	best_node.add_theme_constant_override("outline_size", 6)
	best_node.position = score_node.position + Vector2(0, 54)
	score_node.get_parent().add_child(best_node)
	
func _on_update_countdown(text: String) -> void:
	if result_node:
		if text == "":
			result_node.visible = false
		else:
			result_node.visible = true
			result_node.text = text
			result_node.modulate = Color.WHITE

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


func _on_note_hit(rating: String):
	if rating_weights.has(rating):
		total_notes += 1
		total_rating_points += rating_weights[rating]

func _on_level_finished():
	print("--- LEVEL FINISHED SIGNAL RECEIVED ---")
	
	var average_score: float = 0.0
	if total_notes > 0:
		average_score = total_rating_points / total_notes

	var passed: bool = average_score >= target_average_score
	var formatted_avg: String = "%.2f" % average_score
	
	var new_best: bool = GameState.submit_score(high_score_key, score)
	if best_node:
		best_node.text = " Best: %d pts" % GameState.get_high_score(high_score_key)

	if result_node:
		result_node.visible = true
		if passed:
			result_node.text = "STAGE CLEAR!"
			result_node.modulate = Color("25e24b")
		else:
			result_node.text = "STAGE FAILED!"
			result_node.modulate = Color("e22525")
		if new_best:
			result_node.text += "\nNEW HIGH SCORE!"
	else:
		print("ERROR: Could not find CountdownLabel node!")

	Signals.GameOver.emit(passed)

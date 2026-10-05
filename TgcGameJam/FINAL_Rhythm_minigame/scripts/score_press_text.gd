extends Control

# Preload your TrueType Font file
var custom_font = preload("res://art/PixelOperator8.ttf") 

func _ready():
	# RichTextLabel uses "normal_font" instead of "font"
	$ScoreLevelText.add_theme_font_override("normal_font", custom_font)
	$ScoreLevelText.add_theme_font_size_override("normal_font_size", 28)

func SetTextInfo(text: String):
	$ScoreLevelText.text = "[center]" + text
	
	match text:
		"PERFECT":
			$ScoreLevelText.set("theme_override_colors/default_color", Color("ffbe00"))
		"GREAT":
			$ScoreLevelText.set("theme_override_colors/default_color", Color("e2dd25"))
		"GOOD":
			$ScoreLevelText.set("theme_override_colors/default_color", Color("e2dd25"))
		"OK":
			$ScoreLevelText.set("theme_override_colors/default_color", Color("8dbfc7"))
		_:
			$ScoreLevelText.set("theme_override_colors/default_color", Color("5a5758"))

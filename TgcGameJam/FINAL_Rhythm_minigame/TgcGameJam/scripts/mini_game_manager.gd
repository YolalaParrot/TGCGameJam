extends Node
var parts_collected = 0

@onready var part_label: Label = $"../player/part_label"



func update_collected():
	parts_collected+=1
	part_label.text = "Number of parts collected: " + str(parts_collected)
	print(parts_collected)

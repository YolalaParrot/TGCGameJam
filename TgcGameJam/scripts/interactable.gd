extends Area2D
@onready var label: Label = $Label
@onready var npc = $".."  # the NPC (npc.gd); untyped so its custom functions can be called


signal interacted

func focus():
	label.text = "Talk" if npc.can_interact() else ""
	
func unfocus():
	label.text = ""

func interact():
	interacted.emit()

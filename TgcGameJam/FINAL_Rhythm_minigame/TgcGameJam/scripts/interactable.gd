extends Area2D
@onready var label: Label = $Label
@onready var npc: AnimatableBody2D = $".."


signal interacted

func focus():
	if owner.NPC_Name in GameState.dialogues and not GameState.get_dialogue(owner.NPC_Name).is_empty():
		label.text = "Talk"
	else:
		label.text = ""
	
func unfocus():
	label.text = ""

func interact():
	interacted.emit()

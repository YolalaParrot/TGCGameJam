extends Area2D
@onready var label: Label = $Label
@onready var npc = $".."  # the NPC (npc.gd); untyped so its custom functions can be called


signal interacted

var focused := false

func focus():
	focused = true
	refresh_label()

func unfocus():
	focused = false
	refresh_label()

# "Talk" while the player is next to an NPC they can talk to, otherwise "!" if this NPC is
# the main task's target, otherwise empty.
func refresh_label():
	if focused and npc.can_interact():
		label.text = "Talk"
	else:
		label.text = npc.marker_text()

func interact():
	interacted.emit()

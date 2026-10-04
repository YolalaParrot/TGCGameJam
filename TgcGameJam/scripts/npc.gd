extends AnimatableBody2D
@onready var interactable: Area2D = $Interactable
@export var NPC_Name:String = "NPC"

@export var frames: SpriteFrames
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	if frames:
		anim.sprite_frames = frames
		anim.play("idle")


func _on_interacted():
	var npc_count = GameState.dialogues[NPC_Name].counter
	var npc_dialogues = GameState.get_dialogue(NPC_Name)
	if npc_dialogues.size()==0:
		DialogueBox.show_dialogues(NPC_Name,[])
		return
	var npc_counter = npc_count%npc_dialogues.size()
	print(npc_dialogues[npc_counter])
	if npc_counter<npc_dialogues.size():
		DialogueBox.show_dialogues(NPC_Name,npc_dialogues[npc_counter])
	else:
		print("")

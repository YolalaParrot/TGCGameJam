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
	var npc_dialogue_data = GameState.dialogues[NPC_Name]
	var npc_dialogues = npc_dialogue_data.dialogues
	var npc_counter = npc_dialogue_data.counter%npc_dialogues.size()
	print(npc_dialogues[npc_counter])
	if npc_counter in npc_dialogues:
		DialogueBox.show_dialogues(NPC_Name,npc_dialogues[npc_counter])
	else:
		print("")
	print("Bro , Did you hear , the world is about to end!!!!!!!!")

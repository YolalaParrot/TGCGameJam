extends AnimatableBody2D
@onready var interactable: Area2D = $Interactable
@export var NPC_Name:String = "NPC"
@export var cutscene_id:String = ""  # cutscene played on interact until it is marked seen

@export var frames: SpriteFrames
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# A moving NPC only exists in the map of its current spot (GameState.npc_state)
	var map := GameState.npc_map(NPC_Name)
	if map != "" and map != current_map():
		queue_free()
		return
	if map != "":
		position = GameState.npc_pos(NPC_Name)
	interactable.interacted.connect(_on_interacted)
	if frames:
		anim.sprite_frames = frames
		anim.play("idle")


func has_unseen_cutscene() -> bool:
	return cutscene_id != "" and CutsceneRegistry.has_cutscene(cutscene_id) and not GameState.cutscene_seen(cutscene_id)

func has_dialogue() -> bool:
	return GameState.dialogues.has(NPC_Name) and not GameState.get_dialogue(NPC_Name).is_empty()

func can_interact() -> bool:
	var map := GameState.npc_map(NPC_Name)
	if map != "" and map != current_map():
		return false  # e.g. Jim while he is running off to the hill
	return has_unseen_cutscene() or has_dialogue()

func current_map() -> String:
	return owner.scene_file_path.get_file().get_basename() if owner else ""


func _on_interacted():
	if CutsceneManager.playing:
		return
	if has_unseen_cutscene():
		CutsceneManager.play_cutscene(cutscene_id)
		return
	if not has_dialogue():
		return
	var npc_count = GameState.dialogues[NPC_Name].counter
	var dialogue_set = GameState.get_dialogue_set(NPC_Name)
	var npc_dialogues = dialogue_set.get("lines", [])
	if npc_dialogues.size()==0:
		DialogueBox.show_dialogues(NPC_Name,[])
		return
	var npc_counter = npc_count%npc_dialogues.size()
	print(npc_dialogues[npc_counter])
	if npc_counter<npc_dialogues.size():
		DialogueBox.show_dialogues(NPC_Name,npc_dialogues[npc_counter],dialogue_set.get("on_finish", {}))
	else:
		print("")

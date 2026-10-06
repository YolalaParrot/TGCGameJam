extends AnimatableBody2D
@onready var interactable: Area2D = $Interactable
@export var NPC_Name:String = "NPC"

@export var frames: SpriteFrames

@export_group("Leaving")
@export var leave_flag := ""
@export var leave_x := 150.0
@export var leave_speed := 50.0
var leaving := false
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	var map := GameState.npc_map(NPC_Name)
	if map != "" and map != current_map():
		queue_free()
		return
	if map != "":
		position = GameState.npc_pos(NPC_Name)
	if leave_flag != "":
		if GameState.flags.get(leave_flag, false):
			queue_free()
			return
		GameState.flag_changed.connect(_on_flag_changed)
	interactable.interacted.connect(_on_interacted)
	GameState.task_changed.connect(interactable.refresh_label)
	interactable.refresh_label()
	if frames:
		anim.sprite_frames = frames
		anim.play("idle")


func marker_text() -> String:
	return "!" if GameState.get_current_tasks().get("target", "") == NPC_Name else ""

func pending_cutscene() -> String:
	return CutsceneRegistry.find_for_npc(NPC_Name)

func has_dialogue() -> bool:
	return GameState.dialogues.has(NPC_Name) and not GameState.get_dialogue(NPC_Name).is_empty()

func can_interact() -> bool:
	if leaving:
		return false
	var map := GameState.npc_map(NPC_Name)
	if map != "" and map != current_map():
		return false
	return pending_cutscene() != "" or has_dialogue()

func _on_flag_changed(flag: String, value) -> void:
	if flag == leave_flag and value == true:
		leaving = true
		interactable.refresh_label()


func _process(delta: float) -> void:
	if not leaving:
		return
	anim.flip_h = leave_x < position.x
	position.x = move_toward(position.x, leave_x, leave_speed * delta)
	if position.x == leave_x:
		queue_free()


func current_map() -> String:
	return owner.scene_file_path.get_file().get_basename() if owner else ""


func _on_interacted():
	if CutsceneManager.playing:
		return
	var cutscene_id := pending_cutscene()
	if cutscene_id != "":
		CutsceneManager.play_cutscene(cutscene_id, with_met_flag({}))
		return
	if not has_dialogue():
		return
	var dialogue_set = GameState.get_dialogue_set(NPC_Name)
	var npc_count = dialogue_set.get("counter", 0)
	var npc_dialogues = dialogue_set.get("lines", [])
	if npc_dialogues.size()==0:
		DialogueBox.show_dialogues(NPC_Name,[])
		return
	var npc_counter = npc_count%npc_dialogues.size()
	print(npc_dialogues[npc_counter])
	if npc_counter<npc_dialogues.size():
		DialogueBox.show_dialogues(NPC_Name,npc_dialogues[npc_counter],with_met_flag(dialogue_set.get("on_finish", {})),dialogue_set)
	else:
		print("")


func with_met_flag(on_finish: Dictionary) -> Dictionary:
	if GameState.get_current_tasks().get("target", "") != NPC_Name:
		return on_finish
	var met_flag := "met_" + NPC_Name
	if GameState.flags.get(met_flag, false):
		return on_finish
	var result := on_finish.duplicate(true)
	var to_set: Dictionary = result.get("set", {})
	if not to_set.has(met_flag):
		to_set[met_flag] = true
	result["set"] = to_set
	return result

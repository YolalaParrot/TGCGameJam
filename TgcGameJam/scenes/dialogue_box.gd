extends CanvasLayer
@onready var panel: PanelContainer = $PanelContainer

@onready var dialogue: Label = $PanelContainer/VBoxContainer/Dialogue
var index:=0
var speaker:String = ""
var dialogues: Array = []
var active = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	panel.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if active and event.is_action_pressed("interact"):
		index += 1
		get_viewport().set_input_as_handled()
		show_current_dialogue()
	elif event.is_action_pressed("ui_close_dialog"):
		get_viewport().set_input_as_handled()
		close_box()
	

func show_current_dialogue():
	if index>=dialogues.size():
		close_box()
		return
	dialogue.text = dialogues[index]

func close_box():
	if speaker and speaker in GameState.dialogues and index>=dialogues.size():
		GameState.dialogues[speaker].counter+=1
	GameState.gameState.in_dialogue = false
	panel.visible = false
	active = false
	
func show_dialogues(new_speaker: String,new_dialogues: Array):
	GameState.gameState.in_dialogue = true
	active = true
	panel.visible = true
	speaker = new_speaker
	dialogues = new_dialogues
	index = 0
	if dialogues.is_empty():
		dialogue.text = "..."
	else:
		show_current_dialogue()
	
	
	

extends CanvasLayer
@onready var panel: PanelContainer = $PanelContainer

@onready var dialogue: Label = $PanelContainer/VBoxContainer/Dialogue
@onready var name_label: Label = $PanelContainer/VBoxContainer/Name
var index:=0
var speaker:String = ""
var dialogues: Array = []
var on_finish: Dictionary = {}  # run through GameState.execute when the last line is reached
var entry: Dictionary = {}  # the GameState dialogue entry being shown (holds its counter)
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
	

# Name and dialogue share one LabelSettings, so this resizes both.
func set_font_size(size: int) -> void:
	dialogue.label_settings.font_size = size

func show_current_dialogue():
	if index>=dialogues.size():
		close_box()
		return
	var line: Dictionary = dialogues[index]
	name_label.text = line.keys()[0]
	dialogue.text = line.values()[0]

func close_box():
	if index>=dialogues.size():
		entry["counter"] = entry.get("counter", 0) + 1
		GameState.execute(on_finish)
		if speaker == "jim":
			move_jim_to_hill()
	on_finish = {}
	entry = {}
		
	GameState.gameState.in_dialogue = false
	panel.visible = false
	active = false
	
func show_dialogues(new_speaker: String,new_dialogues: Array,new_on_finish: Dictionary = {}, new_entry: Dictionary = {}):
	if GameState.gameState.inventory_open:
		return
	GameState.gameState.in_dialogue = true
	active = true
	panel.visible = true
	speaker = new_speaker
	dialogues = new_dialogues
	on_finish = new_on_finish
	entry = new_entry
	index = 0
	if dialogues.is_empty():
		name_label.text = ""
		dialogue.text = "..."
	else:
		show_current_dialogue()


func move_jim_to_hill() -> void:
	if not GameState.flags.get("met_jim", false):
		return
	if GameState.npc_map("jim") != "town_one":
		return
	GameState.npc_state["jim"] = {"loc": "hillside", "pos": Vector2(160, 120)}
	var scene := get_tree().current_scene
	var jim := scene.find_child("jim", true, false) as Node2D
	var exit := scene.find_child("town_two_transition", true, false)
	if jim == null or exit == null:
		return
	var target: Vector2 = (exit.get_child(0) as Node2D).global_position
	var duration := jim.global_position.distance_to(target) / 80.0 
	var tween := jim.create_tween()
	tween.tween_property(jim, "global_position", target, duration)
	tween.tween_callback(jim.queue_free)

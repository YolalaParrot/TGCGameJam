extends CanvasLayer
@onready var panel: PanelContainer = $PanelContainer

@onready var dialogue: Label = $PanelContainer/HBoxContainer/VBoxContainer/Dialogue
@onready var name_label: Label = $PanelContainer/HBoxContainer/VBoxContainer/Name
@onready var portrait_left: TextureRect = $PanelContainer/HBoxContainer/PortraitLeft
@onready var portrait_right: TextureRect = $PanelContainer/HBoxContainer/PortraitRight
var index:=0
var speaker:String = ""
var dialogues: Array = []
var on_finish: Dictionary = {}
var entry: Dictionary = {}
var active = false

const move_actions := ["move_left", "move_right", "move_up", "move_down"]

const portraits := {
	"Player": {"sheet": "res://final-assets/Entities/Player animations/protagonist-idle-right.png", "size": Vector2(26, 27), "flip": false},
	"Jim": {"sheet": "res://final-assets/Entities/jim/jim-idle-left.png", "size": Vector2(26, 27), "flip": false},
	"Ken": {"sheet": "res://final-assets/Entities/ken/ken-idle-right.png", "size": Vector2(26, 27), "flip": true},
	"Finn": {"sheet": "res://final-assets/Entities/finn/finn-idle-right.png", "size": Vector2(26, 27), "flip": true},
	"Willy": {"sheet": "res://final-assets/Entities/unclewilly/unclewilly-idle-down.png", "size": Vector2(26, 27), "flip": false},
	"Gary": {"sheet": "res://assets/Entities/npc2-idle-down.png", "size": Vector2(26, 41), "flip": false},
}
const portrait_fps := 5.0

var portrait_frames: Array = []
var portrait_rect: TextureRect
var portrait_frame := 0
var portrait_time := 0.0

func _ready() -> void:
	panel.visible = false
	pass


func _process(delta: float) -> void:
	if not active or portrait_frames.is_empty():
		return
	portrait_time += delta
	if portrait_time >= 1.0 / portrait_fps:
		portrait_time = 0.0
		portrait_frame = (portrait_frame + 1) % portrait_frames.size()
		portrait_rect.texture = portrait_frames[portrait_frame]


func set_portrait(who: String) -> void:
	portrait_frames.clear()
	portrait_left.texture = null
	portrait_right.texture = null
	if not portraits.has(who):
		return
	var info: Dictionary = portraits[who]
	var sheet: Texture2D = load(info.sheet)
	for i in int(sheet.get_width() / info.size.x):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(i * info.size.x, 0, info.size.x, info.size.y)
		portrait_frames.append(frame)
	portrait_rect = portrait_left if who == "Player" else portrait_right
	portrait_rect.flip_h = info.flip
	portrait_frame = 0
	portrait_time = 0.0
	portrait_rect.texture = portrait_frames[0]

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
	else:
		for action in move_actions:
			if event.is_action_pressed(action):
				close_box()
				break
	

func set_font_size(size: int) -> void:
	dialogue.label_settings.font_size = size

func show_current_dialogue():
	if index>=dialogues.size():
		close_box()
		return
	var line: Dictionary = dialogues[index]
	name_label.text = line.keys()[0]
	dialogue.text = line.values()[0]
	set_portrait(name_label.text)

func close_box():
	if index>=dialogues.size():
		entry["counter"] = entry.get("counter", 0) + 1
		GameState.execute(on_finish)
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
		set_portrait("")
	else:
		show_current_dialogue()

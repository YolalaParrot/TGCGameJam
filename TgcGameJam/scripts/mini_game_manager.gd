extends Node


@export var time_limit := 60.0

var parts_collected := 0
var parts_total := 0
var time_left := 0.0
var finished := false

@onready var player: CharacterBody2D = $"../player"
@onready var time_label: Label = $"../player/Label"
@onready var part_label: Label = $"../player/part_label"


func _ready() -> void:
	parts_total = $"../Parts".get_child_count()
	time_left = time_limit
	update_labels()


func _process(delta: float) -> void:
	if finished:
		return
	time_left = maxf(time_left - delta, 0.0)
	time_label.text = "Time left: %d" % ceili(time_left)
	if time_left == 0.0:
		finish(false)


func update_collected():
	if finished:
		return
	parts_collected += 1
	update_labels()
	if parts_collected >= parts_total:
		finish(true)


func update_labels() -> void:
	time_label.text = "Time left: %d" % ceili(time_left)
	part_label.text = "Parts found: %d / %d" % [parts_collected, parts_total]


func finish(passed: bool) -> void:
	finished = true
	player.set_physics_process(false)
	time_label.text = "STAGE CLEAR!" if passed else "TIME'S UP!"
	Signals.GameOver.emit(passed)

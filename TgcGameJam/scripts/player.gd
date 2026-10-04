extends CharacterBody2D

const SPEED = 100.0
var current_dir = "none"

@onready var interact_sensor: Area2D = $InteractSensor
@export var current_interactable:Area2D = null


func _ready() -> void:
	$AnimatedSprite2D.play("front_idle")
	

func _physics_process(delta: float) -> void:
	if GameState.gameState.in_dialogue:
		return
	player_movement(delta)
	find_best_interactable()

func player_movement(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		play_animation(1)
		velocity.x = SPEED
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		play_animation(1)
		velocity.x = -SPEED
		velocity.y = 0
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		play_animation(1)
		velocity.y = SPEED
		velocity.x = 0
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		play_animation(1)
		velocity.y = -SPEED
		velocity.x = 0
	else:
		play_animation(0)
		velocity = Vector2.ZERO
	move_and_slide()

func play_animation(movement: int) -> void:
	var anim = $AnimatedSprite2D
	
	if current_dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			anim.play("side_idle")
	elif current_dir == "left":
		anim.flip_h = true
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			anim.play("side_idle")
	elif current_dir == "down":
		anim.flip_h = true
		if movement == 1:
			anim.play("front_walk")
		elif movement == 0:
			anim.play("front_idle")
	elif current_dir == "up":
		anim.flip_h = true
		if movement == 1:
			anim.play("back_walk")
		elif movement == 0:
			anim.play("back_idle")

func find_best_interactable():
	var interactable_areas = interact_sensor.get_overlapping_areas()
	var best_dist := INF
	var best:Area2D = null
	for area in interactable_areas:
		if area.is_in_group("interactable"):
			if not (area.is_in_group("npc") and area.npc.NPC_Name not in GameState.dialogues):
				var d := global_position.distance_to(area.global_position)
				if d<best_dist:
					best_dist = d
					best = area
	if best==current_interactable:
		return
	if current_interactable:
		current_interactable.unfocus()
	current_interactable = best
	if current_interactable:
		current_interactable.focus()

func _unhandled_input(event: InputEvent) -> void:
	if GameState.gameState.in_dialogue:
		return
	if event.is_action_pressed("interact") and current_interactable:
		current_interactable.interact()
		get_viewport().set_input_as_handled() 
				
				

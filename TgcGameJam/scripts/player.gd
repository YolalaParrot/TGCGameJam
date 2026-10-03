#extends CharacterBody2D
#
#
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
#
#
#func _physics_process(delta: float) -> void:
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#move_and_slide()
#

extends CharacterBody2D

const SPEED = 100.0
var current_dir = "none"

@onready var interact_sensor: Area2D = $InteractSensor
var current_interactable:Area2D = null


func _ready() -> void:
	$AnimatedSprite2D.play("front_idle")
	

func _physics_process(delta: float) -> void:
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
			var d := global_position.distance_to(area.global_position)
			if d<best_dist:
				best_dist = d
				best = area
	if best==current_interactable:
		return
	current_interactable = best

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_interactable:
		print("Bro , Did you hear , the world is about to end!!!!!!!!")
				
				

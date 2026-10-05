extends CharacterBody2D

const SPEED = 5000.0
var current_dir = "none"

@onready var interact_sensor: Area2D = $InteractSensor
@export var current_interactable:Area2D = null
@onready var arrow_timer: Timer = $ArrowTimer
@onready var guidance_arrow: Sprite2D = $GuidanceArrow
var next_task_target:Node2D = null
var arrow_radius:float
var arrow_tween:Tween


func _ready() -> void:
	$AnimatedSprite2D.play("front_idle")
	arrow_radius = guidance_arrow.position.length()
	guidance_arrow.visible = false

func show_arrow() -> void:
	var task = GameState.get_current_tasks()
	if task.is_empty():
		return
	var here := current_location()
	var target_item: Node2D = null

	if here == task.location:
		target_item = owner.find_child(task.target, true, false)
	else:
		var exit_name := bfs(here, task.location)
		var teleporter := owner.find_child(exit_name, true, false) if exit_name != "" else null
		if teleporter:
			target_item = teleporter.get_child(0) as Node2D  # the door's collision shape

	guidance_arrow.visible = target_item != null
	if target_item:
		next_task_target = target_item
		
		# Small Fading Animation for Arrow
		if arrow_tween:
			arrow_tween.kill()
		guidance_arrow.visible = true
		guidance_arrow.modulate.a = 0.0
		arrow_tween = create_tween()
		arrow_tween.tween_property(guidance_arrow, "modulate:a", 1.0, 0.3)
		arrow_tween.tween_interval(1.5)
		arrow_tween.tween_property(guidance_arrow, "modulate:a", 0.0, 1.2)
		arrow_tween.tween_callback(hide_arrow)

func hide_arrow() -> void:
	guidance_arrow.visible = false
	next_task_target = null

func bfs(from: String, to: String) -> String:
	var visited := {from: true}
	var queue: Array = []
	for exit in GameState.Map.get(from, []):
		if exit.to == to:
			return exit.exit
		visited[exit.to] = true
		queue.append([exit.to, exit.exit])  # [region, first exit taken to get there]
	while not queue.is_empty():
		var curr = queue.pop_front()
		for exit in GameState.Map.get(curr[0], []):
			if exit.to == to:
				return curr[1]
			if not visited.has(exit.to):
				visited[exit.to] = true
				queue.append([exit.to, curr[1]])
	print("Cant Find Target")
	return ""
	
func current_location() -> String:
	return owner.scene_file_path.get_file().get_basename()
	
func _process(delta: float) -> void:
	if not guidance_arrow.visible or not is_instance_valid(next_task_target):
		return
	var dir := (next_task_target.global_position - global_position).normalized()
	guidance_arrow.position = dir * arrow_radius   # move onto the circle around the player
	guidance_arrow.rotation = dir.angle() 
	
func _physics_process(delta: float) -> void:
	if GameState.gameState.in_dialogue or GameState.gameState.inventory_open:
		velocity = Vector2.ZERO
		play_animation(0)
		return
	player_movement(delta)
	find_best_interactable()

func player_movement(delta: float) -> void:
	var is_right = Input.is_action_pressed("move_right")
	var is_left = Input.is_action_pressed("move_left")
	var is_down = Input.is_action_pressed("move_down")
	var is_up = Input.is_action_pressed("move_up")
	if is_right:
		if not (is_up or is_down):
			velocity.y = 0
			current_dir = "right"
		play_animation(1)
		velocity.x = SPEED*delta
	if is_left:
		if not (is_up or is_down):
			velocity.y = 0
			current_dir = "left"
		play_animation(1)
		velocity.x = -SPEED*delta
	if is_down:
		if not (is_left or is_right):
			velocity.x = 0
			current_dir = "down"
		play_animation(1)
		velocity.y = SPEED*delta
	if Input.is_action_pressed("move_up"):
		if not (is_left or is_right):
			velocity.x = 0
			current_dir = "up"
		play_animation(1)
		velocity.y = -SPEED*delta
	if not (is_left or is_up or is_down or is_right):
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
			if not (area.is_in_group("npc") and not area.npc.can_interact()):
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
	if GameState.gameState.in_dialogue or CutsceneManager.playing:
		return
	if event.is_action_pressed("inventory"):
		Inventory.toggle()
		get_viewport().set_input_as_handled()
		return
	if GameState.gameState.inventory_open:
		return
	if event.is_action_pressed("interact") and current_interactable:
		current_interactable.interact()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("guide"):
		show_arrow()
				
				

extends Sprite2D

@export var fall_speed: float = 300.0

var init_y_pos: float = -360.0
var target_y_pos: float = 280.0 
var pass_threshold: float = 280.0 # Re-added for key_listener.gd
var miss_threshold: float = 360.0

var has_passed: bool = false

func _init():
	set_process(false)

func _process(delta):
	global_position += Vector2(0, fall_speed * delta)
	
	if global_position.y > miss_threshold:
		if has_node("Timer") and not $Timer.is_stopped():
			$Timer.stop()
		has_passed = true

func Setup(target_x: float, target_frame: int):
	global_position = Vector2(target_x, init_y_pos)
	frame = target_frame
	
	set_process(true)

func _on_destroy_timer_timeout():
	queue_free()

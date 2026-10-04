extends Area2D

@onready var mini_game_manager: Node = %"mini-GameManager"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("im aliveeeeee")





func _on_body_entered(body: Node2D) -> void:
	mini_game_manager.update_collected()
	print("haww u touched mehhh, blehhhbbb")
	queue_free()

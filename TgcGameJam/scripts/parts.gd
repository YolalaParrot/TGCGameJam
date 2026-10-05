extends Area2D

@onready var mini_game_manager: Node = %"mini-GameManager"

func _ready() -> void:
	print ("im aliveeeeee")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	mini_game_manager.update_collected()
	print("haww u touched mehhh, blehhhbbb")
	queue_free()

extends Area3D

@onready var timer: Timer = $Timer
@onready var player: CharacterBody3D = %player

func _on_body_entered(body: Node3D) -> void:
	body.get_node("CollisionShape3D").queue_free()
	Engine.time_scale = 0.5
	timer.start()

func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

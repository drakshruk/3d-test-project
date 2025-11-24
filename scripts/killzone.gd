extends Area3D

@export var damage: float = 10.0
@onready var timer: Timer = $Timer
#@onready var player: CharacterBody3D = %player

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("change_hp"):
		body.change_hp(-damage)
	#Engine.time_scale = 0.5
	#timer.start()

func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

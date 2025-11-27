extends Node3D

signal player_entered(player_node)
signal player_exited(player_node)

var interact_type = -1 as int
# 0 - terminal
# 1 - door (not yet)

func _ready() -> void:
	interact_type = define_type() as int

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == %player:
		emit_signal("player_entered", self)


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == %player:
		emit_signal("player_exited", self)

# Можно подумать как сделать по-другому (не привязываясь к именам)
func define_type() -> int:
	if name == "interact_area_1":
		return 0
	elif name == "interact_area_2":
		return 1
	else:
		return -1

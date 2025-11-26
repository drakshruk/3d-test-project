# PlayerInteractionZone.gd
extends Area3D

class_name PlayerInteractionZone

# Signals to communicate with player
signal interactable_entered(interactable)
signal interactable_exited(interactable)

func _ready() -> void:
	# Monitor areas and bodies
	monitoring = true
	monitorable = false

# Connect signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_area_entered(area: Area3D) -> void:
	if area is Interactable:
		interactable_entered.emit(area)

func _on_body_entered(body: Node3D) -> void:
	if body is Interactable:
		interactable_entered.emit(body)

func _on_area_exited(area: Area3D) -> void:
	if area is Interactable:
		interactable_exited.emit(area)

func _on_body_exited(body: Node3D) -> void:
	if body is Interactable:
		interactable_exited.emit(body)

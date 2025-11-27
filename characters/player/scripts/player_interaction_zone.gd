# PlayerInteractionZone.gd
extends Area3D

class_name PlayerInteractionZone

# Signals to communicate with player
signal interactable_entered(interactable)
signal interactable_exited(interactable)

signal interaction_available(interactable: Interactable)
signal interaction_unavailable()
signal interaction_triggered(interactable: Interactable)

var current_interactables: Array[Interactable] = []
var nearest_interactable: Interactable = null
var player: CharacterBody3D

func _ready() -> void:
	player = get_parent()
	# Monitor areas and bodies
	monitoring = true
	monitorable = false
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearest_interactable:
		_try_interact()

func _on_area_entered(area: Area3D) -> void:
	if area is Interactable:
		_add_interactable(area)

func _on_body_entered(body: Node3D) -> void:
	if body is Interactable:
		_add_interactable(body)

func _on_area_exited(area: Area3D) -> void:
	if area is Interactable:
		_remove_interactable(area)

func _on_body_exited(body: Node3D) -> void:
	if body is Interactable:
		_remove_interactable(body)		

func _add_interactable(interactable: Interactable) -> void:
		if interactable not in current_interactables:
			current_interactables.append(interactable)
			_update_nearest_interactable()

func _remove_interactable(interactable: Interactable) -> void:
	if interactable in current_interactables:
		current_interactables.erase(interactable)
		interactable.set_highlight(false)
		_update_nearest_interactable()		

func _update_nearest_interactable() -> void:
	var old_nearest = nearest_interactable
	
	if current_interactables.is_empty():
		nearest_interactable = null
	else:
		var closest_distance = INF
		for interactable in current_interactables:
			var distance = global_position.distance_to(interactable.global_position)
			
			if distance < closest_distance and interactable.can_interact():
				closest_distance = distance
				nearest_interactable = interactable
	
	if old_nearest and old_nearest != nearest_interactable:
		old_nearest.set_highlight(false)
		
	if nearest_interactable:
		nearest_interactable.set_highlight(true)
		interaction_available.emit(nearest_interactable)

func _try_interact() -> void:
	if nearest_interactable and nearest_interactable.can_interact():
		interaction_triggered.emit(nearest_interactable)
		nearest_interactable.interact(player)

func get_current_interactable() -> Interactable:
	return nearest_interactable

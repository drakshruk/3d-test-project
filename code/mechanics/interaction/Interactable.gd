# Interactable.gd
extends Area3D
class_name Interactable

@onready var terminal: CanvasGroup = $"../../../Terminal"

## Emitted when interaction becomes available/unavailable to player
signal interaction_available_changed(available)

## Display name for UI
@export var interaction_name: String = "Interact"
## Interaction prompt for UI
@export var interaction_prompt: String = "Press E to interact"

var is_highlighted: bool = false

func _ready() -> void:
	# Add to interactable group for global queries
	add_to_group("interactables")
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## Override this to define interaction logic
func interact(interactor: Node) -> void:
	terminal.visible = true
	
	EventBus.terminal_closed.connect(_on_terminal_closed.bind(interactor))
	EventBus.open_terminal()
	print("Interacted with ", name)
	interactor.set_process_input(false)
	interactor.set_physics_process(false)

func _on_terminal_closed(interactor: Node):
	interactor.set_process_input(true)
	interactor.set_physics_process(true)
	terminal.visible = false

## Override this to add conditions for interaction
func can_interact() -> bool:
	return true

## Called when player enters interaction range
func _on_player_entered(player: Node) -> void:
	if player.has_method("_on_interactable_entered"):
		player._on_interactable_entered(self)

## Called when player exits interaction range
func _on_player_exited(player: Node) -> void:
	if player.has_method("_on_interactable_exited"):
		player._on_interactable_exited(self)

## Optional: Highlight when player is near
func set_highlight(enable: bool) -> void:
	if is_highlighted == enable:
		return
		
	is_highlighted = enable
	# Implement visual highlighting - this is just an example
	if has_node("Highlight"):
		get_node("Highlight").visible = enable
	elif has_method("_custom_highlight"):
		#_custom_highlight(enable)
		pass

## Optional: Get interaction text for UI
func get_interaction_text() -> String:
	return interaction_prompt

## Area/body signal handlers
func _on_area_entered(area: Area3D) -> void:
	if area.get_parent() is CharacterBody3D:
		_on_player_entered(area.get_parent())

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:  # Player entered
		_on_player_entered(body)

func _on_area_exited(area: Area3D) -> void:
	if area.get_parent() is CharacterBody3D:
		_on_player_exited(area.get_parent())

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		_on_player_exited(body)

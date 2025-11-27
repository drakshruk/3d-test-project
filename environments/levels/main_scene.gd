extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var camera_3d: Camera3D = $SubViewport/Camera3D

var terminal_active: bool = false

func _add_camera_viewport() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if EventBus.terminal_opened.connect(_on_terminal_opened) != OK:
		print("ERROR: Failed to connect terminal_opened signal")
	if EventBus.terminal_closed.connect(_on_terminal_closed) != OK:
		print("ERROR: Failed to connect terminal_closed signal")
	print("MainScene: Signal connections established")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not terminal_active:
		#print("terminal not active")
		return
	print("terminal active")
	if not sub_viewport:
		print("viewport is null")
		return
	print("viewport active")
	if not sub_viewport.get_texture():
		return
	print("got texture")
	EventBus.send_camera_feed.emit(sub_viewport.get_texture())


func _on_terminal_opened():
	print("MainScene: Terminal opened")
	terminal_active = true
	# Send initial camera feed
	if sub_viewport and sub_viewport.get_texture():
		EventBus.send_camera_feed.emit(sub_viewport.get_texture())
		

func _on_terminal_closed():
	print("MainScene: Terminal closed")
	terminal_active = false
	

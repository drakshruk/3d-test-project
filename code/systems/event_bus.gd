extends Node

signal terminal_opened()
signal terminal_closed()
var terminal_active := false

signal send_camera_feed(camera_feed: ViewportTexture)

func emit_camera_feed(texture: ViewportTexture):
	print("passing camera feed")
	print("amount of nodes connected: ", send_camera_feed.get_connections().size())
	send_camera_feed.emit(texture)

func open_terminal():
	terminal_active = true
	terminal_opened.emit()

func close_terminal():
	terminal_active = false
	terminal_closed.emit()

func _ready():
	print("EventBus loaded and ready!")

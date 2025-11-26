extends Node2D
@onready var camera_display: TextureRect = $"camera-display"

class Command:
	var name: String
	var short_description: String
	
	func _init(n: String = "", desc: String = ""):
		name = n
		short_description = desc

var history = [] as Array[String]
var commands: Array[Command] = [Command.new("help", "prints this text"),
								Command.new("clear", "clears the screen"),
								Command.new("history", "displays the history list"),
								Command.new("camera", "switches to camera view")]
var rotation_var = 0 as float;
@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.timeout.connect(_on_Timer_timeout)
	shift_dir_update(rotation_var)
	timer.start()
	EventBus.send_camera_feed.connect(_on_set_camera_feed)
	print("TerminalUI connected to EventBus signal")
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not $LineEdit.is_editing():
		$LineEdit.edit()

func _on_line_edit_text_submitted(new_text: String) -> void:
	if (new_text != ""):
		$LineEdit.clear()
		history.push_back(new_text)
		var argv = strcmp(new_text, " ")
		var out = processCommand(argv)
		for v in out:
			$Label.text += v

# Функция, возвращающая массив строк, которые будут выведены в терминал
func processCommand(argv: Array[String]) -> Array[String]:
	var out = [] as Array[String]
	
	match argv[0]:
		"help":
			for com in commands:
				out.push_back(com.name + "  -  " + com.short_description + "\n")
		"clear":
			$Label.text = ""
		"history":
			for v in history:
				out.push_back(v + "\n")
		"camera":
			print("switched to camera")
		_:
			out.push_back(argv[0] + ": command not found. Try help to see existing commands.\n")
	
	return out

func strcmp(line: String, char: String) -> Array[String]:
	if (char.length() != 1):
		return []
	
	while line[0] == char:
		line = line.erase(0, 1)
	while line.contains(char + char):
		line.replace(char + char, char)
	
	var words = [] as Array[String]
	var str = "";
	while line.length() != 0:
		var b = line[0]
		if b == char:
			words.push_back(str)
			str = ""
		else:
			str += b
			
		line = line.erase(0, 1);
	words.push_back(str)
	
	return words

# Обработчик события окончания таймера
func _on_Timer_timeout():
	rotation_var += 0.1
	shift_dir_update(rotation_var)
	timer.start()

# Обновление направления сдвига заднего плана
func shift_dir_update(rotation : float):
	var dir = Vector2(10, 0)
	var angle = sin(rotation_var)
	angle = ((angle + 1) / 2) * PI * 0.5
	 # sin = [-1, 1] -> [0, 2] -> [0,1] -> [0, PI / 2]

	var new_dir = Vector2(dir.x * cos(angle) - dir.y * sin(angle), dir.x * sin(angle) + dir.y * cos(angle))
	$BackGround.autoscroll = new_dir

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		self.visible = false
		EventBus.close_terminal()

func _on_set_camera_feed(camera_feed: ViewportTexture):
	if camera_feed:
		print("TerminalUI received camera feed!")
		camera_display.texture = camera_feed

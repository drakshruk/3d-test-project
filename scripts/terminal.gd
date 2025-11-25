extends Node2D

var history = []
var rotation_var = 0 as float;
@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.timeout.connect(_on_Timer_timeout)
	shift_dir_update(rotation_var)
	timer.start()
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not $LineEdit.is_editing():
		$LineEdit.edit()

func _on_line_edit_text_submitted(new_text: String) -> void:
	if (new_text != ""):
		history.push_back(new_text)
		$Label.text += "\n" + new_text
		$LineEdit.clear()
		
	var words = strcmp(new_text, " ")
		
	print(words)

func strcmp(line: String, char: String):
	if (char.length() != 1):
		return []
		
	var words = []
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
		get_tree().change_scene_to_file("res://scenes/main_scene.tscn")

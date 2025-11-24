extends Node3D

@export_group("info")
@export var pos = Vector3()

@onready var collisionShape: CollisionShape3D = $CollisionShape3D
var shape: CylinderShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if collisionShape:
		shape: CylinderShape3D = collisionShape.shape

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dot = %player.position + %player.direction
	print(is_dotInShape(dot));

func is_dotInShape(dot: Vector3):
	var space_state = get_world_3d().direct_space_state
	
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform.origin = dot # Точка, которую проверяем
	params.collide_with_bodies = false
	params.collide_with_areas = false

	var result = space_state.intersect_shape(params, 1)
	if result.size() > 0:
		return true
	else:
		return false

@tool
extends MeshInstance3D

@export var wall_width: float = 1.0:
	set(value):
		wall_width = max(0.1, value)
		update_wall_dimensions()

@export var wall_height: float = 2.0:
	set(value):
		wall_height = max(0.1, value)
		update_wall_dimensions()

@export var wall_depth: float = 0.1:
	set(value):
		wall_depth = max(0.01, value)
		update_wall_dimensions()

func _ready() -> void:
	update_wall_dimensions()

func update_wall_dimensions() -> void:
	if not is_inside_tree():
		return
	
	# Update mesh
	if mesh is BoxMesh:
		mesh.size = Vector3(wall_width, wall_height, wall_depth)
	
	# Update collision shape - direct approach
	var collision_shape := get_node_or_null("StaticBody3D/CollisionShape3D")
	if collision_shape and collision_shape.shape is BoxShape3D:
		collision_shape.shape.size = Vector3(wall_width, wall_height, wall_depth)

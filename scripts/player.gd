extends CharacterBody3D

@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera_3d: Camera3D = %Camera3D
@onready var character: Node3D = $character

@export_group("Health")
@export var max_hp: float = 100.0
@export var i_frames: int = 10
var hp: float = max_hp

## export group for movement
@export_group("Movement")
@export_range(0.1, 20.0, 0.1, "or_greater") var speed: float = 5.0
## Speed multiplier when sprinting (should be higher than normal speed)
@export_range(0.1, 30.0, 0.1, "or_greater") var sprint_speed: float = 8.0
## Vertical velocity applied when jumping
@export_range(1.0, 20.0, 0.1) var jump_velocity: float = 4.5

var input_dir: Vector2 = Vector2.ZERO
var direction: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var is_jumping: bool = false

@export_group("Dash")
@export var dash_speed: float = 15.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5
@export var dash_gravity_multiplier: float = 2.5  # Increased gravity during dash
@export var post_dash_gravity_multiplier: float = 1.8  # Temporary increased gravity after dash
@export var post_dash_gravity_duration: float = 0.5  # How long the extra gravity lasts
@export_range(0.0, 2.0) var inertia_multiplier: float = 0.5  # How much current velocity affects dash
@export var can_dash_in_air: bool = true

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var post_dash_gravity_timer: float = 0.0

## export group for camera settings
@export_group("Camera")
## Mouse sensitivity for camera rotation (higher values = faster rotation)
@export_range(0.0, 1.0, 0.001) var mouse_sensitivity: float = 0.005
## Maximum vertical camera tilt angle in radians (prevents over-rotation)
@export_range(0.0, 1.57, 0.01) var tilt_limit: float = deg_to_rad(75)
## Speed at which the character rotates to face movement direction
@export_range(0.1, 50.0, 0.1) var rotation_speed: float = 10.0

## Raycasts for detecting if we can stick to the wall
## NOTE: All must be on the same collision mask as walls!
@onready var wall_raycast_front: RayCast3D = %WallRaycastForward
@onready var wall_raycast_left: RayCast3D = %WallRaycastLeft
@onready var wall_raycast_right: RayCast3D = %WallRaycastRight

@export_group("Wall sticking")
@export_range(0.0,2.0,0.1) var wall_stick_gravity: float = 0.3
@export var can_stick_to_walls: bool = true

var is_sticking_to_wall: bool = false
var current_wall_normal = Vector3.ZERO

@export_group("Crouching")
@export var crouch_speed: float = 2.5
@export var crouch_height: float = 1.0
@export var stand_height: float = 1.5
@export var crouch_transition_speed: float = 8.0
@export var can_uncrouch_check_distance: float = 0.5 

var is_crouching: bool = false
var target_height: float = stand_height
var original_collision_shape_height: float
var original_collision_shape_position: float
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var crouch_shape_cast: ShapeCast3D = %CrouchShapeCast
var last_crouch_attempt: float = 0.0
var crouch_debounce_time: float = 0.1
var crouch_transition_progress: float = 1.0  # 1.0 = fully transitioned


func _ready() -> void:
	## Captures the mouse cursor for first-person camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if collision_shape:
		var shape: CylinderShape3D = collision_shape.shape
		original_collision_shape_height = shape.height
		original_collision_shape_position = collision_shape.position.y

func _physics_process(delta: float) -> void:
	_handle_crouch_input()
	_update_crouch_state(delta)
	_handle_sticking_to_the_walls()
	_handle_gravity_and_jump(delta)
	_handle_movement_input()
	_handle_dash_input()
	_update_dash_timers(delta) 
	_handle_character_rotation(delta)
	_apply_movement()
	move_and_slide()

## Rotates the character to face the movement direction
func _handle_character_rotation(delta: float) -> void:
	character.rotation.y = lerp_angle(character.rotation.y, camera_pivot.rotation.y + PI, rotation_speed * delta)

## Applies horizontal movement velocity based on input and sprint/stick-to-wall state
func _apply_movement() -> void:
	if is_dashing:
		return
	
	var is_moving = input_dir != Vector2.ZERO and (is_on_floor() or is_sticking_to_wall)
	is_sprinting = Input.is_action_pressed("sprint") and is_moving
	
	var current_speed: float
	if is_crouching:
		current_speed = crouch_speed
	elif is_sprinting:
		current_speed = sprint_speed
	else:
		current_speed = speed
	
	if direction:
		if is_sticking_to_wall:
			# Project movement direction onto wall plane
			var wall_tangent = direction - current_wall_normal * direction.dot(current_wall_normal)
			velocity.x = wall_tangent.x * current_speed
			velocity.z = wall_tangent.z * current_speed
		else:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

## Handles mouse input for camera rotation with tilt limits.
func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion:
		camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		camera_pivot.rotation.y += -event.relative.x * mouse_sensitivity

func _handle_crouch_input() -> void:
	if Time.get_ticks_msec() - last_crouch_attempt < crouch_debounce_time * 1000:
		return
	
	if Input.is_action_pressed("crouch") and is_on_floor() and not is_dashing:
		if not is_crouching:
			is_crouching = true
			target_height = crouch_height
			last_crouch_attempt = Time.get_ticks_msec()
	elif Input.is_action_just_released("crouch"):
		if is_crouching and _can_uncrouch():
			is_crouching = false
			target_height = stand_height

func _can_uncrouch() -> bool:
	# checking if there's an object above the head
	if crouch_shape_cast:
		crouch_shape_cast.force_shapecast_update()
		return crouch_shape_cast.get_collision_count() == 1
	return true

func _update_crouch_state(delta: float) -> void:
	if not collision_shape:
		return
	
	var shape: CylinderShape3D = collision_shape.shape
	
	# Smoothly interpolate to target height
	var new_height = lerp(shape.height, target_height, crouch_transition_speed * delta)
	var height_diff = new_height - shape.height
	shape.height = new_height
	collision_shape.position.y -= height_diff / 2.0
	
	# Smooth camera transition
	var camera_target_y = target_height - 0.5
	camera_pivot.position.y = lerp(camera_pivot.position.y, camera_target_y, crouch_transition_speed * delta)

func change_hp(d_hp: float) -> void:
	hp += d_hp
	hp = max(0, hp)
	print("took ", d_hp, "damage. current hp:", hp)
	shake_camera()
	if hp == 0:
		die()

func shake_camera() -> void:
	var shake_strength = 0.5
	var original_position = camera_3d.position
	camera_3d.position += Vector3(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength,shake_strength),0)
	await get_tree().create_timer(0.1).timeout
	camera_3d.position = original_position

func die() -> void:
	get_tree().reload_current_scene()

func _handle_dash_input() -> void:
	# Check if we can dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		if is_on_floor() or can_dash_in_air:
			start_dash()

func start_dash() -> void:
	if is_dashing or is_crouching:
		return
	
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Solution 2: Cancel some vertical velocity
	if velocity.y > 0:  # Only cancel upward velocity
		velocity.y *= 0.7
	
	# Calculate dash direction based on camera forward
	var camera_forward = -camera_pivot.global_transform.basis.z
	camera_forward.y = 0  # Keep it horizontal
	camera_forward = camera_forward.normalized()
	
	# Add inertia from current movement
	var current_horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var inertia_boost = current_horizontal_velocity * inertia_multiplier
	
	# Combine camera direction with inertia
	dash_direction = (camera_forward * dash_speed) + inertia_boost
	
	# Apply dash velocity
	velocity.x = dash_direction.x
	velocity.z = dash_direction.z		
	print("DASH! Direction: ", dash_direction, " Speed: ", dash_direction.length())

func _update_dash_timers(delta: float) -> void:
	# Update dash duration timer
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			# Start post-dash gravity period
			post_dash_gravity_timer = post_dash_gravity_duration
			# Optional: Preserve some dash momentum when dash ends
			velocity.x *= 0.9
			velocity.z *= 0.9
	# Update cooldown timer
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

func _handle_sticking_to_the_walls() -> void:
	if Input.is_action_just_pressed("stick_to_the_wall") and can_stick_to_walls:
		if not is_sticking_to_wall:
			try_stick_to_wall()
		else:
			release_from_the_wall()

func try_stick_to_wall() -> void:
	# Check all raycasts for wall detection
	var raycasts = [wall_raycast_left, wall_raycast_right, wall_raycast_front]
	for raycast in raycasts:
		if raycast.is_colliding():
			is_sticking_to_wall = true
			current_wall_normal = raycast.get_collision_normal()
			velocity.y = 0
			break

## Releases the player from sticking to the wall
func release_from_the_wall() -> void:
	if is_sticking_to_wall:
		is_sticking_to_wall = false
		current_wall_normal = Vector3.ZERO

## Processes gravity and jumping, modifies velocity depending on the current state(dashing,jumping, etc)
func _handle_gravity_and_jump(delta: float) -> void:
	if is_sticking_to_wall:
		velocity.y -= wall_stick_gravity * delta
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = jump_velocity
			velocity.x += current_wall_normal.x * 3.0
			velocity.z += current_wall_normal.z * 3.0
			release_from_the_wall()
		if not _is_any_raycast_colliding():
			release_from_the_wall()
	elif not is_on_floor():
		var gravity_multiplier = 1.0
		
		# Apply increased gravity during dash
		if is_dashing:
			gravity_multiplier = dash_gravity_multiplier
		# Apply post-dash gravity for a short time
		elif post_dash_gravity_timer > 0:
			gravity_multiplier = post_dash_gravity_multiplier
			post_dash_gravity_timer -= delta
		
		velocity += get_gravity() * delta * gravity_multiplier
		is_jumping = velocity.y > 0
	else:
		is_jumping = false
		post_dash_gravity_timer = 0  # Reset when landing

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true

## Checks if any of the raycasts are colliding with a stickable wall
func _is_any_raycast_colliding() -> bool:
	return (wall_raycast_front.is_colliding() or
			wall_raycast_left.is_colliding() or
			wall_raycast_right.is_colliding())

## Processes movement input and calculates movement direction relative to camera
func _handle_movement_input() -> void:
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	var camera_basis = Transform3D(Basis(Vector3.UP, camera_pivot.rotation.y), Vector3.ZERO).basis
	direction = (camera_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

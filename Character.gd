extends CharacterBody3D

var midi_move := Vector2.ZERO

@export var move_speed: float = 4.5
@export var gravity: float = 20.0
@export var floor_snap_length_value: float = 0.2
@export var max_slope_angle_deg: float = 45.0
@export var ground_snap_speed: float = 15.0
@export var hover_height: float = 1.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

enum MovementMode { PHYSICS, HOVER }
var movement_mode: MovementMode = MovementMode.PHYSICS
var target_y: float = 0.0

func _ready() -> void:
	_apply_movement_settings()

func set_movement_mode(mode: String) -> void:
	if mode == "hover":
		movement_mode = MovementMode.HOVER
		collision_mask = 2
		collision_layer = 2
	else:
		movement_mode = MovementMode.PHYSICS
		collision_mask = 1
		collision_layer = 1
		_apply_movement_settings()

func set_midi_move_input(move_x: float, move_y: float) -> void:
	midi_move = Vector2(move_x, move_y)

func set_world_movement_settings(new_move_speed: float, new_snap_length: float, new_slope_angle_deg: float) -> void:
	move_speed = new_move_speed
	floor_snap_length_value = new_snap_length
	max_slope_angle_deg = new_slope_angle_deg
	_apply_movement_settings()

func _apply_movement_settings() -> void:
	floor_snap_length = floor_snap_length_value
	floor_max_angle = deg_to_rad(max_slope_angle_deg)

func _physics_process(delta: float) -> void:
	var input_vec := Vector2.ZERO

	if Input.is_key_pressed(KEY_RIGHT):
		input_vec.x += 1.0
	if Input.is_key_pressed(KEY_LEFT):
		input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_UP):
		input_vec.y += 1.0
	if Input.is_key_pressed(KEY_DOWN):
		input_vec.y -= 1.0

	if input_vec.length() == 0.0:
		input_vec = midi_move

	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	var move_dir := Vector3.ZERO

	if is_instance_valid(camera):
		var forward := -camera.global_transform.basis.z
		var right := camera.global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		if forward.length() > 0.0:
			forward = forward.normalized()
		if right.length() > 0.0:
			right = right.normalized()
		move_dir = (right * input_vec.x) + (forward * input_vec.y)
	else:
		move_dir = Vector3(input_vec.x, 0.0, -input_vec.y)

	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	if movement_mode == MovementMode.HOVER:
		_process_hover()
	else:
		_process_physics(delta)

	move_and_slide()

func _process_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		apply_floor_snap()

func _process_hover() -> void:
	var space_state := get_world_3d().direct_space_state
	var ray_origin := global_position + Vector3(0, 5.0, 0)
	var ray_end := global_position + Vector3(0, -100.0, 0)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)

	if result.size() > 0:
		target_y = result["position"].y + hover_height

	var current_y := global_position.y
	velocity.y = (target_y - current_y) * ground_snap_speed

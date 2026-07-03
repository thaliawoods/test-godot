extends CharacterBody3D

var midi_move := Vector2.ZERO

@export var move_speed: float = 4.5
@export var gravity: float = 20.0
@export var floor_snap_length_value: float = 0.2
@export var max_slope_angle_deg: float = 45.0
@export var ground_snap_speed: float = 15.0
@export var hover_height: float = 1.0
@export var mouse_sensitivity: float = 0.002

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

enum MovementMode { PHYSICS, HOVER }
var movement_mode: MovementMode = MovementMode.PHYSICS
var target_y: float = 0.0
var hover_climb_enabled: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_apply_movement_settings()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if head != null:
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_movement_mode(mode: String) -> void:
	if mode == "hover":
		movement_mode = MovementMode.HOVER
		collision_mask = 2
		collision_layer = 2
		hover_climb_enabled = false
	else:
		movement_mode = MovementMode.PHYSICS
		collision_mask = 1
		collision_layer = 1
		hover_climb_enabled = false
		_apply_movement_settings()

func set_hover_climb(enabled: bool) -> void:
	hover_climb_enabled = enabled
	if movement_mode == MovementMode.HOVER:
		collision_mask = 0 if enabled else 2

func set_midi_move_input(move_x: float, move_y: float) -> void:
	midi_move = Vector2(move_x, move_y)

func set_world_movement_settings(new_move_speed: float, new_snap_length: float, new_slope_angle_deg: float, new_hover_height: float = -1.0) -> void:
	move_speed = new_move_speed
	floor_snap_length_value = new_snap_length
	max_slope_angle_deg = new_slope_angle_deg
	if new_hover_height > 0.0:
		hover_height = new_hover_height
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

	var accept_hit: bool = false
	if result.size() > 0:
		var normal: Vector3 = result.get("normal", Vector3.UP)
		if not hover_climb_enabled or normal.y > 0.3:
			accept_hit = true

	if not accept_hit and hover_climb_enabled:
		ray_origin = global_position + Vector3(0, 200.0, 0)
		ray_end = global_position + Vector3(0, -1500.0, 0)
		query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.exclude = [get_rid()]
		result = space_state.intersect_ray(query)
		if result.size() > 0:
			var normal2: Vector3 = result.get("normal", Vector3.UP)
			if normal2.y > 0.3:
				accept_hit = true

	if accept_hit:
		target_y = (result["position"] as Vector3).y + hover_height

	if hover_climb_enabled:
		var ground_y: float = target_y - hover_height
		var flat_vel := Vector3(velocity.x, 0.0, velocity.z)
		if flat_vel.length_squared() > 4.0:
			var forward_dir: Vector3 = flat_vel.normalized()
			var max_top_y: float = -1e9
			var probe_distances: Array = [4.0, 10.0, 18.0]
			for pd: float in probe_distances:
				var probe_pos: Vector3 = global_position + forward_dir * pd
				var probe_query := PhysicsRayQueryParameters3D.create(
					probe_pos + Vector3(0.0, 400.0, 0.0),
					probe_pos + Vector3(0.0, -400.0, 0.0)
				)
				probe_query.exclude = [get_rid()]
				var probe_result := space_state.intersect_ray(probe_query)
				if probe_result.size() > 0:
					var normal: Vector3 = probe_result.get("normal", Vector3.UP)
					if normal.y > 0.2:
						var top_y: float = (probe_result["position"] as Vector3).y
						if top_y > max_top_y:
							max_top_y = top_y
			if max_top_y > -1e8 and max_top_y > ground_y + 3.0:
				var climb_target: float = max_top_y + hover_height + 3.0
				target_y = maxf(target_y, climb_target)

	var current_y := global_position.y
	velocity.y = (target_y - current_y) * ground_snap_speed

func _sample_ground_y(space_state: PhysicsDirectSpaceState3D, pos: Vector3) -> float:
	var ray_origin := pos + Vector3(0.0, 60.0, 0.0)
	var ray_end := pos + Vector3(0.0, -200.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)
	if result.size() > 0:
		var normal: Vector3 = result.get("normal", Vector3.UP)
		if normal.y > 0.3:
			return (result["position"] as Vector3).y
	return pos.y - hover_height

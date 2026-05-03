extends Node

@onready var midi_router = $MidiRouter
@onready var world_manager = $WorldManager
@onready var character: CharacterBody3D = $Character
@onready var photogrammetry_manager = $PhotogrammetryManager
@onready var audio_manager = $AudioManager
@onready var head: Node3D = $Character/Head
@onready var camera: Camera3D = $Character/Head/Camera3D

const DEFAULT_WORLD := "world_01"

const DEFAULT_MOVE_SPEED := 8.0
const DEFAULT_SNAP_LENGTH := 0.6
const DEFAULT_SLOPE_ANGLE := 75.0

func _ready() -> void:
	if midi_router != null:
		midi_router.world_requested.connect(_on_world_requested)
		midi_router.movement_input_changed.connect(_on_movement_input_changed)
		midi_router.fx_value_changed.connect(_on_fx_value_changed)
		midi_router.photogrammetry_event_requested.connect(_on_photo_event_requested)
		midi_router.audio_event_requested.connect(_on_audio_event_requested)

	await _load_and_setup_world(DEFAULT_WORLD)

func _load_and_setup_world(world_id: String) -> void:
	if world_manager == null:
		push_warning("WorldManager introuvable")
		return

	world_manager.load_world(world_id)

	if photogrammetry_manager != null:
		photogrammetry_manager.set_current_world(world_id)

	await get_tree().process_frame
	await get_tree().process_frame

	_apply_world_setup(world_id)

func _reset_camera_and_character() -> void:
	if character == null:
		return

	character.velocity = Vector3.ZERO
	character.rotation = Vector3.ZERO

	if head != null:
		head.position = Vector3(0.0, 1.6, 0.0)
		head.rotation = Vector3.ZERO

	if camera != null:
		camera.top_level = false
		camera.current = true
		camera.position = Vector3.ZERO
		camera.rotation = Vector3.ZERO

func _apply_world_setup(world_id: String) -> void:
	_reset_camera_and_character()

	if world_manager == null:
		push_warning("WorldManager introuvable")
		return

	var current_world: Node3D = world_manager.current_world
	if current_world == null:
		push_warning("Aucun monde chargé")
		return

	var spawn_point: Node = current_world.get_node_or_null("SpawnPoint")

	if spawn_point != null and spawn_point is Marker3D:
		character.global_position = (spawn_point as Marker3D).global_position
	else:
		push_warning("SpawnPoint introuvable dans " + world_id + ", position par défaut utilisée")
		character.global_position = Vector3(0.0, 5.0, 0.0)

	if head != null:
		head.position = Vector3(0.0, 1.6, 0.0)
		head.rotation = Vector3.ZERO

	if camera != null:
		camera.position = Vector3.ZERO
		camera.rotation = Vector3.ZERO

	_apply_world_movement_mode(world_id)

func _apply_world_movement_mode(world_id: String) -> void:
	if character == null:
		return
	match world_id:
		"world_01":
			character.set_movement_mode("physics")
			character.set_world_movement_settings(DEFAULT_MOVE_SPEED, DEFAULT_SNAP_LENGTH, DEFAULT_SLOPE_ANGLE)
		"world_02":
			character.set_movement_mode("hover")
			character.set_world_movement_settings(36.0, 0.8, 75.0)
		"world_03":
			character.set_movement_mode("hover")
			character.set_world_movement_settings(24.0, 0.8, 75.0)
		_:
			character.set_movement_mode("hover")
			character.set_world_movement_settings(8.0, 0.8, 75.0)

func _apply_world_movement_settings(world_id: String) -> void:
	if character == null:
		return
	character.set_world_movement_settings(
		DEFAULT_MOVE_SPEED,
		DEFAULT_SNAP_LENGTH,
		DEFAULT_SLOPE_ANGLE
	)

func _on_world_requested(world_id: String) -> void:
	await _load_and_setup_world(world_id)

func _on_movement_input_changed(move_x: float, move_y: float) -> void:
	if character != null:
		character.set_midi_move_input(move_x, move_y)

func _on_fx_value_changed(fx_name: String, normalized_value: float) -> void:
	pass

func _on_photo_event_requested(event_id: String, velocity: int) -> void:
	if photogrammetry_manager != null:
		photogrammetry_manager.trigger_event(event_id, velocity)

func _on_audio_event_requested(event_id: String, velocity: int) -> void:
	if audio_manager != null:
		audio_manager.trigger_event(event_id, velocity)

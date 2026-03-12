extends Node

@onready var midi_router = $MidiRouter
@onready var world_manager = $WorldManager
@onready var character = $Character

func _ready() -> void:
	print("=== MAIN READY ===")
	print("Main -> midi_router = ", midi_router)
	print("Main -> world_manager = ", world_manager)
	print("Main -> character = ", character)

	midi_router.connect("world_requested", _on_world_requested)
	midi_router.connect("movement_input_changed", _on_movement_input_changed)
	midi_router.connect("fx_value_changed", _on_fx_value_changed)
	midi_router.connect("photogrammetry_event_requested", _on_photo_event_requested)
	midi_router.connect("audio_event_requested", _on_audio_event_requested)

	print("=== MAIN CONNECTED ===")

	world_manager.load_world("world_01")

func _on_world_requested(world_id: String) -> void:
	print("Main received world -> ", world_id)
	world_manager.load_world(world_id)

func _on_movement_input_changed(move_x: float, move_y: float) -> void:
	print("Main received movement -> x=", move_x, " y=", move_y)
	character.set_midi_move_input(move_x, move_y)

func _on_fx_value_changed(fx_name: String, normalized_value: float) -> void:
	print("Main received FX -> ", fx_name, " = ", normalized_value)

func _on_photo_event_requested(event_id: String, velocity: int) -> void:
	print("Main received photo -> ", event_id, " velocity=", velocity)

func _on_audio_event_requested(event_id: String, velocity: int) -> void:
	print("Main received audio -> ", event_id, " velocity=", velocity)

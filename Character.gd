extends CharacterBody3D

var midi_move := Vector2.ZERO

@export var move_speed := 6.0

func _ready() -> void:
	print("=== CHARACTER READY ===")

func set_midi_move_input(move_x: float, move_y: float) -> void:
	midi_move.x = move_x
	midi_move.y = move_y
	print("Character input -> x=", move_x, " y=", move_y)

func _physics_process(delta: float) -> void:
	velocity.x = midi_move.x * move_speed
	velocity.z = -midi_move.y * move_speed
	velocity.y = 0.0

	move_and_slide()

	if midi_move.length() > 0.01:
		print("Character moving -> ", global_position)

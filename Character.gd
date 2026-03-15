extends CharacterBody3D

var midi_move := Vector2.ZERO

@export var move_speed := 6.0
@export var gravity := 18.0

func _ready() -> void:
	print("=== CHARACTER READY ===")

func set_midi_move_input(move_x: float, move_y: float) -> void:
	midi_move = Vector2(move_x, move_y)
	print("Character MIDI input -> x=", move_x, " y=", move_y)

func _physics_process(delta: float) -> void:
	var keyboard_move := Vector2.ZERO

	if Input.is_key_pressed(KEY_D):
		keyboard_move.x += 1.0
	if Input.is_key_pressed(KEY_A):
		keyboard_move.x -= 1.0
	if Input.is_key_pressed(KEY_W):
		keyboard_move.y += 1.0
	if Input.is_key_pressed(KEY_S):
		keyboard_move.y -= 1.0

	var final_move := midi_move

	if keyboard_move.length() > 0.0:
		final_move = keyboard_move.normalized()

	velocity.x = final_move.x * move_speed
	velocity.z = -final_move.y * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if final_move.length() > 0.01:
		print("Character moving -> ", global_position)

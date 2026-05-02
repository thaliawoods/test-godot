extends Node

signal world_requested(world_id: String)
signal photogrammetry_event_requested(event_id: String, velocity: int)
signal audio_event_requested(event_id: String, velocity: int)
signal fx_value_changed(fx_name: String, normalized_value: float)
signal movement_input_changed(move_x: float, move_y: float)

var joy_x: float = 0.0
var joy_y: float = 0.0

# Si tes pads reviennent plus tard en NOTE_ON, on garde aussi cette map.
var world_pad_map := {
	40: "world_01",
	41: "world_02",
	42: "world_03",
	43: "world_04",
	36: "world_05"
}

# Pads actuellement vus comme PROGRAM_CHANGE.
var world_program_map := {
	0: "world_01",
	1: "world_02",
	2: "world_03",
	3: "world_04",
	4: "world_05",
	5: "world_06",
	6: "world_07"
}

var knob_fx_map := {
	70: "visual_distortion",
	71: "visual_saturation",
	72: "visual_blur",
	73: "visual_exposure",
	74: "audio_filter",
	75: "audio_reverb",
	76: "audio_distortion",
	77: "event_density"
}

var white_note_map := {
	48: "photo_event_01",
	50: "photo_event_02",
	52: "photo_event_03",
	53: "photo_event_04",
	55: "photo_event_05",
	57: "photo_event_06",
	59: "photo_event_07",
	60: "photo_event_08",
	62: "photo_event_09",
	64: "photo_event_10",
	65: "photo_event_11",
	67: "photo_event_12",
	69: "photo_event_13",
	71: "photo_event_14",
	72: "photo_event_15"
}

var black_note_map := {
	49: "audio_event_01",
	51: "audio_event_02",
	54: "audio_event_03",
	56: "audio_event_04",
	58: "audio_event_05",
	61: "audio_event_06",
	63: "audio_event_07",
	66: "audio_event_08",
	68: "audio_event_09",
	70: "audio_event_10"
}

func _ready() -> void:
	OS.open_midi_inputs()
	print("MidiRouter prêt")
	print("Périphériques MIDI : ", OS.get_connected_midi_inputs())

var keyboard_world_map := {
	KEY_1: "world_01",
	KEY_2: "world_02",
	KEY_3: "world_03",
	KEY_4: "world_04",
	KEY_5: "world_05",
	KEY_6: "world_06",
	KEY_7: "world_07"
}

var keyboard_photo_map := {
	KEY_A: "photo_event_01",
	KEY_S: "photo_event_02",
	KEY_D: "photo_event_03",
	KEY_F: "photo_event_04",
	KEY_G: "photo_event_05",
	KEY_H: "photo_event_06"
}

var keyboard_audio_map := {
	KEY_Q: "audio_event_01",
	KEY_W: "audio_event_02",
	KEY_E: "audio_event_03",
	KEY_R: "audio_event_04",
	KEY_T: "audio_event_05",
	KEY_Y: "audio_event_06",
	KEY_U: "audio_event_07",
	KEY_I: "audio_event_08"
}

func _input(event: InputEvent) -> void:
	if event is InputEventMIDI:
		print(
			"MIDI DEBUG -> msg=", event.message,
			" pitch=", event.pitch,
			" vel=", event.velocity,
			" cc=", event.controller_number,
			" value=", event.controller_value
		)
		_handle_midi_event(event)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		_handle_keyboard_event(event)

func _handle_keyboard_event(event: InputEventKey) -> void:
	var keycode := event.keycode
	var physical := event.physical_keycode
	# Utiliser physical_keycode (fiable sur tous les layouts clavier)
	var key := physical if physical != KEY_NONE else keycode

	if keyboard_world_map.has(key):
		var world_id: String = keyboard_world_map[key]
		print("World requested (keyboard) -> ", world_id)
		world_requested.emit(world_id)
		return

	if keyboard_photo_map.has(key):
		var photo_event_id: String = keyboard_photo_map[key]
		print("Photogrammetry event (keyboard) -> ", photo_event_id)
		photogrammetry_event_requested.emit(photo_event_id, 100)
		return

	if keyboard_audio_map.has(key):
		var audio_event_id: String = keyboard_audio_map[key]
		print("Audio event (keyboard) -> ", audio_event_id)
		audio_event_requested.emit(audio_event_id, 100)
		return

func _handle_midi_event(event: InputEventMIDI) -> void:
	match event.message:
		9:
			_handle_note_on(event)
		11:
			_handle_control_change(event)
		12:
			_handle_program_change(event)
		14:
			_handle_pitch_bend(event)
		_:
			pass

func _handle_note_on(event: InputEventMIDI) -> void:
	if event.velocity <= 0:
		return

	var pitch := event.pitch

	# Si les pads reviennent un jour en NOTE_ON
	if world_pad_map.has(pitch):
		var world_id: String = world_pad_map[pitch]
		print("World requested (note pad) -> ", world_id)
		world_requested.emit(world_id)
		return

	if white_note_map.has(pitch):
		var photo_event_id: String = white_note_map[pitch]
		print("Photogrammetry event -> ", photo_event_id)
		photogrammetry_event_requested.emit(photo_event_id, event.velocity)
		return

	if black_note_map.has(pitch):
		var audio_event_id: String = black_note_map[pitch]
		print("Audio event -> ", audio_event_id)
		audio_event_requested.emit(audio_event_id, event.velocity)
		return

func _handle_control_change(event: InputEventMIDI) -> void:
	var cc := event.controller_number
	var value := event.controller_value

	# Joystick Y
	if cc == 1:
		joy_y = _normalize_cc_to_signed(value)
		_emit_movement_changed()
		return

	# Potards
	if knob_fx_map.has(cc):
		var fx_name: String = knob_fx_map[cc]
		var normalized := _normalize_cc_to_unit(value)
		print("FX changed -> ", fx_name, " = ", normalized)
		fx_value_changed.emit(fx_name, normalized)
		return

func _handle_program_change(event: InputEventMIDI) -> void:
	var program := event.controller_value

	print(
		"PROGRAM_CHANGE DEBUG -> pitch=", event.pitch,
		" vel=", event.velocity,
		" cc=", event.controller_number,
		" value=", event.controller_value
	)

	if world_program_map.has(program):
		var world_id: String = world_program_map[program]
		print("World requested (program change) -> ", world_id)
		world_requested.emit(world_id)
	else:
		print("Program change reçu mais non mappé -> ", program)

func _handle_pitch_bend(event: InputEventMIDI) -> void:
	joy_x = _normalize_pitch_bend_to_signed(event.pitch)
	_emit_movement_changed()

func _emit_movement_changed() -> void:
	var x := _apply_deadzone(joy_x, 0.08)
	var y := _apply_deadzone(joy_y, 0.08)
	print("MidiRouter emit movement -> x=", x, " y=", y)
	movement_input_changed.emit(x, y)

func _normalize_cc_to_unit(value: int) -> float:
	return clamp(float(value) / 127.0, 0.0, 1.0)

func _normalize_cc_to_signed(value: int) -> float:
	return clamp((float(value) - 63.5) / 63.5, -1.0, 1.0)

func _normalize_pitch_bend_to_signed(value: int) -> float:
	return clamp((float(value) - 8192.0) / 8192.0, -1.0, 1.0)

func _apply_deadzone(v: float, threshold: float) -> float:
	if abs(v) < threshold:
		return 0.0
	return v

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

var _midi_hud: CanvasLayer
var _midi_hud_label: Label
var _midi_hud_panel: PanelContainer
var _midi_last_message: String = ""
var _midi_hud_hide_timer: SceneTreeTimer
var _midi_retry_attempts: int = 0
const _MIDI_RETRY_INTERVAL := 1.5
const _MIDI_MAX_RETRIES := 20

func _ready() -> void:
	_build_midi_hud()
	_try_open_midi_inputs("démarrage")
	_schedule_midi_retry()

func _build_midi_hud() -> void:
	_midi_hud = CanvasLayer.new()
	_midi_hud.layer = 100
	add_child(_midi_hud)

	_midi_hud_panel = PanelContainer.new()
	_midi_hud_panel.anchor_left = 1.0
	_midi_hud_panel.anchor_right = 1.0
	_midi_hud_panel.anchor_top = 0.0
	_midi_hud_panel.anchor_bottom = 0.0
	_midi_hud_panel.offset_left = -460.0
	_midi_hud_panel.offset_top = 24.0
	_midi_hud_panel.offset_right = -24.0
	_midi_hud_panel.offset_bottom = 140.0

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.45)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.12)
	_midi_hud_panel.add_theme_stylebox_override("panel", sb)
	_midi_hud.add_child(_midi_hud_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_midi_hud_panel.add_child(margin)

	_midi_hud_label = Label.new()
	_midi_hud_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_midi_hud_label.add_theme_font_size_override("font_size", 16)
	_midi_hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(_midi_hud_label)

	_refresh_midi_hud("Initialisation MIDI…")

func _refresh_midi_hud(extra: String = "") -> void:
	if _midi_hud_label == null:
		return
	var devices: PackedStringArray = OS.get_connected_midi_inputs()
	var lines: PackedStringArray = []
	if devices.size() == 0:
		lines.append("MIDI : aucun périphérique détecté")
		lines.append("→ branche le clavier puis appuie sur une touche")
	else:
		lines.append("MIDI : %d périphérique(s)" % devices.size())
		for d in devices:
			lines.append("• " + d)
	if _midi_last_message != "":
		lines.append("dernier : " + _midi_last_message)
	if extra != "":
		lines.append(extra)
	_midi_hud_label.text = "\n".join(lines)
	_show_midi_hud(6.0)

func _show_midi_hud(hide_after: float = 6.0) -> void:
	if _midi_hud_panel == null:
		return
	_midi_hud_panel.modulate.a = 1.0
	if _midi_hud_hide_timer != null:
		_midi_hud_hide_timer = null
	_midi_hud_hide_timer = get_tree().create_timer(hide_after)
	_midi_hud_hide_timer.timeout.connect(_fade_midi_hud)

func _fade_midi_hud() -> void:
	if _midi_hud_panel == null:
		return
	var tw := create_tween()
	tw.tween_property(_midi_hud_panel, "modulate:a", 0.15, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _try_open_midi_inputs(reason: String) -> void:
	OS.open_midi_inputs()
	var devices: PackedStringArray = OS.get_connected_midi_inputs()
	print("MidiRouter open_midi_inputs (", reason, ") -> ", devices)
	_refresh_midi_hud("tentative : " + reason)

func _schedule_midi_retry() -> void:
	if _midi_retry_attempts >= _MIDI_MAX_RETRIES:
		return
	_midi_retry_attempts += 1
	var t := get_tree().create_timer(_MIDI_RETRY_INTERVAL)
	t.timeout.connect(_on_midi_retry_tick)

func _on_midi_retry_tick() -> void:
	if OS.get_connected_midi_inputs().size() == 0:
		OS.open_midi_inputs()
		_refresh_midi_hud("scan auto #%d" % _midi_retry_attempts)
		_schedule_midi_retry()
	else:
		_refresh_midi_hud("connecté")

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

var _user_gesture_done := false

func _input(event: InputEvent) -> void:
	if event is InputEventMIDI:
		_midi_last_message = "msg=%d pitch=%d vel=%d cc=%d val=%d" % [
			event.message, event.pitch, event.velocity,
			event.controller_number, event.controller_value
		]
		print("MIDI DEBUG -> ", _midi_last_message)
		_refresh_midi_hud()
		_handle_midi_event(event)
		return

	if (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventMouseButton and event.pressed):
		_on_user_gesture()

	if event is InputEventKey and event.pressed and not event.echo:
		_handle_keyboard_event(event)

func _on_user_gesture() -> void:
	if _user_gesture_done and OS.get_connected_midi_inputs().size() > 0:
		return
	_user_gesture_done = true
	_try_open_midi_inputs("user gesture")

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

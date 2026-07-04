extends Node

signal world_requested(world_id: String)
signal photogrammetry_event_requested(event_id: String, velocity: int)
signal audio_event_requested(event_id: String, velocity: int)
signal fx_value_changed(fx_name: String, normalized_value: float)
signal movement_input_changed(move_x: float, move_y: float)
signal hand_left_cycle_requested()
signal hand_right_cycle_requested()
signal hand_left_flip_x_requested()
signal hand_right_flip_x_requested()
signal hand_left_flip_y_requested()
signal hand_right_flip_y_requested()

var joy_x: float = 0.0
var joy_y: float = 0.0

# Config joystick MPK mini 3 :
#   X (pitch bend) : bi-directionnel, 0=gauche, 8192=centre, 16383=droite
#   Y (CC1)        : uni-directionnel, 0..127 = uniquement forward
# → Recule impossible via le joystick : l'utilisateur tourne la caméra
#   pour changer de direction. Simple deadzone suffit.
const JOY_DEADZONE_X := 0.20
const JOY_DEADZONE_Y := 0.15

# Si tes pads reviennent plus tard en NOTE_ON, on garde aussi cette map.
var world_pad_map: Dictionary = {
	40: "world_01",
	41: "world_02",
	42: "world_03",
	43: "world_04",
	36: "world_05",
	37: "world_06",
	38: "world_07"
}

const HAND_CYCLE_MIDI_NOTE := 39
const HAND_CYCLE_MIDI_PROGRAM := 7

# Pads actuellement vus comme PROGRAM_CHANGE.
var world_program_map: Dictionary = {
	0: "world_01",
	1: "world_02",
	2: "world_03",
	3: "world_04",
	4: "world_05",
	5: "world_06",
	6: "world_07"
}

var knob_fx_map: Dictionary = {
	70: "visual_distortion",
	71: "visual_saturation",
	72: "visual_blur",
	73: "visual_exposure",
	74: "audio_filter",
	75: "audio_reverb",
	76: "camera_pitch",
	77: "camera_yaw"
}

var white_note_map: Dictionary = {
	48: "colonnes",       # C3
	50: "maison",         # D3
	52: "pelouse_1",      # E3
	53: "porte",          # F3
	55: "statue",         # G3
	57: "pelouse_2",      # A3
	59: "lampadaire",     # B3
	60: "alexandre",      # C4
	62: "cheyenne",       # D4
	64: "emma",           # E4
	65: "lucien",         # F4
	67: "mayess",         # G4
	69: "pierre",         # A4
	71: "tagada_1",       # B4
	72: "tagada_2"        # C5
}

var black_note_map: Dictionary = {
	49: "audio_event_01",  # C#3
	51: "audio_event_02",  # D#3
	54: "audio_event_03",  # F#3
	56: "audio_event_04",  # G#3
	58: "audio_event_05",  # A#3
	61: "audio_event_06",  # C#4
	63: "audio_event_07",  # D#4 (ancien audio_event_8.mp3)
	66: "audio_event_08",  # F#4 (Cut final groupe 1)
	68: "audio_event_09",  # G#4 (Cut final groupe 3)
	70: "audio_event_10"   # A#4 (final goupe 2)
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
	sb.bg_color = Color(0, 0, 0, 0.25)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.08)
	_midi_hud_panel.add_theme_stylebox_override("panel", sb)
	_midi_hud.add_child(_midi_hud_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_midi_hud_panel.add_child(margin)

	_midi_hud_label = Label.new()
	_midi_hud_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	var tutorial_font: Font = load("res://assets/fonts/Adelphe-Trouble-FructidorRegular.otf") as Font
	if tutorial_font != null:
		_midi_hud_label.add_theme_font_override("font", tutorial_font)
	_midi_hud_label.add_theme_font_size_override("font_size", 18)
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
	KEY_A: "colonnes",
	KEY_S: "maison",
	KEY_D: "pelouse_1",
	KEY_F: "porte",
	KEY_G: "statue",
	KEY_H: "pelouse_2",
	KEY_J: "lampadaire",
	KEY_K: "alexandre",
	KEY_L: "cheyenne",
	KEY_Z: "emma",
	KEY_X: "lucien",
	KEY_C: "mayess",
	KEY_V: "pierre",
	KEY_B: "tagada_1",
	KEY_N: "tagada_2"
}

var keyboard_audio_map := {
	KEY_Q: "audio_event_01",
	KEY_W: "audio_event_02",
	KEY_E: "audio_event_03",
	KEY_R: "audio_event_04",
	KEY_T: "audio_event_05",
	KEY_Y: "audio_event_06",
	KEY_U: "audio_event_07",
	KEY_I: "audio_event_08",
	KEY_O: "audio_event_09",
	KEY_P: "audio_event_10"
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

	if pitch == HAND_CYCLE_MIDI_NOTE:
		print("Hand cycle requested (note pad 8)")
		hand_right_cycle_requested.emit()
		return

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
		print("Audio event -> ", audio_event_id, " (pitch=", pitch, " vel=", event.velocity, ")")
		audio_event_requested.emit(audio_event_id, event.velocity)
		return

	print("[NOTE_ON UNMAPPED] pitch=", pitch, " vel=", event.velocity)

func _handle_control_change(event: InputEventMIDI) -> void:
	var cc := event.controller_number
	var value := event.controller_value

	# Joystick Y (uni-directionnel : val 0..127 → 0..1, forward uniquement)
	if cc == 1:
		joy_y = _normalize_cc_to_unit(value)
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
	# Godot 4: pour PROGRAM_CHANGE, le numéro de programme est dans event.pitch
	# (pas dans event.controller_value qui reste à 0 pour ce type de message)
	var program := event.pitch
	if program == 0 and event.controller_value > 0:
		program = event.controller_value

	print(
		"PROGRAM_CHANGE DEBUG -> program=", program,
		" (pitch=", event.pitch,
		" vel=", event.velocity,
		" cc=", event.controller_number,
		" value=", event.controller_value, ")"
	)

	if program == HAND_CYCLE_MIDI_PROGRAM:
		print("Hand cycle requested (program pad 8)")
		hand_right_cycle_requested.emit()
		return

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
	# X : bi-directionnel avec deadzone (le pitch bend a un vrai retour à zéro
	# spring-loaded, pas de protection anti-overshoot nécessaire ici).
	var out_x := _apply_deadzone(joy_x, JOY_DEADZONE_X)
	# Y : uni-directionnel (0..1). Deadzone simple : sous le seuil = pas de
	# mouvement, au-dessus = avance. Pas de recul possible via joystick,
	# l'utilisateur oriente la caméra pour changer de direction.
	var out_y: float = 0.0
	if joy_y >= JOY_DEADZONE_Y:
		out_y = joy_y
	print("MidiRouter emit movement -> x=", out_x, " y=", out_y,
		" (raw x=", joy_x, " y=", joy_y, ")")
	movement_input_changed.emit(out_x, out_y)

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

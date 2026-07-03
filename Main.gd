extends Node

@onready var midi_router = $MidiRouter
@onready var world_manager = $WorldManager
@onready var character: CharacterBody3D = $Character
@onready var photogrammetry_manager = $PhotogrammetryManager
@onready var audio_manager = $AudioManager
@onready var head: Node3D = $Character/Head
@onready var camera: Camera3D = $Character/Head/Camera3D
@onready var hands_controller: Node3D = get_node_or_null("Character/Head/Camera3D/Hands") as Node3D
@onready var post_process_mat: ShaderMaterial = ($PostProcess/ColorRect as ColorRect).material as ShaderMaterial
@onready var post_process_layer: CanvasLayer = $PostProcess

const DEFAULT_WORLD := "world_01"

const DEFAULT_MOVE_SPEED := 8.0
const DEFAULT_SNAP_LENGTH := 0.6
const DEFAULT_SLOPE_ANGLE := 75.0

const FX_LERP_SPEED := 30.0
const CAM_YAW_SENS := 6.283185307179586
const CAM_PITCH_SENS := 3.141592653589793
const CAM_PITCH_LIMIT := 1.5533430342749535

var _fx_target: Dictionary = {
	"visual_distortion": 0.0,
	"visual_saturation": 0.5,
	"visual_blur": 0.0,
	"visual_exposure": 0.5,
	"audio_filter": 1.0,
	"audio_reverb": 0.0,
	"camera_pitch": 0.5,
	"camera_yaw": 0.5
}
var _fx_current: Dictionary = _fx_target.duplicate()
var _last_yaw_val: float = 0.5
var _last_pitch_val: float = 0.5
var _yaw_first_seen: bool = false
var _pitch_first_seen: bool = false

func _ready() -> void:
	if midi_router != null:
		midi_router.world_requested.connect(_on_world_requested)
		midi_router.movement_input_changed.connect(_on_movement_input_changed)
		midi_router.fx_value_changed.connect(_on_fx_value_changed)
		midi_router.photogrammetry_event_requested.connect(_on_photo_event_requested)
		midi_router.audio_event_requested.connect(_on_audio_event_requested)
		midi_router.hand_left_cycle_requested.connect(_on_hand_left_cycle)
		midi_router.hand_right_cycle_requested.connect(_on_hand_right_cycle)
		midi_router.hand_left_flip_x_requested.connect(_on_hand_left_flip_x)
		midi_router.hand_right_flip_x_requested.connect(_on_hand_right_flip_x)
		midi_router.hand_left_flip_y_requested.connect(_on_hand_left_flip_y)
		midi_router.hand_right_flip_y_requested.connect(_on_hand_right_flip_y)

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
	_reset_fx_state()

	if world_manager == null:
		push_warning("WorldManager introuvable")
		return

	var current_world: Node3D = world_manager.current_world
	if current_world == null:
		push_warning("Aucun monde chargé")
		return

	var spawn_point: Node = current_world.get_node_or_null("SpawnPoint")

	if spawn_point != null and spawn_point is Marker3D:
		var marker: Marker3D = spawn_point as Marker3D
		character.global_position = marker.global_position
		character.rotation.y = marker.rotation.y
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
			character.set_world_movement_settings(DEFAULT_MOVE_SPEED, DEFAULT_SNAP_LENGTH, DEFAULT_SLOPE_ANGLE, 1.0)
		"world_02":
			character.set_movement_mode("hover")
			character.set_world_movement_settings(36.0, 0.8, 75.0, 1.0)
		"world_03":
			character.set_movement_mode("hover")
			character.set_world_movement_settings(24.0, 0.8, 75.0, 1.0)
		"world_06", "world_07":
			character.set_movement_mode("hover")
			character.set_world_movement_settings(72.0, 1.5, 75.0, 5.0)
			character.set_hover_climb(true)
		_:
			character.set_movement_mode("hover")
			character.set_world_movement_settings(8.0, 0.8, 75.0, 1.0)

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
	if _fx_target.has(fx_name):
		_fx_target[fx_name] = normalized_value
	if fx_name == "camera_yaw" and not _yaw_first_seen:
		_yaw_first_seen = true
		_fx_current["camera_yaw"] = normalized_value
		_last_yaw_val = normalized_value
	elif fx_name == "camera_pitch" and not _pitch_first_seen:
		_pitch_first_seen = true
		_fx_current["camera_pitch"] = normalized_value
		_last_pitch_val = normalized_value

func _on_photo_event_requested(event_id: String, velocity: int) -> void:
	if photogrammetry_manager != null:
		photogrammetry_manager.trigger_event(event_id, velocity)

func _on_audio_event_requested(event_id: String, velocity: int) -> void:
	if audio_manager != null:
		audio_manager.trigger_event(event_id, velocity)

func _on_hand_left_cycle() -> void:
	if hands_controller != null and hands_controller.has_method("cycle_left"):
		hands_controller.cycle_left()

func _on_hand_right_cycle() -> void:
	if hands_controller != null and hands_controller.has_method("cycle_right"):
		hands_controller.cycle_right()

func _on_hand_left_flip_x() -> void:
	if hands_controller != null and hands_controller.has_method("flip_left_x"):
		hands_controller.flip_left_x()

func _on_hand_right_flip_x() -> void:
	if hands_controller != null and hands_controller.has_method("flip_right_x"):
		hands_controller.flip_right_x()

func _on_hand_left_flip_y() -> void:
	if hands_controller != null and hands_controller.has_method("flip_left_y"):
		hands_controller.flip_left_y()

func _on_hand_right_flip_y() -> void:
	if hands_controller != null and hands_controller.has_method("flip_right_y"):
		hands_controller.flip_right_y()

func _reset_fx_state() -> void:
	_fx_target = {
		"visual_distortion": 0.0,
		"visual_saturation": 0.5,
		"visual_blur": 0.0,
		"visual_exposure": 0.5,
		"audio_filter": 1.0,
		"audio_reverb": 0.0,
		"camera_pitch": 0.5,
		"camera_yaw": 0.5
	}
	_fx_current = _fx_target.duplicate()
	_last_yaw_val = 0.5
	_last_pitch_val = 0.5
	_yaw_first_seen = false
	_pitch_first_seen = false

func _process(delta: float) -> void:
	var t: float = min(1.0, FX_LERP_SPEED * delta)
	for k in _fx_target.keys():
		_fx_current[k] = lerp(_fx_current[k], _fx_target[k], t)
	_apply_visual_fx()
	_apply_audio_fx()
	_apply_camera_fx()

func _apply_camera_fx() -> void:
	if character == null:
		return
	var yaw_val: float = _fx_current["camera_yaw"]
	var pitch_val: float = _fx_current["camera_pitch"]
	var yaw_delta: float = yaw_val - _last_yaw_val
	var pitch_delta: float = pitch_val - _last_pitch_val
	_last_yaw_val = yaw_val
	_last_pitch_val = pitch_val
	if yaw_delta != 0.0:
		character.rotate_y(-yaw_delta * CAM_YAW_SENS)
	if pitch_delta != 0.0 and head != null:
		head.rotate_x(-pitch_delta * CAM_PITCH_SENS)
		head.rotation.x = clamp(head.rotation.x, -CAM_PITCH_LIMIT, CAM_PITCH_LIMIT)

func _apply_visual_fx() -> void:
	if post_process_mat == null:
		return
	var distortion: float = _fx_current["visual_distortion"]
	var saturation: float = _fx_current["visual_saturation"]
	var blur: float = _fx_current["visual_blur"]
	var exposure: float = _fx_current["visual_exposure"]
	var any_active: bool = (
		distortion > 0.005
		or blur > 0.005
		or abs(saturation - 0.5) > 0.005
		or abs(exposure - 0.5) > 0.005
	)
	if post_process_layer != null:
		post_process_layer.visible = any_active
	if not any_active:
		return
	var brightness: float
	if exposure < 0.5:
		brightness = lerpf(0.3, 1.0, exposure * 2.0)
	else:
		brightness = lerpf(1.0, 2.0, (exposure - 0.5) * 2.0)
	post_process_mat.set_shader_parameter("distortion", distortion)
	post_process_mat.set_shader_parameter("saturation", saturation)
	post_process_mat.set_shader_parameter("brightness", brightness)
	post_process_mat.set_shader_parameter("blur", blur)
	post_process_mat.set_shader_parameter("fog_amount", blur * 0.6)

func _apply_audio_fx() -> void:
	var bus: int = AudioServer.get_bus_index("Effects")
	if bus < 0:
		return
	# Le knob 74 (audio_filter) contrôle filter cutoff + résonance + drive
	# de la distortion. Knob à 1.0 = son clair. Knob à 0.0 = filtre fermé,
	# résonance auto-oscillante et overdrive puissant.
	var f_val: float = _fx_current["audio_filter"]
	var filter: AudioEffectFilter = AudioServer.get_bus_effect(bus, 0) as AudioEffectFilter
	if filter != null:
		filter.cutoff_hz = lerpf(60.0, 20000.0, f_val * f_val)  # courbe expo, ferme plus vite
		filter.resonance = lerpf(4.0, 0.5, f_val)               # 4.0 = auto-oscillation
	var distortion: AudioEffectDistortion = AudioServer.get_bus_effect(bus, 1) as AudioEffectDistortion
	if distortion != null:
		# Distortion s'active quand knob passe sous 0.5, très forte sous 0.2
		var drive_amt: float = clampf((0.5 - f_val) * 2.0, 0.0, 1.0)
		distortion.drive = drive_amt * 0.9
		distortion.pre_gain = drive_amt * 12.0   # +12 dB de gain d'entrée
		distortion.post_gain = -drive_amt * 6.0  # -6 dB pour compenser
	# Le knob 75 (audio_reverb) contrôle chorus + reverb ensemble.
	# Knob à 0.0 = sec. Knob à 1.0 = chorus dense + reverb caverneuse.
	var r_val: float = _fx_current["audio_reverb"]
	var chorus: AudioEffectChorus = AudioServer.get_bus_effect(bus, 2) as AudioEffectChorus
	if chorus != null:
		chorus.wet = r_val * 0.6   # chorus max 60% wet pour rester musical
	var reverb: AudioEffectReverb = AudioServer.get_bus_effect(bus, 3) as AudioEffectReverb
	if reverb != null:
		reverb.wet = r_val * 0.9   # reverb max 90% wet
		reverb.damping = lerpf(0.3, 0.6, r_val)  # amortit plus si beaucoup de reverb

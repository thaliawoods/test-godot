extends Node3D

const HAND_COUNT := 14
const HAND_PATH_TEMPLATE := "res://assets/hands_v2/hand_%02d.fbx"
const HAND_TARGET_SIZE := 0.302
const SAVE_FILE_PATH := "user://hands_calibration.json"
const MOUNT_LEFT_BASE_OVERRIDE := Vector3(-0.28, -0.35, -0.60)
const MOUNT_RIGHT_BASE_OVERRIDE := Vector3(0.28, -0.35, -0.60)
const SWAP_LR_DEFAULT: bool = false

const MESH_INDIVIDUAL_SWAP: Dictionary = {
	2: true,
	7: true,
	8: false,
	9: false,
	12: true,
}

const MESH_FLIP_STATES: Dictionary = {
	1: {"flip_x": true, "flip_y": false},
	9: {"flip_x": true, "flip_y": false},
	11: {"flip_x": true, "flip_y": false},
}

const HAND_SKIP_INDICES: Array = [6]

const MESH_ROTATION_OFFSETS: Dictionary = {
	0: Vector3(-180, 0, 0),
	2: Vector3(-180, 0, 0),
	3: Vector3(-180, 0, 0),
	4: Vector3(0, -180, -180),
	5: Vector3(0, -180, 0),
	7: Vector3(0, 0, -180),
	8: Vector3(90, -90, -90),
	9: Vector3(-90, 0, -180),
	10: Vector3(-180, 0, 0),
	12: Vector3(0, 0, -180),
	13: Vector3(0, -180, 0),
}

@onready var hand_left: MeshInstance3D = $HandLeftMount/HandLeft
@onready var hand_right: MeshInstance3D = $HandRightMount/HandRight
@onready var hand_left_mount: Node3D = $HandLeftMount
@onready var hand_right_mount: Node3D = $HandRightMount

var _hand_meshes: Array = []
var _pair_index: int = 0
var _flip_x: bool = false
var _flip_y: bool = false
var _mesh_rotations: Dictionary = {}

var _mount_left_base: Vector3 = Vector3(-0.3, -0.3, -0.55)
var _mount_right_base: Vector3 = Vector3(0.3, -0.3, -0.55)
var _pos_z_offset: float = 0.0
var _spread_offset: float = 0.0
var _scale_multiplier: float = 1.0
var _swap_lr: bool = SWAP_LR_DEFAULT
var _mesh_swap_runtime: Dictionary = {}
var _mesh_flip_runtime: Dictionary = {}

const POS_STEP: float = 0.02
const SPREAD_STEP: float = 0.02
const SCALE_STEP: float = 0.05

func _ready() -> void:
	_load_hand_meshes()
	if hand_left_mount != null:
		hand_left_mount.position = MOUNT_LEFT_BASE_OVERRIDE
		_mount_left_base = MOUNT_LEFT_BASE_OVERRIDE
	if hand_right_mount != null:
		hand_right_mount.position = MOUNT_RIGHT_BASE_OVERRIDE
		_mount_right_base = MOUNT_RIGHT_BASE_OVERRIDE
	_randomize_pair()
	_load_mesh_flip_state()
	_apply_meshes()
	_apply_mount_rotations()
	_apply_mount_positions()
	_update_hud_label()

func _load_calibration_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SAVE] Aucun fichier de calibration disque — utilisation des défauts hardcodés")
		return
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return
	var content: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	if data.has("mount_left"):
		var ml = data["mount_left"]
		_mount_left_base = Vector3(float(ml.get("x", _mount_left_base.x)), float(ml.get("y", _mount_left_base.y)), float(ml.get("z", _mount_left_base.z)))
		if hand_left_mount != null:
			hand_left_mount.position = _mount_left_base
	if data.has("mount_right"):
		var mr = data["mount_right"]
		_mount_right_base = Vector3(float(mr.get("x", _mount_right_base.x)), float(mr.get("y", _mount_right_base.y)), float(mr.get("z", _mount_right_base.z)))
		if hand_right_mount != null:
			hand_right_mount.position = _mount_right_base
	_pos_z_offset = float(data.get("pos_z_offset", 0.0))
	_spread_offset = float(data.get("spread_offset", 0.0))
	_scale_multiplier = float(data.get("scale_multiplier", 1.0))
	if data.has("target_size"):
		var saved_size: float = float(data["target_size"])
		if HAND_TARGET_SIZE > 0.001:
			_scale_multiplier = saved_size / HAND_TARGET_SIZE
	if data.has("rotations") and data["rotations"] is Dictionary:
		for k in data["rotations"]:
			var r_dict = data["rotations"][k]
			_mesh_rotations[int(k)] = Vector3(float(r_dict.get("x", 0.0)), float(r_dict.get("y", 0.0)), float(r_dict.get("z", 0.0)))
	if data.has("swaps") and data["swaps"] is Dictionary:
		for k in data["swaps"]:
			_mesh_swap_runtime[int(k)] = bool(data["swaps"][k])
	if data.has("flips") and data["flips"] is Dictionary:
		for k in data["flips"]:
			var f_dict = data["flips"][k]
			_mesh_flip_runtime[int(k)] = {"flip_x": bool(f_dict.get("flip_x", false)), "flip_y": bool(f_dict.get("flip_y", false))}
	print("[SAVE] Calibration chargée depuis ", SAVE_FILE_PATH)

func _save_calibration_to_disk() -> void:
	var data := {
		"mount_left": {"x": _mount_left_base.x, "y": _mount_left_base.y, "z": _mount_left_base.z},
		"mount_right": {"x": _mount_right_base.x, "y": _mount_right_base.y, "z": _mount_right_base.z},
		"pos_z_offset": _pos_z_offset,
		"spread_offset": _spread_offset,
		"scale_multiplier": _scale_multiplier,
		"target_size": HAND_TARGET_SIZE * _scale_multiplier,
		"rotations": {},
		"swaps": {},
		"flips": {},
	}
	for i in _mesh_rotations:
		var r: Vector3 = _mesh_rotations[i]
		data["rotations"][str(i)] = {"x": r.x, "y": r.y, "z": r.z}
	for i in range(_hand_meshes.size()):
		if _mesh_rotations.has(i):
			continue
		if MESH_ROTATION_OFFSETS.has(i):
			var r: Vector3 = MESH_ROTATION_OFFSETS[i]
			data["rotations"][str(i)] = {"x": r.x, "y": r.y, "z": r.z}
	for i in _mesh_swap_runtime:
		data["swaps"][str(i)] = _mesh_swap_runtime[i]
	for i in range(_hand_meshes.size()):
		if _mesh_swap_runtime.has(i):
			continue
		if MESH_INDIVIDUAL_SWAP.has(i):
			data["swaps"][str(i)] = MESH_INDIVIDUAL_SWAP[i]
	for i in _mesh_flip_runtime:
		var f: Dictionary = _mesh_flip_runtime[i]
		data["flips"][str(i)] = {"flip_x": f.get("flip_x", false), "flip_y": f.get("flip_y", false)}
	for i in range(_hand_meshes.size()):
		if _mesh_flip_runtime.has(i):
			continue
		if MESH_FLIP_STATES.has(i):
			var f: Dictionary = MESH_FLIP_STATES[i]
			data["flips"][str(i)] = {"flip_x": f.get("flip_x", false), "flip_y": f.get("flip_y", false)}
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		file.close()
		print("[SAVE] Calibration sauvegardée sur disque : ", SAVE_FILE_PATH)
	else:
		print("[SAVE] ERREUR d'ouverture du fichier de sauvegarde")
	print("HandsController: loaded ", _hand_meshes.size(), " hand meshes, pair=", _pair_index)
	print("[CALIB rot]  O/P yaw ±90 | W/X pitch ±90 | C/V roll ±90 | Retour arrière reset rot")
	print("[CALIB pos]  8/9 avancer/reculer | 0/L rapprocher/écarter | . / agrandir/réduire | - swap G/D | ; mirror rot | Entrée dump")

func _update_hud_label() -> void:
	var label: Label = get_node_or_null("/root/Main/KeyboardHUD/Panel/MarginContainer/VBox/CurrentHand") as Label
	if label == null:
		return
	var rot: Vector3 = _get_current_rotation()
	var status: String = "calibrée" if rot != Vector3.ZERO else "défaut"
	label.text = "main : hand_%02d.fbx  (index %d)  [%s]" % [_pair_index + 1, _pair_index, status]

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var kb: InputEventKey = event as InputEventKey
	if not kb.pressed or kb.echo:
		return
	var current: Vector3 = _get_current_rotation()
	var changed: bool = false
	if _key_matches(kb, KEY_O):
		current.y -= 90.0
		changed = true
	elif _key_matches(kb, KEY_P):
		current.y += 90.0
		changed = true
	elif _key_matches(kb, KEY_W):
		current.x -= 90.0
		changed = true
	elif _key_matches(kb, KEY_X):
		current.x += 90.0
		changed = true
	elif _key_matches(kb, KEY_C):
		current.z -= 90.0
		changed = true
	elif _key_matches(kb, KEY_V):
		current.z += 90.0
		changed = true
	elif _key_matches(kb, KEY_ENTER):
		_dump_calibration()
		return
	elif _key_matches(kb, KEY_BACKSPACE):
		current = Vector3.ZERO
		changed = true
	elif _key_matches(kb, KEY_8):
		_pos_z_offset -= POS_STEP
		_apply_mount_positions()
		_print_layout()
		return
	elif _key_matches(kb, KEY_9):
		_pos_z_offset += POS_STEP
		_apply_mount_positions()
		_print_layout()
		return
	elif _key_matches(kb, KEY_0):
		_spread_offset -= SPREAD_STEP
		_apply_mount_positions()
		_print_layout()
		return
	elif _key_matches(kb, KEY_L):
		_spread_offset += SPREAD_STEP
		_apply_mount_positions()
		_print_layout()
		return
	elif _key_matches(kb, KEY_PERIOD):
		_scale_multiplier = maxf(0.1, _scale_multiplier - SCALE_STEP)
		_apply_meshes()
		_print_layout()
		return
	elif _key_matches(kb, KEY_SLASH):
		_scale_multiplier += SCALE_STEP
		_apply_meshes()
		_print_layout()
		return
	elif _key_matches(kb, KEY_MINUS):
		var current_swap: bool = _swap_lr
		if _mesh_swap_runtime.has(_pair_index):
			current_swap = _mesh_swap_runtime[_pair_index]
		elif MESH_INDIVIDUAL_SWAP.has(_pair_index):
			current_swap = MESH_INDIVIDUAL_SWAP[_pair_index]
		_mesh_swap_runtime[_pair_index] = not current_swap
		_apply_meshes()
		_update_hud_label()
		print("[CALIB swap] hand_%02d swap=%s" % [_pair_index + 1, str(_mesh_swap_runtime[_pair_index])])
		return
	elif _key_matches(kb, KEY_SEMICOLON):
		current.y = wrapf(-current.y, -180.0, 180.0)
		current.z = wrapf(-current.z, -180.0, 180.0)
		_mesh_rotations[_pair_index] = current
		_apply_mount_rotations()
		_update_hud_label()
		print("[CALIB mirror] hand_%02d rot=(%.0f, %.0f, %.0f) [Y+Z inversés]" % [_pair_index + 1, current.x, current.y, current.z])
		return
	else:
		return
	if changed:
		current.x = wrapf(current.x, -180.0, 180.0)
		current.y = wrapf(current.y, -180.0, 180.0)
		current.z = wrapf(current.z, -180.0, 180.0)
		_mesh_rotations[_pair_index] = current
		_apply_mount_rotations()
		print("[CALIB] hand_%02d rot=(%.0f, %.0f, %.0f)" % [_pair_index + 1, current.x, current.y, current.z])

func _key_matches(kb: InputEventKey, key: Key) -> bool:
	return kb.keycode == key or kb.physical_keycode == key

func _get_current_rotation() -> Vector3:
	if _mesh_rotations.has(_pair_index):
		return _mesh_rotations[_pair_index]
	if MESH_ROTATION_OFFSETS.has(_pair_index):
		return MESH_ROTATION_OFFSETS[_pair_index]
	return Vector3.ZERO

func _dump_calibration() -> void:
	_save_calibration_to_disk()
	print("=== CALIBRATION DUMP ===")
	print("layout: z_offset=%.3f spread=%.3f scale_mult=%.3f swap_lr=%s" % [_pos_z_offset, _spread_offset, _scale_multiplier, str(_swap_lr)])
	print("individual swaps:")
	for i in range(_hand_meshes.size()):
		if _mesh_swap_runtime.has(i):
			print("\t%d: %s," % [i, str(_mesh_swap_runtime[i])])
		elif MESH_INDIVIDUAL_SWAP.has(i):
			print("\t%d: %s," % [i, str(MESH_INDIVIDUAL_SWAP[i])])
	print("flip states:")
	for i in range(_hand_meshes.size()):
		var flip_data: Dictionary = {}
		if _mesh_flip_runtime.has(i):
			flip_data = _mesh_flip_runtime[i]
		elif MESH_FLIP_STATES.has(i):
			flip_data = MESH_FLIP_STATES[i]
		if not flip_data.is_empty():
			print("\t%d: {\"flip_x\": %s, \"flip_y\": %s}," % [i, str(flip_data.get("flip_x", false)), str(flip_data.get("flip_y", false))])
	print("mount_left_final=%s" % [_mount_left_base + Vector3(-_spread_offset, 0.0, _pos_z_offset)])
	print("mount_right_final=%s" % [_mount_right_base + Vector3(_spread_offset, 0.0, _pos_z_offset)])
	print("effective_size=%.3f m" % [HAND_TARGET_SIZE * _scale_multiplier])
	print("rotations:")
	for i in range(_hand_meshes.size()):
		var rot: Vector3 = Vector3.ZERO
		if _mesh_rotations.has(i):
			rot = _mesh_rotations[i]
		elif MESH_ROTATION_OFFSETS.has(i):
			rot = MESH_ROTATION_OFFSETS[i]
		print("\t%d: Vector3(%.0f, %.0f, %.0f)," % [i, rot.x, rot.y, rot.z])
	print("========================")

func _load_hand_meshes() -> void:
	for i in range(1, HAND_COUNT + 1):
		var path: String = HAND_PATH_TEMPLATE % i
		if not ResourceLoader.exists(path):
			continue
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		var mesh_instance: MeshInstance3D = _find_first_mesh(instance)
		if mesh_instance != null and mesh_instance.mesh != null:
			_hand_meshes.append(mesh_instance.mesh)
		instance.queue_free()

func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child: Node in node.get_children():
		var found: MeshInstance3D = _find_first_mesh(child)
		if found != null:
			return found
	return null

func _randomize_pair() -> void:
	if _hand_meshes.size() < 1:
		return
	_pair_index = randi() % _hand_meshes.size()
	if _pair_index in HAND_SKIP_INDICES:
		_pair_index = _next_valid_index(_pair_index, 1)

func _next_valid_index(from: int, direction: int) -> int:
	if _hand_meshes.is_empty():
		return 0
	var idx: int = from
	for _i in range(_hand_meshes.size()):
		idx = (idx + direction + _hand_meshes.size()) % _hand_meshes.size()
		if not (idx in HAND_SKIP_INDICES):
			return idx
	return from

func _apply_meshes() -> void:
	if _hand_meshes.is_empty():
		return
	var mesh: Mesh = _hand_meshes[_pair_index]
	var effective_swap: bool = _swap_lr
	if _mesh_swap_runtime.has(_pair_index):
		effective_swap = _mesh_swap_runtime[_pair_index]
	elif MESH_INDIVIDUAL_SWAP.has(_pair_index):
		effective_swap = MESH_INDIVIDUAL_SWAP[_pair_index]
	var left_sign: float = -1.0 if effective_swap else 1.0
	var right_sign: float = 1.0 if effective_swap else -1.0
	if hand_left != null:
		hand_left.mesh = mesh
		_normalize_size(hand_left, left_sign)
		_disable_culling(hand_left)
	if hand_right != null:
		hand_right.mesh = mesh
		_normalize_size(hand_right, right_sign)
		_disable_culling(hand_right)

func _normalize_size(mi: MeshInstance3D, x_sign: float) -> void:
	if mi.mesh == null:
		return
	var aabb: AABB = mi.mesh.get_aabb()
	var max_extent: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	if max_extent < 0.00001:
		return
	var factor: float = (HAND_TARGET_SIZE * _scale_multiplier) / max_extent
	mi.scale = Vector3(factor * x_sign, factor, factor)
	var center: Vector3 = aabb.get_center()
	mi.position = Vector3(-center.x * factor * x_sign, -center.y * factor, -center.z * factor)

func _apply_mount_positions() -> void:
	if hand_left_mount != null:
		var pl: Vector3 = _mount_left_base
		pl.x -= _spread_offset
		pl.z += _pos_z_offset
		hand_left_mount.position = pl
	if hand_right_mount != null:
		var pr: Vector3 = _mount_right_base
		pr.x += _spread_offset
		pr.z += _pos_z_offset
		hand_right_mount.position = pr

func _print_layout() -> void:
	print("[CALIB layout] z=%.2f spread=%.2f scale=%.2f" % [_pos_z_offset, _spread_offset, _scale_multiplier])

func _disable_culling(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for surface_idx: int in range(mi.mesh.get_surface_count()):
		var mat: Material = mi.mesh.surface_get_material(surface_idx)
		if mat is StandardMaterial3D:
			var new_mat: StandardMaterial3D = (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			new_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			new_mat.no_depth_test = false
			new_mat.emission_enabled = true
			new_mat.emission = Color(0.95, 0.9, 0.85)
			new_mat.emission_energy_multiplier = 0.45
			mi.set_surface_override_material(surface_idx, new_mat)
		else:
			var fallback: StandardMaterial3D = StandardMaterial3D.new()
			fallback.albedo_color = Color(0.95, 0.75, 0.65)
			fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
			fallback.emission_enabled = true
			fallback.emission = Color(0.9, 0.75, 0.65)
			fallback.emission_energy_multiplier = 0.45
			mi.set_surface_override_material(surface_idx, fallback)

func cycle_left() -> void:
	if _hand_meshes.is_empty():
		return
	_pair_index = _next_valid_index(_pair_index, 1)
	_load_mesh_flip_state()
	_apply_meshes()
	_apply_mount_rotations()
	_update_hud_label()
	print("[HAND] main courante : hand_%02d.fbx (index %d)" % [_pair_index + 1, _pair_index])

func cycle_right() -> void:
	if _hand_meshes.is_empty():
		return
	_pair_index = _next_valid_index(_pair_index, -1)
	_load_mesh_flip_state()
	_apply_meshes()
	_apply_mount_rotations()
	_update_hud_label()
	print("[HAND] main courante : hand_%02d.fbx (index %d)" % [_pair_index + 1, _pair_index])

func _load_mesh_flip_state() -> void:
	var flip_data: Dictionary = {}
	if _mesh_flip_runtime.has(_pair_index):
		flip_data = _mesh_flip_runtime[_pair_index]
	elif MESH_FLIP_STATES.has(_pair_index):
		flip_data = MESH_FLIP_STATES[_pair_index]
	_flip_x = flip_data.get("flip_x", false)
	_flip_y = flip_data.get("flip_y", false)

func _save_mesh_flip_state() -> void:
	_mesh_flip_runtime[_pair_index] = {"flip_x": _flip_x, "flip_y": _flip_y}

func flip_left_x() -> void:
	_flip_x = not _flip_x
	_save_mesh_flip_state()
	_apply_mount_rotations()
	print("[HAND] hand_%02d flip_x=%s flip_y=%s" % [_pair_index + 1, str(_flip_x), str(_flip_y)])

func flip_right_x() -> void:
	_flip_x = not _flip_x
	_save_mesh_flip_state()
	_apply_mount_rotations()
	print("[HAND] hand_%02d flip_x=%s flip_y=%s" % [_pair_index + 1, str(_flip_x), str(_flip_y)])

func flip_left_y() -> void:
	_flip_y = not _flip_y
	_save_mesh_flip_state()
	_apply_mount_rotations()
	print("[HAND] hand_%02d flip_x=%s flip_y=%s" % [_pair_index + 1, str(_flip_x), str(_flip_y)])

func flip_right_y() -> void:
	_flip_y = not _flip_y
	_save_mesh_flip_state()
	_apply_mount_rotations()
	print("[HAND] hand_%02d flip_x=%s flip_y=%s" % [_pair_index + 1, str(_flip_x), str(_flip_y)])

func _apply_mount_rotations() -> void:
	var basis_default: Basis = Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))
	var final_basis: Basis = basis_default
	if _flip_x:
		final_basis = final_basis.rotated(final_basis.x.normalized(), PI)
	if _flip_y:
		final_basis = final_basis.rotated(final_basis.y.normalized(), PI)
	var offset_deg: Vector3 = _get_current_rotation()
	if offset_deg != Vector3.ZERO:
		var offset_basis: Basis = Basis.from_euler(Vector3(deg_to_rad(offset_deg.x), deg_to_rad(offset_deg.y), deg_to_rad(offset_deg.z)))
		final_basis = final_basis * offset_basis
	if hand_left_mount != null:
		hand_left_mount.transform.basis = final_basis
	if hand_right_mount != null:
		hand_right_mount.transform.basis = final_basis

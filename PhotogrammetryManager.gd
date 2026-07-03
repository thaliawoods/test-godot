extends Node3D

var current_world_id: String = "world_01"
var spawned_nodes: Array[Node3D] = []

# Taille cible des objets en mètres et distance devant le joueur
const TARGET_SIZE := 8.0
const SPAWN_DISTANCE := 12.0
const MIN_HEIGHT := 6.0

var photo_scene_map := {
	"world_01": {
		"colonnes":   "res://photogrammetry/photo_event_01.tscn",
		"maison":     "res://photogrammetry/photo_event_02.tscn",
		"pelouse_1":  "res://photogrammetry/photo_event_03.tscn",
		"porte":      "res://photogrammetry/photo_event_04.tscn",
		"statue":     "res://photogrammetry/photo_event_05.tscn",
		"pelouse_2":  "res://photogrammetry/photo_event_06.tscn",
		"lampadaire": "res://photogrammetry/photo_event_07.tscn",
		"alexandre":  "res://photogrammetry/photo_event_08.tscn",
		"cheyenne":   "res://photogrammetry/photo_event_09.tscn",
		"emma":       "res://photogrammetry/photo_event_10.tscn",
		"lucien":     "res://photogrammetry/photo_event_11.tscn",
		"mayess":     "res://photogrammetry/photo_event_12.tscn",
		"pierre":     "res://photogrammetry/photo_event_13.tscn",
		"tagada_1":   "res://photogrammetry/photo_event_14.tscn",
		"tagada_2":   "res://photogrammetry/photo_event_15.tscn",
		"tagada_3":   "res://photogrammetry/photo_event_16.tscn"
	},
	"world_02": {
		"colonnes":   "res://photogrammetry/photo_event_01.tscn",
		"maison":     "res://photogrammetry/photo_event_02.tscn",
		"pelouse_1":  "res://photogrammetry/photo_event_03.tscn",
		"porte":      "res://photogrammetry/photo_event_04.tscn",
		"statue":     "res://photogrammetry/photo_event_05.tscn",
		"pelouse_2":  "res://photogrammetry/photo_event_06.tscn",
		"lampadaire": "res://photogrammetry/photo_event_07.tscn",
		"alexandre":  "res://photogrammetry/photo_event_08.tscn",
		"cheyenne":   "res://photogrammetry/photo_event_09.tscn",
		"emma":       "res://photogrammetry/photo_event_10.tscn",
		"lucien":     "res://photogrammetry/photo_event_11.tscn",
		"mayess":     "res://photogrammetry/photo_event_12.tscn",
		"pierre":     "res://photogrammetry/photo_event_13.tscn",
		"tagada_1":   "res://photogrammetry/photo_event_14.tscn",
		"tagada_2":   "res://photogrammetry/photo_event_15.tscn",
		"tagada_3":   "res://photogrammetry/photo_event_16.tscn"
	},
	"world_03": {
		"colonnes":   "res://photogrammetry/photo_event_01.tscn",
		"maison":     "res://photogrammetry/photo_event_02.tscn",
		"pelouse_1":  "res://photogrammetry/photo_event_03.tscn",
		"porte":      "res://photogrammetry/photo_event_04.tscn",
		"statue":     "res://photogrammetry/photo_event_05.tscn",
		"pelouse_2":  "res://photogrammetry/photo_event_06.tscn",
		"lampadaire": "res://photogrammetry/photo_event_07.tscn",
		"alexandre":  "res://photogrammetry/photo_event_08.tscn",
		"cheyenne":   "res://photogrammetry/photo_event_09.tscn",
		"emma":       "res://photogrammetry/photo_event_10.tscn",
		"lucien":     "res://photogrammetry/photo_event_11.tscn",
		"mayess":     "res://photogrammetry/photo_event_12.tscn",
		"pierre":     "res://photogrammetry/photo_event_13.tscn",
		"tagada_1":   "res://photogrammetry/photo_event_14.tscn",
		"tagada_2":   "res://photogrammetry/photo_event_15.tscn",
		"tagada_3":   "res://photogrammetry/photo_event_16.tscn"
	},
	"world_04": {
		"colonnes":   "res://photogrammetry/photo_event_01.tscn",
		"maison":     "res://photogrammetry/photo_event_02.tscn",
		"pelouse_1":  "res://photogrammetry/photo_event_03.tscn",
		"porte":      "res://photogrammetry/photo_event_04.tscn",
		"statue":     "res://photogrammetry/photo_event_05.tscn",
		"pelouse_2":  "res://photogrammetry/photo_event_06.tscn",
		"lampadaire": "res://photogrammetry/photo_event_07.tscn",
		"alexandre":  "res://photogrammetry/photo_event_08.tscn",
		"cheyenne":   "res://photogrammetry/photo_event_09.tscn",
		"emma":       "res://photogrammetry/photo_event_10.tscn",
		"lucien":     "res://photogrammetry/photo_event_11.tscn",
		"mayess":     "res://photogrammetry/photo_event_12.tscn",
		"pierre":     "res://photogrammetry/photo_event_13.tscn",
		"tagada_1":   "res://photogrammetry/photo_event_14.tscn",
		"tagada_2":   "res://photogrammetry/photo_event_15.tscn",
		"tagada_3":   "res://photogrammetry/photo_event_16.tscn"
	},
	"world_05": {
		"colonnes":   "res://photogrammetry/photo_event_01.tscn",
		"maison":     "res://photogrammetry/photo_event_02.tscn",
		"pelouse_1":  "res://photogrammetry/photo_event_03.tscn",
		"porte":      "res://photogrammetry/photo_event_04.tscn",
		"statue":     "res://photogrammetry/photo_event_05.tscn",
		"pelouse_2":  "res://photogrammetry/photo_event_06.tscn",
		"lampadaire": "res://photogrammetry/photo_event_07.tscn",
		"alexandre":  "res://photogrammetry/photo_event_08.tscn",
		"cheyenne":   "res://photogrammetry/photo_event_09.tscn",
		"emma":       "res://photogrammetry/photo_event_10.tscn",
		"lucien":     "res://photogrammetry/photo_event_11.tscn",
		"mayess":     "res://photogrammetry/photo_event_12.tscn",
		"pierre":     "res://photogrammetry/photo_event_13.tscn",
		"tagada_1":   "res://photogrammetry/photo_event_14.tscn",
		"tagada_2":   "res://photogrammetry/photo_event_15.tscn",
		"tagada_3":   "res://photogrammetry/photo_event_16.tscn"
	},
	"world_06": {
		"colonnes":   "res://photogrammetry/photo_event_01.tscn",
		"maison":     "res://photogrammetry/photo_event_02.tscn",
		"pelouse_1":  "res://photogrammetry/photo_event_03.tscn",
		"porte":      "res://photogrammetry/photo_event_04.tscn",
		"statue":     "res://photogrammetry/photo_event_05.tscn",
		"pelouse_2":  "res://photogrammetry/photo_event_06.tscn",
		"lampadaire": "res://photogrammetry/photo_event_07.tscn",
		"alexandre":  "res://photogrammetry/photo_event_08.tscn",
		"cheyenne":   "res://photogrammetry/photo_event_09.tscn",
		"emma":       "res://photogrammetry/photo_event_10.tscn",
		"lucien":     "res://photogrammetry/photo_event_11.tscn",
		"mayess":     "res://photogrammetry/photo_event_12.tscn",
		"pierre":     "res://photogrammetry/photo_event_13.tscn",
		"tagada_1":   "res://photogrammetry/photo_event_14.tscn",
		"tagada_2":   "res://photogrammetry/photo_event_15.tscn",
		"tagada_3":   "res://photogrammetry/photo_event_16.tscn"
	},
	"world_07": {
		"colonnes":   "res://photogrammetry/photo_event_01.tscn",
		"maison":     "res://photogrammetry/photo_event_02.tscn",
		"pelouse_1":  "res://photogrammetry/photo_event_03.tscn",
		"porte":      "res://photogrammetry/photo_event_04.tscn",
		"statue":     "res://photogrammetry/photo_event_05.tscn",
		"pelouse_2":  "res://photogrammetry/photo_event_06.tscn",
		"lampadaire": "res://photogrammetry/photo_event_07.tscn",
		"alexandre":  "res://photogrammetry/photo_event_08.tscn",
		"cheyenne":   "res://photogrammetry/photo_event_09.tscn",
		"emma":       "res://photogrammetry/photo_event_10.tscn",
		"lucien":     "res://photogrammetry/photo_event_11.tscn",
		"mayess":     "res://photogrammetry/photo_event_12.tscn",
		"pierre":     "res://photogrammetry/photo_event_13.tscn",
		"tagada_1":   "res://photogrammetry/photo_event_14.tscn",
		"tagada_2":   "res://photogrammetry/photo_event_15.tscn",
		"tagada_3":   "res://photogrammetry/photo_event_16.tscn"
	}
}

func set_current_world(world_id: String) -> void:
	current_world_id = world_id

func trigger_event(event_id: String, _velocity: int) -> void:
	clear_spawned()

	if not photo_scene_map.has(current_world_id):
		return
	var world_bank: Dictionary = photo_scene_map[current_world_id]
	if not world_bank.has(event_id):
		return

	var scene_path: String = world_bank[event_id]
	if not ResourceLoader.exists(scene_path):
		return

	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		return

	var node: Node3D = packed_scene.instantiate() as Node3D
	if node == null:
		return

	_disable_imported_cameras(node)
	add_child(node)
	spawned_nodes.append(node)

	await get_tree().process_frame
	await get_tree().process_frame

	if is_instance_valid(node):
		_auto_place(node)

func _auto_place(node: Node3D) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	# Calculer l'AABB pour auto-scale
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(node, meshes)

	var found := false
	var combined := AABB()
	for mi: MeshInstance3D in meshes:
		if mi.mesh == null:
			continue
		var mesh_aabb := mi.get_aabb()
		for i: int in range(8):
			var corner := mesh_aabb.position + Vector3(
				mesh_aabb.size.x if (i & 1) else 0.0,
				mesh_aabb.size.y if (i & 2) else 0.0,
				mesh_aabb.size.z if (i & 4) else 0.0
			)
			var global_corner := mi.to_global(corner)
			if not found:
				combined = AABB(global_corner, Vector3.ZERO)
				found = true
			else:
				combined = combined.expand(global_corner)

	var max_extent := maxf(maxf(combined.size.x, combined.size.y), combined.size.z)
	var height_extent := combined.size.y

	print("AABB combined size -> ", combined.size)
	print("max_extent -> ", max_extent, " | height_extent -> ", height_extent)

	# Appliquer le scale
	if max_extent > 0.001:
		var scale_factor := TARGET_SIZE / max_extent
		# Si l'objet est trop plat, augmenter le scale pour garantir une hauteur minimale
		if height_extent > 0.001:
			var scaled_height := height_extent * scale_factor
			print("scaled_height -> ", scaled_height, " | scale_factor -> ", scale_factor)
			if scaled_height < MIN_HEIGHT:
				scale_factor = MIN_HEIGHT / height_extent
				print("FLAT object: new scale_factor -> ", scale_factor)
		# Multiplicateur d'échelle spécifique à l'objet (metadata "scale_multiplier")
		if node.has_meta("scale_multiplier"):
			var mult: float = float(node.get_meta("scale_multiplier"))
			scale_factor *= mult
			print("scale_multiplier meta -> ×", mult, " | final scale_factor -> ", scale_factor)
		node.scale = Vector3(scale_factor, scale_factor, scale_factor)
	else:
		node.scale = Vector3(10, 10, 10)

	print("Final scale -> ", node.scale)

	# Placer devant le joueur, au niveau du sol
	var cam_pos := cam.global_position
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.01:
		forward = forward.normalized()
	else:
		forward = Vector3(0, 0, -1)

	var spawn_pos := cam_pos + forward * SPAWN_DISTANCE

	# Raycast vers le bas pour trouver le vrai sol
	var space_state := get_world_3d().direct_space_state
	var ray_origin := Vector3(spawn_pos.x, cam_pos.y + 10.0, spawn_pos.z)
	var ray_end := Vector3(spawn_pos.x, cam_pos.y - 50.0, spawn_pos.z)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := space_state.intersect_ray(query)

	if result.size() > 0:
		spawn_pos.y = result["position"].y
	else:
		# Fallback : hauteur du joueur moins la tête
		spawn_pos.y = cam_pos.y - 1.6

	# Petit offset au-dessus du sol pour éviter l'enfouissement
	spawn_pos.y += 0.5

	node.global_position = spawn_pos
	var final_scaled_height := height_extent * node.scale.y
	print("Spawn Y -> ", spawn_pos.y, " | final_scaled_height -> ", final_scaled_height)

func _disable_imported_cameras(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Camera3D:
			(child as Camera3D).current = false
		_disable_imported_cameras(child)

func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_meshes(child, result)

func clear_spawned() -> void:
	for n: Node3D in spawned_nodes:
		if is_instance_valid(n):
			n.queue_free()
	spawned_nodes.clear()

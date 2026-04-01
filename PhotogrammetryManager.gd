extends Node3D

var current_world_id: String = "world_01"
var spawned_nodes: Array[Node3D] = []

# Taille cible des objets en mètres et distance devant le joueur
const TARGET_SIZE := 8.0
const SPAWN_DISTANCE := 12.0

var photo_scene_map := {
	"world_01": {
		"photo_event_01": "res://photogrammetry/photo_event_01.tscn",
		"photo_event_02": "res://photogrammetry/photo_event_02.tscn",
		"photo_event_03": "res://photogrammetry/photo_event_03.tscn",
		"photo_event_04": "res://photogrammetry/photo_event_04.tscn",
		"photo_event_05": "res://photogrammetry/photo_event_05.tscn",
		"photo_event_06": "res://photogrammetry/photo_event_06.tscn"
	},
	"world_02": {
		"photo_event_01": "res://photogrammetry/photo_event_01.tscn",
		"photo_event_02": "res://photogrammetry/photo_event_02.tscn",
		"photo_event_03": "res://photogrammetry/photo_event_03.tscn",
		"photo_event_04": "res://photogrammetry/photo_event_04.tscn",
		"photo_event_05": "res://photogrammetry/photo_event_05.tscn",
		"photo_event_06": "res://photogrammetry/photo_event_06.tscn"
	},
	"world_03": {
		"photo_event_01": "res://photogrammetry/photo_event_01.tscn",
		"photo_event_02": "res://photogrammetry/photo_event_02.tscn",
		"photo_event_03": "res://photogrammetry/photo_event_03.tscn",
		"photo_event_04": "res://photogrammetry/photo_event_04.tscn",
		"photo_event_05": "res://photogrammetry/photo_event_05.tscn",
		"photo_event_06": "res://photogrammetry/photo_event_06.tscn"
	},
	"world_04": {
		"photo_event_01": "res://photogrammetry/photo_event_01.tscn",
		"photo_event_02": "res://photogrammetry/photo_event_02.tscn",
		"photo_event_03": "res://photogrammetry/photo_event_03.tscn",
		"photo_event_04": "res://photogrammetry/photo_event_04.tscn",
		"photo_event_05": "res://photogrammetry/photo_event_05.tscn",
		"photo_event_06": "res://photogrammetry/photo_event_06.tscn"
	},
	"world_05": {
		"photo_event_01": "res://photogrammetry/photo_event_01.tscn",
		"photo_event_02": "res://photogrammetry/photo_event_02.tscn",
		"photo_event_03": "res://photogrammetry/photo_event_03.tscn",
		"photo_event_04": "res://photogrammetry/photo_event_04.tscn",
		"photo_event_05": "res://photogrammetry/photo_event_05.tscn",
		"photo_event_06": "res://photogrammetry/photo_event_06.tscn"
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

	# Appliquer le scale
	if max_extent > 0.001:
		var scale_factor := TARGET_SIZE / max_extent
		node.scale = Vector3(scale_factor, scale_factor, scale_factor)
	else:
		node.scale = Vector3(10, 10, 10)

	# Placer devant le joueur, au niveau du sol
	var cam_pos := cam.global_position
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.01:
		forward = forward.normalized()
	else:
		forward = Vector3(0, 0, -1)

	var spawn_pos := cam_pos + forward * SPAWN_DISTANCE
	# Poser au sol (Y du joueur - hauteur tête 1.6m)
	spawn_pos.y = cam_pos.y - 1.6

	node.global_position = spawn_pos

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

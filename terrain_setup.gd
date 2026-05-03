extends Node3D

const WORLD_TARGET_SIZE := 50.0
const SMALL_WORLD_THRESHOLD := 5.0

@export var auto_scale_enabled := true
@export var auto_spawn_enabled := true
@export var auto_ground_enabled := true
@export var auto_walls_enabled := true
@export var auto_mesh_collision_enabled := true

func _ready() -> void:
	var meshes := _collect_meshes(self)
	if meshes.is_empty():
		return

	if auto_scale_enabled:
		var pre_result: Variant = _get_merged_aabb(meshes)
		if pre_result == null:
			return
		var pre_aabb: AABB = pre_result as AABB

		var max_extent: float = maxf(maxf(pre_aabb.size.x, pre_aabb.size.y), pre_aabb.size.z)
		if max_extent < SMALL_WORLD_THRESHOLD and max_extent > 0.001:
			var scale_factor: float = WORLD_TARGET_SIZE / max_extent
			scale = Vector3(scale_factor, scale_factor, scale_factor)

	if not auto_spawn_enabled and not auto_ground_enabled and not auto_walls_enabled and not auto_mesh_collision_enabled:
		return

	await get_tree().process_frame
	await get_tree().process_frame

	var post_result: Variant = _get_merged_aabb(meshes)
	if post_result == null:
		return
	var aabb: AABB = post_result as AABB

	if auto_ground_enabled:
		_create_flat_ground(aabb)

	if auto_spawn_enabled:
		_auto_place_spawn(aabb)

	if auto_walls_enabled:
		_create_boundary_walls(aabb)

	if auto_mesh_collision_enabled:
		_create_mesh_collision(meshes)

func _create_mesh_collision(meshes: Array[MeshInstance3D]) -> void:
	for mi: MeshInstance3D in meshes:
		if mi.mesh == null:
			continue
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var col := CollisionShape3D.new()
		var shape := mi.mesh.create_trimesh_shape()
		if shape == null:
			body.queue_free()
			continue
		col.shape = shape
		mi.add_child(body)
		body.add_child(col)

func _auto_place_spawn(aabb: AABB) -> void:
	var spawn_point: Marker3D = get_node_or_null("SpawnPoint") as Marker3D
	if spawn_point == null:
		return
	var center: Vector3 = aabb.position + aabb.size * 0.5
	var top_y: float = aabb.position.y + aabb.size.y
	spawn_point.global_position = Vector3(center.x, top_y + 2.0, center.z)

func _create_flat_ground(aabb: AABB) -> void:
	var center: Vector3 = aabb.position + aabb.size * 0.5
	var floor_y: float = aabb.position.y - 1.0
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.position = Vector3(center.x, floor_y, center.z)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(aabb.size.x + 10.0, 2.0, aabb.size.z + 10.0)
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _create_boundary_walls(aabb: AABB) -> void:
	var center: Vector3 = aabb.position + aabb.size * 0.5
	var wall_height: float = maxf(20.0, aabb.size.y * 2.0)
	var wall_y: float = aabb.position.y + wall_height * 0.5

	_create_wall("Wall_North", Vector3(center.x, wall_y, aabb.position.z), Vector3(aabb.size.x + 4.0, wall_height, 2.0))
	_create_wall("Wall_South", Vector3(center.x, wall_y, aabb.position.z + aabb.size.z), Vector3(aabb.size.x + 4.0, wall_height, 2.0))
	_create_wall("Wall_East", Vector3(aabb.position.x + aabb.size.x, wall_y, center.z), Vector3(2.0, wall_height, aabb.size.z + 4.0))
	_create_wall("Wall_West", Vector3(aabb.position.x, wall_y, center.z), Vector3(2.0, wall_height, aabb.size.z + 4.0))

func _create_wall(wall_name: String, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = 2
	body.collision_mask = 2
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _get_merged_aabb(meshes: Array[MeshInstance3D]) -> Variant:
	var found := false
	var merged := AABB()
	for mi: MeshInstance3D in meshes:
		if mi.mesh == null:
			continue
		var local_aabb := mi.mesh.get_aabb()
		for i: int in range(8):
			var corner := local_aabb.position + Vector3(
				local_aabb.size.x if (i & 1) else 0.0,
				local_aabb.size.y if (i & 2) else 0.0,
				local_aabb.size.z if (i & 4) else 0.0
			)
			var g := mi.to_global(corner)
			if not found:
				merged = AABB(g, Vector3.ZERO)
				found = true
			else:
				merged = merged.expand(g)
	if found:
		return merged
	return null

func _collect_meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			result.append(child as MeshInstance3D)
		result.append_array(_collect_meshes(child))
	return result

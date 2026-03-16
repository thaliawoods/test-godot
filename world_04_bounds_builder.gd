extends Node3D

func _ready() -> void:
	print("=== BUILD WORLD 04 BOUNDS ===")

	var merged_aabb_result: Variant = _get_merged_mesh_aabb(self)
	if merged_aabb_result == null:
		print("Aucun mesh trouvé.")
		return

	var merged_aabb: AABB = merged_aabb_result as AABB
	print("Merged AABB position -> ", merged_aabb.position)
	print("Merged AABB size -> ", merged_aabb.size)

	_remove_existing_bounds()
	_create_bounds_from_aabb(merged_aabb)

	print("=== DONE ===")

func _remove_existing_bounds() -> void:
	var names: Array[String] = [
		"Ground",
		"Wall_North",
		"Wall_South",
		"Wall_East",
		"Wall_West"
	]

	for node_name: String in names:
		var existing: Node = get_node_or_null(node_name)
		if existing != null:
			existing.queue_free()

func _create_bounds_from_aabb(aabb: AABB) -> void:
	var center: Vector3 = aabb.position + (aabb.size * 0.5)
	var half_size: Vector3 = aabb.size * 0.5

	var floor_y: float = aabb.position.y - 2.0
	var wall_height: float = max(20.0, aabb.size.y * 0.5)

	_create_box_body(
		"Ground",
		Vector3(center.x, floor_y, center.z),
		Vector3(aabb.size.x, 4.0, aabb.size.z)
	)

	_create_box_body(
		"Wall_North",
		Vector3(center.x, floor_y + wall_height * 0.5, aabb.position.z),
		Vector3(aabb.size.x, wall_height, 4.0)
	)

	_create_box_body(
		"Wall_South",
		Vector3(center.x, floor_y + wall_height * 0.5, aabb.position.z + aabb.size.z),
		Vector3(aabb.size.x, wall_height, 4.0)
	)

	_create_box_body(
		"Wall_East",
		Vector3(aabb.position.x + aabb.size.x, floor_y + wall_height * 0.5, center.z),
		Vector3(4.0, wall_height, aabb.size.z)
	)

	_create_box_body(
		"Wall_West",
		Vector3(aabb.position.x, floor_y + wall_height * 0.5, center.z),
		Vector3(4.0, wall_height, aabb.size.z)
	)

func _create_box_body(node_name: String, body_position: Vector3, box_size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = body_position

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"

	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape

	body.add_child(collision)
	add_child(body)

	body.owner = get_tree().edited_scene_root
	collision.owner = get_tree().edited_scene_root

	print(node_name, " -> pos=", body_position, " size=", box_size)

func _get_merged_mesh_aabb(node: Node) -> Variant:
	var found: bool = false
	var merged: AABB = AABB()

	for mesh_instance: MeshInstance3D in _collect_meshes(node):
		if mesh_instance.mesh == null:
			continue

		var aabb_result: Variant = _get_mesh_global_aabb(mesh_instance)
		if aabb_result == null:
			continue

		var mesh_aabb: AABB = aabb_result as AABB

		if not found:
			merged = mesh_aabb
			found = true
		else:
			merged = merged.merge(mesh_aabb)

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

func _get_mesh_global_aabb(mesh_instance: MeshInstance3D) -> Variant:
	if mesh_instance.mesh == null:
		return null

	var local_aabb: AABB = mesh_instance.mesh.get_aabb()

	var corners: Array[Vector3] = [
		Vector3(local_aabb.position.x, local_aabb.position.y, local_aabb.position.z),
		Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y, local_aabb.position.z),
		Vector3(local_aabb.position.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z),
		Vector3(local_aabb.position.x, local_aabb.position.y, local_aabb.position.z + local_aabb.size.z),
		Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z),
		Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y, local_aabb.position.z + local_aabb.size.z),
		Vector3(local_aabb.position.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z + local_aabb.size.z),
		Vector3(local_aabb.position.x + local_aabb.size.x, local_aabb.position.y + local_aabb.size.y, local_aabb.position.z + local_aabb.size.z)
	]

	var first_corner: Vector3 = mesh_instance.to_global(corners[0])
	var min_v: Vector3 = first_corner
	var max_v: Vector3 = first_corner

	for corner: Vector3 in corners:
		var g: Vector3 = mesh_instance.to_global(corner)
		min_v.x = min(min_v.x, g.x)
		min_v.y = min(min_v.y, g.y)
		min_v.z = min(min_v.z, g.z)
		max_v.x = max(max_v.x, g.x)
		max_v.y = max(max_v.y, g.y)
		max_v.z = max(max_v.z, g.z)

	return AABB(min_v, max_v - min_v)

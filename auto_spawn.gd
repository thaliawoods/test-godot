extends Node3D

const WORLD_TARGET_SIZE := 50.0

func _ready() -> void:
	var spawn_point: Marker3D = get_node_or_null("SpawnPoint") as Marker3D
	if spawn_point == null:
		return

	var meshes: Array[MeshInstance3D] = _collect_meshes(self)
	if meshes.is_empty():
		return

	# Calculer l'AABB avant scale
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

	if not found:
		return

	# Auto-scale pour que le monde fasse ~50m d'envergure
	var max_extent := maxf(maxf(merged.size.x, merged.size.y), merged.size.z)
	if max_extent > 0.001:
		var scale_factor := WORLD_TARGET_SIZE / max_extent
		scale = Vector3(scale_factor, scale_factor, scale_factor)
		print("Auto scale -> ", scale_factor, " (extent was ", max_extent, ")")

	# Recalculer l'AABB après scale
	found = false
	merged = AABB()
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

	var center := merged.position + merged.size * 0.5
	var top_y := merged.position.y + merged.size.y

	# Spawn au centre du mesh, légèrement au-dessus du sol
	var ground_y := merged.position.y
	spawn_point.global_position = Vector3(center.x, ground_y + 2.0, center.z)
	print("Auto SpawnPoint -> ", spawn_point.global_position)

	# Sol plat + murs (comme world_04) au lieu de trimesh trop détaillé
	_create_bounds(merged)

func _create_bounds(aabb: AABB) -> void:
	var center := aabb.position + aabb.size * 0.5
	var floor_y := aabb.position.y - 1.0
	var wall_height := maxf(20.0, aabb.size.y * 2.0)

	_create_box_body("Ground", Vector3(center.x, floor_y, center.z), Vector3(aabb.size.x, 2.0, aabb.size.z))
	_create_box_body("Wall_North", Vector3(center.x, floor_y + wall_height * 0.5, aabb.position.z), Vector3(aabb.size.x, wall_height, 2.0))
	_create_box_body("Wall_South", Vector3(center.x, floor_y + wall_height * 0.5, aabb.position.z + aabb.size.z), Vector3(aabb.size.x, wall_height, 2.0))
	_create_box_body("Wall_East", Vector3(aabb.position.x + aabb.size.x, floor_y + wall_height * 0.5, center.z), Vector3(2.0, wall_height, aabb.size.z))
	_create_box_body("Wall_West", Vector3(aabb.position.x, floor_y + wall_height * 0.5, center.z), Vector3(2.0, wall_height, aabb.size.z))
	print("Bounds créés (sol + 4 murs)")

func _create_box_body(node_name: String, body_position: Vector3, box_size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = body_position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _collect_meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			result.append(child as MeshInstance3D)
		result.append_array(_collect_meshes(child))
	return result

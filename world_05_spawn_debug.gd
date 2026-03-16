extends Node3D

func _ready() -> void:
	print("=== DEBUG WORLD 05 ===")

	var mesh_node: MeshInstance3D = get_node_or_null("world_05/mesh_out_node")
	if mesh_node == null:
		print("mesh_out_node introuvable")
		return

	if mesh_node.mesh == null:
		print("mesh_out_node n'a pas de mesh")
		return

	var aabb: AABB = mesh_node.mesh.get_aabb()

	print("Mesh local position -> ", mesh_node.position)
	print("Mesh global position -> ", mesh_node.global_position)
	print("AABB position -> ", aabb.position)
	print("AABB size -> ", aabb.size)

	var center_local: Vector3 = aabb.position + (aabb.size * 0.5)
	var center_global: Vector3 = mesh_node.to_global(center_local)

	print("Center local -> ", center_local)
	print("Center global -> ", center_global)

	var suggested_spawn: Vector3 = Vector3(
		center_global.x,
		mesh_node.to_global(Vector3(center_local.x, aabb.position.y + aabb.size.y, center_local.z)).y + 2.0,
		center_global.z
	)

	print("Suggested SpawnPoint -> ", suggested_spawn)

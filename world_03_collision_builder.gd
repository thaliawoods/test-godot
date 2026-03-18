extends Node3D

func _ready() -> void:
	print("=== DEBUG WORLD 03 COLLISIONS ===")
	_scan_meshes(self)

func _scan_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance: MeshInstance3D = child as MeshInstance3D
			var has_body: bool = mesh_instance.get_node_or_null("StaticBody3D") != null

			print("----")
			print("Node: ", mesh_instance.name)
			print("Global position: ", mesh_instance.global_position)
			print("Has StaticBody3D: ", has_body)

			if mesh_instance.mesh != null:
				var aabb: AABB = mesh_instance.mesh.get_aabb()
				print("AABB position: ", aabb.position)
				print("AABB size: ", aabb.size)

		_scan_meshes(child)

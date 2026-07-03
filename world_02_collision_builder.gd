extends Node3D

var target_names: Array[String] = [
	"Object_4",
	"Object_5",
	"Object_6",
	"Object_14",
	"Object_15",
	"Object_16"
]

func _ready() -> void:
	print("=== BUILD WORLD 02 SAFE COLLISIONS ===")
	_create_trimesh_collisions(self)
	print("=== DONE ===")

func _create_trimesh_collisions(node: Node) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance: MeshInstance3D = child as MeshInstance3D

			if mesh_instance.name in target_names and mesh_instance.mesh != null:
				var existing_body: Node = mesh_instance.get_node_or_null("StaticBody3D")
				if existing_body == null:
					mesh_instance.create_trimesh_collision()
					print("Collision trimesh créée pour : ", mesh_instance.name)

		_create_trimesh_collisions(child)

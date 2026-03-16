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
	_create_box_collisions(self)
	print("=== DONE ===")

func _create_box_collisions(node: Node) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance: MeshInstance3D = child as MeshInstance3D

			if mesh_instance.name in target_names and mesh_instance.mesh != null:
				var existing_body: Node = mesh_instance.get_node_or_null("StaticBody3D")
				if existing_body == null:
					var aabb: AABB = mesh_instance.mesh.get_aabb()

					var body: StaticBody3D = StaticBody3D.new()
					body.name = "StaticBody3D"

					var collision: CollisionShape3D = CollisionShape3D.new()
					collision.name = "CollisionShape3D"

					var shape: BoxShape3D = BoxShape3D.new()
					shape.size = Vector3(
						aabb.size.x * 0.9,
						aabb.size.y * 0.9,
						aabb.size.z * 0.9
					)

					collision.shape = shape
					collision.position = aabb.position + (aabb.size * 0.5)

					mesh_instance.add_child(body)
					body.add_child(collision)

					body.owner = get_tree().edited_scene_root
					collision.owner = get_tree().edited_scene_root

					print("Collision créée pour : ", mesh_instance.name)

		_create_box_collisions(child)

extends Node3D

var current_world_id: String = "world_01"
var spawned_nodes: Array[Node3D] = []

var photo_scene_map := {
	"world_01": {
		"photo_event_01": "res://photogrammetry/world_01/photo_event_01.tscn",
		"photo_event_02": "res://photogrammetry/world_01/photo_event_02.tscn",
		"photo_event_03": "res://photogrammetry/world_01/photo_event_03.tscn",
		"photo_event_04": "res://photogrammetry/world_01/photo_event_04.tscn",
		"photo_event_05": "res://photogrammetry/world_01/photo_event_05.tscn",
		"photo_event_06": "res://photogrammetry/world_01/photo_event_06.tscn"
	},
	"world_02": {},
	"world_03": {},
	"world_04": {},
	"world_05": {}
}

func set_current_world(world_id: String) -> void:
	current_world_id = world_id
	print("PhotogrammetryManager -> world = ", world_id)

func trigger_event(event_id: String, velocity: int) -> void:
	clear_spawned()

	if not photo_scene_map.has(current_world_id):
		push_warning("Aucune banque photo pour : %s" % current_world_id)
		return

	var world_bank: Dictionary = photo_scene_map[current_world_id]

	if not world_bank.has(event_id):
		push_warning("Event photo introuvable : %s dans %s" % [event_id, current_world_id])
		return

	var scene_path: String = world_bank[event_id]

	if not ResourceLoader.exists(scene_path):
		push_warning("Scène photo absente : %s" % scene_path)
		return

	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		push_warning("Impossible de charger : %s" % scene_path)
		return

	var node: Node3D = packed_scene.instantiate() as Node3D
	if node == null:
		push_warning("La scène n'est pas un Node3D : %s" % scene_path)
		return

	add_child(node)
	_place_in_front_of_camera(node)
	spawned_nodes.append(node)

	print("Photo node added: ", node.name, " at ", node.global_position)
	print("Photo spawn -> ", current_world_id, " / ", event_id)

func _place_in_front_of_camera(node: Node3D) -> void:
	node.global_position = Vector3(0, 0, 0)
	node.rotation = Vector3.ZERO
	node.scale = Vector3(200, 200, 200)

func clear_spawned() -> void:
	for n: Node3D in spawned_nodes:
		if is_instance_valid(n):
			n.queue_free()
	spawned_nodes.clear() 

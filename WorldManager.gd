extends Node

@onready var world_holder = $"../WorldHolder"

var current_world: Node3D = null

var world_scene_map := {
	"world_01": preload("res://worlds/world_01.tscn"),
	"world_02": preload("res://worlds/world_02.tscn"),
	"world_03": preload("res://worlds/world_03.tscn"),
	"world_04": preload("res://worlds/world_04.tscn")
}

func load_world(world_id: String) -> void:
	if current_world != null:
		current_world.queue_free()
		current_world = null

	if not world_scene_map.has(world_id):
		push_warning("Monde introuvable : %s" % world_id)
		return

	current_world = world_scene_map[world_id].instantiate()
	world_holder.add_child(current_world)

	print("Monde chargé : ", world_id)

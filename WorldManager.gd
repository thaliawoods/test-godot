extends Node

@onready var world_holder = $"../WorldHolder"

var current_world: Node3D = null

func load_world(world_id: String) -> void:
	if current_world != null:
		current_world.queue_free()
		current_world = null

	var world := Node3D.new()
	world.name = world_id
	world_holder.add_child(world)
	current_world = world

	print("Monde chargé : ", world_id)

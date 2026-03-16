extends Node

func trigger_event(event_id: String, velocity: int) -> void:
	var number = event_id.replace("audio_event_0", "")
	if number == event_id:
		number = event_id.replace("audio_event_", "")

	var path := "res://audio/audio_event_%s.wav" % number
	var stream: AudioStream = load(path)

	if stream == null:
		push_warning("Could not load audio file: %s" % path)
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	player.volume_db = lerp(-20.0, 0.0, float(velocity) / 127.0)

	add_child(player)
	player.play()

	print("Audio event -> ", event_id)

	player.finished.connect(func():
		if is_instance_valid(player):
			player.queue_free()
	)

extends Node

var audio_map := {
	"audio_event_01": "res://audio/audio_event_01.wav",
	"audio_event_02": "res://audio/audio_event_02.wav"
}

func trigger_event(event_id: String, velocity: int) -> void:
	if not audio_map.has(event_id):
		push_warning("Audio event not found: %s" % event_id)
		return

	var path: String = audio_map[event_id]
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

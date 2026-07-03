extends Node

func _ready() -> void:
	_ensure_effects_bus()

func _ensure_effects_bus() -> void:
	if AudioServer.get_bus_index("Effects") >= 0:
		return
	var idx: int = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, "Effects")
	AudioServer.set_bus_send(idx, "Master")
	var filter: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	filter.cutoff_hz = 20000.0
	filter.resonance = 0.5
	AudioServer.add_bus_effect(idx, filter)
	var reverb: AudioEffectReverb = AudioEffectReverb.new()
	reverb.wet = 0.0
	reverb.dry = 1.0
	reverb.room_size = 0.8
	AudioServer.add_bus_effect(idx, reverb)
	var limiter: AudioEffectLimiter = AudioEffectLimiter.new()
	limiter.ceiling_db = -0.3
	limiter.threshold_db = -3.0
	limiter.soft_clip_db = 2.0
	AudioServer.add_bus_effect(idx, limiter)
	AudioServer.set_bus_volume_db(idx, 6.0)
	print("[AudioManager] Bus 'Effects' créé (filter + reverb + limiter, +6 dB)")

func trigger_event(event_id: String, velocity: int) -> void:
	print("[AudioManager] trigger_event called: id=", event_id, " vel=", velocity)
	var number: String = event_id.replace("audio_event_0", "")
	if number == event_id:
		number = event_id.replace("audio_event_", "")

	var path: String = "res://audio/audio_event_%s.mp3" % number
	var stream: AudioStream = load(path)

	if stream == null:
		push_warning("Could not load audio file: %s" % path)
		print("[AudioManager] FAILED to load: ", path)
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	var bus_name: String = "Effects"
	if AudioServer.get_bus_index(bus_name) < 0:
		bus_name = "Master"
	player.bus = bus_name
	var vol_db: float = lerpf(-3.0, 6.0, float(velocity) / 127.0)
	player.volume_db = vol_db

	add_child(player)
	player.play()

	print("[AudioManager] Playing ", path, " on bus '", bus_name, "' vol_db=", vol_db, " stream_len=", stream.get_length())

	player.finished.connect(func():
		if is_instance_valid(player):
			player.queue_free()
	)

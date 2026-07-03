extends Node

# Suivi des sons actuellement en lecture par event_id, pour le toggle
# (rejouer la même note = arrêter le son en cours).
var _playing: Dictionary = {}

func _ready() -> void:
	_ensure_effects_bus()

func _ensure_effects_bus() -> void:
	if AudioServer.get_bus_index("Effects") >= 0:
		return
	var idx: int = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, "Effects")
	AudioServer.set_bus_send(idx, "Master")
	# [0] Filtre passe-bas avec résonance dynamique (contrôlé par knob 74)
	var filter: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	filter.cutoff_hz = 20000.0
	filter.resonance = 0.5
	AudioServer.add_bus_effect(idx, filter)
	# [1] Distortion overdrive (drive contrôlé dynamiquement selon knob 74)
	var distortion: AudioEffectDistortion = AudioEffectDistortion.new()
	distortion.mode = AudioEffectDistortion.MODE_OVERDRIVE
	distortion.pre_gain = 0.0
	distortion.drive = 0.0
	distortion.post_gain = 0.0
	AudioServer.add_bus_effect(idx, distortion)
	# [2] Chorus large (profondeur contrôlée dynamiquement selon knob 75)
	var chorus: AudioEffectChorus = AudioEffectChorus.new()
	chorus.wet = 0.0
	chorus.dry = 1.0
	chorus.voice_count = 3
	AudioServer.add_bus_effect(idx, chorus)
	# [3] Reverb très caverneuse (contrôlée par knob 75)
	var reverb: AudioEffectReverb = AudioEffectReverb.new()
	reverb.wet = 0.0
	reverb.dry = 1.0
	reverb.room_size = 0.9
	reverb.damping = 0.3
	reverb.spread = 1.0
	reverb.predelay_msec = 40.0
	AudioServer.add_bus_effect(idx, reverb)
	# [4] Limiter pour éviter le clipping avec toute cette distortion
	var limiter: AudioEffectLimiter = AudioEffectLimiter.new()
	limiter.ceiling_db = -0.3
	limiter.threshold_db = -3.0
	limiter.soft_clip_db = 2.0
	AudioServer.add_bus_effect(idx, limiter)
	AudioServer.set_bus_volume_db(idx, 6.0)
	print("[AudioManager] Bus 'Effects' créé (filter + distortion + chorus + reverb + limiter)")

func trigger_event(event_id: String, velocity: int) -> void:
	print("[AudioManager] trigger_event called: id=", event_id, " vel=", velocity)

	# Toggle : si le son est déjà en cours pour cet event, on l'arrête.
	if _playing.has(event_id):
		var existing: AudioStreamPlayer = _playing[event_id]
		if is_instance_valid(existing):
			existing.stop()
			existing.queue_free()
		_playing.erase(event_id)
		print("[AudioManager] Toggled OFF: ", event_id)
		return

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
	_playing[event_id] = player

	print("[AudioManager] Playing ", path, " on bus '", bus_name, "' vol_db=", vol_db, " stream_len=", stream.get_length())

	# Nettoyage à la fin naturelle du son.
	player.finished.connect(func():
		if is_instance_valid(player):
			player.queue_free()
		if _playing.get(event_id) == player:
			_playing.erase(event_id)
	)

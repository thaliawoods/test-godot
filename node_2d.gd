extends Node2D

func _ready():
	OS.open_midi_inputs()
	print("🎹 MIDI inputs:", OS.get_connected_midi_inputs())

func _input(event):
	if event is InputEventMIDI:
		print("🎛 NOTE MIDI 👉 pitch:", event.pitch, " velocity:", event.velocity)

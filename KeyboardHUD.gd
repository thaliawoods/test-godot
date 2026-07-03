extends CanvasLayer

@onready var panel: PanelContainer = $Panel
var hud_visible := true
var fade_tween: Tween

func _ready() -> void:
	panel.modulate.a = 0.0
	_update_scale()
	get_tree().root.size_changed.connect(_update_scale)
	_fade_to(1.0, 0.8)
	_fade_out_after(5.0)

func _update_scale() -> void:
	var window_height := get_viewport().get_visible_rect().size.y
	var base_height := 648.0
	var s := window_height / base_height
	panel.scale = Vector2(s, s)
	panel.position.x = 32.0 * s
	panel.position.y = window_height - panel.size.y * s - 32.0 * s

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB or event.keycode == KEY_TAB:
			hud_visible = not hud_visible
			if hud_visible:
				_fade_to(1.0, 0.4)
			else:
				_fade_to(0.0, 0.4)

func _fade_to(alpha: float, duration: float) -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(panel, "modulate:a", alpha, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _fade_out_after(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if hud_visible:
		hud_visible = false
		_fade_to(0.0, 1.5)

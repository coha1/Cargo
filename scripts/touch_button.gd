class_name TouchButton
extends Panel


## The input action fired while this button is held.
@export var action_name: String = ""


var _touch_index: int = -1


func _ready() -> void:
	_set_pressed(false)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			var local: Vector2 = event.position - global_position
			if Rect2(Vector2.ZERO, size).has_point(local):
				_touch_index = event.index
				_fire(true)
				_set_pressed(true)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_fire(false)
			_set_pressed(false)

	elif event is InputEventScreenDrag and event.index == _touch_index:
		var local: Vector2 = event.position - global_position
		if not Rect2(Vector2.ZERO, size).has_point(local):
			_touch_index = -1
			_fire(false)
			_set_pressed(false)


func _fire(pressed: bool) -> void:
	if action_name.is_empty():
		return
	if pressed:
		Input.action_press(action_name, 1.0)
	else:
		Input.action_release(action_name)


func _set_pressed(pressed: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(16)
	style.set_border_width_all(2)
	if pressed:
		style.bg_color = Color(0.28, 0.55, 0.95, 0.90)
		style.border_color = Color(0.55, 0.80, 1.00, 0.95)
	else:
		style.bg_color = Color(0.06, 0.08, 0.16, 0.72)
		style.border_color = Color(0.30, 0.50, 0.85, 0.55)
	add_theme_stylebox_override("panel", style)

class_name TouchButton
extends Panel


## The input action fired while this button is held.
@export var action_name: String = ""


var _touch_index: int = -1


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			var local: Vector2 = event.position - global_position
			if Rect2(Vector2.ZERO, size).has_point(local):
				_touch_index = event.index
				_fire(true)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_fire(false)

	elif event is InputEventScreenDrag and event.index == _touch_index:
		var local: Vector2 = event.position - global_position
		if not Rect2(Vector2.ZERO, size).has_point(local):
			_touch_index = -1
			_fire(false)


func _fire(pressed: bool) -> void:
	if action_name.is_empty():
		return
	if pressed:
		Input.action_press(action_name, 1.0)
	else:
		Input.action_release(action_name)

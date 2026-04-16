class_name TouchControls
extends Control


## Force the overlay visible regardless of device — useful for layout testing in the editor.
@export var force_visible: bool = false


func _ready() -> void:
	if not force_visible and not DisplayServer.is_touchscreen_available():
		visible = false
		return
	_strip_mouse_bindings()
	print(get_path(), ": touch controls active")


## Removes all InputEventMouseButton bindings from every action so that
## incidental mouse clicks don't trigger driving inputs on touchscreen devices.
func _strip_mouse_bindings() -> void:
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			if event is InputEventMouseButton:
				InputMap.action_erase_event(action, event)

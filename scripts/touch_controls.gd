class_name TouchControls
extends Control


## Force touch mode on at startup — useful for layout testing in the editor.
@export var force_touch_on: bool = false


@onready var _controls_layer: Control = $VirtualGamepad
@onready var _toggle_button: Button = $ToggleLayer/ToggleButton

var _touch_active: bool = false


func _ready() -> void:
	_toggle_button.pressed.connect(_on_toggle_pressed)
	_set_touch_active(force_touch_on)


func _on_toggle_pressed() -> void:
	_set_touch_active(not _touch_active)


func _set_touch_active(active: bool) -> void:
	_touch_active = active
	_controls_layer.visible = active
	_toggle_button.text = "Touch: ON" if active else "Touch: OFF"
	_toggle_button.release_focus()
	if active:
		_strip_mouse_bindings()
	else:
		InputMap.load_from_project_settings()


## Removes all InputEventMouseButton bindings from every action so that
## incidental mouse clicks don't trigger driving inputs on touchscreen devices.
func _strip_mouse_bindings() -> void:
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			if event is InputEventMouseButton:
				InputMap.action_erase_event(action, event)

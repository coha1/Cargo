class_name CameraFollow
extends Node3D


## Distance behind the target
@export var follow_distance: float = 10.0

## Height above target pivot
@export var follow_height: float = 4.5

## Position smoothing speed (higher = snappier)
@export var position_smooth: float = 5.0

var target: Node3D


func _ready() -> void:
	top_level = true


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var behind := target.global_transform.basis.z
	var desired := target.global_position + behind * follow_distance + Vector3.UP * follow_height

	global_position = global_position.lerp(desired, position_smooth * delta)
	look_at(target.global_position + Vector3.UP * 1.2)

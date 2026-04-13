class_name CameraFollow
extends Node3D


## Distance behind the target
@export var follow_distance: float = 10.0

## Height above target pivot
@export var follow_height: float = 4.5

## Position smoothing speed (higher = snappier)
@export var position_smooth: float = 5.0

## Max yaw rate the camera chases the car's heading, in rad/s.
## Lower = more panhandle lag; higher = snappier tracking.
@export var yaw_speed: float = 1.5

var target: Node3D

## The camera's current flat heading (unit vector in XZ), updated each frame
var _cam_flat_dir: Vector3 = Vector3.BACK


func _ready() -> void:
	top_level = true


func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Project the car's forward axis onto the horizontal plane.
	# Only update our tracked heading when the car isn't pointing nearly
	# straight up or down (e.g. during a flip) — avoids sudden camera snaps.
	var forward := target.global_transform.basis.z
	var flat_car := Vector3(forward.x, 0.0, forward.z)
	if flat_car.length_squared() > 0.1:
		flat_car = flat_car.normalized()
		# Signed angle from our current heading to where the car is pointing.
		# Clamp to the max rotation allowed this frame (panhandle lag).
		var angle := _cam_flat_dir.signed_angle_to(flat_car, Vector3.UP)
		var max_rot := yaw_speed * delta
		angle = clamp(angle, -max_rot, max_rot)
		_cam_flat_dir = _cam_flat_dir.rotated(Vector3.UP, angle)

	var desired := target.global_position + _cam_flat_dir * follow_distance + Vector3.UP * follow_height
	global_position = global_position.lerp(desired, position_smooth * delta)
	look_at(target.global_position + Vector3.UP * 1.2)

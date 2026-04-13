class_name Car
extends VehicleBody3D


## Maximum engine force applied to drive wheels
@export var engine_force_max: float = 6000.0

## Maximum steering angle in radians
@export var steering_max: float = 0.5

## How fast steering travels to target, in radians per second
@export var steering_speed: float = 1.8

## How fast steering returns to centre when input is released, in radians per second
@export var steering_return_speed: float = 3.5

## Brake force
@export var brake_force: float = 25.0

## Yaw torque applied per steering unit while airborne
@export var air_yaw_torque: float = 4000.0

## Downward force (N) applied while grounded to resist suspension bounce
@export var ground_downforce: float = 4000.0

## Rear wheel friction slip while e-brake is held — lower = more slide
@export var ebrake_friction: float = 0.05

const _RIGHTING_FORCE: float = 25000.0

var _steer_current: float = 0.0
var _normal_rear_friction: float = 1.2

@onready var _wheels: Array[VehicleWheel3D] = [$WheelFL, $WheelFR, $WheelRL, $WheelRR]
@onready var _wheels_rear: Array[VehicleWheel3D] = [$WheelRL, $WheelRR]


func _ready() -> void:
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, -0.3, 0.0)
	angular_damp = 1.5
	_normal_rear_friction = _wheels_rear[0].wheel_friction_slip


func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("car_accelerate", "car_brake")
	var steer_target := Input.get_axis("car_steer_right", "car_steer_left")
	var ebrake := Input.is_action_pressed("car_ebrake")

	if _is_grounded():
		engine_force = throttle * engine_force_max
		brake = 0.0
		apply_central_force(Vector3.DOWN * ground_downforce)
		_apply_ebrake(ebrake)
		var steer_target_angle := steer_target * steering_max
		var rate := steering_speed if steer_target != 0.0 else steering_return_speed
		_steer_current = move_toward(_steer_current, steer_target_angle, rate * delta)
		steering = _steer_current
	else:
		engine_force = 0.0
		brake = 0.0
		steering = 0.0
		_apply_ebrake(false)
		apply_torque(Vector3.UP * steer_target * air_yaw_torque)
		_steer_current = move_toward(_steer_current, 0.0, steering_return_speed * delta)
		angular_velocity = angular_velocity.lerp(Vector3.ZERO, 0.1)

	_apply_stability()


func _is_grounded() -> bool:
	for wheel: VehicleWheel3D in _wheels:
		if wheel.is_in_contact():
			return true
	return false


func _apply_ebrake(active: bool) -> void:
	var friction := ebrake_friction if active else _normal_rear_friction
	for wheel: VehicleWheel3D in _wheels_rear:
		wheel.wheel_friction_slip = friction


func _apply_stability() -> void:
	var up := global_transform.basis.y
	if up.y > 0.5:
		return
	var torque_axis := up.cross(Vector3.UP)
	if torque_axis.length_squared() < 0.001:
		torque_axis = global_transform.basis.z
	apply_torque(torque_axis.normalized() * _RIGHTING_FORCE)

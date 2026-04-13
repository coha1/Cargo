class_name Car
extends VehicleBody3D


@export var engine_force_max: float = 6000.0 ## Maximum engine force applied to drive wheels
@export var steering_max: float = 0.5 ## Maximum steering angle in radians
@export var steering_speed: float = 1.8 ## How fast steering travels to target, in radians per second
@export var steering_return_speed: float = 3.5 ## How fast steering returns to center when input is released, in radians per second
@export var brake_force: float = 25.0
@export var air_roll_speed_max: float = 2.8 ## Peak roll speed in rad/s with no boost (~0.45 full rolls/sec)
@export var air_roll_accel: float = 3.0 ## Roll speed ramp-up rate in rad/s² — controls how long buildup takes
@export var air_pitch_speed_max: float = 3.5 ## Peak pitch speed in rad/s with no boost
@export var air_pitch_accel: float = 4.0 ## Pitch speed ramp-up rate in rad/s²
@export var air_boost_multiplier: float = 2.5 ## Speed multiplier applied to aerial rotation when e-brake is held — hold for fast spins
@export var ground_downforce: float = 4000.0 ## Downward force (N) applied while grounded to resist suspension bounce
@export var ebrake_friction: float = 0.05 ## Rear wheel friction slip while e-brake is held — lower = more slide

@onready var _wheels: Array[VehicleWheel3D] = [$WheelFL, $WheelFR, $WheelRL, $WheelRR]
@onready var _wheels_rear: Array[VehicleWheel3D] = [$WheelRL, $WheelRR]

var _steer_current: float = 0.0
var _normal_rear_friction: float = 1.2
var _air_roll_speed: float = 0.0
var _air_pitch_speed: float = 0.0


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
		_air_roll_speed = 0.0
		_air_pitch_speed = 0.0
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
		# Ramp roll and pitch speed toward the input target each frame.
		# This gives a gradual buildup rather than instant max rotation —
		# hold the input longer to spin faster, like GTA V aerial inertia.
		# Holding e-brake while airborne boosts the speed ceiling for fast deliberate spins.
		var boost := air_boost_multiplier if ebrake else 1.0
		_air_roll_speed = move_toward(_air_roll_speed, steer_target * air_roll_speed_max * boost, air_roll_accel * delta)
		var pitch := Input.get_axis("car_pitch_down", "car_pitch_up")
		_air_pitch_speed = move_toward(_air_pitch_speed, pitch * air_pitch_speed_max * boost, air_pitch_accel * delta)
		# Strip the existing roll and pitch components from angular velocity
		# and replace them with the accumulated values, leaving yaw untouched.
		var roll_axis := global_transform.basis.z.normalized()
		var pitch_axis := global_transform.basis.x.normalized()
		var av := angular_velocity
		av -= roll_axis * av.dot(roll_axis)
		av -= pitch_axis * av.dot(pitch_axis)
		av += roll_axis * _air_roll_speed + pitch_axis * _air_pitch_speed
		angular_velocity = av
		_steer_current = move_toward(_steer_current, 0.0, steering_return_speed * delta)

func _is_grounded() -> bool:
	for wheel: VehicleWheel3D in _wheels:
		if wheel.is_in_contact():
			return true
	return false


func _apply_ebrake(active: bool) -> void:
	var friction := ebrake_friction if active else _normal_rear_friction
	for wheel: VehicleWheel3D in _wheels_rear:
		wheel.wheel_friction_slip = friction

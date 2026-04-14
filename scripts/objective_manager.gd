class_name ObjectiveManager
extends Node

## Assumed average travel speed used to estimate delivery time (m/s).
## Deliberately conservative to account for turns and obstacles.
const AVG_SPEED: float = 11.0

@export var card_path:          NodePath ## NodePath to the ObjectiveCard node in the HUD.
@export var pickup_zone_path:   NodePath ## NodePath to the pickup ZoneMarker.
@export var delivery_zone_path: NodePath ## NodePath to the delivery ZoneMarker.
@export var car_path:           NodePath ## NodePath to the Car (VehicleBody3D).

var _card:     ObjectiveCard
var _pickup:   ZoneMarker
var _delivery: ZoneMarker
var _car:      VehicleBody3D

# Timer state
var _elapsed:  float = 0.0
var _timing:   bool  = false
var _picked_up: bool = false

# Distance references recorded at acceptance / pickup
var _start_pos:           Vector3   # car position when order accepted
var _dist_to_pickup:      float     # total straight-line dist  start → pickup
var _dist_to_delivery:    float     # total straight-line dist  pickup → delivery
var _eta:                 float     # estimated completion time in seconds


func _ready() -> void:
	_card     = get_node(card_path)          as ObjectiveCard  if card_path          else null
	_pickup   = get_node(pickup_zone_path)   as ZoneMarker     if pickup_zone_path   else null
	_delivery = get_node(delivery_zone_path) as ZoneMarker     if delivery_zone_path else null
	_car      = get_node(car_path)           as VehicleBody3D  if car_path           else null

	if _card == null or _pickup == null or _delivery == null or _car == null:
		printerr(get_path(), ": assign all four NodePath exports in the inspector")
		return

	_card.order_accepted.connect(_on_order_accepted)
	_card.order_declined.connect(_on_order_declined)
	_pickup.car_entered.connect(_on_pickup_entered)
	_delivery.car_entered.connect(_on_delivery_entered)


func _process(delta: float) -> void:
	if not _timing or _card == null or _car == null:
		return

	_elapsed += delta

	# Live clock on the card
	_card.update_elapsed(_elapsed)

	# Progress lines
	_card.update_tracker_progress(_calc_line1(), _calc_line2())


# ── Zone callbacks ────────────────────────────────────────────────────────────

func _on_order_declined() -> void:
	_timing    = false
	_elapsed   = 0.0
	_picked_up = false


func _on_order_accepted() -> void:
	_elapsed   = 0.0
	_timing    = true
	_picked_up = false

	_start_pos = _car.global_position

	# Straight-line distances used for line progress and ETA.
	# We use the ground-plane (XZ) distance so vertical terrain variation
	# doesn't distort the estimate.
	_dist_to_pickup   = _flat_dist(_start_pos, _pickup.global_position)
	_dist_to_delivery = _flat_dist(_pickup.global_position, _delivery.global_position)

	var total_dist := _dist_to_pickup + _dist_to_delivery
	_eta = total_dist / AVG_SPEED if total_dist > 0.0 else 1.0

	print("ObjectiveManager: ETA = %.1fs (%.0fm @ %.0fm/s)" \
		  % [_eta, total_dist, AVG_SPEED])


func _on_pickup_entered() -> void:
	if _timing and not _picked_up:
		_picked_up = true
		if _card:
			_card.advance_to_picked_up()


func _on_delivery_entered() -> void:
	if _timing and _picked_up:
		_timing = false
		var stars := _rate(_elapsed, _eta)
		if _card:
			_card.complete_delivery(_elapsed, stars)


# ── Progress helpers ──────────────────────────────────────────────────────────

## 0–1 fill for the Accepted→Pickup line: how close the car is to the pickup.
func _calc_line1() -> float:
	if _dist_to_pickup <= 0.0:
		return 1.0
	if _picked_up:
		return 1.0
	var remaining := _flat_dist(_car.global_position, _pickup.global_position)
	return clampf(1.0 - remaining / _dist_to_pickup, 0.0, 1.0)


## 0–1 fill for the Pickup→Delivery line: how close the car is to delivery.
func _calc_line2() -> float:
	if not _picked_up:
		return 0.0
	if _dist_to_delivery <= 0.0:
		return 1.0
	var remaining := _flat_dist(_car.global_position, _delivery.global_position)
	return clampf(1.0 - remaining / _dist_to_delivery, 0.0, 1.0)


# ── Rating ────────────────────────────────────────────────────────────────────

## Returns 1–3 stars based on how the actual time compares to the ETA.
##   3 ★  — within ETA             (on pace or faster)
##   2 ★  — within 1.6× ETA       (a bit slow)
##   1 ★  — over 1.6× ETA         (very slow)
static func _rate(actual: float, eta: float) -> int:
	if actual <= eta:
		return 3
	if actual <= eta * 1.6:
		return 2
	return 1


# ── Util ──────────────────────────────────────────────────────────────────────

## Flat (XZ-plane) distance — ignores height differences so ramps/terrain
## don't make nearby zones appear further than they are.
static func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

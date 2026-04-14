class_name ObjectiveManager
extends Node

## NodePath to the ObjectiveCard node in the HUD.
@export var card_path: NodePath
## NodePath to the pickup ZoneMarker.
@export var pickup_zone_path: NodePath
## NodePath to the delivery ZoneMarker.
@export var delivery_zone_path: NodePath

var _card:     ObjectiveCard
var _pickup:   ZoneMarker
var _delivery: ZoneMarker

var _elapsed: float = 0.0
var _timing:  bool  = false


func _ready() -> void:
	_card     = get_node(card_path)     as ObjectiveCard if card_path     else null
	_pickup   = get_node(pickup_zone_path)  as ZoneMarker   if pickup_zone_path  else null
	_delivery = get_node(delivery_zone_path) as ZoneMarker  if delivery_zone_path else null

	if _card == null or _pickup == null or _delivery == null:
		printerr(get_path(), ": assign card_path, pickup_zone_path, and delivery_zone_path in the inspector")
		return

	_card.order_accepted.connect(_on_order_accepted)
	_pickup.car_entered.connect(_on_pickup_entered)
	_delivery.car_entered.connect(_on_delivery_entered)


func _process(delta: float) -> void:
	if _timing:
		_elapsed += delta


func _on_order_accepted() -> void:
	_elapsed = 0.0
	_timing  = true


func _on_pickup_entered() -> void:
	# advance_to_picked_up guards against wrong state internally
	if _card:
		_card.advance_to_picked_up()


func _on_delivery_entered() -> void:
	if _timing and _card:
		_timing = false
		_card.complete_delivery(_elapsed)

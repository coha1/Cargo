class_name Collectible
extends Area3D


signal collected

var _is_collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _is_collected:
		return
	if not body is VehicleBody3D:
		return
	_is_collected = true
	collected.emit()
	queue_free()

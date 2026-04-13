class_name HUD
extends CanvasLayer


@onready var _coin_label: Label = $Control/CoinLabel

var _count: int = 0
var _total: int = 0


func setup(total: int) -> void:
	_total = total
	_count = 0
	_refresh()


func increment() -> void:
	_count += 1
	_refresh()


func _refresh() -> void:
	_coin_label.text = "Coins: %d / %d" % [_count, _total]

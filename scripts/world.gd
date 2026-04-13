class_name World
extends Node3D


const COLLECTIBLE_COUNT: int = 12

## Collectible scene to scatter across the terrain
@export var collectible_scene: PackedScene

@onready var _hud: HUD = $HUD
@onready var _car: Car = $Car
@onready var _camera: CameraFollow = $CameraFollow
@onready var _terrain: Terrain = $Terrain


func _ready() -> void:
	_camera.target = _car

	# Drop the car a short distance above its editor-placed position so physics settle naturally
	_car.global_position.y += 3.0

	_hud.setup(COLLECTIBLE_COUNT)
	_spawn_collectibles()

	print(get_path(), ": world ready")


func _spawn_collectibles() -> void:
	if collectible_scene == null:
		printerr(get_path(), ": collectible_scene not assigned")
		return

	var half := float(Terrain.GRID_SIZE) * Terrain.CELL_SIZE * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 77

	for i in range(COLLECTIBLE_COUNT):
		var wx := rng.randf_range(-half * 0.8, half * 0.8)
		var wz := rng.randf_range(-half * 0.8, half * 0.8)
		var wy := _terrain.height_at(wx, wz) + 1.5

		var coin := collectible_scene.instantiate() as Collectible
		if coin == null:
			printerr(get_path(), ": collectible_scene root is not Collectible")
			continue
		coin.position = Vector3(wx, wy, wz)
		coin.collected.connect(_on_collectible_collected)
		add_child(coin)

	print(get_path(), ": spawned ", COLLECTIBLE_COUNT, " collectibles")


func _on_collectible_collected() -> void:
	_hud.increment()

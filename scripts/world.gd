class_name World
extends Node3D


const GRID_SIZE: int = 80
const CELL_SIZE: float = 3.0
const HEIGHT_SCALE: float = 9.0
const COLLECTIBLE_COUNT: int = 12

## Collectible scene to scatter across the terrain
@export var collectible_scene: PackedScene

@onready var _hud: HUD = $HUD
@onready var _car: Car = $Car
@onready var _camera: CameraFollow = $CameraFollow

var _noise: FastNoiseLite


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = 42
	_noise.frequency = 0.025
	_noise.fractal_octaves = 4

	_build_terrain()
	_build_flat_area()
	_camera.target = _car

	# Spawn well above terrain — let physics settle naturally
	_car.global_position = Vector3(0.0, _terrain_height_at(0.0, 0.0) + 8.0, 0.0)

	_hud.setup(COLLECTIBLE_COUNT)
	_spawn_collectibles()

	print(get_path(), ": world ready")


func _build_terrain() -> void:
	var size := GRID_SIZE
	var cs := CELL_SIZE
	var half := float(size) * cs * 0.5

	# Pre-cache heights so each grid point is evaluated once
	var heights := PackedFloat32Array()
	heights.resize((size + 1) * (size + 1))
	for gz in range(size + 1):
		for gx in range(size + 1):
			heights[gz * (size + 1) + gx] = _noise.get_noise_2d(float(gx), float(gz)) * HEIGHT_SCALE

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for gz in range(size):
		for gx in range(size):
			var x0 := float(gx) * cs - half
			var x1 := float(gx + 1) * cs - half
			var z0 := float(gz) * cs - half
			var z1 := float(gz + 1) * cs - half

			var h00 := heights[gz * (size + 1) + gx]
			var h10 := heights[gz * (size + 1) + (gx + 1)]
			var h01 := heights[(gz + 1) * (size + 1) + gx]
			var h11 := heights[(gz + 1) * (size + 1) + (gx + 1)]

			var v00 := Vector3(x0, h00, z0)
			var v10 := Vector3(x1, h10, z0)
			var v01 := Vector3(x0, h01, z1)
			var v11 := Vector3(x1, h11, z1)

			# CCW winding — normals face up
			st.add_vertex(v00)
			st.add_vertex(v01)
			st.add_vertex(v10)

			st.add_vertex(v10)
			st.add_vertex(v01)
			st.add_vertex(v11)

	st.generate_normals()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.55, 0.18)
	# Disable culling so terrain is visible regardless of normal direction
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)

	var mesh := st.commit()
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	add_child(mesh_inst)

	# HeightMapShape3D is far more stable than trimesh for terrain in Jolt
	var hmap := HeightMapShape3D.new()
	hmap.map_width = size + 1
	hmap.map_depth = size + 1
	hmap.map_data = heights

	var col_shape := CollisionShape3D.new()
	col_shape.shape = hmap
	# Scale grid-space coords to world-space cell size
	col_shape.scale = Vector3(cs, 1.0, cs)

	var static_body := StaticBody3D.new()
	static_body.add_child(col_shape)
	add_child(static_body)

	print(get_path(), ": terrain built")


func _build_flat_area() -> void:
	# Flat slab starting at the north terrain edge (z = +120) and stretching outward.
	# Top surface at y = 0; transition from terrain is a natural roll-off.
	var terrain_edge_z := float(GRID_SIZE) * CELL_SIZE * 0.5  # 120.0
	var depth := 400.0
	var width := 350.0
	var thickness := 2.0
	var center := Vector3(0.0, -thickness * 0.5, terrain_edge_z + depth * 0.5)
	var area_size := Vector3(width, thickness, depth)

	var grid_shader := Shader.new()
	grid_shader.code = "
shader_type spatial;
render_mode cull_disabled;

uniform float grid_size : hint_range(1.0, 100.0) = 10.0;
uniform vec4 base_color : source_color = vec4(0.70, 0.64, 0.50, 1.0);
uniform vec4 line_color : source_color = vec4(0.38, 0.32, 0.22, 1.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 coord = world_pos.xz / grid_size;
	vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float line = min(grid.x, grid.y);
	float is_line = 1.0 - clamp(line, 0.0, 1.0);
	ALBEDO = mix(base_color.rgb, line_color.rgb, is_line);
	ROUGHNESS = 0.95;
}
"

	var mat := ShaderMaterial.new()
	mat.shader = grid_shader

	var mesh := BoxMesh.new()
	mesh.size = area_size

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.position = center
	mesh_inst.set_surface_override_material(0, mat)
	add_child(mesh_inst)

	var shape := BoxShape3D.new()
	shape.size = area_size

	var col := CollisionShape3D.new()
	col.shape = shape

	var body := StaticBody3D.new()
	body.position = center
	body.add_child(col)
	add_child(body)

	print(get_path(), ": flat test area built — ", width, "x", depth, "m")


func _spawn_collectibles() -> void:
	if collectible_scene == null:
		printerr(get_path(), ": collectible_scene not assigned")
		return

	var half := float(GRID_SIZE) * CELL_SIZE * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 77

	for i in range(COLLECTIBLE_COUNT):
		var wx := rng.randf_range(-half * 0.8, half * 0.8)
		var wz := rng.randf_range(-half * 0.8, half * 0.8)
		var wy := _terrain_height_at(wx, wz) + 1.5

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


func _terrain_height_at(world_x: float, world_z: float) -> float:
	var half := float(GRID_SIZE) * CELL_SIZE * 0.5
	var gx := (world_x + half) / CELL_SIZE
	var gz := (world_z + half) / CELL_SIZE
	return _noise.get_noise_2d(gx, gz) * HEIGHT_SCALE

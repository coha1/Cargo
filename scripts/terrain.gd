@tool
class_name Terrain
extends Node3D


const GRID_SIZE: int = 80
const CELL_SIZE: float = 3.0
const HEIGHT_SCALE: float = 9.0

## Press to rebuild the terrain mesh and collision in the editor.
@export_tool_button("Regenerate Terrain", "Reload") var _regen_btn = _build

var _noise: FastNoiseLite


func _ready() -> void:
	_build()


## Returns the world-space terrain height at (world_x, world_z).
## Safe to call after _ready() has run.
func height_at(world_x: float, world_z: float) -> float:
	var lx := world_x - global_position.x
	var lz := world_z - global_position.z
	var half := float(GRID_SIZE) * CELL_SIZE * 0.5
	var gx := (lx + half) / CELL_SIZE
	var gz := (lz + half) / CELL_SIZE
	return global_position.y + _noise.get_noise_2d(gx, gz) * HEIGHT_SCALE


func _build() -> void:
	# Free any previously generated geometry so a re-bake starts clean.
	for child in get_children():
		child.free()

	_noise = FastNoiseLite.new()
	_noise.seed = 42
	_noise.frequency = 0.025
	_noise.fractal_octaves = 4

	_build_terrain()

	if not Engine.is_editor_hint():
		print(get_path(), ": terrain built")


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

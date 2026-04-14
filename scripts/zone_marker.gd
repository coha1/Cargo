class_name ZoneMarker
extends Area3D

## Emitted once when the player's car enters the trigger area.
signal car_entered

@export var zone_label: String = "ZONE"
@export var zone_color: Color = Color(0.3, 0.9, 0.4, 1.0)
@export var trigger_radius: float = 5.5


func _ready() -> void:
	_build_visuals()
	body_entered.connect(_on_body_entered)


func _build_visuals() -> void:
	# ── Ground disc ──────────────────────────────────────────────────────────
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(zone_color.r, zone_color.g, zone_color.b, 0.60)
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.emission_enabled = true
	disc_mat.emission = zone_color * 0.35
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = trigger_radius
	disc_mesh.bottom_radius = trigger_radius
	disc_mesh.height = 0.06
	disc_mesh.radial_segments = 32
	disc_mesh.rings = 1
	disc_mesh.material = disc_mat

	var disc := MeshInstance3D.new()
	disc.mesh = disc_mesh
	disc.position.y = 0.04
	add_child(disc)

	# ── Vertical beacon beam (faint transparent column) ───────────────────────
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(zone_color.r, zone_color.g, zone_color.b, 0.18)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.emission_enabled = true
	beam_mat.emission = zone_color * 0.25
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.2
	beam_mesh.bottom_radius = 0.2
	beam_mesh.height = 9.0
	beam_mesh.radial_segments = 8
	beam_mesh.material = beam_mat

	var beam := MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.position.y = 4.5
	add_child(beam)

	# ── Floating label (always faces camera) ──────────────────────────────────
	var label := Label3D.new()
	label.text = zone_label
	label.position = Vector3(0.0, 7.5, 0.0)
	label.font_size = 72
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = zone_color
	label.outline_size = 12
	add_child(label)

	# ── Trigger collision ─────────────────────────────────────────────────────
	var shape := CylinderShape3D.new()
	shape.radius = trigger_radius
	shape.height = 4.0

	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 2.0
	add_child(col)

	# ── Gentle breathing pulse on the disc ────────────────────────────────────
	var tween := create_tween().set_loops()
	tween.tween_property(disc, "scale", Vector3(1.05, 1.0, 1.05), 1.1) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(disc, "scale", Vector3(1.0, 1.0, 1.0), 1.1) \
		.set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		car_entered.emit()

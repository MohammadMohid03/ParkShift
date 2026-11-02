extends RefCounted
## Shared procedural art. No external models, textures or plugins.

static var materials: Dictionary = {}
static var meshes: Dictionary = {}

static func material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var key := str(color) + str(roughness)
	if materials.has(key):
		return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materials[key] = mat
	return mat

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var key := "box" + str(size)
	if not meshes.has(key):
		var generated := BoxMesh.new()
		generated.size = size
		if meshes.size() > 512:
			meshes.clear()
		meshes[key] = generated
	var mesh: BoxMesh = meshes[key]
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = at
	parent.add_child(instance)
	return instance

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, sides: int = 12) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = at
	parent.add_child(instance)
	return instance

static func collider(parent: Node3D, at: Vector3, size: Vector3, hazard: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	if hazard:
		body.add_to_group("hazards")
	return body

static func bevel_box(parent: Node3D, at: Vector3, size: Vector3, color: Color, bevel: float = 0.12) -> MeshInstance3D:
	var x: float = size.x * 0.5
	var z: float = size.z * 0.5
	var b: float = minf(bevel, minf(x, z) * 0.5)
	var ring: Array[Vector2] = [Vector2(-x + b, -z), Vector2(x - b, -z), Vector2(x, -z + b), Vector2(x, z - b), Vector2(x - b, z), Vector2(-x + b, z), Vector2(-x, z - b), Vector2(-x, -z + b)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(8):
		var a: Vector2 = ring[index]
		var c: Vector2 = ring[(index + 1) % 8]
		var lo_a := Vector3(a.x, -size.y * 0.5, a.y)
		var lo_c := Vector3(c.x, -size.y * 0.5, c.y)
		var hi_a := Vector3(a.x, size.y * 0.5, a.y)
		var hi_c := Vector3(c.x, size.y * 0.5, c.y)
		for vertex in [lo_a, hi_c, hi_a, lo_a, lo_c, hi_c, Vector3(0, size.y * 0.5, 0), hi_a, hi_c, Vector3(0, -size.y * 0.5, 0), lo_c, lo_a]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = material(color, 0.5)
	instance.position = at
	parent.add_child(instance)
	return instance

static func car_model(parent: Node3D, paint: Color, style: int = 0) -> Node3D:
	var model := Node3D.new()
	parent.add_child(model)
	var body := bevel_box(model, Vector3(0, 0.56, 0), Vector3(1.65, 0.48, 3.35), paint, 0.2)
	var lacquer := material(paint, 0.27).duplicate() as StandardMaterial3D
	lacquer.metallic = 0.55
	lacquer.clearcoat_enabled = true
	lacquer.clearcoat = 0.65
	lacquer.clearcoat_roughness = 0.2
	body.material_override = lacquer
	box(model, Vector3(0, 0.30, 0), Vector3(1.42, 0.15, 2.8), Color("233b42"))
	var cabin_length: float = [1.65, 2.2, 1.4][style]
	var cabin_height: float = 0.40 if style == 2 else 0.57
	_cabin(model, cabin_length, cabin_height)
	var roof := bevel_box(model, Vector3(0, 0.83 + cabin_height, 0.32), Vector3(1.13, 0.065, cabin_length * 0.59), paint, 0.1)
	roof.material_override = lacquer
	box(model, Vector3(0, 0.80, -1.16), Vector3(1.18, 0.025, 0.62), paint.lightened(0.06))
	for side in [-1.0, 1.0]:
		for z in [-1.05, 1.06]:
			var pivot := Node3D.new()
			pivot.name = "WheelPivot%s%s" % [str(side), str(z)]
			pivot.position = Vector3(side * 0.81, 0.35, z)
			model.add_child(pivot)
			var roll := Node3D.new()
			roll.name = "Roll"
			pivot.add_child(roll)
			var wheel := cylinder(roll, Vector3.ZERO, 0.35, 0.22, Color("14202b"), 16)
			wheel.rotation.z = PI / 2.0
			var hub := cylinder(roll, Vector3(side * 0.125, 0, 0), 0.23, 0.025, Color("4c5c6b"), 12)
			hub.rotation.z = PI / 2.0
			for spoke in range(5):
				var angle := TAU * spoke / 5
				var arm := box(roll, Vector3(side * 0.143, sin(angle) * 0.1, cos(angle) * 0.1), Vector3(0.022, 0.055, 0.22), Color("d4e0e6"))
				arm.rotation.x = -angle
		var lamp := box(model, Vector3(side * 0.52, 0.64, -1.686), Vector3(0.43, 0.09, 0.035), Color("d8f3ff"))
		lamp.material_override = _lamp(Color("c4e9ff"))
		var tail := box(model, Vector3(side * 0.52, 0.64, 1.686), Vector3(0.43, 0.08, 0.035), Color("e45038"))
		tail.name = "TailLight" + str(side)
		tail.material_override = _lamp(Color("e45038"))
		box(model, Vector3(side * 0.89, 0.92, -0.46), Vector3(0.18, 0.12, 0.23), paint)
		box(model, Vector3(side * 0.673, 1.0, 0.12), Vector3(0.03, 0.45, 0.08), paint)
		box(model, Vector3(side * 0.832, 0.39, 0), Vector3(0.045, 0.08, 2.4), Color("223449"))
		box(model, Vector3(side * 0.837, 0.74, 0.35), Vector3(0.02, 0.035, 0.18), Color("d3dee4"))
	box(model, Vector3(0, 0.48, -1.72), Vector3(0.7, 0.17, 0.02), Color("142234"))
	for x in [-0.22, 0.0, 0.22]:
		box(model, Vector3(x, 0.48, -1.733), Vector3(0.025, 0.13, 0.015), Color("8a9daa"))
	box(model, Vector3(0, 0.39, -1.70), Vector3(1.20, 0.13, 0.055), Color("3f5259"))
	box(model, Vector3(0, 0.40, 1.70), Vector3(1.20, 0.12, 0.055), Color("3f5259"))
	box(model, Vector3(0, 0.58, 1.719), Vector3(0.4, 0.12, 0.02), Color("f4eee0"))
	if style == 1:
		for x in [-0.43, 0.43]:
			box(model, Vector3(x, 1.33, 0.3), Vector3(0.045, 0.06, 1.4), Color("52676a"))
	elif style == 2:
		box(model, Vector3(0, 0.91, 1.42), Vector3(1.6, 0.09, 0.3), paint.darkened(0.18))
		box(model, Vector3(0, 0.806, -1.16), Vector3(0.25, 0.012, 0.65), Color("f7e9b9"))
	return model

static func _lamp(color: Color) -> StandardMaterial3D:
	var mat := material(color, 0.25).duplicate() as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.45
	return mat

static func _cabin(parent: Node3D, length: float, height: float) -> void:
	var lower: Array[Vector3] = [Vector3(-0.67, 0.8, -length * 0.5 + 0.2), Vector3(0.67, 0.8, -length * 0.5 + 0.2), Vector3(0.67, 0.8, length * 0.5 + 0.2), Vector3(-0.67, 0.8, length * 0.5 + 0.2)]
	var upper: Array[Vector3] = [Vector3(-0.56, 0.8 + height, -length * 0.28 + 0.32), Vector3(0.56, 0.8 + height, -length * 0.28 + 0.32), Vector3(0.56, 0.8 + height, length * 0.28 + 0.32), Vector3(-0.56, 0.8 + height, length * 0.28 + 0.32)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(4):
		var next := (i + 1) % 4
		for point in [lower[i], upper[next], upper[i], lower[i], lower[next], upper[next]]:
			surface.add_vertex(point)
	surface.generate_normals()
	var glass := MeshInstance3D.new()
	glass.mesh = surface.commit()
	var mat := material(Color("172f46"), 0.16).duplicate() as StandardMaterial3D
	mat.metallic = 0.35
	glass.material_override = mat
	parent.add_child(glass)

static func tree(parent: Node3D, at: Vector3, scale_factor: float = 1.0) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	root.scale = Vector3.ONE * scale_factor
	cylinder(root, Vector3(0, 0.75, 0), 0.14, 1.5, Color("82765a"), 7)
	var crown := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.15
	mesh.height = 2.3
	mesh.radial_segments = 8
	mesh.rings = 4
	crown.mesh = mesh
	crown.material_override = material(Color("718f72"))
	crown.position.y = 2.1
	root.add_child(crown)

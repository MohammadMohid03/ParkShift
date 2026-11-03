extends RefCounted
## Reusable, original architectural dressing. No downloaded assets or extra lights.
const Art = preload("res://scripts/geometry.gd")
static var surfaces: Dictionary = {}

static func surface(kind: String) -> StandardMaterial3D:
	if surfaces.has(kind):
		return surfaces[kind]
	var colors := {"concrete": Color("999b98"), "asphalt": Color("343b40"), "epoxy": Color("404950"), "metal": Color("39444c")}
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.9 if kind == "asphalt" else (0.38 if kind == "epoxy" else 0.78)
	mat.metallic = 0.65 if kind == "metal" else 0.0
	var noise := FastNoiseLite.new()
	noise.seed = 731
	noise.frequency = 0.24 if kind == "asphalt" else 0.18
	noise.fractal_octaves = 4
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.noise = noise
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([colors[kind].darkened(0.07), colors[kind].lightened(0.035)])
	texture.color_ramp = ramp
	mat.albedo_texture = texture
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * (1.4 if kind == "asphalt" else 0.35)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	surfaces[kind] = mat
	return mat

static func block(parent: Node3D, at: Vector3, size: Vector3, kind: String) -> MeshInstance3D:
	var mesh := Art.box(parent, at, size, Color.WHITE)
	mesh.material_override = surface(kind)
	return mesh

static func sign_at(parent: Node3D, text: String, at: Vector3, size: int = 54) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.009
	label.position = at
	label.outline_size = 0
	label.modulate = Color("e5e7dd")
	parent.add_child(label)

static func courtyard(parent: Node3D) -> void:
	# Everything tall is beyond the existing +/-15 m driving boundary.
	block(parent, Vector3(0, -0.55, 0), Vector3(100, 0.2, 100), "concrete")
	block(parent, Vector3(0, 3.0, -18), Vector3(34, 6, 0.7), "concrete")
	for x in [-11.0, 0.0, 11.0]:
		block(parent, Vector3(x, 1.65, -17.55), Vector3(7.8, 3.3, 0.13), "metal")
		for row in range(11):
			Art.box(parent, Vector3(x, 0.18 + row * 0.28, -17.46), Vector3(7.7, 0.025, 0.025), Color("19252d"))
		Art.box(parent, Vector3(x, 3.5, -17.1), Vector3(8.4, 0.16, 1.6), Color("26333c"))
		var fixture := Art.box(parent, Vector3(x, 3.39, -16.7), Vector3(2.0, 0.025, 0.16), Color("e8e7dc"))
		fixture.material_override = Art._lamp(Color("e8e7dc"))
		sign_at(parent, "P  /  " + ("ARRIVALS" if x == 0 else "PARKING"), Vector3(x, 4.45, -17.59))
	for side in [-1.0, 1.0]:
		block(parent, Vector3(side * 16.5, 1.4, 0), Vector3(0.6, 2.8, 34), "concrete")
		for z in [-13.0, -5.0, 3.0, 11.0]:
			block(parent, Vector3(side * 16.0, 2.25, z), Vector3(0.65, 4.5, 0.65), "concrete")
			Art.box(parent, Vector3(side * 15.98, 0.65, z), Vector3(0.68, 0.7, 0.68), Color("27333e"))
			Art.box(parent, Vector3(side * 15.98, 1.05, z), Vector3(0.69, 0.14, 0.69), Color("dfaa58"))
		block(parent, Vector3(side * 16, 4.45, 0), Vector3(0.75, 0.35, 34), "concrete")
	for x in [-15.0, -5.1, 5.1, 15.0]:
		block(parent, Vector3(x, 2.9, -17.3), Vector3(0.65, 5.8, 0.7), "concrete")
		Art.box(parent, Vector3(x, 0.65, -16.92), Vector3(0.66, 1.3, 0.025), Color("26333c"))
		Art.box(parent, Vector3(x, 1.35, -16.9), Vector3(0.66, 0.12, 0.03), Color("ef9149"))

static func finish_yard(parent: Node3D) -> void:
	for child in parent.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var size: Vector3 = child.mesh.size
			if size.x >= 30 and size.z >= 30 and child.position.y > -0.2:
				child.material_override = surface("asphalt")
			elif child.position.y > 0 and size.y > 0.25 and (size.x > 20 or size.z > 20):
				child.material_override = surface("concrete")
	for x in [-7.0, 7.0]:
		for edge in [-1.55, 1.55]:
			Art.box(parent, Vector3(x + edge, 0.016, -5), Vector3(0.09, 0.01, 5.6), Color("cfcec1"))
		Art.box(parent, Vector3(x, 0.016, -7.8), Vector3(3.2, 0.01, 0.09), Color("cfcec1"))
		# Stops are inside the existing parked-car footprint/collision, not new hazards.
		block(parent, Vector3(x, 0.08, -6.8), Vector3(1.65, 0.16, 0.22), "concrete")
		for dx in [-0.55, 0.55]:
			Art.box(parent, Vector3(x + dx, 0.165, -6.8), Vector3(0.22, 0.012, 0.23), Color("dfb467"))
	for side in [-1.0, 1.0]:
		for z in [-9.0, 1.0, 11.0]:
			Art.box(parent, Vector3(side * 14.45, 0.007, z), Vector3(0.38, 0.012, 2.0), Color("202830"))
			for slit in range(12):
				Art.box(parent, Vector3(side * 14.45, 0.016, z - 0.88 + slit * 0.16), Vector3(0.34, 0.008, 0.035), Color("768087"))
	for x in [-10.5, -3.5, 3.5, 10.5]:
		Art.box(parent, Vector3(x, 0.006, 0), Vector3(0.015, 0.003, 29), Color("222a30"))

static func district(parent: Node3D, district_id: int, extent: float) -> void:
	# Perimeter architecture stays beyond the authored collision boundary.
	var accents := [Color("dfa65d"), Color("96b0bb"), Color("bdc8cc"), Color("e5b667"), Color("ef9149")]
	var accent: Color = accents[district_id]
	# Shallow perimeter service walks separate the yard from the architecture.
	# They sit outside the authored route; no invisible new driving obstacles.
	for side in [-1.0, 1.0]:
		block(parent, Vector3(side * (extent - 1.1), 0.04, 0), Vector3(1.4, 0.08, extent * 2 - 2), "concrete")
		for z in range(-int(extent) + 4, int(extent) - 3, 8):
			Art.box(parent, Vector3(side * (extent - 1.85), 0.025, z), Vector3(0.12, 0.025, 2.0), accent)
	# District-specific industrial infill, all beyond the collision boundary.
	if district_id in [3, 4]:
		for x in range(-int(extent) + 4, int(extent) - 3, 8):
			block(parent, Vector3(x, 1.7, -extent - 1.9), Vector3(5.4, 3.4, 0.15), "metal")
			for row in range(4):
				Art.box(parent, Vector3(x, 0.55 + row * 0.72, -extent - 1.79), Vector3(5.2, 0.035, 0.02), accent.darkened(0.2))
	elif district_id == 1:
		for side in [-1.0, 1.0]:
			block(parent, Vector3(side * (extent + 0.8), 1.3, 8), Vector3(0.3, 2.6, 1.2), "metal")
			sign_at(parent, "P / CITY", Vector3(side * (extent + 0.8), 2.9, 8), 42)
	if district_id != 2:
		var shell := Node3D.new()
		parent.add_child(shell)
		courtyard(shell)
		shell.scale = Vector3(extent / 15.0, 1, extent / 15.0)
	else:
		block(parent, Vector3(0, -9, 0), Vector3(140, 0.2, 140), "concrete")
	for side in [-1.0, 1.0]:
		for z in range(-12, 13, 6):
			var x: float = side * (extent + 0.7)
			block(parent, Vector3(x, 1.6, z), Vector3(0.48, 3.2, 0.48), "concrete")
			Art.box(parent, Vector3(x, 0.8, z), Vector3(0.5, 0.18, 0.5), accent)
			if district_id in [1, 2]:
				var height: float = 6.0 + absf(z) * 0.4
				var base: float = -9.0 if district_id == 2 else 0.0
				block(parent, Vector3(side * (extent + 8), base + height / 2, z), Vector3(6, height, 5), "concrete")
				for floor_index in range(1, int(height / 1.5)):
					Art.box(parent, Vector3(side * (extent + 4.98), base + floor_index * 1.5, z), Vector3(0.025, 0.8, 4.2), Color("425763"))
			var fixture := Art.box(parent, Vector3(x, 3.23, z), Vector3(0.8, 0.06, 0.24), Color.WHITE)
			fixture.material_override = Art._lamp(Color("e0e5df"))
		block(parent, Vector3(side * (extent + 0.7), 1.2, 0), Vector3(0.12, 0.12, extent * 2), "metal")
		Art.box(parent, Vector3(side * (extent - 0.6), 0.015, 0), Vector3(0.1, 0.01, extent * 2 - 1.2), accent)
		for z in [-10.0, 0.0, 10.0]:
			Art.box(parent, Vector3(side * (extent - 0.4), 0.018, z), Vector3(0.3, 0.01, 1.4), Color("242b31"))
	var rear: float = -extent - 1.0
	block(parent, Vector3(0, 3.1, rear), Vector3(14, 1.1, 0.18), "metal")
	sign_at(parent, preload("res://scripts/campaign_catalog.gd").DISTRICTS[district_id].to_upper(), Vector3(0, 3.1, rear + 0.11), 60)
	for mesh in parent.get_children():
		if mesh is MeshInstance3D and mesh.mesh is BoxMesh:
			var dimensions: Vector3 = mesh.mesh.size
			if dimensions.y > 0.25 and mesh.position.y > 0 and (dimensions.x > 20 or dimensions.z > 20):
				mesh.material_override = surface("concrete")

static func showroom(stage: Node3D) -> void:
	for child in stage.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var size: Vector3 = child.mesh.size
			if size.x > 30:
				child.material_override = surface("epoxy")
			elif size.y > 4:
				child.material_override = surface("concrete")
	for x in [-1.6, 9.4]:
		block(stage, Vector3(x, 2.4, -4.5), Vector3(0.6, 4.8, 0.8), "concrete")
		Art.box(stage, Vector3(x, 0.75, -4.04), Vector3(0.62, 1.5, 0.05), Color("1b2b3b"))
		Art.box(stage, Vector3(x, 1.55, -4.02), Vector3(0.63, 0.12, 0.05), Color("ef9149"))
	block(stage, Vector3(3.8, 4.7, -4.5), Vector3(11.6, 0.35, 0.8), "metal")
	for x in [0.0, 2.0, 4.0, 6.0, 8.0]:
		Art.box(stage, Vector3(x, 2.1, -4.84), Vector3(0.014, 4.1, 0.008), Color("5e666a"))
	for x in [0.2, 3.8, 7.4]:
		var strip := Art.box(stage, Vector3(x, 4.43, -4.0), Vector3(2.5, 0.045, 0.16), Color.WHITE)
		strip.material_override = Art._lamp(Color("e3ebec"))
	for x in range(-6, 15, 3):
		Art.box(stage, Vector3(x, -0.092, 0), Vector3(0.015, 0.006, 25), Color("253039"))
	for z in range(-9, 16, 3):
		Art.box(stage, Vector3(3, -0.092, z), Vector3(25, 0.006, 0.015), Color("253039"))
	var ring := Art.cylinder(stage, Vector3(3.8, -0.035, 0), 3.76, 0.025, Color("b8bcbc"), 64)
	ring.material_override = Art.material(Color("89949d"), 0.3)
	sign_at(stage, "PARKSHIFT  /  MOTOR WORKS", Vector3(3.8, 1.7, -4.80), 28)

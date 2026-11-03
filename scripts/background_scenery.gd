extends RefCounted
## Deterministic background pockets, kept outside the swept driving corridor.
## Reuses local CC0 cars and original procedural props; no added lights/textures.
const Art = preload("res://scripts/geometry.gd")
const WorldArt = preload("res://scripts/automotive_world.gd")
const Vehicles = preload("res://scripts/vehicle_visual.gd")
const Materials = preload("res://scripts/environment_materials.gd")
const PAINTS := [Color("657b86"), Color("bbc2bf"), Color("803f38"), Color("364654")]

static func build(parent: Node3D, definition: Dictionary) -> void:
	var district: int = definition.district
	var extent: float = float(definition.arena) * 0.5
	var legacy: bool = definition.get("legacy_layout", false)
	var path: Array = [definition.start] + definition.route
	var pockets: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 17051 + int(definition.id) * 137
	# Cars and greenery suit public parking; freight and equipment suit workshops.
	var themes := [
		["car", "tree", "car", "container", "tree", "bench"],
		["car", "tree", "bench", "car", "tree", "container"],
		["car", "planter", "equipment", "car", "planter", "bench"],
		["container", "car", "tree", "equipment", "car", "bench"],
		["car", "container", "tree", "car", "equipment", "bench"]
	]
	var count := 6 if legacy else 18
	for slot in range(count):
		var kind: String = themes[district][slot % 6]
		var radius: float = 3.6 if kind == "container" else (3.1 if kind == "car" else 2.1)
		var best := Vector3.ZERO
		var found := false
		var score := INF
		# Prefer scenery near the route, but reserve a generous clear buffer for
		# steering, the camera, the cone edges and both ends of the challenge.
		for attempt in range(100):
			var candidate := Vector3(rng.randf_range(-extent + radius + 0.8, extent - radius - 0.8), 0, rng.randf_range(-extent + radius + 0.8, extent - radius - 0.8))
			var clearance := route_distance(candidate, path)
			if clearance < radius + (3.8 if legacy else 4.8):
				continue
			if flat_distance(candidate, definition.bay) < radius + 6.0 or flat_distance(candidate, definition.start) < radius + 5.0:
				continue
			var blocked := false
			for pocket in pockets:
				if flat_distance(candidate, pocket.at) < radius + pocket.radius + 1.2:
					blocked = true
			for block in definition.blocks:
				if flat_distance(candidate, block.at) < radius + Vector2(block.size.x, block.size.z).length() * 0.5 + 0.5:
					blocked = true
			for parked in definition.parked:
				if flat_distance(candidate, parked.at) < radius + 3.1:
					blocked = true
			for cone in definition.cones:
				if flat_distance(candidate, cone) < radius + 0.6:
					blocked = true
			if blocked:
				continue
			if clearance < score:
				best = candidate
				score = clearance
				found = true
		if not found:
			continue # Dense introductory layouts get fewer props, never a blocked route.
		pockets.append({"at": best, "radius": radius})
		var root := Node3D.new()
		root.name = "Background_%s_%02d" % [kind, slot]
		parent.add_child(root)
		root.position = best
		root.rotation.y = float(slot % 4) * PI * 0.5
		match kind:
			"car": parked_car(root, slot)
			"container": container(root, slot, district)
			"tree", "planter": planting(root, kind == "tree", slot)
			"equipment": equipment(root)
			"bench": bench(root)

static func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

static func route_distance(point: Vector3, path: Array) -> float:
	var nearest := INF
	for i in range(path.size() - 1):
		var a := Vector2(path[i].x, path[i].z)
		var b := Vector2(path[i + 1].x, path[i + 1].z)
		var p := Vector2(point.x, point.z)
		nearest = minf(nearest, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return nearest

static func parked_car(root: Node3D, variant: int) -> void:
	var id: String = ["metro", "touring", "sport"][(variant + int(variant / 3)) % 3]
	Vehicles.build(root, id, PAINTS[variant % PAINTS.size()])
	var size: Vector3 = preload("res://scripts/vehicle_profiles.gd").profile(id).size
	Art.collider(root, Vector3.UP * size.y * 0.5, size)
	for x in [-1.4, 1.4]:
		Art.box(root, Vector3(x, 0.015, 0), Vector3(0.07, 0.01, 5.5), Color("bebfb4"))
	Art.box(root, Vector3(0, 0.015, -2.75), Vector3(2.85, 0.01, 0.07), Color("bebfb4"))
	WorldArt.block(root, Vector3(0, 0.10, -2.65), Vector3(1.7, 0.20, 0.18), "concrete")

static func container(root: Node3D, variant: int, district: int = 4) -> void:
	# The original proxy is retained exactly; only the skin changes by district.
	Art.collider(root, Vector3(0, 1.25, 0), Vector3(2.48, 2.5, 6.08))
	var paint: Color = [Color("6e8c88"),Color("9d6953"),Color("adb3a6")][variant%3]
	var body := Art.box(root,Vector3(0,1.25,0),Vector3(2.4,2.5,6),Color.WHITE)
	body.material_override = Materials.surface("brick" if district==0 else "metal", Color("d4c3a2") if district==0 else paint)
	if district in [0,1,3]:
		for side in [-1.0,1.0]:
			for z in [-1.6,1.2]:
				var frame := Art.box(root,Vector3(side*1.22,1.65,z),Vector3(0.04,1.1,1.6),Color("d0d5ce"))
				var glass := Art.box(root,Vector3(side*1.25,1.65,z),Vector3(0.025,0.94,1.42),Color.WHITE)
				glass.material_override = Materials.surface("glass")
				glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Art.box(root,Vector3(0,1.1,3.02),Vector3(1.0,2.2,0.04),Color("31494a"))
		Art.box(root,Vector3(0.32,1.0,3.05),Vector3(0.06,0.08,0.03),Color("b1b6ad"))
		WorldArt.sign_at(root,["OFFICE","PAY HERE","","SERVICE"][district],Vector3(0,2.3,3.06),28)
		Art.box(root,Vector3(0,2.58,0),Vector3(2.6,0.16,6.2),Color("485957"))
	elif district==2:
		# Roof equipment enclosure: same visible volume and original collision.
		for side in [-1.0,1.0]:
			for row in range(9):
				Art.box(root,Vector3(side*1.22,0.3+row*0.24,0),Vector3(0.035,0.10,5.6),Color("839393"))
		for z in [-1.5,1.5]:
			Art.cylinder(root,Vector3(0,2.53,z),0.82,0.06,Color("263738"),20)
			for spoke in range(5):
				var angle := spoke*TAU/5
				var blade := Art.box(root,Vector3(cos(angle)*0.35,2.57,z+sin(angle)*0.35),Vector3(0.75,0.02,0.15),Color("8a9895"))
				blade.rotation.y = -angle
	else:
		for side in [-1.0,1.0]:
			for z in range(15):
				Art.box(root,Vector3(side*1.22,1.25,-2.8+z*0.4),Vector3(0.04,2.25,0.055),paint.lightened(0.08))
			for y in [0.12,2.4]:
				Art.box(root,Vector3(side*1.23,y,0),Vector3(0.06,0.12,6.06),paint.darkened(0.2))
		for x in [-0.6,0.6]:
			Art.box(root,Vector3(x,1.25,3.015),Vector3(1.14,2.25,0.035),paint.darkened(0.1))
			WorldArt.block(root,Vector3(x+0.3,1.25,3.06),Vector3(0.045,2.12,0.045),"metal")
		WorldArt.sign_at(root,"PS  /  %04d" % (variant+103),Vector3(0,2.0,3.07),25)

static func planting(root: Node3D, tree: bool, variant: int) -> void:
	WorldArt.block(root, Vector3(0, 0.24, 0), Vector3(2.65, 0.48, 2.65), "concrete")
	Art.box(root, Vector3(0, 0.49, 0), Vector3(2.35, 0.025, 2.35), Color("474737"))
	Art.collider(root, Vector3(0, 0.24, 0), Vector3(2.65, 0.48, 2.65))
	if tree:
		Art.cylinder(root, Vector3(0, 1.35, 0), 0.15, 1.8, Color("655343"), 8)
		Art.collider(root, Vector3(0, 1.3, 0), Vector3(0.32, 1.7, 0.32))
		for side in [-1.0,1.0]:
			var branch := Art.cylinder(root,Vector3(side*0.25,1.9,0),0.07,0.9,Color("655343"),7)
			branch.rotation.z = -side*0.6
	for i in range(5):
		var angle := float(i) * TAU / 5.0 + variant
		var crown := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.86 if tree else 0.55
		mesh.height = mesh.radius * 1.6
		mesh.radial_segments = 16
		mesh.rings = 8
		crown.mesh = mesh
		crown.position = Vector3(cos(angle) * 0.55, (2.5 if tree else 0.85) + (i % 2) * 0.26, sin(angle) * 0.55)
		crown.scale = Vector3(1.0 + (i%2)*0.13, 0.9+(i%3)*0.12, 1.0)
		crown.material_override = Art.material(Color("4b684b") if i % 2 else Color("66805a"))
		root.add_child(crown)

static func equipment(root: Node3D) -> void:
	WorldArt.block(root, Vector3(0, 0.12, 0), Vector3(2.5, 0.24, 2.3), "concrete")
	WorldArt.block(root, Vector3(0, 0.8, 0), Vector3(2.15, 1.36, 1.8), "metal")
	Art.collider(root, Vector3(0, 0.8, 0), Vector3(2.5, 1.6, 2.3))
	for i in range(9):
		Art.box(root, Vector3(0, 0.35 + i * 0.12, 0.91), Vector3(1.9, 0.045, 0.025), Color("87908f"))
	for x in [-0.55, 0.55]:
		Art.cylinder(root, Vector3(x, 1.51, 0), 0.39, 0.05, Color("18262e"), 16)

static func bench(root: Node3D) -> void:
	for x in [-0.85, 0.85]:
		WorldArt.block(root, Vector3(x, 0.28, 0), Vector3(0.14, 0.56, 0.65), "metal")
	for z in [-0.22, 0.0, 0.22]:
		Art.box(root, Vector3(0, 0.57, z), Vector3(2.3, 0.09, 0.18), Color("8d7655"))
	for y in [0.82, 1.04]:
		Art.box(root, Vector3(0, y, -0.35), Vector3(2.3, 0.17, 0.08), Color("8d7655"))
	Art.collider(root, Vector3(0, 0.55, 0), Vector3(2.3, 1.1, 0.8))
	WorldArt.block(root, Vector3(1.55, 0.45, 0), Vector3(0.5, 0.9, 0.5), "metal")
	Art.collider(root, Vector3(1.55, 0.45, 0), Vector3(0.5, 0.9, 0.5))
	Art.box(root, Vector3(1.55, 0.92, 0), Vector3(0.52, 0.045, 0.52), Color("192830"))

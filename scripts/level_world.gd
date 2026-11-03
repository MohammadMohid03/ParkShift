extends Node3D

const Art = preload("res://scripts/geometry.gd")
const BayScene: PackedScene = preload("res://scenes/parking_bay.tscn")
var bay: Node3D

func build(definition: Dictionary, index: int) -> void:
	Art.box(self, Vector3(0, -0.36, 0), Vector3(32, 0.7, 32), Color("d7cdb7"))
	Art.box(self, Vector3(0, -0.065, 0), Vector3(30, 0.12, 30), Color("40565b"))
	Art.collider(self, Vector3(0, -0.20, 0), Vector3(32, 0.4, 32), false)
	for x in [-15.0, 15.0]:
		Art.box(self, Vector3(x, 0.18, 0), Vector3(0.3, 0.35, 30), Color("f2e4c7"))
		Art.collider(self, Vector3(x, 0.5, 0), Vector3(0.3, 1.0, 30))
	for z in [-15.0, 15.0]:
		Art.box(self, Vector3(0, 0.18, z), Vector3(30.3, 0.35, 0.3), Color("f2e4c7"))
		Art.collider(self, Vector3(0, 0.5, z), Vector3(30.3, 1.0, 0.3))
	# Road seams and painted edge markings.
	for z in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		Art.box(self, Vector3(0, 0.003, z), Vector3(25.7, 0.003, 0.02), Color("465e61"))
	for x in [-11.8, 11.8]:
		for z in range(-10, 11, 3):
			Art.box(self, Vector3(x, 0.02, z), Vector3(0.065, 0.012, 1.5), Color("b8bca9"))
	for block in definition.blocks:
		var at: Vector3 = block.at
		var dimensions: Vector3 = block.size
		Art.box(self, at + Vector3(0, dimensions.y * 0.5, 0), dimensions, Color("d9c4a1"))
		Art.collider(self, at + Vector3(0, dimensions.y * 0.5, 0), dimensions)
		if block.kind == "planter":
			Art.box(self, at + Vector3(0, dimensions.y + 0.025, 0), Vector3(dimensions.x - 0.2, 0.05, dimensions.z - 0.2), Color("788464"))
			Art.tree(self, at + Vector3(0, dimensions.y, 0), 0.8)
	var paint_colors: Array[Color] = [Color("bbc4c3"), Color("e7b28f"), Color("889cab"), Color("c0b7a0")]
	var parked_index: int = 0
	for parked in definition.parked:
		var root := Node3D.new()
		add_child(root)
		root.position = parked.at
		root.rotation.y = float(parked.yaw)
		var model := preload("res://scripts/vehicle_visual.gd").build(root, "shelby_2010" if index == 0 else "metro", paint_colors[parked_index % paint_colors.size()])
		if index == 0:
			# Uniform scale stays within the original parked-car collision footprint.
			model.scale = Vector3.ONE * 0.915
		Art.collider(root, Vector3(0, 0.65, 0), Vector3(1.82, 1.3, 4.26))
		parked_index += 1
	bay = BayScene.instantiate()
	add_child(bay)
	bay.configure(definition.bay, definition.bay_yaw, definition.bay_size, definition.reverse)
	_build_surroundings(index)

func _build_surroundings(index: int) -> void:
	Art.box(self, Vector3(0, -0.9, 0), Vector3(200, 0.1, 200), Color("b6c9c0"))
	for x in [-17.0, 17.0]:
		for z in [-9.0, -1.0, 7.0]:
			Art.box(self, Vector3(x, 0.1, z), Vector3(3, 0.3, 3), Color("c7b991"))
			Art.tree(self, Vector3(x, 0.25, z), 1.05)
	for x in [-10.0, -2.0, 7.0]:
		var height: float = 3.5 + fmod(absf(x), 3.0)
		Art.box(self, Vector3(x, height * 0.5, -17), Vector3(6.5, height, 5), Color("e6d5b7"))
		Art.box(self, Vector3(x, height + 0.08, -17), Vector3(6.7, 0.16, 5.2), Color("f3e6ca"))
		for offset in [-1.8, 0.0, 1.8]:
			Art.box(self, Vector3(x + offset, height * 0.6, -14.48), Vector3(1.0, 1.2, 0.035), Color("5d7b7c"))
		Art.box(self, Vector3(x, 1.5, -14.1), Vector3(5.8, 0.12, 1.0), Color("b87d62") if index % 2 == 0 else Color("6d978c"))
	for x in [-10.0, 10.0]:
		Art.cylinder(self, Vector3(x, 1.8, -12.6), 0.07, 3.6, Color("52696a"), 8)
		Art.box(self, Vector3(x, 3.58, -12.6), Vector3(0.7, 0.13, 0.5), Color("f6e3b6"))
	var sign := Label3D.new()
	sign.text = "P A R K S H I F T"
	sign.font_size = 60
	sign.pixel_size = 0.014
	sign.position = Vector3(0, 0.05, 10.2)
	sign.rotation.x = -PI / 2.0
	sign.modulate = Color("cad2bd")
	sign.outline_size = 0
	add_child(sign)

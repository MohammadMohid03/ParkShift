extends Node3D
## One flat practice yard, in metres. Markings have no gameplay validation.
const Art = preload("res://scripts/geometry.gd")

func _ready() -> void:
	Art.box(self, Vector3(0, -0.35, 0), Vector3(100, 0.4, 100), Color("bccbb7"))
	_solid("Asphalt", Vector3(0, -0.15, 0), Vector3(28, 0.3, 34), Color("56676a"), false)
	_solid("WestWall", Vector3(-14, 0.55, 0), Vector3(0.45, 1.1, 34), Color("ded7c3"))
	_solid("EastWall", Vector3(14, 0.55, 0), Vector3(0.45, 1.1, 34), Color("ded7c3"))
	_solid("NorthWall", Vector3(0, 0.55, -17), Vector3(28, 1.1, 0.45), Color("ded7c3"))
	_solid("SouthWall", Vector3(0, 0.55, 17), Vector3(28, 1.1, 0.45), Color("ded7c3"))
	for x in [-10.0, -6.5, -3.0, 3.0, 6.5, 10.0]:
		for side in [-1.0, 1.0]:
			Art.box(self, Vector3(x + side * 1.5, 0.012, -11), Vector3(0.09, 0.02, 5.0), Color("f2e9d0"))
		Art.box(self, Vector3(x, 0.012, -13.5), Vector3(3.0, 0.02, 0.09), Color("f2e9d0"))
		_solid("WheelStop", Vector3(x, 0.12, -13), Vector3(1.7, 0.24, 0.32), Color("d2ae65"))
	for index in range(3):
		var position_in_yard := Vector3([-10.0, -3.0, 6.5][index], 0, -11)
		var parked := Node3D.new()
		parked.name = "ParkedCar%d" % index
		add_child(parked)
		parked.position = position_in_yard
		Art.car_model(parked, [Color("bf7965"), Color("cbb98a"), Color("7d9ca3")][index])
		Art.collider(parked, Vector3(0, 0.65, 0), Vector3(1.9, 1.3, 3.5))
	_solid("Island", Vector3(-6, 0.28, 1), Vector3(2.4, 0.56, 6), Color("d5cfbb"))
	Art.box(self, Vector3(-6, 0.57, 1), Vector3(2.0, 0.04, 5.6), Color("8eaa85"))
	for z in [-0.5, 2.5]:
		Art.tree(self, Vector3(-6, 0.6, z), 0.85)
	_solid("Barrier", Vector3(7, 0.4, 2), Vector3(4, 0.8, 0.45), Color("dfb564"))
	for x in [5.5, 6.5, 7.5, 8.5]:
		Art.box(self, Vector3(x, 0.65, 1.767), Vector3(0.42, 0.21, 0.025), Color("384b50"))
	for x in [-10.0, 10.0]:
		for z in [7.0, 10.0]:
			_solid("Bollard", Vector3(x, 0.45, z), Vector3(0.35, 0.9, 0.35), Color("d4a859"))
	for z in range(-6, 14, 3):
		Art.box(self, Vector3(0, 0.012, z), Vector3(0.08, 0.02, 1.1), Color("d6d8c9"))
	for x in [-17.0, 17.0]:
		for z in [-12.0, -3.0, 7.0]:
			Art.tree(self, Vector3(x, -0.15, z), 1.3)

func _solid(label: String, at: Vector3, size: Vector3, color: Color, hazard: bool = true) -> void:
	var body := Art.collider(self, at, size, hazard)
	body.name = label
	Art.box(body, Vector3.ZERO, size, color)

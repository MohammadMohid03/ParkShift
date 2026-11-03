extends RefCounted
## District road finishes share bounded material and texture caches.
static var floors: Dictionary = {}
static func floor_material(district: int) -> StandardMaterial3D:
	if floors.has(district): return floors[district]
	var surfaces = preload("res://scripts/environment_materials.gd")
	var mat: StandardMaterial3D
	match district:
		0: mat = surfaces.surface("asphalt", Color("e8e2d4"))
		1: mat = surfaces.surface("asphalt", Color("929ba4"))
		2: mat = surfaces.surface("concrete", Color("a0a9af"))
		3: mat = surfaces.surface("concrete", Color("808b92"))
		_: mat = surfaces.surface("asphalt", Color("c5c5cb"))
	floors[district] = mat
	return mat

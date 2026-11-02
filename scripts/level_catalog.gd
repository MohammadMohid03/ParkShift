extends RefCounted
## Layout data is independent from driving, rewards and presentation.

const LEVELS: Array[Dictionary] = [
	{"name": "FIRST LIGHT", "place": "01 / THE COURTYARD", "lesson": "Drive straight into the mint bay. Stop and hold your position.",
	"start": Vector3(0, 0.05, 7.5), "yaw": 0.0, "bay": Vector3(0, 0, -5.5), "bay_yaw": 0.0,
	"bay_size": Vector2(3.2, 5.2), "par": 25.0, "reverse": false,
	"blocks": [], "parked": [{"at": Vector3(-7, 0, -5), "yaw": 0.0}, {"at": Vector3(7, 0, -5), "yaw": 0.0}]},
	{"name": "THE RIGHT TURN", "place": "02 / ARCADE CORNER", "lesson": "Take the outside lane, then turn right into the bay.",
	"start": Vector3(-8, 0.05, 7), "yaw": 0.0, "bay": Vector3(6, 0, -6), "bay_yaw": -PI / 2.0,
	"bay_size": Vector2(3.2, 5.2), "par": 40.0, "reverse": false,
	"blocks": [{"at": Vector3(0, 0, 1.5), "size": Vector3(10, 0.9, 3), "kind": "planter"}],
	"parked": [{"at": Vector3(6, 0, -1), "yaw": -PI / 2.0}]},
	{"name": "THREAD THE LINE", "place": "03 / MARKET ROW", "lesson": "Line up before entering the narrow aisle. Small corrections work best.",
	"start": Vector3(7, 0.05, 7), "yaw": PI / 2.0, "bay": Vector3(0, 0, -6), "bay_yaw": 0.0,
	"bay_size": Vector2(2.7, 4.9), "par": 45.0, "reverse": false,
	"blocks": [],
	"parked": [{"at": Vector3(-3.3, 0, -6), "yaw": 0.0}, {"at": Vector3(3.3, 0, -6), "yaw": PI},
		{"at": Vector3(-3.3, 0, -1), "yaw": 0.0}, {"at": Vector3(3.3, 0, -1), "yaw": PI}]},
	{"name": "LOOK BACK", "place": "04 / REVERSE STUDIO", "lesson": "Hold REVERSE to back into the bay. Keep the nose pointing toward the arrow.",
	"start": Vector3(0, 0.05, -8), "yaw": 0.0, "bay": Vector3(0, 0, -0.5), "bay_yaw": 0.0,
	"bay_size": Vector2(2.9, 5.0), "par": 35.0, "reverse": true,
	"blocks": [{"at": Vector3(0, 0, 4.5), "size": Vector3(10, 0.6, 0.5), "kind": "curb"}],
	"parked": [{"at": Vector3(-3.3, 0, -0.5), "yaw": 0.0}, {"at": Vector3(3.3, 0, -0.5), "yaw": 0.0}]},
	{"name": "GOLDEN HOUR", "place": "05 / THE TERRACE", "lesson": "Go around the long garden, then ease into the final tight space.",
	"start": Vector3(-8, 0.05, 7), "yaw": 0.0, "bay": Vector3(7, 0, -6.5), "bay_yaw": -PI / 2.0,
	"bay_size": Vector2(2.65, 4.8), "par": 55.0, "reverse": false,
	"blocks": [{"at": Vector3(-2.5, 0, 1.5), "size": Vector3(3, 0.9, 10), "kind": "planter"},
		{"at": Vector3(3, 0, 5), "size": Vector3(5, 0.6, 1.6), "kind": "planter"}],
	"parked": [{"at": Vector3(7, 0, -3.2), "yaw": -PI / 2.0}, {"at": Vector3(7, 0, -9.6), "yaw": -PI / 2.0}]}
]

static var CARS: Array[Dictionary] = _cars()

static func _cars() -> Array[Dictionary]:
	var entries: Array[Dictionary] = [
	{"id": "metro", "name": "METRO / HATCHBACK", "tag": "Small footprint. Big character.", "color": Color("a8ead5"), "price": 0, "shape": 0},
	{"id": "touring", "name": "TOURING / SUV", "tag": "The long way home.", "color": Color("ed9a77"), "price": 1500, "shape": 1},
	{"id": "sport", "name": "SPORT / SEDAN", "tag": "A little more attitude.", "color": Color("eecb73"), "price": 500, "shape": 2}
]

	for imported in preload("res://scripts/imported_car_catalog.gd").entries():
		entries.append({"id": imported.id, "name": imported.name, "tag": imported["class"], "color": Color.WHITE, "price": imported.price, "shape": 2, "trial": true})
	return entries

static func car(car_id: String) -> Dictionary:
	for entry in CARS:
		if entry.id == car_id:
			return entry
	return CARS[0]

static func stars_for(seconds: float, contacts: int, par: float) -> int:
	if contacts == 0 and seconds <= par:
		return 3
	if contacts <= 2 and seconds <= par * 1.75:
		return 2
	return 1

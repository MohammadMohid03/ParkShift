extends RefCounted
## User-supplied vehicles are local trials; source rights are recorded per entry.
static var cached: Array = []

static func entries() -> Array:
	if cached.is_empty() and FileAccess.file_exists("res://data/imported_cars.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/imported_cars.json"))
		if parsed is Array:
			cached = parsed
	return cached

static func find(id: String) -> Dictionary:
	for entry in entries():
		if entry.id == id:
			return entry
	return {}

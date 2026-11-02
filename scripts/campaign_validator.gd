extends RefCounted
## Raw JSON schema. Unknown authoring metadata is allowed.
const COUNT := 100
const MAX_COORDINATE := 100000.0

static func validate(candidate: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not candidate is Array:
		errors.append("root: expected an array of %d level records" % COUNT)
		return errors
	if candidate.size() != COUNT:
		errors.append("root: expected %d level records, got %d" % [COUNT, candidate.size()])
	for index in range(candidate.size()):
		var path := "level %03d" % (index + 1)
		var record: Variant = candidate[index]
		if not record is Dictionary:
			errors.append(path + ": expected an object")
			continue
		_number(record, "id", path, errors, index + 1, index + 1, true)
		_number(record, "district", path, errors, index / 20, index / 20, true)
		for key in ["name", "lesson"]:
			_text(record, key, path, errors)
		for key in ["start", "bay"]:
			_vector(record.get(key), 3, path + "." + key, errors)
		_vector(record.get("bay_size"), 2, path + ".bay_size", errors, true)
		for key in ["yaw", "bay_yaw"]:
			_number(record, key, path, errors, -MAX_COORDINATE, MAX_COORDINATE)
		_number(record, "arena", path, errors, 10, 1000)
		for key in ["gold", "silver"]:
			_number(record, key, path, errors, 0.001, 86400)
		if _finite(record.get("gold")) and _finite(record.get("silver")) and record.silver < record.gold:
			errors.append(path + ".silver: must be greater than or equal to gold")
		_number(record, "base_reward", path, errors, 1, 1000000, true)
		_bool(record, "reverse", path, errors)
		if record.has("legacy_layout"):
			_bool(record, "legacy_layout", path, errors)
		for key in ["route", "cones"]:
			var points: Variant = record.get(key)
			if not points is Array:
				errors.append(path + "." + key + ": expected an array")
				continue
			if key == "route" and points.is_empty():
				errors.append(path + ".route: expected at least one waypoint")
			for point in range(points.size()):
				_vector(points[point], 3, "%s.%s[%d]" % [path, key, point], errors)
		for key in ["blocks", "parked"]:
			var items: Variant = record.get(key)
			if not items is Array:
				errors.append(path + "." + key + ": expected an array")
				continue
			for item_index in range(items.size()):
				var item: Variant = items[item_index]
				var item_path := "%s.%s[%d]" % [path, key, item_index]
				if not item is Dictionary:
					errors.append(item_path + ": expected an object")
					continue
				_vector(item.get("at"), 3, item_path + ".at", errors)
				if key == "parked":
					_number(item, "yaw", item_path, errors, -MAX_COORDINATE, MAX_COORDINATE)
				else:
					_vector(item.get("size"), 3, item_path + ".size", errors, true)
					_text(item, "kind", item_path, errors)
					if item.get("kind") == "planter" and _valid_vector(item.get("size"), 3):
						if item.size[0] <= 0.2 or item.size[2] <= 0.2:
							errors.append(item_path + ".size: planter width and length must exceed 0.2 m")
		var difficulty: Variant = record.get("difficulty")
		if not difficulty is Dictionary:
			errors.append(path + ".difficulty: expected an object")
		else:
			_text(difficulty, "tier", path + ".difficulty", errors)
			_optional_numbers(difficulty, path + ".difficulty", errors, {
				"heading_degrees": [0.001, 180, false], "hold_seconds": [0.001, 86400, false],
				"stop_speed": [0, 100, false], "gold_max_hits": [-1, 100, true], "silver_max_hits": [-1, 100, true]})
		if record.has("road_features"):
			var features: Variant = record.road_features
			if not features is Dictionary:
				errors.append(path + ".road_features: expected an object")
			else:
				_optional_numbers(features, path + ".road_features", errors, {
					"stop_seconds": [0.001, 86400, false], "speed_breakers": [0, 100, true]})
				if features.has("boom_barrier"):
					_bool(features, "boom_barrier", path + ".road_features", errors)
	return errors

static func _finite(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value)

static func _number(data: Dictionary, key: String, path: String, errors: Array[String], minimum: float, maximum: float, integer: bool = false) -> void:
	var value: Variant = data.get(key)
	if not _finite(value):
		errors.append(path + "." + key + ": expected a finite number")
	elif value < minimum or value > maximum or (integer and value != floor(value)):
		errors.append("%s.%s: expected %s in [%s, %s]" % [path, key, "an integer" if integer else "a number", minimum, maximum])

static func _optional_numbers(data: Dictionary, path: String, errors: Array[String], rules: Dictionary) -> void:
	for key in rules:
		if data.has(key):
			_number(data, key, path, errors, rules[key][0], rules[key][1], rules[key][2])

static func _text(data: Dictionary, key: String, path: String, errors: Array[String]) -> void:
	var value: Variant = data.get(key)
	if not value is String or value.strip_edges().is_empty():
		errors.append(path + "." + key + ": expected a non-empty string")

static func _bool(data: Dictionary, key: String, path: String, errors: Array[String]) -> void:
	if not data.get(key) is bool:
		errors.append(path + "." + key + ": expected a boolean")

static func _valid_vector(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count:
		return false
	for component in value:
		if not _finite(component) or absf(component) > MAX_COORDINATE:
			return false
	return true

static func _vector(value: Variant, count: int, path: String, errors: Array[String], positive: bool = false) -> void:
	if not _valid_vector(value, count):
		errors.append("%s: expected exactly %d finite numbers with magnitude <= %s" % [path, count, MAX_COORDINATE])
		return
	if positive:
		for component in value:
			if component <= 0:
				errors.append(path + ": dimensions must be positive")
				return

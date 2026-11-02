extends RefCounted
## Only a fully validated campaign is exposed to scene and reward consumers.
const COUNT: int = 100
const SOURCE := "res://data/campaign_levels.json"
const Validator = preload("res://scripts/campaign_validator.gd")
const DISTRICTS := ["The Starter Garage", "Downtown", "The Rooftops", "Precision Complex", "Master Garage"]
static var _records: Array = []
static var _loaded: bool = false
static var errors: Array[String] = []
static var source_path: String = SOURCE

static func load_campaign(path: String = SOURCE, report_errors: bool = true) -> bool:
	_loaded = true
	_records.clear()
	errors.clear()
	source_path = path
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot read campaign file (error %d)" % FileAccess.get_open_error())
	else:
		var parser := JSON.new()
		if parser.parse(file.get_as_text()) != OK:
			errors.append("JSON line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		else:
			errors = Validator.validate(parser.data)
			if errors.is_empty():
				_records = parser.data.duplicate(true)
	if report_errors:
		for message in errors:
			push_error("%s: %s" % [path, message])
	return errors.is_empty()

static func available() -> bool:
	if not _loaded:
		load_campaign()
	return errors.is_empty()

static func error_summary() -> String:
	if available():
		return ""
	return "%s: %s%s" % [source_path, errors[0], " (+%d more errors)" % (errors.size() - 1) if errors.size() > 1 else ""]

static func level(index: int) -> Dictionary:
	if index < 0 or index >= COUNT or not available():
		return {}
	var data: Dictionary = _records[index].duplicate(true)
	data.start = vector(data.start)
	data.bay = vector(data.bay)
	data.bay_size = Vector2(data.bay_size[0], data.bay_size[1])
	data.route = data.route.map(vector)
	data.cones = data.cones.map(vector)
	for block in data.blocks:
		block.at = vector(block.at)
		block.size = vector(block.size)
	for car in data.parked:
		car.at = vector(car.at)
	return data

static func vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

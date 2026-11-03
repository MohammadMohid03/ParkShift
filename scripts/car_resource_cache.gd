extends RefCounted
## Two recent detailed cars only; never preload the whole collection on mobile.
## A single worker and a latest-request slot bound memory during rapid browsing.
const CAPACITY := 2
static var scenes: Dictionary = {}
static var recent: Array[String] = []
static var active: String = ""
static var wanted: String = ""
static var failed: Dictionary = {}

static func _retain(path: String, scene: PackedScene) -> void:
	scenes[path] = scene
	recent.erase(path)
	recent.append(path)
	while recent.size() > CAPACITY:
		scenes.erase(recent.pop_front())

static func ready(path: String) -> bool:
	return scenes.has(path)

static func request(path: String) -> void:
	wanted = path
	failed.erase(path)
	if ready(path):
		_retain(path, scenes[path])
		wanted = ""
	elif active.is_empty():
		_start()

static func _start() -> void:
	if wanted.is_empty():
		return
	active = wanted
	wanted = ""
	var error := ResourceLoader.load_threaded_request(active, "PackedScene", false)
	if error != OK:
		failed[active] = error
		active = ""

static func poll() -> void:
	if not active.is_empty():
		var status := ResourceLoader.load_threaded_get_status(active)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var scene := ResourceLoader.load_threaded_get(active) as PackedScene
			if scene != null:
				_retain(active, scene)
			else:
				failed[active] = ERR_FILE_CORRUPT
			active = ""
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			failed[active] = ERR_CANT_OPEN
			active = ""
	if active.is_empty():
		if ready(wanted):
			wanted = ""
		_start()

static func scene_for(path: String) -> PackedScene:
	# Gameplay can reuse a garage-loaded scene. Direct level entry has a synchronous
	# fallback; the interactive garage only calls this after ready() becomes true.
	if ready(path):
		_retain(path, scenes[path])
		return scenes[path]
	var scene: PackedScene
	if active == path:
		scene = ResourceLoader.load_threaded_get(path) as PackedScene
		active = ""
	else:
		scene = load(path) as PackedScene
	if wanted == path:
		wanted = ""
	if scene != null:
		_retain(path, scene)
	return scene

extends Node
## Physical keys and independent touch fingers feed the same controls.

var pointers: Dictionary = {}
var enabled: bool = false
var steering_sensitivity: float = 1.0
var wheel_value: float = 0.0

func set_wheel(value: float) -> void:
	wheel_value = clampf(value, -1.0, 1.0) if enabled else 0.0

func _ready() -> void:
	var preferences := get_node_or_null("/root/Progress")
	if preferences != null:
		steering_sensitivity = preferences.steering_sensitivity
	_add_action("steer_left", [KEY_A, KEY_LEFT])
	_add_action("steer_right", [KEY_D, KEY_RIGHT])
	_add_action("drive", [KEY_W, KEY_UP])
	_add_action("reverse", [KEY_S, KEY_DOWN])
	_add_action("brake", [KEY_SPACE])

func _add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func set_pointer(action: String, token: int, down: bool) -> void:
	var key := "%s:%d" % [action, token]
	if down and enabled:
		pointers[key] = action
	else:
		pointers.erase(key)

func strength(action: String) -> float:
	if not enabled:
		return 0.0
	return maxf(Input.get_action_strength(action), 1.0 if pointers.values().has(action) else 0.0)

func steer() -> float:
	return clampf(strength("steer_right") - strength("steer_left") + wheel_value, -1, 1) if enabled else 0.0

func throttle() -> float:
	return strength("drive") - strength("reverse")

func reset() -> void:
	pointers.clear()
	wheel_value = 0.0

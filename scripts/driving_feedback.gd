extends RefCounted
## Short optional pulses. Desktop runs are silent; Android hardware varies.
static func pulse(node: Node, duration_ms: int) -> void:
	var preferences := node.get_node_or_null("/root/Progress")
	if OS.get_name() == "Android" and preferences != null and preferences.haptics_enabled:
		Input.vibrate_handheld(duration_ms)

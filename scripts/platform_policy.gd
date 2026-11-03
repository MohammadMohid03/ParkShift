extends Node
## Editor IPC remains available in the editor, but is idle in exported games.
func _ready() -> void:
	call_deferred("apply_policy")
	if OS.has_feature("android"):
		Engine.max_fps = 60

func apply_policy() -> void:
	if OS.has_feature("editor") or OS.get_cmdline_user_args().has("--enable-mcp-runtime"):
		return
	for name in ["MCPRuntimeBridge", "MCPInputBridge", "MCPScreenshotBridge"]:
		var bridge := get_node_or_null("/root/" + name)
		if bridge != null:
			bridge.set_process(false)
			bridge.set_physics_process(false)
			bridge.set_process_input(false)

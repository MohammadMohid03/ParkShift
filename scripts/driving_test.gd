extends Node3D
## Phase 2 entry point: driving only; no progression or save writes.
@onready var car: CharacterBody3D = $Car
@onready var drive_input: Node = $DriveInput
@onready var follow_camera: Node3D = $FollowCamera
@onready var telemetry: Label = $HUD/Telemetry
@onready var pause_label: Label = $HUD/Paused
var suspended: bool = false

func _ready() -> void:
	car.input_source = drive_input
	reset_drive()

func reset_drive() -> void:
	drive_input.reset()
	car.reset(Vector3(2, 0.05, 9), 0.0)
	_set_suspended(false)
	follow_camera.snap_to_target()

func _process(_delta: float) -> void:
	var gear := "R" if car.speed < -0.05 else ("D" if car.speed > 0.05 else "N")
	telemetry.text = "%02d km/h   /   %s" % [roundi(absf(car.speed) * 3.6), gear]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			reset_drive()
		elif event.physical_keycode == KEY_ESCAPE:
			_set_suspended(not suspended)

func _set_suspended(value: bool) -> void:
	suspended = value
	car.active = not value
	drive_input.enabled = not value
	drive_input.reset()
	pause_label.visible = value
	follow_camera.set_interaction_enabled(not value)

func _notification(what: int) -> void:
	if is_node_ready() and (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED):
		_set_suspended(true)

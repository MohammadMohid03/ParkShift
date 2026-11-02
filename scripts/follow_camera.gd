extends Node3D
## Elevated chase rig. World collision uses a sphere sweep on the spring arm.
@export var target_path: NodePath
@export var follow_response: float = 12.0
@export var heading_response: float = 4.0
@export var maximum_turn_rate: float = 100.0
@export var pivot_height: float = 1.3
@export var look_ahead: float = 1.2
var reverse_route: bool = false
const DEFAULT_ELEVATION := 35.0
const DEFAULT_DISTANCE := 13.0
var orbit_yaw := 0.0
var elevation := DEFAULT_ELEVATION
var distance := DEFAULT_DISTANCE
var manual_view := false
var interaction_enabled := true
var fingers: Dictionary = {}
var mouse_orbit := false
@onready var target: Node3D = get_node(target_path)
@onready var arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
	process_physics_priority = 10
	snap_to_target()

func snap_to_target() -> void:
	global_position = _pivot_position()
	rotation.y = _heading()
	_apply_lens()
	reset_physics_interpolation()

func _pivot_position() -> Vector3:
	return target.global_position + Vector3.UP * pivot_height - target.global_basis.z * (0.0 if manual_view else look_ahead) * (-1.0 if reverse_route else 1.0)

func _heading() -> float:
	return target.global_rotation.y + (PI if reverse_route else 0.0) + orbit_yaw

func _apply_lens() -> void:
	arm.rotation.x = -deg_to_rad(elevation)
	arm.spring_length = distance

func set_interaction_enabled(value: bool) -> void:
	interaction_enabled = value
	fingers.clear()
	mouse_orbit = false

func reset_view() -> void:
	fingers.clear()
	mouse_orbit = false
	orbit_yaw = 0.0
	elevation = DEFAULT_ELEVATION
	distance = DEFAULT_DISTANCE
	manual_view = false
	snap_to_target()

func show_car_front(front: bool) -> void:
	fingers.clear()
	mouse_orbit = false
	orbit_yaw = (PI if front else 0.0) - (PI if reverse_route else 0.0)
	elevation = 20.0
	distance = 9.0
	manual_view = true
	snap_to_target()

func orbit(relative: Vector2) -> void:
	# Normalize to viewport height so sensitivity survives aspect/size changes.
	var movement := relative / maxf(get_viewport().get_visible_rect().size.y,1.0)
	var yaw_change := -movement.x * TAU
	orbit_yaw = wrapf(orbit_yaw + yaw_change,-PI,PI)
	rotation.y += yaw_change
	elevation = clampf(elevation + movement.y * 100.0,12.0,75.0)
	manual_view = true
	_apply_lens()

func zoom(factor: float) -> void:
	distance = clampf(distance * factor,6.0,24.0)
	_apply_lens()

func _unhandled_input(event: InputEvent) -> void:
	if not interaction_enabled: return
	# Only begin gestures after the HUD and driving controls have declined them.
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		if fingers.size() < 2:
			fingers[event.index] = event.position
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device != -1:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_orbit = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom(0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_C:
		reset_view()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not interaction_enabled: return
	# Owned gestures keep receiving releases even when they cross a HUD panel.
	if event is InputEventScreenTouch and (not event.pressed or event.canceled) and fingers.has(event.index):
		fingers.erase(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		if fingers.size() == 2:
			var other: int = fingers.keys()[0] if fingers.keys()[0] != event.index else fingers.keys()[1]
			var before: float = (fingers[event.index] as Vector2).distance_to(fingers[other])
			var after: float = event.position.distance_to(fingers[other])
			if before > 20 and after > 20: zoom(before/after)
		else:
			orbit(event.position - (fingers[event.index] as Vector2))
		fingers[event.index] = event.position
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed and mouse_orbit:
		mouse_orbit = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and event.device != -1 and mouse_orbit:
		orbit(event.relative)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		fingers.clear()
		mouse_orbit = false

func _physics_process(delta: float) -> void:
	var desired := _pivot_position()
	if target is CharacterBody3D:
		desired += Vector3(target.velocity.x, 0, target.velocity.z) * 0.10
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_response * delta))
	var difference := wrapf(_heading() - rotation.y, -PI, PI)
	var change := difference * (1.0 - exp(-heading_response * delta))
	rotation.y += clampf(change, -deg_to_rad(maximum_turn_rate) * delta, deg_to_rad(maximum_turn_rate) * delta)

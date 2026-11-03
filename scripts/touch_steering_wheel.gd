extends Control
## One captured finger rotates the wheel; a second finger remains free for pedals.
signal steering_changed(value: float)
var tokens: Dictionary = {}
var angle: float = 0.0
var previous_angle: float = 0.0
const LIMIT: float = PI * 0.75

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func release() -> void:
	tokens.clear()
	angle = 0.0
	steering_changed.emit(0.0)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release()

func _point(position: Vector2) -> float:
	return (position - get_global_rect().get_center()).angle()

func _press(token: int, position: Vector2, pressed: bool) -> void:
	if pressed and tokens.is_empty() and get_global_rect().has_point(position):
		tokens[token] = true
		previous_angle = _point(position)
		get_viewport().set_input_as_handled()
	elif not pressed and tokens.has(token):
		tokens.erase(token)
		get_viewport().set_input_as_handled()

func _drag(token: int, position: Vector2) -> void:
	if not tokens.has(token): return
	if position.distance_to(get_global_rect().get_center()) < 16: return
	var current := _point(position)
	angle = clampf(angle + wrapf(current - previous_angle, -PI, PI), -LIMIT, LIMIT)
	previous_angle = current
	steering_changed.emit(angle / LIMIT)
	queue_redraw()
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		_press(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != -1:
		_press(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion and event.device != -1:
		_drag(-1, event.position)

func _process(delta: float) -> void:
	if tokens.is_empty() and not is_zero_approx(angle):
		angle = move_toward(angle, 0, delta * 5.0)
		steering_changed.emit(angle / LIMIT)
		queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := size.x * 0.41
	draw_circle(center, radius + 9, Color(0.08, 0.11, 0.09, 0.94))
	draw_arc(center, radius, 0, TAU, 64, Color("c2cbb9"), 10, true)
	for offset in [0.0, PI * 0.8, -PI * 0.8]:
		var direction := Vector2.from_angle(angle - PI * 0.5 + offset)
		draw_line(center + direction * 18, center + direction * (radius - 5), Color("7b8b76"), 9, true)
	draw_circle(center, 22, Color("29382a"))
	var tip := Vector2.from_angle(angle - PI * 0.5)
	draw_line(center + tip * (radius - 9), center + tip * (radius + 5), Color("d4ec78"), 7, true)

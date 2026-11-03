extends Control
## Each pedal/steering control owns its finger IDs; steering and drive can overlap.

signal held(action: String, token: int, down: bool)
const ThemeFactory = preload("res://scripts/campaign_theme.gd")
var action: String = ""
var symbol: String = ""
var caption: String = ""
var accent: bool = false
var tokens: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(104, 104)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var inside: bool = false
	if event is InputEventScreenTouch:
		inside = get_global_rect().has_point(event.position)
		if event.pressed and inside:
			tokens[event.index] = true
			held.emit(action, event.index, true)
			get_viewport().set_input_as_handled()
		elif not event.pressed and tokens.has(event.index):
			tokens.erase(event.index)
			held.emit(action, event.index, false)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and tokens.has(event.index):
		inside = get_global_rect().has_point(event.position)
		tokens[event.index] = inside
		held.emit(action, event.index, inside)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != -1:
		inside = get_global_rect().has_point(event.position)
		if event.pressed and inside:
			tokens[-1] = true
			held.emit(action, -1, true)
			get_viewport().set_input_as_handled()
		elif not event.pressed and tokens.has(-1):
			tokens.erase(-1)
			held.emit(action, -1, false)
	elif event is InputEventMouseMotion and tokens.has(-1):
		inside = get_global_rect().has_point(event.position)
		tokens[-1] = inside
		held.emit(action, -1, inside)
	queue_redraw()

func _draw() -> void:
	var pressed: bool = tokens.values().has(true)
	var background := StyleBoxFlat.new()
	background.bg_color = ThemeFactory.ORANGE if pressed else Color(0.08, 0.11, 0.09, 0.94)
	background.border_color = ThemeFactory.ORANGE if pressed else Color("667063")
	background.set_border_width_all(2 if pressed else 1)
	background.set_corner_radius_all(10)
	draw_style_box(background, Rect2(Vector2.ZERO, size))
	var color := ThemeFactory.NAVY if pressed else ThemeFactory.INK
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
	draw_string(font, Vector2((size.x - width) * 0.5, size.y * 0.39), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, color)
	var caption_font: Font = ThemeFactory.BODY
	var caption_width := caption_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(caption_font, Vector2((size.x - caption_width) * 0.5, size.y * 0.71), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)

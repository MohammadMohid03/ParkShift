extends RefCounted
## Shared workshop palette, type, and interaction states.
const NAVY := Color("151b19")
const ORANGE := Color("d4ec78") # Compatibility name for the primary accent.
const SURFACE := Color("202824")
const RAISED := Color("2b3530")
const INK := Color("f2f1e8")
const MUTED := Color("a8b3aa")
const BORDER := Color("39463e")
const BODY = preload("res://assets/fonts/Barlow-Regular.ttf")
const DISPLAY = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")

static func box(color: Color, padding: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

static func line_box(color: Color, padding: int = 14) -> StyleBoxFlat:
	var style := box(color, padding)
	style.border_color = BORDER
	style.set_border_width_all(1)
	return style

static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY
	theme.default_font_size = 20
	theme.set_stylebox("panel", "PanelContainer", box(SURFACE))
	theme.set_stylebox("panel", "AcceptDialog", line_box(SURFACE, 20))
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, line_box(RAISED))
		theme.set_stylebox("hover", type, line_box(Color("37443b")))
		theme.set_stylebox("pressed", type, box(ORANGE, 14))
		theme.set_stylebox("disabled", type, box(Color("1d2520"), 14))
		var focus := box(Color(0, 0, 0, 0), 0)
		focus.set_border_width_all(2)
		focus.border_color = ORANGE
		theme.set_stylebox("focus", type, focus)
		theme.set_color("font_color", type, INK)
		theme.set_color("font_hover_color", type, INK)
		theme.set_color("font_pressed_color", type, NAVY)
		theme.set_color("font_disabled_color", type, MUTED)
	theme.set_color("font_color", "Label", INK)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		theme.set_stylebox(state, "CheckButton", box(Color(0,0,0,0), 8))
	theme.set_color("font_pressed_color", "CheckButton", INK)
	theme.set_stylebox("background", "ProgressBar", box(Color("0d1410"), 0))
	theme.set_stylebox("fill", "ProgressBar", box(ORANGE, 0))
	for type in ["HSlider", "VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", type, box(Color("151d17"), 4))
		theme.set_stylebox("grabber", type, box(Color("6f806b"), 4))
		theme.set_stylebox("grabber_highlight", type, box(ORANGE, 4))
	return theme

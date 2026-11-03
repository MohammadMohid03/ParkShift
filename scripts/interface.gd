extends CanvasLayer
## Menu, garage, run HUD and results. Gameplay never depends on these controls.

signal level_requested(index: int)
signal menu_requested
signal garage_requested
signal car_previewed(car_id: String)
signal car_purchased(car_id: String)
signal pause_requested
signal resume_requested
signal retry_requested
signal next_requested
signal touch_held(action: String, token: int, down: bool)

const Catalog = preload("res://scripts/level_catalog.gd")
const TouchControl = preload("res://scripts/touch_control.gd")
const INK := Color("132a30")
const CREAM := Color("f2efdf")
const MUTED := Color("aac1bc")
const MINT := Color("b4ebd3")
const GOLD := Color("eac77a")
var root: Control
var clock_label: Label
var contact_label: Label
var speed_label: Label
var status_label: Label
var park_meter: ProgressBar
var toast_label: Label
var active_screen: String = ""
var touch_buttons: Dictionary = {}

func _ready() -> void:
	layer = 10
	root = Control.new()
	root.name = "Interface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

func clear() -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	touch_buttons.clear()

func _style(color: Color, radius: int = 12, margin: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

func _label(text: String, font_size: int = 18, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 50
	button.add_theme_font_size_override("font_size", 17)
	var normal := _style(MINT if primary else Color("294348"), 8, 16)
	var hover := _style(Color("d0f8e5") if primary else Color("3d5d60"), 8, 16)
	var disabled := _style(Color("22363b"), 8, 16)
	var focus := _style(Color.TRANSPARENT, 8, 0)
	focus.border_color = CREAM
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK if primary else CREAM)
	button.add_theme_color_override("font_disabled_color", Color("738b8c"))
	button.pressed.connect(callback)
	return button

func _vbox(separation: int = 12) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box

func _hbox(separation: int = 12) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box

func _panel(parent: Node, width: float, color: Color = INK) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	panel.add_theme_stylebox_override("panel", _style(color, 16, 28))
	parent.add_child(panel)
	var content := _vbox(16)
	panel.add_child(content)
	return content

func _fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _shade(opacity: float = 0.6) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.065, 0.07, opacity)
	root.add_child(shade)
	_fill(shade)

func _center() -> CenterContainer:
	var center := CenterContainer.new()
	root.add_child(center)
	_fill(center)
	return center

func _stars(count: int) -> String:
	return "★".repeat(count) + "☆".repeat(3 - count)

func show_menu(progress: Node) -> void:
	clear()
	active_screen = "menu"
	_shade(0.76)
	var content := _panel(_center(), 1080, Color(0.04, 0.09, 0.10, 0.94))
	var heading := _hbox()
	content.add_child(heading)
	var brand := _label("PARKSHIFT", 38)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(brand)
	heading.add_child(_label("%d  COINS" % progress.coins, 20, GOLD))
	content.add_child(_label("A little patience. A perfect place.", 23, MINT))
	content.add_child(_label("FIVE PLACES TO FIND YOUR FLOW", 13, MUTED))
	var levels := _hbox(14)
	content.add_child(levels)
	for index in range(Catalog.LEVELS.size()):
		var definition: Dictionary = Catalog.LEVELS[index]
		var card := _vbox(12)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		levels.add_child(card)
		var label := _label("%02d" % (index + 1), 44, MINT if progress.unlocked(index) else Color("526a6a"))
		card.add_child(label)
		var title := _label(definition.name, 17)
		title.custom_minimum_size = Vector2(180, 52)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(title)
		card.add_child(_label(_stars(progress.stars[index]), 24, GOLD))
		var best: float = progress.best_times[index]
		card.add_child(_label("BEST %.1fs" % best if best > 0 else "PAR %ds" % int(definition.par), 13, MUTED))
		var play := _button("DRIVE" if progress.unlocked(index) else "LOCKED", func() -> void: level_requested.emit(index), progress.unlocked(index))
		play.disabled = not progress.unlocked(index)
		card.add_child(play)
	content.add_child(HSeparator.new())
	var footer := _hbox(16)
	content.add_child(footer)
	var help := _label("W / S  drive & reverse     A / D  steer     SPACE  brake\nTouch: hold a pedal and steering together.", 16, MUTED)
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(help)
	footer.add_child(_button("GARAGE  /  3 CARS", func() -> void: garage_requested.emit()))
	if not progress.save_error.is_empty():
		content.add_child(_label(progress.save_error, 14, GOLD))
	elif progress.recovered_backup:
		content.add_child(_label("Progress restored from your local backup.", 14, GOLD))

func _anchored(parent: Node, at: Vector2, dimensions: Vector2, anchor: Vector2 = Vector2.ZERO) -> Control:
	var control := Control.new()
	parent.add_child(control)
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = at.x
	control.offset_top = at.y
	control.offset_right = at.x + dimensions.x
	control.offset_bottom = at.y + dimensions.y
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

func show_play(definition: Dictionary, index: int) -> void:
	clear()
	active_screen = "play"
	var title_holder := _anchored(root, Vector2(28, 22), Vector2(390, 98))
	var title_panel := _panel(title_holder, 390, Color(0.04, 0.09, 0.10, 0.91))
	title_panel.add_child(_label(definition.place, 15, MINT))
	title_panel.add_child(_label(definition.name, 23))
	var stats := _anchored(root, Vector2(-370, 22), Vector2(342, 90), Vector2(1, 0))
	var row := _hbox(12)
	stats.add_child(row)
	clock_label = _label("0.0s", 26, INK)
	clock_label.custom_minimum_size.x = 94
	row.add_child(clock_label)
	contact_label = _label("0 HITS", 17, INK)
	contact_label.custom_minimum_size.x = 90
	row.add_child(contact_label)
	row.add_child(_button("PAUSE", func() -> void: pause_requested.emit()))
	var lesson := _label(definition.lesson, 15, INK)
	lesson.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lesson)
	lesson.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	lesson.position = Vector2(430, 98)
	lesson.size = Vector2(820, 46)
	lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var steering := _anchored(root, Vector2(28, -114), Vector2(180, 86), Vector2(0, 1))
	var steering_row := _hbox(12)
	steering.add_child(steering_row)
	_touch(steering_row, "steer_left", "‹", "LEFT")
	_touch(steering_row, "steer_right", "›", "RIGHT")
	var pedals := _anchored(root, Vector2(-298, -114), Vector2(270, 86), Vector2(1, 1))
	var pedals_row := _hbox(10)
	pedals.add_child(pedals_row)
	_touch(pedals_row, "brake", "■", "BRAKE")
	_touch(pedals_row, "reverse", "R", "REVERSE")
	_touch(pedals_row, "drive", "↑", "DRIVE", true)
	var feedback := _anchored(root, Vector2(-215, -106), Vector2(430, 90), Vector2(0.5, 1))
	var feedback_box := _vbox(8)
	feedback_box.custom_minimum_size.x = 430
	feedback.add_child(feedback_box)
	speed_label = _label("0 KM/H", 16, INK)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_box.add_child(speed_label)
	status_label = _label("FIND THE MINT BAY", 15, INK)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_box.add_child(status_label)
	park_meter = ProgressBar.new()
	park_meter.custom_minimum_size.y = 6
	park_meter.show_percentage = false
	park_meter.max_value = 1.0
	park_meter.add_theme_stylebox_override("background", _style(Color(0.08, 0.16, 0.17, 0.3), 3, 0))
	park_meter.add_theme_stylebox_override("fill", _style(Color("39866b"), 3, 0))
	feedback_box.add_child(park_meter)
	toast_label = _label("", 16, Color("a54438"))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_box.add_child(toast_label)
	# Level number is kept in the node name for readable remote scene inspection.
	root.name = "Interface_Level_%d" % (index + 1)

func _touch(parent: Node, action: String, symbol: String, caption: String, accent: bool = false) -> void:
	var control := TouchControl.new()
	control.name = action
	control.action = action
	control.symbol = symbol
	control.caption = caption
	control.accent = accent
	control.held.connect(func(a: String, token: int, down: bool) -> void: touch_held.emit(a, token, down))
	parent.add_child(control)
	touch_buttons[action] = control

func update_play(seconds: float, contacts: int, speed: float, status: String, ratio: float, toast: String) -> void:
	if active_screen != "play":
		return
	clock_label.text = "%.1fs" % seconds
	contact_label.text = "%d HITS" % contacts
	speed_label.text = "%s  %02d KM/H" % ["R" if speed < -0.1 else "D", int(absf(speed) * 3.6)]
	status_label.text = status
	park_meter.value = ratio
	toast_label.text = toast

func show_pause() -> void:
	clear()
	active_screen = "pause"
	_shade()
	var content := _panel(_center(), 410)
	content.add_child(_label("TAKE A BREATH", 30))
	content.add_child(_label("Your run is paused.", 18, MUTED))
	content.add_child(_button("RESUME", func() -> void: resume_requested.emit(), true))
	content.add_child(_button("START AGAIN", func() -> void: retry_requested.emit()))
	content.add_child(_button("LEVEL SELECT", func() -> void: menu_requested.emit()))

func show_result(index: int, stars: int, seconds: float, contacts: int, reward: int, progress: Node) -> void:
	clear()
	active_screen = "result"
	_shade(0.5)
	var content := _panel(_center(), 470)
	content.add_child(_label("PERFECTLY PLACED", 30, MINT))
	content.add_child(_label(Catalog.LEVELS[index].place, 15, MUTED))
	var star_label := _label(_stars(stars), 50, GOLD)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(star_label)
	content.add_child(_label("%.1f SECONDS    /    %d CONTACTS" % [seconds, contacts], 18))
	content.add_child(_label("+%d COINS    ·    BALANCE %d" % [reward, progress.coins], 18, GOLD))
	content.add_child(_label("3 stars: no contacts, within %ds.\n2 stars: at most 2 contacts, within %ds." % [int(Catalog.LEVELS[index].par), int(Catalog.LEVELS[index].par * 1.75)], 14, MUTED))
	if index < 4:
		content.add_child(_button("NEXT PLACE  →", func() -> void: next_requested.emit(), true))
	else:
		content.add_child(_label("FIVE PLACES. ONE PERFECT FINISH.", 16, MINT))
		content.add_child(_button("VISIT YOUR GARAGE", func() -> void: garage_requested.emit(), true))
	var row := _hbox()
	content.add_child(row)
	for button in [_button("RETRY", func() -> void: retry_requested.emit()), _button("LEVELS", func() -> void: menu_requested.emit())]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	if not progress.save_error.is_empty():
		content.add_child(_label(progress.save_error, 14, GOLD))

func show_garage(progress: Node, preview_id: String) -> void:
	clear()
	active_screen = "garage"
	var header := _anchored(root, Vector2(40, 30), Vector2(640, 140))
	var title := _vbox(10)
	header.add_child(title)
	title.add_child(_label("THE GARAGE", 42, INK))
	title.add_child(_label("Three characters. The same precise handling.", 20, INK))
	title.add_child(_button("← LEVEL SELECT", func() -> void: menu_requested.emit()))
	var holder := _anchored(root, Vector2(-420, 24), Vector2(392, 650), Vector2(1, 0))
	var content := _panel(holder, 392)
	content.add_child(_label("%d  COINS" % progress.coins, 23, GOLD))
	for definition in Catalog.CARS:
		var button := _button(definition.name + ("  /  SELECTED" if progress.selected == definition.id else "  /  PREVIEW"), func() -> void: car_previewed.emit(definition.id), preview_id == definition.id)
		content.add_child(button)
		content.add_child(_label(definition.tag, 15, MUTED))
		if preview_id == definition.id:
			var owned: bool = progress.owned.has(definition.id)
			var text: String = "USE THIS CAR" if owned else "UNLOCK  /  %d COINS" % preload("res://scripts/economy.gd").price(definition.id)
			var purchase := _button(text, func() -> void: car_purchased.emit(definition.id), true)
			purchase.disabled = progress.selected == definition.id or (not owned and progress.coins < preload("res://scripts/economy.gd").price(definition.id))
			content.add_child(purchase)
	content.add_child(_label("Earn coins by clearing levels\nand improving your best star ratings.", 15, MUTED))
	if not progress.save_error.is_empty():
		content.add_child(_label(progress.save_error, 14, GOLD))

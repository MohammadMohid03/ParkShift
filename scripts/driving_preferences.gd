extends RefCounted
## Shared menu and pause controls; defaults leave the original steering unchanged.
static func build(parent: Control, store: Node, changed: Callable = Callable()) -> void:
	var mode := OptionButton.new()
	mode.add_item("Steering: arrow buttons")
	mode.add_item("Steering: touch wheel")
	mode.selected = 1 if store.steering_mode == "wheel" else 0
	mode.custom_minimum_size.y = 44
	parent.add_child(mode)
	mode.item_selected.connect(func(index: int) -> void:
		store.steering_mode = "wheel" if index == 1 else "buttons"
		store.save_progress()
		if changed.is_valid(): changed.call())
	_slider(parent, store, "Steering response", "steering_sensitivity", 0.7, 1.5, changed)
	_slider(parent, store, "Touch button size", "touch_scale", 0.85, 1.15, changed)
	for entry in [["Parking guide lines", "parking_guides"], ["Gentle vibration", "haptics_enabled"]]:
		var toggle := CheckButton.new()
		toggle.text = entry[0]
		toggle.custom_minimum_size.y = 48
		toggle.button_pressed = bool(store.get(entry[1]))
		parent.add_child(toggle)
		var key: String = entry[1]
		toggle.toggled.connect(func(value: bool) -> void:
			store.set(key, value)
			store.save_progress()
			if changed.is_valid(): changed.call())
	var note := Label.new()
	note.text = "Guides estimate your path; check clearance."
	note.add_theme_font_size_override("font_size", 16)
	parent.add_child(note)

static func _slider(parent: Control, store: Node, title: String, key: String, low: float, high: float, changed: Callable) -> void:
	var label := Label.new()
	label.text = "%s / %d%%" % [title, roundi(float(store.get(key)) * 100)]
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = 0.05
	slider.value = float(store.get(key))
	slider.custom_minimum_size = Vector2(300, 40)
	slider.tooltip_text = "Changes response speed, not the car's turning radius." if key == "steering_sensitivity" else "Keeps the four driving buttons in their current corners."
	parent.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		store.set(key, value)
		label.text = "%s / %d%%" % [title, roundi(value * 100)]
		if changed.is_valid(): changed.call())
	slider.drag_ended.connect(func(_changed: bool) -> void: store.save_progress())
	slider.focus_exited.connect(store.save_progress)

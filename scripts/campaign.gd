extends Node3D
const Catalog = preload("res://scripts/campaign_catalog.gd")
const Economy = preload("res://scripts/economy.gd")
const Cars = preload("res://scripts/level_catalog.gd")
const Art = preload("res://scripts/geometry.gd")
const ThemeFactory = preload("res://scripts/campaign_theme.gd")
const LevelScene = preload("res://scenes/campaign_level.tscn")
const CarResources = preload("res://scripts/car_resource_cache.gd")
const Profiles = preload("res://scripts/vehicle_profiles.gd")
var selected_district: int = 0
var screen: String = "main"
var active_level: Node3D
var preview: Node3D
var preview_id: String = "metro"
var preview_model_id: String = ""
var pending_preview_path: String = ""
var preview_load_error: bool = false
var preview_loading_label: Label
var garage_scroll: ScrollContainer
var garage_buttons: Dictionary = {}
var selected_label: Label
var purchase_button: Button
var purchase_dialog: ConfirmationDialog
var pending_purchase: String = ""
var menu_transition: Tween
var save_notice: Label
var level_buttons: Array[Button] = []
var ui_sound := AudioStreamPlayer.new()
@onready var camera: Camera3D = $Camera3D
@onready var stage: Node3D = $Stage
@onready var ui: Control = $UI/Root
@onready var store: Node = get_node("/root/Progress")
@onready var menu_environment: Environment = $WorldEnvironment.environment

func _ready() -> void:
	add_child(ui_sound)
	ui_sound.stream = preload("res://scripts/vehicle_audio.gd").tone("ui")
	ui_sound.volume_db = -20
	ui.theme = ThemeFactory.create_theme()
	preload("res://scripts/workshop_showroom.gd").build(stage)
	camera.position = Vector3(7.2, 5.0, 12)
	camera.look_at(Vector3(0, 0.4, 0))
	menu_environment = preload("res://scripts/presentation.gd").environment(0)
	menu_environment.background_mode = Environment.BG_COLOR
	menu_environment.background_color = Color("242c26")
	menu_environment.ambient_light_color = Color("eee7ce")
	menu_environment.ambient_light_energy = 0.6
	$Sun.light_energy = 0.9
	$Sun.light_color = Color("fff0d4")
	$Sun.shadow_enabled = false
	show_main()

func _clear_level() -> void:
	store.abandon_run()
	if is_instance_valid(active_level):
		active_level.car.active = false
		active_level.drive_input.enabled = false
		remove_child(active_level)
		active_level.queue_free()
		active_level = null
	stage.show()
	$Sun.show()
	$WorldEnvironment.environment = menu_environment
	camera.make_current()

func _clear_ui() -> VBoxContainer:
	if menu_transition != null:
		menu_transition.kill()
	ui.modulate.a = 0.85
	menu_transition = create_tween()
	menu_transition.tween_property(ui, "modulate:a", 1.0, 0.12)
	pending_purchase = ""
	if is_instance_valid(purchase_dialog):
		purchase_dialog.hide()
		purchase_dialog.queue_free()
		purchase_dialog = null
	get_viewport().gui_release_focus()
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	level_buttons.clear()
	var backing := ColorRect.new()
	backing.name = "MenuBacking"
	backing.color = ThemeFactory.NAVY
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(backing)
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if screen in ["main", "garage"]:
		backing.anchor_right = 0.40
	var margin := MarginContainer.new()
	ui.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	var brand := _label("PARKSHIFT", 34)
	brand.add_theme_font_override("font", ThemeFactory.DISPLAY)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var balance := _label("%s cr" % str(store.coins), 20)
	balance.add_theme_color_override("font_color", ThemeFactory.ORANGE)
	header.add_child(balance)
	for entry in [["Home", show_main, "main"], ["Levels", show_levels, "levels"], ["Garage", show_garage, "garage"], ["Settings", show_audio, "audio"]]:
		var nav := _button(entry[0], entry[1])
		var style := ThemeFactory.box(ThemeFactory.NAVY, 12)
		style.set_corner_radius_all(0)
		style.border_width_bottom = 2 if screen == entry[2] else 0
		style.border_color = ThemeFactory.ORANGE
		nav.add_theme_stylebox_override("normal", style)
		nav.add_theme_color_override("font_color", ThemeFactory.ORANGE if screen == entry[2] else ThemeFactory.MUTED)
		header.add_child(nav)
	var separator := HSeparator.new()
	column.add_child(separator)
	return column

func _label(value: String, size: int = 20) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	if size >= 28:
		label.add_theme_font_override("font", ThemeFactory.DISPLAY)
	return label

func _button(value: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 52
	button.pressed.connect(callback)
	button.pressed.connect(func() -> void: ui_sound.play())
	if primary:
		button.add_theme_stylebox_override("normal", ThemeFactory.box(ThemeFactory.ORANGE, 14))
		button.add_theme_stylebox_override("hover", ThemeFactory.box(ThemeFactory.ORANGE.lightened(0.12), 14))
		button.add_theme_color_override("font_color", ThemeFactory.NAVY)
		button.add_theme_color_override("font_hover_color", ThemeFactory.NAVY)
	return button

func _panel(parent: Node, width: float = 0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	return column

func _spacer(parent: Node) -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

func _footer(parent: Node, expand_space: bool = true) -> void:
	if expand_space:
		_spacer(parent)
	save_notice = _label(store.save_error, 16)
	save_notice.visible = not store.save_error.is_empty()
	save_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_notice.add_theme_color_override("font_color", ThemeFactory.ORANGE)
	parent.add_child(save_notice)
	if not Catalog.available():
		var notice := _label("Campaign unavailable. Repair the campaign data and restart.\n" + Catalog.error_summary(), 16)
		notice.name = "CampaignDataError"
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notice.add_theme_color_override("font_color", ThemeFactory.ORANGE)
		parent.add_child(notice)

func show_main() -> void:
	_clear_level()
	screen = "main"
	_set_preview(store.selected)
	var column := _clear_ui()
	_spacer(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	var panel := _panel(row, 430)
	panel.get_parent().add_theme_stylebox_override("panel", ThemeFactory.box(Color(0,0,0,0), 0))
	panel.add_theme_constant_override("separation", 18)
	panel.add_child(_label("Precision parking.", 54))
	var description := _label("100 challenges. Five districts. Your line.", 20)
	description.add_theme_color_override("font_color", ThemeFactory.MUTED)
	panel.add_child(description)
	var completed := 0
	var stars := 0
	var next := 99
	for index in range(Catalog.COUNT):
		stars += store.stars[index]
		if store.stars[index] > 0:
			completed += 1
		elif next == 99:
			next = index
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(400, 5)
	progress.max_value = 100
	progress.value = completed
	progress.show_percentage = false
	panel.add_child(progress)
	var progress_label := _label("%02d / 100 completed     %d stars" % [completed, stars], 18)
	progress_label.add_theme_color_override("font_color", ThemeFactory.MUTED)
	panel.add_child(progress_label)
	panel.add_child(_button("Continue  /  Level %02d  →" % (next + 1), func() -> void: start_level(next), true))
	panel.add_child(_button("Explore the districts", show_levels))
	var selected := _label("Driving: " + Cars.car(store.selected).name, 18)
	selected.add_theme_color_override("font_color", ThemeFactory.MUTED)
	panel.add_child(selected)
	_footer(column)

func show_levels() -> void:
	_clear_level()
	if is_instance_valid(preview):
		preview.hide()
	screen = "levels"
	stage.hide()
	var column := _clear_ui()
	column.add_theme_constant_override("separation", 14)
	if not Catalog.available():
		column.add_child(_label("Campaign unavailable", 32))
		_footer(column)
		return
	var banner := preload("res://scripts/district_art.gd").new()
	banner.district = selected_district
	column.add_child(banner)
	var title := _label(Catalog.DISTRICTS[selected_district], 36)
	banner.add_child(title)
	title.position = Vector2(20, 12)
	var cleared := 0
	for index in range(selected_district * 20, selected_district * 20 + 20):
		if store.stars[index] > 0: cleared += 1
	var subtitle := _label("District %02d   /   %d of 20 completed" % [selected_district + 1, cleared], 18)
	banner.add_child(subtitle)
	subtitle.position = Vector2(20, 60)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)
	for district in range(5):
		var tab := _button(["Starter", "Downtown", "Rooftops", "Precision", "Master"][district], func() -> void: select_district(district), district == selected_district)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tab)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for index in range(selected_district * 20, selected_district * 20 + 20):
		var definition := Catalog.level(index)
		var unlocked: bool = store.unlocked(index)
		var rating := "\u2605".repeat(store.stars[index]) + "\u2606".repeat(3 - store.stars[index])
		var best := "--" if store.best_times[index] <= 0 else "%.1fs" % store.best_times[index]
		var text := "%03d %s\nBest %s / Base %d coins\n%s" % [index + 1, definition.name, best, Economy.base_reward(index), rating]
		var button := _button(text, func() -> void: start_level(index))
		_hide_button_text(button)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(220, 128)
		button.disabled = not unlocked
		button.name = "Level%d" % (index + 1)
		button.tooltip_text = definition.lesson
		grid.add_child(button)
		var content := _button_content(button)
		var number := _label("%02d" % (index + 1), 26)
		number.add_theme_font_override("font", ThemeFactory.DISPLAY)
		number.add_theme_color_override("font_color", ThemeFactory.ORANGE if unlocked else ThemeFactory.MUTED)
		content.add_child(number)
		var name_label := _label(definition.name, 18)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		content.add_child(name_label)
		var record := _label("Best %s  ·  %d cr" % [best, Economy.base_reward(index)], 15)
		record.add_theme_color_override("font_color", ThemeFactory.MUTED)
		content.add_child(record)
		var stars_label := _label(rating if unlocked else "Locked", 17)
		stars_label.add_theme_color_override("font_color", ThemeFactory.ORANGE if store.stars[index] > 0 else ThemeFactory.MUTED)
		content.add_child(stars_label)
		level_buttons.append(button)
	_footer(column, false)

func select_district(index: int) -> void:
	selected_district = clampi(index, 0, 4)
	show_levels()

func show_garage() -> void:
	_clear_level()
	screen = "garage"
	var column := _clear_ui()
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	title_row.add_child(_label("Your garage", 38))
	var count := _label("   %d owned / %d cars" % [store.owned.size(), Cars.CARS.size()], 18)
	count.add_theme_color_override("font_color", ThemeFactory.MUTED)
	title_row.add_child(count)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var panel := _panel(row, 430)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.get_parent().add_theme_stylebox_override("panel", ThemeFactory.box(ThemeFactory.NAVY, 0))
	panel.add_theme_constant_override("separation", 12)
	garage_buttons.clear()
	var scroll := ScrollContainer.new()
	scroll.name = "CarListScroll"
	garage_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.scroll_deadzone = 12
	panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "AllCars"
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for entry in Cars.CARS:
		var owned: bool = store.owns_car(entry.id)
		var state := "Current car" if store.selected == entry.id else ("Owned" if owned else "%d cr  /  Locked" % Economy.price(entry.id))
		var button := _button(entry.name + "\n" + state, func() -> void: preview_car(entry.id))
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.custom_minimum_size.y = 82
		_hide_button_text(button)
		list.add_child(button)
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 12)
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation", 12)
		margin.add_child(line)
		var glyph := preload("res://scripts/vehicle_glyph.gd").new()
		glyph.paint = entry.color
		glyph.length_ratio = 1.12 if entry.id in ["touring", "shelby_patrol"] else 1.0
		line.add_child(glyph)
		var details := VBoxContainer.new()
		details.mouse_filter = Control.MOUSE_FILTER_IGNORE
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(details)
		var name_label := _label(entry.name, 20)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		details.add_child(name_label)
		var status := _label(state, 16)
		status.add_theme_color_override("font_color", ThemeFactory.MUTED)
		details.add_child(status)
		garage_buttons[entry.id] = button
	selected_label = _label("", 20)
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(selected_label)
	purchase_button = _button("", select_preview, true)
	purchase_button.custom_minimum_size.y = 58
	panel.add_child(purchase_button)
	_footer(column, false)
	preview_car(store.selected)
	_reveal_garage_car(store.selected, garage_scroll)

func _reveal_garage_car(car_id: String, scroll: ScrollContainer) -> void:
	# Container positions are not final on the frame the menu is constructed.
	await get_tree().process_frame
	await get_tree().process_frame
	if screen != "garage" or not is_instance_valid(scroll) or scroll != garage_scroll:
		return
	if car_id == Cars.CARS[0].id:
		scroll.scroll_vertical = 0
	elif garage_buttons.has(car_id):
		scroll.ensure_control_visible(garage_buttons[car_id])

func _set_preview(car_id: String) -> void:
	preview_id = car_id
	pending_preview_path = ""
	preview_load_error = false
	CarResources.wanted = ""
	if is_instance_valid(preview) and preview_model_id == car_id:
		preview.show()
		preview.scale = Vector3.ONE * (1.5 if screen == "main" else 1.45)
		return
	var profile := Profiles.profile(car_id)
	if profile.has("path") and not CarResources.ready(profile.path):
		if is_instance_valid(preview):
			preview.hide()
		pending_preview_path = profile.path
		CarResources.request(profile.path)
		return
	_install_preview(car_id)

func is_preview_loading() -> bool:
	return not pending_preview_path.is_empty()

func _install_preview(car_id: String) -> void:
	if is_instance_valid(preview):
		stage.remove_child(preview)
		preview.queue_free()
	var definition := Cars.car(car_id)
	preview = preload("res://scripts/vehicle_visual.gd").build(stage, car_id, definition.color)
	preview.position = Vector3(3.8, 0, 0)
	preview.rotation.y = PI - 0.4
	preview.scale = Vector3.ONE * (1.5 if screen == "main" else 1.45)
	preview_model_id = car_id

func preview_car(car_id: String) -> void:
	if Cars.car(car_id).id != car_id:
		return
	_set_preview(car_id)
	for id in garage_buttons:
		var style := ThemeFactory.box(ThemeFactory.SURFACE if id == car_id else ThemeFactory.NAVY, 12)
		style.border_width_left = 3 if id == car_id else 0
		style.border_color = ThemeFactory.ORANGE
		garage_buttons[id].add_theme_stylebox_override("normal", style)
	var owned: bool = store.owns_car(car_id)
	var price := Economy.price(car_id)
	if is_instance_valid(selected_label):
		selected_label.text = Cars.car(car_id).name
	if is_instance_valid(purchase_button):
		purchase_button.disabled = store.selected == car_id or (not owned and store.coins < price)
		purchase_button.text = "Selected" if store.selected == car_id else ("Use this car" if owned else ("Unlock / %d coins" % price if store.coins >= price else "Need %d more coins" % (price - store.coins)))

func cycle_preview(direction: int) -> void:
	if screen != "garage":
		return
	var index := 0
	for entry in Cars.CARS:
		if entry.id == preview_id:
			break
		index += 1
	preview_car(Cars.CARS[posmod(index + direction, Cars.CARS.size())].id)

func select_preview() -> void:
	if screen != "garage" or is_preview_loading() or preview_load_error:
		return
	if store.owns_car(preview_id):
		store.select_campaign_car(preview_id)
		show_garage()
		return
	if is_instance_valid(purchase_dialog) or store.coins < Economy.price(preview_id):
		return
	pending_purchase = preview_id
	purchase_dialog = ConfirmationDialog.new()
	purchase_dialog.title = "Unlock vehicle"
	purchase_dialog.dialog_text = "%s\nSpend %d coins? Balance after purchase: %d" % [Cars.car(preview_id).name, Economy.price(preview_id), store.coins - Economy.price(preview_id)]
	purchase_dialog.ok_button_text = "Confirm unlock"
	purchase_dialog.get_ok_button().custom_minimum_size.y = 56
	purchase_dialog.get_cancel_button().custom_minimum_size.y = 56
	purchase_dialog.theme = ui.theme
	purchase_dialog.confirmed.connect(_confirm_purchase)
	purchase_dialog.canceled.connect(_cancel_purchase)
	purchase_dialog.close_requested.connect(_cancel_purchase)
	ui.add_child(purchase_dialog)
	purchase_dialog.popup_centered(Vector2i(560, 210))

func _cancel_purchase() -> void:
	pending_purchase = ""
	if is_instance_valid(purchase_dialog):
		purchase_dialog.hide()
		purchase_dialog.queue_free()
		purchase_dialog = null

func _confirm_purchase() -> void:
	var id := pending_purchase
	_cancel_purchase()
	if screen != "garage" or id.is_empty():
		return
	var purchased: bool = store.purchase_car(id)
	show_garage()
	preview_car(id)
	if not purchased and is_instance_valid(save_notice):
		save_notice.text = store.save_error if not store.save_error.is_empty() else "Not enough coins. No purchase made."
		save_notice.show()

func start_level(index: int) -> bool:
	if not store.unlocked(index) or Catalog.level(index).is_empty():
		return false
	_clear_level()
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	screen = "play"
	selected_district = index / 20
	stage.hide()
	$Sun.hide()
	$WorldEnvironment.environment = null
	active_level = LevelScene.instantiate()
	active_level.level_index = index
	active_level.selected_car = store.selected if store.owns_car(store.selected) else "metro"
	active_level.exit_requested.connect(show_levels)
	active_level.advance_requested.connect(_next_level)
	add_child(active_level)
	return true

func _next_level() -> void:
	if not is_instance_valid(active_level) or not active_level.level_finished:
		return
	var index: int = active_level.level_index + 1
	if index == Catalog.COUNT:
		show_levels()
	else:
		start_level(index)

func _process(delta: float) -> void:
	CarResources.poll()
	if screen == "garage" or screen == "main":
		if is_preview_loading():
			if CarResources.ready(pending_preview_path):
				pending_preview_path = ""
				_install_preview(preview_id)
				if screen == "garage":
					preview_car(preview_id)
			elif CarResources.failed.has(pending_preview_path):
				pending_preview_path = ""
				preview_load_error = true
		if not is_instance_valid(preview_loading_label) or preview_loading_label.is_queued_for_deletion():
			preview_loading_label = _label("", 18)
			preview_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			preview_loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ui.add_child(preview_loading_label)
			preview_loading_label.set_anchor_and_offset(SIDE_LEFT, 0.51, 0)
			preview_loading_label.set_anchor_and_offset(SIDE_RIGHT, 0.96, 0)
			preview_loading_label.set_anchor_and_offset(SIDE_TOP, 0.82, 0)
			preview_loading_label.set_anchor_and_offset(SIDE_BOTTOM, 0.88, 0)
		preview_loading_label.text = "Couldn't load this car. Select it to retry." if preview_load_error else "Loading vehicle…"
		preview_loading_label.visible = is_preview_loading() or preview_load_error
		if screen == "garage" and is_instance_valid(purchase_button) and (is_preview_loading() or preview_load_error):
			purchase_button.disabled = true
	elif is_instance_valid(preview_loading_label):
		preview_loading_label.hide()
	if screen == "garage" and is_instance_valid(preview):
		preview.rotation.y += delta * 0.18

func _unhandled_key_input(event: InputEvent) -> void:
	if screen != "play" and event.is_action_pressed("ui_cancel"):
		show_main()

func show_audio() -> void:
	_clear_level()
	screen = "audio"
	var column := _clear_ui()
	column.add_theme_constant_override("separation", 10)
	column.add_child(_label("Settings", 36))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	var panel := _panel(row, 480)
	panel.add_child(_label("Master volume", 24))
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(400, 48)
	slider.value = store.audio_volume
	panel.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		store.audio_volume = value
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001)))
	)
	slider.drag_ended.connect(func(_changed: bool) -> void: store.save_progress())
	slider.focus_exited.connect(store.save_progress)
	panel.add_child(_label("Engine, tires and parking feedback", 18))
	panel.add_child(_button("Back to home", func() -> void: store.save_progress(); show_main(), true))
	var controls := _panel(row, 480)
	controls.add_theme_constant_override("separation", 6)
	controls.add_child(_label("Driving controls", 24))
	preload("res://scripts/driving_preferences.gd").build(controls, store)
	_footer(column)

func _hide_button_text(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 1)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color(0,0,0,0))

func _button_content(button: Button) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 14)
	for side in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 8)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)
	return column

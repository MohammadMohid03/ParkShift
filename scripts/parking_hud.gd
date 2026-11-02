extends CanvasLayer
## Presentation and button signals only; no driving or parking rules.
signal restart_requested
signal next_requested
signal resume_requested
signal menu_requested
var level_number: int = 1
var reverse_required: bool = false
var touch_root: Control
var steering_wheel: Control
var reward_tween: Tween
var impact_tween: Tween
var controls_dialog: AcceptDialog
var camera_toolbar: HBoxContainer
@onready var readout: Label = $Root/TopBar/Row/Readout
@onready var target: Label = $Root/Feedback/Column/Target
@onready var instruction: Label = $Root/Feedback/Column/Instruction
@onready var progress: ProgressBar = $Root/Feedback/Column/Hold
@onready var overlay: ColorRect = $Root/Overlay
@onready var title: Label = $Root/Overlay/Center/Panel/Column/Title
@onready var stars: Label = $Root/Overlay/Center/Panel/Column/Stars
@onready var detail: Label = $Root/Overlay/Center/Panel/Column/Detail
@onready var next_button: Button = $Root/Overlay/Center/Panel/Column/Buttons/Next
@onready var resume_button: Button = $Root/Overlay/Center/Panel/Column/Resume
@onready var hint: Label = $Root/Feedback/Column/Hint
@onready var lives_label: Label = $Root/TopBar/Row/Lives
@onready var retry_button: Button = $Root/Overlay/Center/Panel/Column/Buttons/Restart

func _ready() -> void:
	var palette = preload("res://scripts/campaign_theme.gd")
	$Root.theme = palette.create_theme()
	var bar_style: StyleBoxFlat = palette.box(Color(0.08, 0.11, 0.09, 0.97), 14)
	bar_style.content_margin_top = 10
	bar_style.content_margin_bottom = 10
	$Root/TopBar.add_theme_stylebox_override("panel", bar_style)
	$Root/TopBar/Row/Level.add_theme_font_override("font", palette.DISPLAY)
	$Root/TopBar/Row/Level.add_theme_font_size_override("font_size", 24)
	lives_label.add_theme_font_size_override("font_size", 18)
	title.add_theme_font_override("font", palette.DISPLAY)
	title.add_theme_font_size_override("font_size", 40)
	$Root/TopBar/Row/Restart.pressed.connect(func() -> void: restart_requested.emit())
	$Root/Overlay/Center/Panel/Column/Buttons/Restart.pressed.connect(func() -> void: restart_requested.emit())
	next_button.pressed.connect(func() -> void: next_requested.emit())
	resume_button.pressed.connect(func() -> void: resume_requested.emit())

func begin_level(gold: float, silver: float) -> void:
	if is_instance_valid(controls_dialog):
		controls_dialog.hide()
	if impact_tween != null:
		impact_tween.kill()
	lives_label.modulate = Color.WHITE
	if reward_tween != null:
		reward_tween.kill()
	stars.scale = Vector2.ONE
	_toggle_touch(true)
	get_viewport().gui_release_focus()
	$Root/Feedback.show()
	overlay.hide()
	next_button.disabled = false
	next_button.text = "Next Level"
	next_button.show()
	retry_button.text = "Restart"
	var level_selection := $Root/Overlay/Center/Panel/Column.get_node_or_null("LevelSelection")
	if level_selection != null:
		level_selection.show()
	hint.text = "3 stars: %ds   /   2 stars: %ds   /   Finish for 1 star" % [roundi(gold), roundi(silver)]
	update_driving(0, 0, "GO AROUND THE BARRIER TO THE MINT BAY", 0, 20)

func show_data_error(message: String) -> void:
	_toggle_touch(false)
	$Root/Feedback.hide()
	$Root/TargetMarker.hide()
	$Root/TopBar.hide()
	title.text = "Campaign unavailable"
	detail.text = "Repair the campaign data and restart.\n" + message
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stars.hide()
	next_button.hide()
	resume_button.hide()
	retry_button.hide()
	var levels: Button = $Root/Overlay/Center/Panel/Column/LevelSelection
	levels.show()
	levels.pressed.connect(func() -> void: menu_requested.emit())
	overlay.show()

func update_driving(seconds: float, speed: float, message: String, hold: float, distance: float) -> void:
	readout.text = "%02d:%02d   |   %02d km/h" % [int(seconds) / 60, int(seconds) % 60, roundi(absf(speed) * 3.6)]
	target.text = ("R  REVERSE BAY  /  %dm" if reverse_required else "P  TARGET BAY  /  %dm") % ceili(distance)
	instruction.text = message
	progress.value = hold

func show_complete(count: int, seconds: float) -> void:
	_toggle_touch(false)
	$Root/Feedback.hide()
	$Root/TargetMarker.hide()
	title.text = "Perfectly placed"
	stars.text = "★".repeat(count) + "☆".repeat(3 - count)
	detail.text = "Level %02d complete in %.1f seconds\nStars are based on completion time." % [level_number, seconds]
	stars.show()
	next_button.show()
	resume_button.hide()
	overlay.show()
	$Root/Overlay/Center/Panel/Column/Buttons/Restart.grab_focus()
	$Root/Overlay/Center/Panel/Column/Buttons/Restart.text = "Restart"
	next_button.show()
	stars.pivot_offset = stars.size * 0.5
	stars.scale = Vector2.ONE * 0.75
	reward_tween = create_tween()
	reward_tween.tween_property(stars, "scale", Vector2.ONE * 1.08, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reward_tween.tween_property(stars, "scale", Vector2.ONE, 0.15)
	stars.text = char(0x2606).repeat(3)
	for index in range(count):
		var revealed := index + 1
		reward_tween.tween_callback(func() -> void: stars.text = char(0x2605).repeat(revealed) + char(0x2606).repeat(3 - revealed))
		reward_tween.tween_interval(0.13)

func set_paused(paused: bool) -> void:
	_toggle_touch(not paused)
	if not paused:
		if is_instance_valid(controls_dialog):
			controls_dialog.hide()
		get_viewport().gui_release_focus()
	overlay.visible = paused
	if paused:
		title.text = "Paused"
		detail.text = "The timer is stopped.\n" + hint.text
		stars.hide()
		next_button.hide()
		resume_button.show()
		resume_button.grab_focus()
	var controls := $Root/Overlay/Center/Panel/Column.get_node_or_null("DrivingControls")
	if controls != null:
		controls.visible = paused

func flash_impact() -> void:
	if impact_tween != null:
		impact_tween.kill()
	lives_label.modulate = Color("ff6e51")
	impact_tween = create_tween()
	impact_tween.tween_property(lives_label, "modulate", Color.WHITE, 0.4)

func update_lives(count: int) -> void:
	count = clampi(count, 0, 3)
	lives_label.text = "♥ ".repeat(count).strip_edges() + "♡ ".repeat(3 - count).strip_edges()

func show_game_over(hits: int) -> void:
	_toggle_touch(false)
	$Root/Feedback.hide()
	$Root/TargetMarker.hide()
	title.text = "Vehicle damaged"
	stars.hide()
	detail.text = "%d impacts. Your run is over.\nRetry this level and try again." % hits
	next_button.hide()
	resume_button.hide()
	var level_selection := $Root/Overlay/Center/Panel/Column.get_node_or_null("LevelSelection")
	if level_selection != null:
		level_selection.show()
	retry_button.text = "Retry"
	overlay.show()
	retry_button.grab_focus()

func show_next_placeholder() -> void:
	detail.text = "You finished the first parking challenge.\nLevel 02 is not available yet. Try for a faster time!"
	next_button.text = "More levels coming"
	next_button.disabled = true

func update_target(camera: Camera3D, location: Vector3) -> void:
	# When the world-space sign is offscreen or under a HUD panel, point to it.
	var marker: Label = $Root/TargetMarker
	var screen_size: Vector2 = $Root.size
	var point := camera.unproject_position(location)
	var behind := camera.is_position_behind(location)
	var bounds := Rect2(Vector2(85, 145), screen_size - Vector2(170, 370))
	marker.visible = not overlay.visible and (behind or not bounds.has_point(point))
	if not marker.visible:
		return
	if behind:
		point.y = bounds.end.y
	var arrow := "↑" if point.y < bounds.position.y else ("↓" if point.y >= bounds.end.y else ("←" if point.x < bounds.position.x else "→"))
	marker.text = arrow + " PARK %02d" % level_number
	marker.position = point.clamp(bounds.position, bounds.end) - Vector2(60, 0)

func enable_campaign_navigation() -> void:
	var button := Button.new()
	button.text = "Levels"
	button.custom_minimum_size = Vector2(100, 48)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: menu_requested.emit())
	$Root/TopBar/Row.add_child(button)
	var results_button: Button = $Root/Overlay/Center/Panel/Column/LevelSelection
	results_button.visible = true
	results_button.pressed.connect(func() -> void: menu_requested.emit())
	var pause := Button.new()
	pause.text = "Pause"
	pause.custom_minimum_size = Vector2(85, 48)
	pause.focus_mode = Control.FOCUS_NONE
	pause.pressed.connect(func() -> void: get_parent()._set_suspended(true))
	$Root/TopBar/Row.add_child(pause)
	var controls := Button.new()
	controls.name = "DrivingControls"
	controls.text = "Driving controls"
	controls.custom_minimum_size.y = 48
	controls.hide()
	controls.pressed.connect(_show_controls)
	$Root/Overlay/Center/Panel/Column.add_child(controls)

func _show_controls() -> void:
	if is_instance_valid(controls_dialog):
		controls_dialog.queue_free()
	controls_dialog = AcceptDialog.new()
	controls_dialog.wrap_controls = false
	controls_dialog.title = "Driving controls"
	controls_dialog.ok_button_text = "Done"
	controls_dialog.theme = $Root.theme
	controls_dialog.get_ok_button().custom_minimum_size.y = 48
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	controls_dialog.add_child(column)
	column.add_theme_constant_override("separation", 6)
	var store := get_node("/root/Progress")
	preload("res://scripts/driving_preferences.gd").build(column, store, func() -> void:
		get_parent().drive_input.steering_sensitivity = store.steering_sensitivity
		apply_touch_preferences())
	controls_dialog.confirmed.connect(store.save_progress)
	controls_dialog.canceled.connect(store.save_progress)
	$Root.add_child(controls_dialog)
	controls_dialog.popup_centered(Vector2i(560, 510))

func enable_touch_controls(input_source: Node) -> void:
	_enable_camera_controls()
	touch_root = Control.new()
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(touch_root)
	touch_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for index in range(4):
		var touch := preload("res://scripts/touch_control.gd").new()
		touch.action = ["steer_left", "steer_right", "drive", "reverse"][index]
		touch.symbol = ["←", "→", "↑", "↓"][index]
		touch.caption = ["LEFT", "RIGHT", "DRIVE", "REVERSE"][index]
		touch.held.connect(input_source.set_pointer)
		touch_root.add_child(touch)
		touch.anchor_top = 1
		touch.anchor_bottom = 1
		touch.offset_top = -128
		touch.offset_bottom = -20
		if index < 2:
			touch.offset_left = 24 + index * 116
			touch.offset_right = 128 + index * 116
		else:
			touch.anchor_left = 1
			touch.anchor_right = 1
			touch.offset_left = -240 + (index - 2) * 120
			touch.offset_right = -136 + (index - 2) * 120
	steering_wheel = preload("res://scripts/touch_steering_wheel.gd").new()
	steering_wheel.steering_changed.connect(input_source.set_wheel)
	touch_root.add_child(steering_wheel)
	steering_wheel.anchor_top = 1
	steering_wheel.anchor_bottom = 1
	apply_touch_preferences()
	_toggle_touch(true)

func apply_touch_preferences() -> void:
	if not is_instance_valid(touch_root):
		return
	var store := get_node_or_null("/root/Progress")
	var scale: float = store.touch_scale if store != null else 1.0
	var width := 124.0 * scale
	for index in range(4):
		var button: Control = touch_root.get_child(index)
		button.custom_minimum_size = Vector2(width, width)
		button.offset_top = -20 - width
		button.offset_bottom = -20
		if index < 2:
			button.offset_left = 24 + index * (width + 12)
			button.offset_right = button.offset_left + width
		else:
			button.offset_left = -24 - (4 - index) * width - (3 - index) * 12
			button.offset_right = button.offset_left + width
		button.visible = index >= 2 or store == null or store.steering_mode != "wheel"
		button.queue_redraw()
	if is_instance_valid(steering_wheel):
		steering_wheel.release()
		steering_wheel.visible = store != null and store.steering_mode == "wheel"
		steering_wheel.offset_left = 24
		steering_wheel.offset_right = 24 + 178 * scale
		steering_wheel.offset_top = -20 - 178 * scale
		steering_wheel.offset_bottom = -20
	get_parent().drive_input.reset()

func _toggle_touch(active: bool) -> void:
	if is_instance_valid(camera_toolbar):
		camera_toolbar.visible = active
		get_parent().follow_camera.set_interaction_enabled(active)
	if is_instance_valid(touch_root):
		touch_root.visible = active
		if is_instance_valid(steering_wheel):
			steering_wheel.release()
		for button in touch_root.get_children():
			button.tokens.clear()
			button.queue_redraw()

func _enable_camera_controls() -> void:
	if is_instance_valid(camera_toolbar): return
	camera_toolbar = HBoxContainer.new()
	camera_toolbar.name = "CameraControls"
	camera_toolbar.add_theme_constant_override("separation",8)
	$Root.add_child(camera_toolbar)
	camera_toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	camera_toolbar.offset_left = -570
	camera_toolbar.offset_right = -20
	camera_toolbar.offset_top = 104
	camera_toolbar.offset_bottom = 152
	var help := Label.new()
	help.text = "Drag to orbit / pinch to zoom"
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help.add_theme_font_size_override("font_size",16)
	help.add_theme_color_override("font_color",Color("f2f1e8"))
	help.add_theme_color_override("font_shadow_color",Color("151b19"))
	help.add_theme_constant_override("shadow_offset_x",1)
	help.add_theme_constant_override("shadow_offset_y",1)
	camera_toolbar.add_child(help)
	var camera_rig: Node3D = get_parent().follow_camera
	for caption in ["Front","Rear","Reset view"]:
		var button := Button.new()
		button.text = caption
		button.custom_minimum_size = Vector2(86 if caption != "Reset view" else 112,48)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size",16)
		camera_toolbar.add_child(button)
		if caption == "Reset view": button.pressed.connect(camera_rig.reset_view)
		else: button.pressed.connect(camera_rig.show_car_front.bind(caption == "Front"))

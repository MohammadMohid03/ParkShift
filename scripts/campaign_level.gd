extends "res://scripts/parking_level.gd"
const Campaign = preload("res://scripts/campaign_catalog.gd")
const World = preload("res://scenes/district_world.tscn")
const Art = preload("res://scripts/geometry.gd")
const ThemeFactory = preload("res://scripts/campaign_theme.gd")
signal exit_requested
signal advance_requested
var level_index: int = 0
var selected_car: String = "metro"
var difficulty: Dictionary = {}
var reward_token: int = 0
var reward_claimed: bool = false
var reward_label: Label
var retry_save: Button
var road_features: Node3D
var reward_reveal: Tween
var campaign_available: bool = false

func _ready() -> void:
	campaign_available = not Campaign.level(level_index).is_empty()
	if not campaign_available:
		# F6/direct scene entry must also stop before the inherited parking setup.
		set_process(false)
		set_physics_process(false)
		car.active = false
		drive_input.enabled = false
		puzzle_ui.show_data_error(Campaign.error_summary() if not Campaign.available() else "Level index %d is out of range." % level_index)
		puzzle_ui.menu_requested.connect(func() -> void: exit_requested.emit())
		return
	super._ready()

func _set_suspended(value: bool) -> void:
	if campaign_available:
		super._set_suspended(value)

func _configure_parking() -> void:
	var definition := Campaign.level(level_index)
	level_number = level_index + 1
	level_title = definition.name.to_upper()
	spawn_position = definition.start
	spawn_yaw = definition.yaw
	# Keep the long reverse slalom ahead of the camera without gear-change spins.
	follow_camera.reverse_route = level_index >= 5 and definition.reverse
	three_star_seconds = definition.gold
	two_star_seconds = definition.silver
	# Replace only the layout instances; the car, camera and parking loop are reused.
	var yard := get_node("Yard")
	remove_child(yard)
	yard.queue_free()
	remove_child(bay)
	bay.queue_free()
	var world := World.instantiate()
	add_child(world)
	world.build(definition, level_index)
	bay = world.bay
	difficulty = definition.get("difficulty", {})
	bay.heading_tolerance = difficulty.get("heading_degrees", 8.0)
	bay.hold_duration = difficulty.get("hold_seconds", 1.4)
	bay.speed_tolerance = difficulty.get("stop_speed", 0.15)
	for at in definition.cones:
		var cone_root := Node3D.new()
		world.add_child(cone_root)
		cone_root.position = at
		Art.box(cone_root, Vector3(0, 0.045, 0), Vector3(0.5, 0.09, 0.5), Color("132337"))
		var cone := Art.cylinder(cone_root, Vector3(0, 0.35, 0), 0.24, 0.6, Color("ef9149"))
		cone.mesh.top_radius = 0.055
		Art.cylinder(cone_root, Vector3(0, 0.36, 0), 0.15, 0.09, Color("fff1da"))
		Art.collider(cone_root, Vector3(0, 0.35, 0), Vector3(0.5, 0.7, 0.5))
	puzzle_ui.get_node("Root").theme = ThemeFactory.create_theme()
	puzzle_ui.enable_campaign_navigation()
	puzzle_ui.menu_requested.connect(func() -> void: exit_requested.emit())
	car.set_cosmetic(selected_car)
	if definition.has("road_features"):
		road_features = preload("res://scripts/road_features.gd").new()
		add_child(road_features)
		road_features.setup(self, definition, world)
	world.batch_static_meshes()
	var guide := preload("res://scripts/parking_guide.gd").new()
	guide.name = "ParkingGuide"
	guide.car = car
	car.add_child(guide)
	$WorldEnvironment.environment = preload("res://scripts/presentation.gd").environment(int(definition.district))
	preload("res://scripts/presentation.gd").configure_sun($Sun, int(definition.district))
	puzzle_ui.enable_touch_controls($DriveInput)
	var audio := preload("res://scripts/vehicle_audio.gd").new()
	audio.car = car
	add_child(audio)

func _next_level() -> void:
	if level_finished:
		advance_requested.emit()

func _finish_level() -> void:
	if level_finished:
		return
	super._finish_level()
	if difficulty.get("gold_max_hits", -1) >= 0:
		puzzle_ui.detail.text = "Level %02d complete in %.1f seconds / %d hits\nGold requires a clean run; silver allows one hit." % [level_number, elapsed, hit_count]
	if level_index == Campaign.COUNT - 1:
		puzzle_ui.title.text = "Campaign complete"
		puzzle_ui.next_button.text = "Continue / All levels"
	else:
		puzzle_ui.next_button.text = "Continue"
	claim_completion_reward()

func stars_for_time(seconds: float) -> int:
	var rating := super.stars_for_time(seconds)
	var gold_hits: int = difficulty.get("gold_max_hits", -1)
	var silver_hits: int = difficulty.get("silver_max_hits", -1)
	if gold_hits >= 0 and hit_count > gold_hits:
		rating = mini(rating, 2)
	if silver_hits >= 0 and hit_count > silver_hits:
		rating = mini(rating, 1)
	return rating

func reset_drive() -> void:
	if not campaign_available:
		return
	if reward_reveal != null:
		reward_reveal.kill()
	super.reset_drive()
	if is_instance_valid(road_features):
		road_features.reset()
	reward_claimed = false
	reward_token = get_node("/root/Progress").begin_run(level_index)
	if is_instance_valid(reward_label):
		reward_label.text = ""
	if is_instance_valid(retry_save):
		retry_save.hide()
	if difficulty.get("gold_max_hits", -1) >= 0:
		puzzle_ui.hint.text += "  /  Gold: clean  /  Silver: 1 hit max"
	var economy = preload("res://scripts/economy.gd")
	puzzle_ui.hint.text += "\nCoins: Gold %d / Silver %d / Bronze %d" % [economy.quote(level_index, 3, 0).coins, economy.quote(level_index, 2, 0).coins, economy.quote(level_index, 1, 0).coins]

func _on_car_contacted(impact_speed: float) -> void:
	super._on_car_contacted(impact_speed)
	if life_failed:
		get_node("/root/Progress").abandon_run()

func claim_completion_reward() -> void:
	if not level_finished or life_failed or reward_claimed:
		return
	var store := get_node("/root/Progress")
	if not is_instance_valid(reward_label):
		var column := puzzle_ui.get_node("Root/Overlay/Center/Panel/Column")
		reward_label = Label.new()
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.add_theme_font_size_override("font_size", 20)
		reward_label.add_theme_color_override("font_color", ThemeFactory.ORANGE)
		column.add_child(reward_label)
		column.move_child(reward_label, 3)
		retry_save = Button.new()
		retry_save.text = "Retry saving reward"
		retry_save.custom_minimum_size.y = 52
		retry_save.pressed.connect(claim_completion_reward)
		column.add_child(retry_save)
	var reward: Dictionary = store.claim_run(reward_token, level_index, awarded_stars, elapsed)
	if reward.is_empty():
		reward_label.text = "Reward not saved. No coins credited."
		puzzle_ui.detail.text = store.save_error
		retry_save.show()
		puzzle_ui.next_button.disabled = true
		return
	reward_claimed = true
	retry_save.hide()
	puzzle_ui.next_button.disabled = false
	puzzle_ui.detail.text = "Time %.1fs / Gold target %.1fs / Silver target %.1fs\n%d hits / %s medal" % [elapsed, three_star_seconds, two_star_seconds, hit_count, reward.name]
	reward_label.text = "+%d coins / Balance %d\n%s" % [reward.coins, store.coins, ("Reward already claimed. Improve your medal to earn the difference." if int(reward.coins) == 0 else "%d%% of %d base coins, less %d previously claimed" % [reward.percent, reward.base, mini(int(reward.previously_paid), int(reward.entitlement))])]
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Reward is already committed once; presentation never changes the balance.
	reward_label.modulate.a = 0.0
	reward_reveal = create_tween()
	reward_reveal.tween_interval(0.25)
	reward_reveal.tween_property(reward_label, "modulate:a", 1.0, 0.35)

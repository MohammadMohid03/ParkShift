extends "res://scripts/driving_test.gd"
## Single-level loop built on the Phase 2 scene and controller.
signal level_completed(stars: int)
@export var spawn_position := Vector3(7, 0.05, 9)
@export var spawn_yaw: float = 0.0
@export var target_position := Vector3(3, 0, -10.5)
@export var target_yaw: float = 0.0
@export var three_star_seconds: float = 60.0
@export var two_star_seconds: float = 100.0
@onready var bay: Node3D = $ParkingBay
@onready var puzzle_ui: CanvasLayer = $ParkingHUD
@onready var sound: Node = $SuccessSound
var elapsed: float = 0.0
var run_clock := preload("res://scripts/run_clock.gd").new()
var gameplay_started: bool = false
var level_finished: bool = false
var life_failed: bool = false
var hit_count: int = 0
var lives_remaining: int = 3
var awarded_stars: int = 0
var celebration: Tween
@export var level_number: int = 1
@export var level_title: String = "THE FIRST TURN"

func _ready() -> void:
	# Car updates before the parking evaluation each physics tick.
	process_physics_priority = 5
	_configure_parking()
	bay.parking_completed.connect(_finish_level)
	puzzle_ui.restart_requested.connect(reset_drive)
	puzzle_ui.resume_requested.connect(func() -> void: _set_suspended(false))
	puzzle_ui.next_requested.connect(_next_level)
	car.contacted.connect(_on_car_contacted)
	var sign_label := Label3D.new()
	sign_label.text = "PARK %02d" % level_number
	sign_label.font_size = 48
	sign_label.pixel_size = 0.012
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.position = Vector3(0, 2.2, 0)
	sign_label.modulate = Color("b2f5d9")
	bay.add_child(sign_label)
	super._ready()

func _configure_parking() -> void:
	bay.configure(target_position, target_yaw, Vector2(3.2, 5.6), false)

func _next_level() -> void:
	puzzle_ui.show_next_placeholder()

func reset_drive() -> void:
	run_clock.reset()
	gameplay_started = false
	life_failed = false
	hit_count = 0
	lives_remaining = 3
	if celebration != null:
		celebration.kill()
	level_finished = false
	awarded_stars = 0
	elapsed = 0.0
	bay.reset_progress()
	super.reset_drive()
	car.reset(spawn_position, spawn_yaw)
	car.reset_physics_interpolation()
	follow_camera.snap_to_target()
	if is_instance_valid(sound.player):
		sound.player.stop()
	puzzle_ui.level_number = level_number
	puzzle_ui.reverse_required = bay.reverse_required
	puzzle_ui.get_node("Root/TopBar/Row/Level").text = "%02d / %s" % [level_number, level_title]
	puzzle_ui.begin_level(three_star_seconds, two_star_seconds)
	puzzle_ui.update_lives(lives_remaining)

func _physics_process(delta: float) -> void:
	if suspended or level_finished or life_failed:
		return
	if not gameplay_started:
		gameplay_started = true
		run_clock.resume()
	elapsed = run_clock.seconds()
	bay.evaluate(car, delta)

func _process(_delta: float) -> void:
	if not level_finished and not life_failed:
		puzzle_ui.update_driving(elapsed, car.speed, bay.status, bay.progress, car.global_position.distance_to(bay.global_position))
		puzzle_ui.update_target(get_viewport().get_camera_3d(), bay.global_position + Vector3.UP * 2.2)

func stars_for_time(seconds: float) -> int:
	if seconds <= three_star_seconds:
		return 3
	if seconds <= maxf(three_star_seconds, two_star_seconds):
		return 2
	return 1

func _finish_level() -> void:
	if level_finished or life_failed:
		return
	run_clock.pause()
	elapsed = run_clock.seconds()
	level_finished = true
	awarded_stars = stars_for_time(elapsed)
	car.active = false
	car.speed = 0.0
	car.velocity = Vector3.ZERO
	puzzle_ui.update_driving(elapsed, 0, bay.status, 1.0, 0)
	drive_input.enabled = false
	drive_input.reset()
	sound.cue(true)
	preload("res://scripts/driving_feedback.gd").pulse(self, 55)
	celebration = create_tween()
	celebration.tween_property(bay.pad_material, "albedo_color", Color("c9ffe6"), 0.18)
	celebration.tween_property(bay.pad_material, "albedo_color", Color("70cfa7"), 0.35)
	puzzle_ui.show_complete(awarded_stars, elapsed)
	level_completed.emit(awarded_stars)

func _on_car_contacted(_impact_speed: float) -> void:
	if suspended or level_finished or life_failed:
		return
	hit_count += 1
	lives_remaining = maxi(0, lives_remaining - 1)
	puzzle_ui.update_lives(lives_remaining)
	preload("res://scripts/driving_feedback.gd").pulse(self, 35 if lives_remaining > 0 else 70)
	puzzle_ui.flash_impact()
	if lives_remaining == 0:
		run_clock.pause()
		elapsed = run_clock.seconds()
		life_failed = true
		car.active = false
		car.speed = 0.0
		car.velocity = Vector3.ZERO
		drive_input.enabled = false
		drive_input.reset()
		puzzle_ui.show_game_over(hit_count)

func _set_suspended(value: bool) -> void:
	if level_finished or life_failed:
		return
	if value:
		run_clock.pause()
		elapsed = run_clock.seconds()
	elif gameplay_started:
		run_clock.resume()
	super._set_suspended(value)
	puzzle_ui.set_paused(value)

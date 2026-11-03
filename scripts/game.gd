extends Node3D
## One explicit state machine owns transitions; each level is data-driven.

enum State { MENU, PLAYING, PAUSED, RESULTS, GARAGE }
const Catalog = preload("res://scripts/level_catalog.gd")
const WorldScene: PackedScene = preload("res://scenes/level_world.tscn")
const Art = preload("res://scripts/geometry.gd")
var state: State = State.MENU
var level_index: int = 0
var elapsed: float = 0.0
var contacts: int = 0
var toast_seconds: float = 0.0
var world: Node3D
var preview_id: String = "metro"
var garage_stage: Node3D
@onready var progress_store: Node = get_node("/root/Progress")
@onready var car: CharacterBody3D = $Car
@onready var drive_input: Node = $DriveInput
@onready var ui: CanvasLayer = $UI
@onready var camera: Camera3D = $Camera3D
@onready var sound: Node = $Sound

func _ready() -> void:
	car.input_source = drive_input
	car.contacted.connect(_on_contact)
	ui.level_requested.connect(start_level)
	ui.menu_requested.connect(show_menu)
	ui.garage_requested.connect(show_garage)
	ui.pause_requested.connect(pause_run)
	ui.resume_requested.connect(resume_run)
	ui.retry_requested.connect(func() -> void: start_level(level_index))
	ui.next_requested.connect(func() -> void: start_level(level_index + 1))
	ui.touch_held.connect(drive_input.set_pointer)
	ui.car_previewed.connect(preview_car)
	ui.car_purchased.connect(_purchase_car)
	show_menu()

func _clear_world() -> void:
	progress_store.abandon_run()
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
		world = null
	if is_instance_valid(garage_stage):
		remove_child(garage_stage)
		garage_stage.queue_free()
		garage_stage = null

func _build_level(index: int) -> void:
	_clear_world()
	world = WorldScene.instantiate()
	add_child(world)
	world.build(Catalog.LEVELS[index], index)
	car.reset(Catalog.LEVELS[index].start, Catalog.LEVELS[index].yaw)
	car.set_cosmetic(progress_store.selected)
	camera.position = Vector3(0, 29, 23)
	camera.look_at(Vector3(0, 0, -0.5))
	camera.size = 27.0

func _set_state(next_state: State) -> void:
	state = next_state
	drive_input.reset()
	drive_input.enabled = state == State.PLAYING
	car.active = state == State.PLAYING

func show_menu() -> void:
	_set_state(State.MENU)
	_build_level(0)
	camera.position = Vector3(22, 30, 26)
	camera.look_at(Vector3.ZERO)
	camera.size = 29.0
	ui.show_menu(progress_store)

func start_level(index: int) -> bool:
	if index < 0 or index >= Catalog.LEVELS.size() or not progress_store.unlocked(index):
		return false
	level_index = index
	_build_level(index)
	progress_store.begin_run(index)
	elapsed = 0.0
	contacts = 0
	toast_seconds = 0.0
	_set_state(State.PLAYING)
	ui.show_play(Catalog.LEVELS[index], index)
	return true

func pause_run() -> void:
	if state != State.PLAYING:
		return
	_set_state(State.PAUSED)
	ui.show_pause()

func resume_run() -> void:
	if state != State.PAUSED:
		return
	_set_state(State.PLAYING)
	ui.show_play(Catalog.LEVELS[level_index], level_index)

func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	elapsed += delta
	toast_seconds = maxf(0.0, toast_seconds - delta)
	var parked: bool = world.bay.evaluate(car, delta)
	ui.update_play(elapsed, contacts, car.speed, world.bay.status, world.bay.progress, "CONTACT  /  TAKE IT SLOW" if toast_seconds > 0.0 else "")
	if parked:
		_finish_level()

func _process(delta: float) -> void:
	if state == State.GARAGE and is_instance_valid(car.model):
		car.model.rotation.y += delta * 0.22

func _finish_level() -> void:
	_set_state(State.RESULTS)
	car.speed = 0.0
	car.velocity = Vector3.ZERO
	var stars: int = Catalog.stars_for(elapsed, contacts, Catalog.LEVELS[level_index].par)
	var reward: int = progress_store.complete_level(level_index, stars, elapsed)
	sound.cue(true)
	ui.show_result(level_index, stars, elapsed, contacts, reward, progress_store)

func _on_contact(_impact: float) -> void:
	if state == State.PLAYING:
		contacts += 1
		toast_seconds = 1.5
		sound.cue(false)

func show_garage() -> void:
	_set_state(State.GARAGE)
	_clear_world()
	garage_stage = Node3D.new()
	add_child(garage_stage)
	Art.box(garage_stage, Vector3(0, -0.2, 0), Vector3(150, 0.4, 150), Color("cfdbc9"))
	Art.cylinder(garage_stage, Vector3(-1.7, -0.025, 0), 3.6, 0.08, Color("e6e1cd"), 48)
	car.reset(Vector3(-1.7, 0.035, 0), 0.0)
	camera.position = Vector3(6, 8, 12)
	camera.look_at(Vector3(0, 0.4, 0))
	camera.size = 8.5
	preview_car(progress_store.selected)

func preview_car(car_id: String) -> void:
	if state != State.GARAGE:
		return
	preview_id = car_id
	car.set_cosmetic(car_id)
	ui.show_garage(progress_store, preview_id)

func _purchase_car(car_id: String) -> void:
	if state != State.GARAGE or Catalog.car(car_id).id != car_id:
		return
	if progress_store.owns_car(car_id):
		progress_store.select_car(car_id)
		preview_car(car_id)
		return
	var price := preload("res://scripts/economy.gd").price(car_id)
	if price <= 0 or progress_store.coins < price or has_node("PurchaseConfirmation"):
		return
	var dialog := ConfirmationDialog.new()
	dialog.name = "PurchaseConfirmation"
	dialog.dialog_text = "Unlock %s for %d coins?" % [Catalog.car(car_id).name, price]
	dialog.ok_button_text = "Confirm unlock"
	dialog.get_ok_button().custom_minimum_size.y = 56
	dialog.get_cancel_button().custom_minimum_size.y = 56
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		if state == State.GARAGE and progress_store.purchase_car(car_id):
			preview_car(car_id)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(560, 210))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if state == State.PLAYING:
			pause_run()
		elif state == State.PAUSED:
			resume_run()
		else:
			show_menu()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED) and is_node_ready():
		pause_run()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		if state == State.PLAYING:
			pause_run()
		else:
			show_menu()

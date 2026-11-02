extends CharacterBody3D
## Kinematic arcade bicycle model with per-vehicle dimensions and handling.

signal contacted(impact_speed: float)
const Art = preload("res://scripts/geometry.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const Profiles = preload("res://scripts/vehicle_profiles.gd")
const Visual = preload("res://scripts/vehicle_visual.gd")
@export var maximum_speed: float = 7.0
@export var reverse_speed: float = 3.6
@export var acceleration: float = 5.5
@export var braking: float = 15.0
@export var steering_angle: float = 0.60
@export var coasting_deceleration: float = 2.8
@export var steering_response: float = 5.0
@export var wheelbase: float = 2.25
@export var gravity: float = 18.0
@export var high_speed_steering_factor: float = 0.65
## Optional replacement model: origin at ground level, nose pointing along -Z.
@export var visual_scene: PackedScene
var input_source: Node
var active: bool = false
var speed: float = 0.0
var steering: float = 0.0
var reverse_distance: float = 0.0
var contact_latched: bool = false
var contact_damage_reported: bool = false
var contact_position: Vector3 = Vector3.ZERO
var vehicle_size := Vector3(1.82, 1.47, 4.26)
var wheel_radius: float = 0.315
var model: Node3D
var cosmetic_id: String = "metro"
var turn_query := PhysicsShapeQueryParameters3D.new()
var road_speed_limit: float = INF
var road_bump_height: float = 0.0
var visual_wheels: Array[Node] = []
var tail_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	set_cosmetic(cosmetic_id)
	# Slight inset prevents the resting floor contact from blocking every turn.
	var turn_shape := BoxShape3D.new()
	turn_shape.size = $CollisionShape3D.shape.size - Vector3.ONE * 0.006
	turn_query.shape = turn_shape
	turn_query.collision_mask = collision_mask
	turn_query.exclude = [get_rid()]
	turn_query.margin = 0.0

func set_cosmetic(car_id: String) -> void:
	car_id = Catalog.car(car_id).id
	cosmetic_id = car_id
	var profile := Profiles.profile(car_id)
	vehicle_size = profile.size
	wheel_radius = profile.radius
	for key in ["maximum_speed", "reverse_speed", "acceleration", "braking", "coasting_deceleration", "steering_angle", "steering_response", "high_speed_steering_factor", "wheelbase"]:
		set(key, profile[key])
	var collision := BoxShape3D.new()
	collision.size = Vector3(vehicle_size.x, 1.2, vehicle_size.z)
	$CollisionShape3D.shape = collision
	$CollisionShape3D.position.y = 0.6
	if turn_query.shape != null:
		turn_query.shape.size = collision.size - Vector3.ONE * 0.006
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	if visual_scene != null:
		model = visual_scene.instantiate() as Node3D
		add_child(model)
	else:
		var definition := Catalog.car(car_id)
		model = Visual.build(self, car_id, definition.color)
	model.name = "VehicleVisual"
	visual_wheels = model.find_children("Wheel_*", "Node3D", true, false)
	tail_materials.clear()
	var brake_material: StandardMaterial3D = model.get_meta("brake_material") if model.has_meta("brake_material") else null
	if brake_material != null:
		tail_materials.append(brake_material)
	for material in model.get_meta("brake_materials", []):
		tail_materials.append(material)

func parking_half_extents() -> Vector2:
	return Vector2(vehicle_size.x, vehicle_size.z) * 0.5

func reset(at: Vector3, yaw: float) -> void:
	position = at
	rotation = Vector3(0, yaw, 0)
	velocity = Vector3.ZERO
	speed = 0.0
	steering = 0.0
	reverse_distance = 0.0
	road_speed_limit = INF
	road_bump_height = 0.0
	contact_latched = false
	contact_damage_reported = false
	if is_instance_valid(model):
		model.rotation = Vector3.ZERO
		model.position.y = 0.0
	for wheel in visual_wheels:
		wheel.rotation.y = 0
		wheel.get_node("Roll").rotation = Vector3.ZERO
	for mat in tail_materials:
		mat.emission_energy_multiplier = 0.3

func _physics_process(delta: float) -> void:
	if not active or input_source == null:
		return
	var pedal: float = input_source.throttle()
	var brake: float = input_source.strength("brake")
	var is_braking := brake > 0.0 or pedal * speed < 0.0
	steering = move_toward(steering, input_source.steer(), delta * steering_response * input_source.steering_sensitivity)
	if brake > 0.0:
		speed = move_toward(speed, 0.0, braking * delta)
	elif not is_zero_approx(pedal):
		var target: float = pedal * (maximum_speed if pedal > 0.0 else reverse_speed)
		var rate: float = braking if speed * pedal < 0.0 else acceleration
		speed = move_toward(speed, target, rate * delta)
	else:
		speed = move_toward(speed, 0.0, coasting_deceleration * delta)
	if absf(speed) > road_speed_limit:
		speed = move_toward(speed, signf(speed) * road_speed_limit, braking * delta)
	var steering_scale := lerpf(1.0, high_speed_steering_factor, clampf(absf(speed) / maxf(maximum_speed, 0.1), 0.0, 1.0))
	_turn_safely(-speed / maxf(wheelbase, 0.1) * tan(steering * steering_angle * steering_scale) * delta)
	var forward := -global_basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	velocity.y = -1.0 if is_on_floor() else velocity.y - gravity * delta
	var old_position := global_position
	move_and_slide()
	var hit: bool = false
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if absf(collision.get_normal().y) < 0.6:
			hit = true
			break
	# At tiny contact distances floor recovery can consume the slide iterations.
	# Keep the speedometer and acceleration state honest if translation is blocked.
	var travelled := (global_position - old_position).dot(forward) * signf(speed)
	if absf(speed) > 0.01 and travelled < absf(speed) * delta * 0.5:
		hit = true
	if hit:
		if not contact_latched:
			contact_latched = true
			contact_damage_reported = false
			contact_position = global_position
		if not contact_damage_reported and absf(speed) > 0.4:
			# A clear side impact counts; soft contact at a standstill does not.
			contacted.emit(absf(speed))
			contact_damage_reported = true
		speed = 0.0
	elif not contact_latched or global_position.distance_to(contact_position) > 0.5:
		# Sliding or holding against one obstacle is one hit. Back away to re-arm.
		contact_latched = false
		contact_damage_reported = false
	if speed < -0.1:
		reverse_distance += Vector2(global_position.x - old_position.x, global_position.z - old_position.z).length()
	elif speed > 0.1:
		reverse_distance = 0.0
	if is_instance_valid(model):
		for wheel in visual_wheels:
			# Wheel rolling is unchanged; the body gets only a subtle road response.
			wheel.rotation.y = -steering * steering_angle * steering_scale if wheel.get_meta("front", false) else 0.0
			wheel.get_node("Roll").rotate(wheel.get_meta("roll_axis", Vector3(0, 0, 1)), -(global_position - old_position).dot(forward) / float(wheel.get_meta("radius", wheel_radius)))
		model.position.y = lerpf(model.position.y, road_bump_height, 1.0 - exp(-18.0 * delta))
		for mat in tail_materials:
			mat.emission_energy_multiplier = 2.0 if is_braking else 0.3

func _turn_safely(angle: float) -> void:
	# Translation is swept by move_and_slide; rotation needs its own overlap guard.
	# Small angular steps also protect corners while creeping beside a wall.
	var steps := maxi(1, ceili(absf(angle) / 0.01))
	for step in range(steps):
		var candidate := global_transform
		candidate.basis = Basis(Vector3.UP, angle / steps) * candidate.basis
		turn_query.transform = candidate * $CollisionShape3D.transform
		if not get_world_3d().direct_space_state.intersect_shape(turn_query, 1).is_empty():
			return
		global_transform = candidate

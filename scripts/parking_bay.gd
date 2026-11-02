extends Node3D
## Full footprint containment, heading, speed and continuous hold validation.
signal parking_completed

const Art = preload("res://scripts/geometry.gd")
const CarScript = preload("res://scripts/car.gd")
const HOLD_SECONDS: float = 1.4
const HEADING_TOLERANCE: float = 8.0
const SPEED_TOLERANCE: float = 0.15
@export var hold_duration: float = HOLD_SECONDS
@export var heading_tolerance: float = HEADING_TOLERANCE
@export var speed_tolerance: float = SPEED_TOLERANCE
@export var edge_margin: float = 0.08
@export var height_tolerance: float = 0.3
## Fallback for older custom vehicles; current cars provide measured extents.
@export var visual_half_width: float = 0.98
@export var visual_half_length: float = 1.75
var size: Vector2 = Vector2(3.2, 5.2)
var reverse_required: bool = false
var held_seconds: float = 0.0
var status: String = "FIND THE MINT BAY"
var progress: float = 0.0
var completed: bool = false
var pad: MeshInstance3D
var pad_material: StandardMaterial3D

func configure(at: Vector3, yaw: float, dimensions: Vector2, reverse_only: bool) -> void:
	position = at
	rotation.y = yaw
	size = dimensions
	reverse_required = reverse_only
	pad = Art.box(self, Vector3(0, 0.014, 0), Vector3(size.x, 0.012, size.y), Color("436d65"))
	# A private material prevents feedback changing other procedural art.
	pad_material = pad.material_override.duplicate() as StandardMaterial3D
	pad.material_override = pad_material
	for x in [-size.x * 0.5, size.x * 0.5]:
		Art.box(self, Vector3(x, 0.035, 0), Vector3(0.08, 0.015, size.y), Color("b2f5d9"))
	for z in [-size.y * 0.5, size.y * 0.5]:
		Art.box(self, Vector3(0, 0.035, z), Vector3(size.x, 0.015, 0.08), Color("b2f5d9"))
	# Arrow at the front communicates the required car heading.
	for side in [-1.0, 1.0]:
		var arrow := Art.box(self, Vector3(side * 0.25, 0.045, -size.y * 0.5 - 0.6), Vector3(0.65, 0.02, 0.09), Color("b2f5d9"))
		arrow.rotation.y = side * -PI / 4.0
	var label := Label3D.new()
	label.text = "R" if reverse_required else "P"
	label.font_size = 100
	label.pixel_size = 0.011
	label.position = Vector3(0, 0.045, 0)
	label.rotation.x = -PI / 2.0
	label.modulate = Color("b2f5d9")
	label.outline_size = 0
	add_child(label)

func contains_vehicle(car: Node3D) -> bool:
	if absf(to_local(car.global_position).y) > height_tolerance:
		return false
	var half_width := visual_half_width
	var half_length := visual_half_length
	if car.has_method("parking_half_extents"):
		var footprint: Vector2 = car.parking_half_extents()
		half_width = footprint.x
		half_length = footprint.y
	var collision := car.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null and collision.shape is BoxShape3D:
		half_width = maxf(half_width, collision.shape.size.x * absf(collision.scale.x) * 0.5 + absf(collision.position.x))
		half_length = maxf(half_length, collision.shape.size.z * absf(collision.scale.z) * 0.5 + absf(collision.position.z))
	for x in [-half_width, half_width]:
		for z in [-half_length, half_length]:
			var corner := to_local(car.to_global(Vector3(x, 0, z)))
			if absf(corner.x) > size.x * 0.5 - edge_margin or absf(corner.z) > size.y * 0.5 - edge_margin:
				return false
	return true

func evaluate(car: Node3D, delta: float) -> bool:
	if completed:
		return true
	var contained := contains_vehicle(car)
	var car_forward := -car.global_basis.z
	var bay_forward := -global_basis.z
	var angle: float = rad_to_deg(Vector2(car_forward.x, car_forward.z).angle_to(Vector2(bay_forward.x, bay_forward.z)))
	angle = absf(angle)
	var near := to_local(car.global_position).length() < 6.0
	var planar_speed := absf(car.speed)
	if car is CharacterBody3D:
		planar_speed = maxf(planar_speed, Vector2(car.velocity.x, car.velocity.z).length())
	var valid: bool = contained and angle <= heading_tolerance and planar_speed <= speed_tolerance
	var reverse_ready: bool = not reverse_required or car.reverse_distance >= 1.5
	if not reverse_ready:
		valid = false
	if valid:
		held_seconds += delta
		status = "HOLD STEADY"
	elif not contained:
		held_seconds = 0.0
		status = "FIT ALL FOUR CORNERS INSIDE" if near else "FIND THE MINT BAY"
	elif angle > heading_tolerance:
		held_seconds = 0.0
		status = "POINT THE NOSE TOWARD THE ARROW"
	elif not reverse_ready:
		held_seconds = 0.0
		status = "REVERSE INTO THIS BAY  %.1f / 1.5 m" % minf(car.reverse_distance, 1.5)
	else:
		held_seconds = 0.0
		status = "BRAKE TO A COMPLETE STOP"
	# This bar is strictly the parking hold meter. It stays empty throughout the
	# reverse maneuver, and only advances once every parking condition is valid.
	progress = clampf(held_seconds / maxf(hold_duration, 0.01), 0.0, 1.0)
	completed = held_seconds >= maxf(hold_duration, 0.01)
	if pad_material != null:
		pad_material.albedo_color = Color("70cfa7") if valid else (Color("bf995b") if contained else Color("436d65"))
	if completed:
		status = "PERFECTLY PLACED"
		parking_completed.emit()
	return completed

func reset_progress() -> void:
	held_seconds = 0.0
	progress = 0.0
	completed = false
	status = "FIND THE MINT BAY"
	if pad_material != null:
		pad_material.albedo_color = Color("436d65")

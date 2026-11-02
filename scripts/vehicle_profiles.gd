extends RefCounted
## Stable save IDs; dimensions include mirrors and bumpers, in metres.
const PROFILES := {
	"metro": {"asset": "hatchback", "size": Vector3(1.82, 1.47, 4.26), "center_z": 0.02967, "wheelbase": 2.62, "radius": 0.315, "maximum_speed": 6.5, "reverse_speed": 2.4, "acceleration": 4.3, "braking": 8.5, "coasting_deceleration": 1.4, "steering_angle": 0.70, "steering_response": 4.5, "high_speed_steering_factor": 0.58},
	"touring": {"asset": "suv", "size": Vector3(1.95, 1.77, 4.91), "center_z": -0.045, "wheelbase": 2.90, "radius": 0.365, "maximum_speed": 6.2, "reverse_speed": 2.2, "acceleration": 3.5, "braking": 7.5, "coasting_deceleration": 1.25, "steering_angle": 0.75, "steering_response": 4.0, "high_speed_steering_factor": 0.55},
	"sport": {"asset": "sedan", "size": Vector3(1.88, 1.46, 4.87), "center_z": -0.050, "wheelbase": 2.85, "radius": 0.33, "maximum_speed": 7.0, "reverse_speed": 2.6, "acceleration": 4.8, "braking": 9.0, "coasting_deceleration": 1.3, "steering_angle": 0.74, "steering_response": 4.8, "high_speed_steering_factor": 0.60}
}

static func profile(id: String) -> Dictionary:
	var imported := preload("res://scripts/imported_car_catalog.gd").find(id)
	if not imported.is_empty():
		var result: Dictionary = PROFILES.sport.duplicate(true)
		result.asset = id
		result.path = "res://assets/cars/prepared/%s.glb" % id
		result.size = Vector3(imported.size[0], imported.size[1], imported.size[2])
		result.radius = float(imported.wheels.Wheel_FL.radius)
		result.wheelbase = absf(float(imported.wheels.Wheel_FL.pivot[2]) - float(imported.wheels.Wheel_RL.pivot[2]))
		result.steering_angle = atan(result.wheelbase / 3.0)
		result.maximum_speed = 6.5
		return result
	return PROFILES.get(id, PROFILES.metro)

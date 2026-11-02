extends MultiMeshInstance3D
## Short kinematic path estimate, not an obstacle sensor or completion validator.
var car: CharacterBody3D
var preferences: Node
var elapsed: float = 0.0
var guide_material := StandardMaterial3D.new()

func _ready() -> void:
	preferences = get_node_or_null("/root/Progress")
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var dash := BoxMesh.new()
	dash.size = Vector3(0.055, 0.009, 0.20)
	multimesh.mesh = dash
	multimesh.instance_count = 20
	guide_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = guide_material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _physics_process(delta: float) -> void:
	visible = car.active and absf(car.speed) < 3.5 and (preferences == null or preferences.parking_guides)
	if not visible:
		return
	elapsed += delta
	if elapsed < 0.05:
		return
	elapsed = 0
	var direction := -1.0 if car.speed < -0.05 or (car.input_source != null and car.input_source.throttle() < 0) else 1.0
	guide_material.albedo_color = Color("e6b275") if direction < 0 else Color("94c9c2")
	var angle: float = car.steering * car.steering_angle * lerpf(1.0, car.high_speed_steering_factor, clampf(absf(car.speed) / car.maximum_speed, 0, 1))
	var heading := 0.0
	var center := Vector3.ZERO
	for index in range(10):
		heading -= direction * 0.38 / maxf(car.wheelbase, 0.1) * tan(angle)
		var basis := Basis(Vector3.UP, heading)
		center -= basis.z * direction * 0.38
		for side in range(2):
			var point: Vector3 = center + basis * Vector3((-1 if side == 0 else 1) * car.vehicle_size.x * 0.5, 0.045, -direction * car.vehicle_size.z * 0.5)
			multimesh.set_instance_transform(index * 2 + side, Transform3D(basis, point))

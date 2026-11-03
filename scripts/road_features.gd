extends Node3D
## Local, deterministic road obstacles. Barrier never closes onto a vehicle.
const Art = preload("res://scripts/geometry.gd")
var game: Node3D
var gate: Node3D
var arm: Node3D
var blocker: CollisionShape3D
var instruction: Label3D
var bump_frames: Array[Transform3D] = []
var stopped: float = 0.0
var stop_seconds: float = 1.0
var opened: bool = false
var arm_angle: float = 0.0
var cleared: bool = false

func show_message(message: String) -> void:
	if instruction.text != message:
		instruction.text = message

func setup(owner_game: Node3D, data: Dictionary, static_world: Node3D) -> void:
	game = owner_game
	process_physics_priority = -5
	stop_seconds = float(data.road_features.get("stop_seconds", 1.0))
	var route: Array = [data.start] + data.route
	var end: Vector3 = route[-1]
	var approach: Vector3 = (end - Vector3(route[-2])).normalized()
	approach.y = 0
	var heading := atan2(-approach.x, -approach.z)
	gate = Node3D.new()
	add_child(gate)
	gate.position = end - approach * 13.0
	gate.rotation.y = heading
	for side in [-1.0, 1.0]:
		Art.box(gate, Vector3(side * 3.25, 0.65, 0), Vector3(0.5, 1.3, 0.55), Color("e3a150"))
		Art.collider(gate, Vector3(side * 3.25, 0.65, 0), Vector3(0.5, 1.3, 0.55))
	arm = Node3D.new()
	gate.add_child(arm)
	arm.position = Vector3(-3.25, 1.15, 0)
	Art.box(arm, Vector3(3.25, 0, 0), Vector3(6.5, 0.18, 0.16), Color("e3e4d9"))
	for i in range(8):
		Art.box(arm, Vector3(0.35 + i * 0.8, 0, 0), Vector3(0.34, 0.19, 0.17), Color("e36e43"))
	var body := Art.collider(gate, Vector3(0, 1.15, 0), Vector3(6.5, 0.22, 0.2))
	blocker = body.get_child(0)
	instruction = Label3D.new()
	instruction.position = Vector3(0, 2.0, 0)
	instruction.font_size = 48
	instruction.pixel_size = 0.008
	instruction.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gate.add_child(instruction)
	# Mark the stopping area well before the arm, with full front-overhang room.
	Art.box(gate, Vector3(0, 0.02, 5.0), Vector3(4.7, 0.012, 0.18), Color("dfcfb0"))
	var desired: int = int(data.road_features.get("speed_breakers", 2))
	for i in range(route.size() - 1):
		if bump_frames.size() >= desired: break
		var a: Vector3 = route[i]
		var b: Vector3 = route[i + 1]
		if a.distance_to(b) < 5: continue
		var at := a.lerp(b, 0.5)
		at.y = 0
		if at.distance_to(data.start) < 7 or at.distance_to(gate.position) < 10 or at.distance_to(end) < 10: continue
		var yaw := atan2(-(b.x - a.x), -(b.z - a.z))
		var frame := Transform3D(Basis(Vector3.UP, yaw), at)
		bump_frames.append(frame)
		var bump := Node3D.new()
		static_world.add_child(bump)
		bump.transform = frame
		# Low profile rubber segments; response is modeled, not a vertical wall.
		for piece in range(10):
			Art.bevel_box(bump, Vector3(-2.25 + piece * 0.5, 0.045, 0), Vector3(0.49, 0.09, 0.65), Color("d8a144") if piece % 2 == 0 else Color("25313a"), 0.08)
	reset()

func reset() -> void:
	stopped = 0
	opened = false
	cleared = false
	arm_angle = 0
	arm.rotation.z = 0
	blocker.set_deferred("disabled", false)
	instruction.text = "STOP AT THE LINE / WAIT FOR GREEN"
	instruction.modulate = Color("f3b064")
	game.car.road_speed_limit = INF
	game.car.road_bump_height = 0.0

func _physics_process(delta: float) -> void:
	if game == null or game.suspended or game.level_finished or game.life_failed: return
	var car = game.car
	car.road_speed_limit = INF
	car.road_bump_height = 0.0
	var local: Vector3 = gate.to_local(car.global_position)
	if not opened:
		var waiting: bool = absf(local.x) < 2.6 and local.z > 3.3 and local.z < 8.0 and absf(car.speed) < 0.25
		stopped = stopped + delta if waiting else 0.0
		if waiting:
			show_message("HOLD STOP / %.1f" % maxf(0, stop_seconds - stopped))
		else:
			show_message("STOP AT THE LINE / WAIT FOR GREEN")
		if stopped >= stop_seconds:
			opened = true
	if opened and not cleared:
		arm_angle = move_toward(arm_angle, PI * 0.48, delta * 1.4)
		arm.rotation.z = arm_angle
		if arm_angle >= deg_to_rad(75):
			cleared = true
			blocker.set_deferred("disabled", true)
			instruction.text = "GO / BARRIER OPEN"
			instruction.modulate = Color("81dfb0")
	for frame in bump_frames:
		var point: Vector3 = frame.affine_inverse() * car.global_position
		if absf(point.x) < 3.0 and absf(point.z) < car.vehicle_size.z * 0.5 + 0.4:
			car.road_speed_limit = 1.6
			car.road_bump_height = 0.035 * (0.5 + 0.5 * cos(point.z * 5.0))

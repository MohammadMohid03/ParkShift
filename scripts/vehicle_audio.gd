extends Node
## Original synthesized mono audio; prepared once, never generated per frame.
var car: CharacterBody3D
var engine := AudioStreamPlayer.new()
var effects := AudioStreamPlayer.new()
var tires := AudioStreamPlayer.new()
var smoothed_load: float = 0.0
static var streams: Dictionary = {}

static func tone(kind: String) -> AudioStreamWAV:
	if streams.has(kind):
		return streams[kind]
	var rate: int = 22050
	var duration: float = 1.0 if kind in ["engine", "tires"] else 0.18
	var random := RandomNumberGenerator.new()
	random.seed = 419
	var filtered_noise := 0.0
	var data := PackedByteArray()
	data.resize(int(rate * duration) * 2)
	for i in range(data.size() / 2):
		var t: float = float(i) / rate
		var value: float
		filtered_noise = lerpf(filtered_noise, random.randf_range(-1, 1), 0.23)
		if kind == "engine":
			value = (sin(TAU * 55 * t) * 0.55 + sin(TAU * 110 * t) * 0.25 + sin(TAU * 165 * t) * 0.13 + sin(TAU * 220 * t) * 0.07) * (0.36 + sin(TAU * 11 * t) * 0.035)
		elif kind == "tires":
			value = filtered_noise * 0.6 * sin(PI * t) + sin(TAU * 410 * t) * 0.025 * sin(PI * t)
		elif kind == "contact":
			value = (sin(TAU * 65 * t) * 0.6 + filtered_noise * 0.65) * pow(1 - t / duration, 3)
		else:
			var hz: float = 90 if kind == "contact" else (780 if kind == "brake" else 620)
			value = sin(TAU * hz * t) * pow(1 - t / duration, 3) * sin(minf(t * 100, PI / 2)) * 0.5
		data.encode_s16(i * 2, int(value * 16000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if kind in ["engine", "tires"]:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = rate
	streams[kind] = stream
	return stream

func _ready() -> void:
	add_child(engine)
	add_child(effects)
	add_child(tires)
	tires.stream = tone("tires")
	tires.volume_db = -30
	engine.stream = tone("engine")
	tone("contact")
	engine.volume_db = -30
	effects.volume_db = -19
	car.contacted.connect(func(impact: float) -> void:
		effects.volume_db = lerpf(-24, -13, clampf(impact / 5.0, 0, 1))
		play_effect("contact"))

func play_effect(kind: String) -> void:
	effects.stream = tone(kind)
	effects.play()

func _process(delta: float) -> void:
	if not car.active:
		engine.stop()
		tires.stop()
		return
	if not engine.playing:
		engine.play()
	var throttle: float = car.input_source.throttle() if car.input_source != null else 0.0
	smoothed_load = lerpf(smoothed_load, absf(throttle), 1.0 - exp(-5 * delta))
	engine.pitch_scale = lerpf(engine.pitch_scale, 0.85 + absf(car.speed) * 0.13 + smoothed_load * 0.14, 1.0 - exp(-4 * delta))
	engine.volume_db = -31 + absf(car.speed) * 0.7 + smoothed_load * 2.0
	var braking_now: bool = car.input_source != null and (car.input_source.strength("brake") > 0 or throttle * car.speed < -0.1)
	var scrub: bool = absf(car.speed) > 1.2 and (braking_now or (absf(car.steering) > 0.55 and absf(car.speed) > 3.0))
	if scrub and not tires.playing:
		tires.play()
	elif not scrub:
		tires.stop()
	tires.pitch_scale = 0.85 + absf(car.speed) * 0.055
	tires.volume_db = -33 + minf(absf(car.speed), 6.0)

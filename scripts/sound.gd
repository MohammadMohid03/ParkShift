extends Node
## Tiny original synthesized cues; no audio assets or imports required.

var player: AudioStreamPlayer
var enabled: bool = true

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -15.0
	add_child(player)

func cue(success: bool) -> void:
	if not enabled:
		return
	var rate: int = 22050
	var duration: float = 0.55 if success else 0.10
	var samples := PackedByteArray()
	samples.resize(int(rate * duration) * 2)
	for index in range(samples.size() / 2):
		var t: float = float(index) / rate
		var frequency: float = (523.25 if t < 0.16 else (659.25 if t < 0.32 else 783.99)) if success else 110.0
		var envelope: float = minf(t * 50.0, 1.0) * pow(1.0 - t / duration, 2)
		var sample: int = int(sin(TAU * frequency * t) * envelope * 14000.0)
		samples.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = samples
	player.stream = stream
	player.play()

func _exit_tree() -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream = null

extends RefCounted
## Monotonic active-play time; independent of render/physics frame rates.
var accumulated_usec: int = 0
var started_usec: int = 0
var running: bool = false

func reset() -> void:
	accumulated_usec = 0
	started_usec = 0
	running = false

func resume() -> void:
	if not running:
		started_usec = Time.get_ticks_usec()
		running = true

func pause() -> void:
	if running:
		accumulated_usec += Time.get_ticks_usec() - started_usec
		running = false

func seconds() -> float:
	return (accumulated_usec + (Time.get_ticks_usec() - started_usec if running else 0)) / 1000000.0

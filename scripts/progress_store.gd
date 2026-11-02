extends Node
## Versioned local progress. A backup protects the previous valid save.

signal changed
const Catalog = preload("res://scripts/level_catalog.gd")
const Economy = preload("res://scripts/economy.gd")
const VERSION: int = 4
const LEVEL_COUNT: int = 100
var audio_volume: float = 0.65
var steering_sensitivity: float = 1.0
var touch_scale: float = 1.0
var steering_mode: String = "buttons"
var parking_guides: bool = true
var haptics_enabled: bool = true
var save_path: String = "user://parkshift_save.json"
var coins: int = 0
var stars: Array[int] = []
var best_times: Array[float] = []
var best_medals: Array[int] = []
var reward_paid: Array[int] = []
var owned: Array[String] = ["metro"]
var selected: String = "metro"
var save_error: String = ""
var recovered_backup: bool = false
var run_sequence: int = 0
var last_paid_run: int = 0
var active_run: int = 0
var active_level: int = -1
var last_reward: Dictionary = {}


func _init() -> void:
	stars.resize(LEVEL_COUNT)
	stars.fill(0)
	best_times.resize(LEVEL_COUNT)
	best_times.fill(0.0)
	best_medals.resize(LEVEL_COUNT)
	best_medals.fill(0)
	reward_paid.resize(LEVEL_COUNT)
	reward_paid.fill(0)

func set_audio_volume(value: float) -> void:
	audio_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(audio_volume, 0.0001)))
	save_progress()

func _ready() -> void:
	# Test runners may isolate their save within their own project artifacts.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-path="):
			save_path = argument.trim_prefix("--save-path=")
	load_progress()

func unlocked(index: int) -> bool:
	if index < 0 or index >= LEVEL_COUNT or index >= stars.size():
		return false
	for previous in range(index):
		if stars[previous] == 0:
			return false
	return true

func record_parking_result(index: int, earned_stars: int, seconds: float) -> bool:
	if not unlocked(index) or earned_stars < 1 or earned_stars > 3 or not is_finite(seconds) or seconds < 0:
		return false
	stars[index] = maxi(stars[index], earned_stars)
	if best_times[index] == 0 or seconds < best_times[index]:
		best_times[index] = maxf(0.01, seconds)
	var saved := save_progress()
	changed.emit()
	return saved

func owns_car(car_id: String) -> bool:
	return Catalog.car(car_id).id == car_id and owned.has(car_id)

func select_campaign_car(car_id: String) -> bool:
	if not owns_car(car_id):
		return false
	var previous := selected
	selected = car_id
	if not save_progress():
		selected = previous
		return false
	changed.emit()
	return true

func purchase_car(car_id: String) -> bool:
	# Called only after the garage confirmation. Repeated taps are idempotent.
	if Catalog.car(car_id).id != car_id:
		return false
	if owns_car(car_id):
		return true
	var price := Economy.price(car_id)
	if price <= 0 or coins < price:
		return false
	coins -= price
	owned.append(car_id)
	if not save_progress():
		coins += price
		owned.erase(car_id)
		return false
	changed.emit()
	return true

func select_car(car_id: String) -> bool:
	# Legacy entry point must never bypass purchase confirmation.
	return select_campaign_car(car_id)

func begin_run(index: int) -> int:
	abandon_run()
	if not unlocked(index):
		return 0
	run_sequence += 1
	active_run = run_sequence
	active_level = index
	return active_run

func abandon_run() -> void:
	active_run = 0
	active_level = -1

func claim_run(token: int, index: int, earned_stars: int, seconds: float) -> Dictionary:
	if token <= last_paid_run or token != active_run or index != active_level or not unlocked(index):
		return {}
	var reward := Economy.quote(index, earned_stars, seconds)
	if reward.is_empty():
		return {}
	var old_stars := stars[index]
	var old_time := best_times[index]
	var old_paid := last_paid_run
	var old_medal := best_medals[index]
	var old_reward := reward_paid[index]
	reward["entitlement"] = int(reward.coins)
	reward.coins = maxi(0, int(reward.coins) - old_reward)
	reward["previously_paid"] = old_reward
	best_medals[index] = maxi(old_medal, int(reward.tier))
	reward_paid[index] = maxi(old_reward, int(reward.entitlement))
	stars[index] = maxi(stars[index], earned_stars)
	if best_times[index] == 0 or seconds < best_times[index]:
		best_times[index] = maxf(0.01, seconds)
	coins += int(reward.coins)
	last_paid_run = token
	if not save_progress():
		coins -= int(reward.coins)
		stars[index] = old_stars
		best_times[index] = old_time
		last_paid_run = old_paid
		best_medals[index] = old_medal
		reward_paid[index] = old_reward
		return {}
	last_reward = reward.duplicate()
	abandon_run()
	changed.emit()
	return reward

func complete_level(index: int, earned_stars: int, seconds: float) -> int:
	# Compatibility entry point: a live run token is still required.
	return int(claim_run(active_run, index, earned_stars, seconds).get("coins", 0))

func save_progress() -> bool:
	var data := {"version": VERSION, "coins": coins, "stars": stars, "best_times": best_times, "owned": owned, "selected": selected, "audio_volume": audio_volume, "run_sequence": run_sequence, "last_paid_run": last_paid_run, "best_medals": best_medals, "reward_paid": reward_paid}
	data["driving_settings"] = {"steering_sensitivity": steering_sensitivity, "touch_scale": touch_scale, "parking_guides": parking_guides, "haptics_enabled": haptics_enabled}
	data["driving_settings"]["steering_mode"] = steering_mode
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "Could not write local progress. This session still works."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		save_error = "Local progress could not be saved."
		return false
	var absolute := ProjectSettings.globalize_path(save_path)
	# Do not overwrite a good backup with a corrupt primary file.
	if FileAccess.file_exists(save_path) and not _read_valid(save_path).is_empty():
		if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
			save_error = "Could not back up local progress."
			return false
	if FileAccess.file_exists(save_path):
		if DirAccess.remove_absolute(absolute) != OK:
			save_error = "Could not replace local progress."
			return false
	if DirAccess.rename_absolute(absolute + ".tmp", absolute) != OK:
		save_error = "Could not finish saving. A previous backup may be available."
		return false
	save_error = ""
	return true

func _read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {}
	var version: Variant = parsed.get("version")
	if not (version is float or version is int) or (version != VERSION and version != 3 and version != 2 and version != 1):
		return {}
	if not parsed.get("stars") is Array or parsed.stars.size() < 5 or parsed.stars.size() > LEVEL_COUNT:
		return {}
	if not parsed.get("best_times") is Array or parsed.best_times.size() != parsed.stars.size() or not parsed.get("owned") is Array:
		return {}
	if not (parsed.get("coins") is float or parsed.get("coins") is int):
		return {}
	if not is_finite(parsed.coins) or parsed.coins < 0 or parsed.coins != floor(parsed.coins):
		return {}
	for value in parsed.stars:
		if not (value is float or value is int) or not is_finite(value) or value != floor(value) or value < 0 or value > 3:
			return {}
	for value in parsed.best_times:
		if not (value is float or value is int) or not is_finite(value) or value < 0:
			return {}
	return parsed

func load_progress() -> void:
	# Reloads, missing saves and malformed saves always start from safe defaults.
	coins = 0
	run_sequence = 0
	last_paid_run = 0
	abandon_run()
	last_reward = {}
	stars.resize(LEVEL_COUNT)
	stars.fill(0)
	best_times.resize(LEVEL_COUNT)
	best_times.fill(0.0)
	best_medals.resize(LEVEL_COUNT)
	best_medals.fill(0)
	reward_paid.resize(LEVEL_COUNT)
	reward_paid.fill(0)
	audio_volume = 0.65
	steering_sensitivity = 1.0
	touch_scale = 1.0
	steering_mode = "buttons"
	parking_guides = true
	haptics_enabled = true
	AudioServer.set_bus_volume_db(0, linear_to_db(audio_volume))
	owned.assign(["metro"])
	selected = "metro"
	save_error = ""
	var data := _read_valid(save_path)
	recovered_backup = false
	if data.is_empty():
		data = _read_valid(save_path + ".bak")
		recovered_backup = not data.is_empty()
	if data.is_empty():
		if FileAccess.file_exists(save_path):
			save_error = "Save could not be read. Starting a fresh session."
		return
	coins = clampi(int(data.coins), 0, 9007199254740991)
	for field in ["run_sequence", "last_paid_run"]:
		var value: Variant = data.get(field, 0)
		if (value is float or value is int) and is_finite(value) and value >= 0 and value <= 9007199254740991 and value == floor(value):
			set(field, int(value))
	run_sequence = maxi(run_sequence, last_paid_run)
	for index in range(data.stars.size()):
		stars[index] = int(data.stars[index])
		best_times[index] = float(data.best_times[index])
	# Older versions did not record per-level payments. Conservatively consider
	# completed levels fully paid, preserving balance without repeat first rewards.
	var stored_rewards: Variant = data.get("reward_paid", [])
	var stored_medals: Variant = data.get("best_medals", [])
	for index in range(LEVEL_COUNT):
		best_medals[index] = stars[index]
		reward_paid[index] = Economy.base_reward(index) if stars[index] > 0 else 0
		if int(data.version) == VERSION:
			if stored_rewards is Array and index < stored_rewards.size():
				var amount: Variant = stored_rewards[index]
				if (amount is int or amount is float) and is_finite(amount) and amount >= 0 and amount <= 9007199254740991 and amount == floor(amount):
					reward_paid[index] = int(amount)
			if stored_medals is Array and index < stored_medals.size():
				var medal: Variant = stored_medals[index]
				if (medal is int or medal is float) and is_finite(medal) and medal == floor(medal) and medal >= 0 and medal <= 3:
					best_medals[index] = int(medal)
	owned = ["metro"]
	for car_id in data.owned:
		if car_id is String and Catalog.car(car_id).id == car_id and not owned.has(car_id):
			owned.append(car_id)
	selected = str(data.get("selected", "metro"))
	if not owned.has(selected):
		selected = "metro"
	var volume: Variant = data.get("audio_volume", 0.65)
	if (volume is float or volume is int) and is_finite(volume):
		audio_volume = clampf(volume, 0, 1)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(audio_volume, 0.0001)))
	var preferences: Variant = data.get("driving_settings", {})
	if preferences is Dictionary:
		steering_mode = "wheel" if preferences.get("steering_mode") == "wheel" else "buttons"
		for key in ["steering_sensitivity", "touch_scale"]:
			var value: Variant = preferences.get(key, 1.0)
			if (value is float or value is int) and is_finite(value):
				set(key, clampf(float(value), 0.7 if key == "steering_sensitivity" else 0.85, 1.5 if key == "steering_sensitivity" else 1.15))
		for key in ["parking_guides", "haptics_enabled"]:
			if preferences.get(key) is bool:
				set(key, preferences[key])

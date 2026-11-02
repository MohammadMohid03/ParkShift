extends RefCounted
## Shared offline reward policy. Existing level times and collision star rules apply.
const Campaign = preload("res://scripts/campaign_catalog.gd")
static var config: Dictionary = {}

static func settings() -> Dictionary:
	if config.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		if data is Dictionary:
			config = data
	return config

static func price(id: String) -> int:
	return int(settings().get("car_prices", {}).get(id, -1))

static func base_reward(index: int) -> int:
	if index < 0 or index >= Campaign.COUNT:
		return 0
	var level := Campaign.level(index)
	if level.is_empty():
		return 0
	if level.has("base_reward"):
		return maxi(0, int(level.base_reward))
	var bases: Array = settings().get("district_base_rewards", [100, 200, 300, 400, 500])
	return int(bases[index / 20]) + (index % 20) * int(settings().get("reward_step_per_level", 5))

static func quote(index: int, stars: int, seconds: float) -> Dictionary:
	if index < 0 or index >= Campaign.COUNT or stars < 1 or stars > 3 or not is_finite(seconds) or seconds < 0:
		return {}
	var level := Campaign.level(index)
	if level.is_empty():
		return {}
	var time_tier: int = 3 if seconds <= float(level.gold) else (2 if seconds <= float(level.silver) else 1)
	var tier := mini(stars, time_tier)
	var percentages: Array = settings().get("tier_percentages", [40, 70, 100])
	var percent := int(percentages[tier - 1])
	var base := base_reward(index)
	return {"tier": tier, "name": ["Bronze", "Silver", "Gold"][tier - 1], "base": base, "percent": percent, "coins": (base * percent + 50) / 100}

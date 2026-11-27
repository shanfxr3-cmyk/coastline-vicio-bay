extends RefCounted

## Continuous 24-hour solar/lunar clock with interpolated coastal lighting.
## Visual application is throttled separately by quality tier in the main scene.

const DAY_DURATION_REAL_SEC := 1440.0
const GAME_SECONDS_PER_REAL_SECOND := 60.0
const UPDATE_INTERVALS: Array[float] = [4.0, 1.0, 0.25]
const PHASE_JUMP_HOURS: Array[float] = [5.8, 9.0, 12.0, 16.75, 18.75, 21.0]

var hours: float = 16.75
var cloud_offset: Vector2 = Vector2.ZERO
var update_interval: float = UPDATE_INTERVALS[0]
var _update_elapsed: float = 0.0

var _keyframes: Array[Dictionary] = [
	_night_key(0.0),
	_night_key(5.0),
	_key(6.5, Color(0.12, 0.24, 0.42), Color(0.95, 0.48, 0.28), Color(0.15, 0.20, 0.28), Color(1.0, 0.50, 0.25), 0.36, Color(0.80, 0.48, 0.34), 0.0024),
	_key(9.0, Color(0.10, 0.34, 0.58), Color(0.65, 0.82, 0.92), Color(0.20, 0.29, 0.35), Color(1.0, 0.86, 0.66), 0.48, Color(0.62, 0.76, 0.82), 0.0012),
	_key(12.0, Color(0.08, 0.32, 0.62), Color(0.58, 0.79, 0.92), Color(0.20, 0.29, 0.35), Color(1.0, 0.94, 0.82), 0.52, Color(0.60, 0.76, 0.85), 0.0010),
	_key(16.75, Color(0.11, 0.30, 0.44), Color(0.95, 0.58, 0.32), Color(0.16, 0.24, 0.32), Color(1.0, 0.64, 0.34), 0.42, Color(0.76, 0.56, 0.44), 0.0018),
	_key(18.25, Color(0.07, 0.12, 0.28), Color(0.70, 0.30, 0.26), Color(0.08, 0.11, 0.18), Color(1.0, 0.36, 0.20), 0.30, Color(0.36, 0.23, 0.29), 0.0026),
	_key(19.0, Color(0.05, 0.11, 0.22), Color(0.24, 0.41, 0.58), Color(0.06, 0.09, 0.14), Color(0.45, 0.62, 0.90), 0.30, Color(0.13, 0.23, 0.35), 0.0030),
	_night_key(20.5),
	_night_key(24.0),
]


func _key(hour: float, top: Color, horizon: Color, ground: Color, sun: Color, ambient: float, fog: Color, density: float) -> Dictionary:
	return {
		"hour": hour,
		"sky_top": top,
		"sky_horizon": horizon,
		"ground_horizon": ground,
		"sun_color": sun,
		"ambient_energy": ambient,
		"fog_color": fog,
		"fog_density": density,
	}


func _night_key(hour: float) -> Dictionary:
	return _key(hour, Color(0.015, 0.025, 0.065), Color(0.04, 0.07, 0.14), Color(0.015, 0.025, 0.045), Color(0.48, 0.61, 0.82), 0.20, Color(0.04, 0.08, 0.14), 0.0032)


func set_quality_tier(tier: int) -> void:
	update_interval = UPDATE_INTERVALS[clampi(tier, 0, 2)]


func set_hours(value: float) -> void:
	hours = fposmod(value, 24.0)
	_update_elapsed = 0.0


func jump_to_next_phase() -> void:
	for jump_hour: float in PHASE_JUMP_HOURS:
		if jump_hour > hours + 0.05:
			set_hours(jump_hour)
			return
	set_hours(PHASE_JUMP_HOURS[0])


func advance(delta: float) -> bool:
	hours = fposmod(hours + delta * GAME_SECONDS_PER_REAL_SECOND / 3600.0, 24.0)
	cloud_offset += Vector2(delta * 0.0015, delta * 0.0004)
	_update_elapsed += delta
	if _update_elapsed < update_interval:
		return false
	_update_elapsed = fmod(_update_elapsed, update_interval)
	return true


func get_phase_name() -> String:
	if hours >= 5.0 and hours < 8.0:
		return "Dawn"
	if hours >= 8.0 and hours < 16.0:
		return "Day"
	if hours >= 16.0 and hours < 18.25:
		return "Golden"
	if hours >= 18.25 and hours < 19.75:
		return "Blue"
	return "Night"


func get_clock_text() -> String:
	var total_minutes: int = int(hours * 60.0) % 1440
	return "%02d:%02d" % [total_minutes / 60, total_minutes % 60]


func sample() -> Dictionary:
	var from_key: Dictionary = _keyframes[0]
	var to_key: Dictionary = _keyframes[1]
	for index: int in range(_keyframes.size() - 1):
		if hours >= float(_keyframes[index]["hour"]) and hours <= float(_keyframes[index + 1]["hour"]):
			from_key = _keyframes[index]
			to_key = _keyframes[index + 1]
			break
	var span: float = maxf(0.001, float(to_key["hour"]) - float(from_key["hour"]))
	var weight: float = smoothstep(0.0, 1.0, clampf((hours - float(from_key["hour"])) / span, 0.0, 1.0))
	var elevation: float = sin((hours - 6.0) / 24.0 * TAU) * 75.0
	var sun_yaw: float = -90.0 + (hours - 6.0) / 12.0 * 180.0
	var sun_direction: Vector3 = Basis.from_euler(Vector3(deg_to_rad(-elevation), deg_to_rad(sun_yaw), 0.0)).z.normalized()
	var moon_direction: Vector3 = -sun_direction
	var night_factor: float = clampf((4.0 - elevation) / 24.0, 0.0, 1.0)
	var sunlight: float = smoothstep(-2.0, 12.0, elevation) * 1.85
	var moonlight: float = night_factor * 0.32
	var use_sun: bool = elevation > -2.0
	var result := {
		"phase": get_phase_name(),
		"hours": hours,
		"clock": get_clock_text(),
		"sun_elevation": elevation,
		"sun_direction": sun_direction,
		"moon_direction": moon_direction,
		"moon_strength": night_factor,
		"night_factor": night_factor,
		"light_pitch": -elevation if use_sun else elevation,
		"light_yaw": sun_yaw if use_sun else sun_yaw + 180.0,
		"light_color": _color(from_key, to_key, "sun_color", weight) if use_sun else Color(0.48, 0.61, 0.82),
		"light_energy": sunlight if use_sun else moonlight,
		"sky_top": _color(from_key, to_key, "sky_top", weight),
		"sky_horizon": _color(from_key, to_key, "sky_horizon", weight),
		"ground_horizon": _color(from_key, to_key, "ground_horizon", weight),
		"sun_color": _color(from_key, to_key, "sun_color", weight),
		"ambient_energy": lerpf(float(from_key["ambient_energy"]), float(to_key["ambient_energy"]), weight),
		"fog_color": _color(from_key, to_key, "fog_color", weight),
		"fog_density": lerpf(float(from_key["fog_density"]), float(to_key["fog_density"]), weight),
		"led_boost": lerpf(1.25, 3.4, night_factor),
		"cloud_offset": cloud_offset,
	}
	return result


func _color(from_key: Dictionary, to_key: Dictionary, key: String, weight: float) -> Color:
	return (from_key[key] as Color).lerp(to_key[key] as Color, weight)

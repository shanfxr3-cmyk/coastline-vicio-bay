extends SceneTree

## Continuous 24-hour clock, solar/lunar lighting, and scene integration tests.

const DayNightCycleScript := preload("res://world/day_night_cycle.gd")
const SettingsScript := preload("res://core/settings.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cycle := DayNightCycleScript.new()
	cycle.set_hours(12.0)
	var noon: Dictionary = cycle.sample()
	_check(cycle.get_phase_name() == "Day", "Noon phase incorrect")
	_check(is_equal_approx(float(noon["sun_elevation"]), 75.0), "Noon solar elevation incorrect")
	_check(float(noon["light_energy"]) > 1.8 and is_zero_approx(float(noon["moon_strength"])), "Noon sun/moon energy incorrect")
	_check(cycle.get_clock_text() == "12:00", "Noon clock formatting incorrect")

	cycle.set_hours(0.0)
	var midnight: Dictionary = cycle.sample()
	_check(cycle.get_phase_name() == "Night", "Midnight phase incorrect")
	_check(is_equal_approx(float(midnight["sun_elevation"]), -75.0), "Midnight solar elevation incorrect")
	_check(float(midnight["light_energy"]) > 0.3 and float(midnight["moon_strength"]) > 0.99, "Midnight moon lighting missing")
	_check((midnight["moon_direction"] as Vector3).dot(midnight["sun_direction"] as Vector3) < -0.999, "Moon is not opposite the sun")

	cycle.set_hours(14.0)
	var afternoon: Dictionary = cycle.sample()
	_check((afternoon["sky_top"] as Color).is_equal_approx((noon["sky_top"] as Color)) == false, "Sky keyframes are not interpolating")
	cycle.set_hours(16.75)
	cycle.jump_to_next_phase()
	_check(is_equal_approx(cycle.hours, 18.75), "TOD did not jump to blue hour")
	cycle.jump_to_next_phase()
	_check(is_equal_approx(cycle.hours, 21.0), "TOD did not jump to night")
	cycle.jump_to_next_phase()
	_check(is_equal_approx(cycle.hours, 5.8), "TOD did not wrap to dawn")

	cycle.set_quality_tier(0)
	cycle.set_hours(0.0)
	_check(not cycle.advance(0.5), "LOW updated atmosphere before its four-second budget")
	_check(cycle.advance(3.5), "LOW did not update at its four-second budget")
	_check(cycle.cloud_offset.length() > 0.0, "Cloud offset is not advancing")
	cycle.set_hours(23.99)
	cycle.advance(1.0)
	_check(cycle.hours >= 0.0 and cycle.hours < 0.1, "24-hour clock did not wrap through midnight")
	cycle.set_hours(0.0)
	cycle.advance(DayNightCycleScript.DAY_DURATION_REAL_SEC)
	_check(is_zero_approx(cycle.hours), "Full 24-hour cycle did not return to midnight")

	var packed: Resource = load("res://world/main.tscn")
	_check(packed != null and packed is PackedScene, "Unable to load atmosphere scene")
	if packed != null and packed is PackedScene:
		var main: Node3D = (packed as PackedScene).instantiate()
		root.add_child(main)
		await process_frame
		var scene_cycle := main.get("_day_cycle") as DayNightCycleScript
		var st := root.get_node("Settings") as SettingsScript
		st.apply_preset(SettingsScript.QualityPreset.LOW, false)
		_check(is_equal_approx(scene_cycle.update_interval, 4.0), "LOW atmosphere interval mismatch")
		st.apply_preset(SettingsScript.QualityPreset.MEDIUM, false)
		_check(is_equal_approx(scene_cycle.update_interval, 1.0), "MEDIUM atmosphere interval mismatch")
		st.apply_preset(SettingsScript.QualityPreset.HIGH, false)
		_check(is_equal_approx(scene_cycle.update_interval, 0.25), "HIGH atmosphere interval mismatch")
		scene_cycle.set_hours(0.0)
		main.call("_apply_day_night_sample")
		var gs := root.get_node("GameState")
		_check(gs.get("time_of_day_phase") == "Night" and is_zero_approx(float(gs.get("time_of_day_hours"))), "GameState did not receive scene time")
		var sky_mat := main.get("_sky_mat") as ShaderMaterial
		_check(float(sky_mat.get_shader_parameter("moon_strength")) > 0.99, "Scene sky did not receive moon lighting")
		main.queue_free()
		await process_frame
		await process_frame

	if _failures.is_empty():
		print("ATMOSPHERE_TEST_PASS: 24hWrap, Interpolation, Sun, Moon, CloudMotion, QualityIntervals, SceneSync")
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	for message: String in _failures:
		printerr("ATMOSPHERE_TEST_FAIL: " + message)
	quit(0 if _failures.is_empty() else 1)

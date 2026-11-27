extends SceneTree

## Structural rendering-budget and Phase 2 atmosphere regressions.

const SettingsScript := preload("res://core/settings.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var packed: Resource = load("res://world/main.tscn")
	if packed == null or not (packed is PackedScene):
		_failures.append("Unable to load main scene")
		_finish()
		return
	var main_inst: Node = (packed as PackedScene).instantiate()
	root.add_child(main_inst)
	await _frames(4)
	var st := root.get_node("Settings") as SettingsScript
	var stats: Dictionary = main_inst.call("get_optimization_stats")
	var batches: int = int(stats.get("static_batches", 0))
	var instances: int = int(stats.get("static_instances", 0))
	_check(batches > 0 and batches <= 48, "Static batch budget exceeded or batching missing: %d" % batches)
	_check(instances == 163, "Static instance inventory changed unexpectedly: %d" % instances)

	var barrier := main_inst.get_node_or_null("BayfrontGeometry/VaultPracticeBarrier") as StaticBody3D
	_check(barrier != null, "Vault collision body was removed during visual batching")
	if barrier != null:
		var collision: CollisionShape3D = null
		for child: Node in barrier.get_children():
			if child is CollisionShape3D:
				collision = child as CollisionShape3D
		_check(collision != null and collision.shape is BoxShape3D, "Vault box collider missing after batching")

	var gib: int = 1024 * 1024 * 1024
	_check(st.classify_hardware("Adreno (TM) 613", 6 * gib) == SettingsScript.QualityPreset.LOW, "Entry-level 6 GB Adreno must default to LOW")
	_check(st.classify_hardware("Adreno (TM) 710", 8 * gib) == SettingsScript.QualityPreset.MEDIUM, "Mid-range Adreno/RAM classification incorrect")
	_check(st.classify_hardware("Adreno (TM) 730", 8 * gib) == SettingsScript.QualityPreset.HIGH, "Upper-mid Adreno/RAM classification incorrect")
	_check(st.classify_hardware("Mali-G57 MC2", 8 * gib) == SettingsScript.QualityPreset.LOW, "Entry Mali must remain LOW")
	_check(st.classify_hardware("Mali-G610", 8 * gib) == SettingsScript.QualityPreset.MEDIUM, "Mid-range Mali classification incorrect")
	_check(st.classify_hardware("Mali-G78", 8 * gib) == SettingsScript.QualityPreset.HIGH, "Upper-mid Mali classification incorrect")
	_check(st.classify_hardware("Unknown GPU", 16 * gib) == SettingsScript.QualityPreset.LOW, "Unknown GPU must fail safely to LOW")
	_check(st.classify_hardware("Adreno (TM) 730", 6 * gib) == SettingsScript.QualityPreset.LOW, "GPU name alone must not override the RAM floor")

	var presets: Array[SettingsScript.QualityPreset] = [SettingsScript.QualityPreset.LOW, SettingsScript.QualityPreset.MEDIUM, SettingsScript.QualityPreset.HIGH]
	var expected_scales: Array[float] = [0.50, 0.70, 0.85]
	var expected_targets: Array[int] = [30, 30, 60]
	var expected_atlases: Array[int] = [512, 1024, 2048]
	var expected_lights: Array[int] = [0, 2, 5]
	var expected_water: Array[Vector2i] = [Vector2i(8, 4), Vector2i(24, 12), Vector2i(48, 32)]
	var hud := main_inst.get_node("HudLayer/TouchControls") as Control
	var quality_button := hud.get("_quality_button") as Button
	var tod_button := hud.get("_tod_button") as Button
	for index: int in range(presets.size()):
		st.apply_preset(presets[index], false)
		await _frames(2)
		stats = main_inst.call("get_optimization_stats")
		var preset_name: String = st.get_preset_name()
		_check(is_equal_approx(root.scaling_3d_scale, expected_scales[index]), preset_name + " render scale was not applied to the root viewport")
		_check(st.shadow_atlas_size == expected_atlases[index], preset_name + " shadow atlas value incorrect")
		_check(st.target_fps == expected_targets[index], preset_name + " device-class FPS target incorrect")
		_check(st.get_preset_display_name().contains("%d FPS" % expected_targets[index]), preset_name + " UI label does not show its FPS target")
		_check(quality_button.text == "QUAL: " + st.get_preset_display_name(), preset_name + " QUAL button label mismatch")
		_check(quality_button.get_global_rect().end.x <= hud.get_viewport_rect().size.x, preset_name + " QUAL button overflows the viewport: rect=" + str(quality_button.get_global_rect()) + " viewport=" + str(hud.get_viewport_rect().size))
		_check(not quality_button.get_global_rect().intersects(tod_button.get_global_rect()), preset_name + " QUAL and TOD buttons overlap")
		_check(int(stats.get("active_street_lights", -1)) == expected_lights[index], preset_name + " dynamic-light budget incorrect")
		_check(stats.get("water_subdivisions", Vector2i.ZERO) == expected_water[index], preset_name + " water mesh tier incorrect")
		_check(bool(stats.get("probe_enabled", true)) == (index > 0), preset_name + " reflection-probe tier incorrect")
		_check(bool(stats.get("shadows_enabled", true)) == (index > 0), preset_name + " sun-shadow tier incorrect")
		_check(root.msaa_3d == (Viewport.MSAA_2X if index == 2 else Viewport.MSAA_DISABLED), preset_name + " MSAA tier incorrect")
		_check(root.screen_space_aa == (Viewport.SCREEN_SPACE_AA_DISABLED if index == 0 else Viewport.SCREEN_SPACE_AA_FXAA), preset_name + " screen-space AA tier incorrect")
		var world_env := main_inst.get_node("WorldEnvironment") as WorldEnvironment
		_check(world_env.environment.glow_enabled == (index == 2), preset_name + " glow tier incorrect")
		_check(world_env.environment.fog_enabled == (index > 0), preset_name + " fog tier incorrect")
		_check(world_env.environment.sky.sky_material is ShaderMaterial, preset_name + " custom Phase 2 sky missing")
		var expected_radiance: int = [Sky.RADIANCE_SIZE_64, Sky.RADIANCE_SIZE_128, Sky.RADIANCE_SIZE_256][index] as int
		_check(world_env.environment.sky.radiance_size == expected_radiance, preset_name + " sky radiance tier incorrect")

	st.apply_preset(SettingsScript.QualityPreset.HIGH, false)
	st.update_performance_fallback(5.0, 100, true)
	_check(st.current_preset == SettingsScript.QualityPreset.HIGH, "Fallback triggered before a full 10-second window")
	st.update_performance_fallback(5.0, 90, true)
	_check(st.current_preset == SettingsScript.QualityPreset.MEDIUM, "HIGH did not fall back after a 19 FPS 10-second average")
	var notice := hud.get("_notice_label") as Label
	_check(notice.visible and notice.text.contains("FPS AVG"), "Fallback did not show its short HUD message")
	st.update_performance_fallback(10.0, 250, true)
	_check(st.current_preset == SettingsScript.QualityPreset.MEDIUM, "25 FPS MEDIUM should not fall back")
	st.update_performance_fallback(10.0, 150, true)
	_check(st.current_preset == SettingsScript.QualityPreset.LOW, "MEDIUM did not fall back after a 15 FPS 10-second average")
	st.apply_preset(SettingsScript.QualityPreset.LOW, false)
	st.toggle_fps_uncapped()
	_check(Engine.max_fps == 0 and st.fps_uncapped, "DBG uncap did not remove the engine FPS cap")
	st.toggle_fps_uncapped()
	_check(Engine.max_fps == 30 and not st.fps_uncapped, "DBG cap restore did not restore LOW 30 FPS")

	main_inst.queue_free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("PERFORMANCE_TEST_PASS: Presets=3, Batches=%d/48, Instances=%d, Sky=QuarterRes, Colliders=Intact" % [batches, instances])
	_finish()


func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message: String in _failures:
		printerr("PERFORMANCE_TEST_FAIL: " + message)
	quit(1)

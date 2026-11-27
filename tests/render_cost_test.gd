extends SceneTree

## Reproducible rendered LOW -> MEDIUM feature-isolation benchmark.
## This QA script is excluded from Android exports.

const SettingsScript := preload("res://core/settings.gd")

var _frames_to_measure: int = 30
var _report_path: String = ""
var _results: Array[Dictionary] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--cost-frames="):
			_frames_to_measure = maxi(10, int(arg.trim_prefix("--cost-frames=")))
		elif arg.begins_with("--cost-report="):
			_report_path = arg.trim_prefix("--cost-report=")
	call_deferred("_run")


func _run() -> void:
	var packed: Resource = load("res://world/main.tscn")
	if packed == null or not (packed is PackedScene):
		printerr("RENDER_COST_FAIL: Unable to load main scene")
		quit(1)
		return
	var main: Node3D = (packed as PackedScene).instantiate()
	root.add_child(main)
	var st := root.get_node("Settings") as SettingsScript
	st.set_process(false)
	main.set_process(false)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _render_frames(8)

	for case_name: String in ["low", "resolution", "shadows", "water", "reflections", "aa", "medium", "low_repeat"]:
		_configure_case(case_name, st, main)
		Engine.max_fps = 0
		await _render_frames(10)
		var calls: int = 0
		var triangles: int = 0
		var started_usec: int = Time.get_ticks_usec()
		for _frame: int in range(_frames_to_measure):
			await RenderingServer.frame_post_draw
			calls += int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			triangles += int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		var elapsed_sec: float = float(Time.get_ticks_usec() - started_usec) / 1000000.0
		var fps: float = float(_frames_to_measure) / maxf(elapsed_sec, 0.0001)
		var result := {
			"case": case_name,
			"fps": snappedf(fps, 0.01),
			"frame_ms": snappedf(1000.0 / maxf(fps, 0.001), 0.01),
			"draw_calls": snappedf(float(calls) / float(_frames_to_measure), 0.1),
			"triangles": snappedf(float(triangles) / float(_frames_to_measure), 0.1),
			"scale": snappedf(root.scaling_3d_scale, 0.001),
		}
		_results.append(result)
		print("RENDER_COST case=%s fps=%.2f ms=%.2f calls=%.1f tris=%.1f scale=%.3f" % [case_name, fps, 1000.0 / maxf(fps, 0.001), result["draw_calls"], result["triangles"], root.scaling_3d_scale])

	if not _report_path.is_empty():
		var file: FileAccess = FileAccess.open(_report_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"renderer": st.renderer_method, "gpu": st.detected_gpu_name, "frames_per_case": _frames_to_measure, "results": _results}, "\t"))
			file.close()
			print("RENDER_COST_REPORT: " + _report_path)
	main.queue_free()
	for _frame: int in range(8):
		await process_frame
	print("RENDER_COST_PASS: Cases=%d" % _results.size())
	quit(0)


func _configure_case(case_name: String, st: SettingsScript, main: Node3D) -> void:
	st.apply_preset(SettingsScript.QualityPreset.MEDIUM if case_name == "medium" else SettingsScript.QualityPreset.LOW, false)
	match case_name:
		"resolution":
			root.scaling_3d_scale = 0.70
		"shadows":
			var sun := main.get("_sun") as DirectionalLight3D
			sun.shadow_enabled = true
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun.directional_shadow_max_distance = 90.0
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		"water":
			var water := main.get("_water_mesh") as PlaneMesh
			water.subdivide_width = 24
			water.subdivide_depth = 12
			var water_mat := main.get("_water_mat") as ShaderMaterial
			water_mat.set_shader_parameter("quality_level", 1)
		"reflections":
			var probe := main.get("_probe") as ReflectionProbe
			probe.visible = true
		"aa":
			root.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA


func _render_frames(count: int) -> void:
	for _frame: int in range(count):
		await RenderingServer.frame_post_draw

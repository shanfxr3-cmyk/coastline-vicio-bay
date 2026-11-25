extends CanvasLayer

## Telemetry overlay (FPS, frame ms, draw calls, triangles, VRAM, RAM, streaming, physics)
## plus deterministic CLI screenshot capture helper for headless/lavapipe QA.

const EventBusScript := preload("res://core/event_bus.gd")
const GameStateScript := preload("res://core/game_state.gd")
const SettingsScript := preload("res://core/settings.gd")
const StreamingScript := preload("res://world/streaming.gd")

var overlay_visible: bool = true
var _panel: PanelContainer = null
var _label: Label = null
var _update_accum: float = 0.0

var _screenshot_path: String = ""
var _screenshot_frames: int = 0
var _frame_counter: int = 0
var _screenshot_saved: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_parse_user_args()
	_build_ui()
	if DisplayServer.get_name() == "headless":
		overlay_visible = false
		_panel.visible = false


func _parse_user_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.trim_prefix("--screenshot=")
		elif arg.begins_with("--screenshot-frames="):
			_screenshot_frames = maxi(1, int(arg.trim_prefix("--screenshot-frames=")))
	if not _screenshot_path.is_empty() and _screenshot_frames == 0:
		_screenshot_frames = 20


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DebugTelemetryPanel"
	_panel.position = Vector2(14.0, 14.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.07, 0.11, 0.72)
	style.border_color = Color(0.0, 0.83, 1.0, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0, 1.0))
	_panel.add_child(_label)
	add_child(_panel)
	_refresh_text()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_ev := event as InputEventKey
		if key_ev.pressed and not key_ev.echo and key_ev.keycode == KEY_F3:
			toggle_overlay()


func toggle_overlay() -> void:
	overlay_visible = not overlay_visible
	if _panel != null:
		_panel.visible = overlay_visible
	var eb := get_node_or_null("/root/EventBus") as EventBusScript
	if eb != null:
		eb.debug_overlay_toggled.emit(overlay_visible)


func _process(delta: float) -> void:
	_frame_counter += 1
	if not _screenshot_saved and not _screenshot_path.is_empty() and _frame_counter >= _screenshot_frames:
		_screenshot_saved = true
		call_deferred("_capture_and_quit")

	if not overlay_visible:
		return
	_update_accum += delta
	if _update_accum >= 0.2:
		_update_accum = 0.0
		_refresh_text()


func _refresh_text() -> void:
	if _label == null:
		return
	var fps: float = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / maxf(fps, 0.001)
	var draw_calls: int = int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	var tris: int = int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	var vram_mb: float = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / (1024.0 * 1024.0)
	var ram_mb: float = OS.get_static_memory_usage() / (1024.0 * 1024.0)
	var phys_objs: int = int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	var phys_engine: String = str(ProjectSettings.get_setting("physics/3d/physics_engine", "Default"))

	var gs := get_node_or_null("/root/GameState") as GameStateScript
	var st := get_node_or_null("/root/Settings") as SettingsScript
	var stream := get_node_or_null("/root/Streaming") as StreamingScript

	var title: String = gs.GAME_TITLE if gs != null else "Coastline: Vicio Bay"
	var tod: String = gs.time_of_day_phase if gs != null else "Golden"
	var tier: String = st.build_tier if st != null else "STANDARD"
	var method: String = st.renderer_method if st != null else "mobile"
	var preset: String = st.get_preset_name() if st != null else "MEDIUM"
	var rscale: float = st.render_scale if st != null else 1.0
	var chunk: Vector2i = stream.active_chunk if stream != null else Vector2i.ZERO
	var loaded_c: int = stream.get_loaded_count() if stream != null else 0
	var pending_c: int = stream.get_pending_count() if stream != null else 0

	_label.text = (
		"%s  [%s | %s | %s x%.2f]\n"
		+ "FPS: %.1f (%.2f ms)  |  Calls: %d  |  Tris: %d\n"
		+ "VRAM: %.1f MB  |  RAM: %.1f MB\n"
		+ "Stream: chunk (%d,%d) loaded=%d queue=%d\n"
		+ "Physics (%s): active=%d  |  TOD: %s\n"
		+ "Hero: %s  |  State: %s"
	) % [
		title,
		tier,
		method,
		preset,
		rscale,
		fps,
		frame_ms,
		draw_calls,
		tris,
		vram_mb,
		ram_mb,
		chunk.x,
		chunk.y,
		loaded_c,
		pending_c,
		phys_engine,
		phys_objs,
		tod,
		gs.active_protagonist_id if gs != null else "kian",
		gs.locomotion_state if gs != null else "IDLE",
	]


func _capture_and_quit() -> void:
	await RenderingServer.frame_post_draw
	var exit_code: int = 0
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		var abs_path: String = _screenshot_path
		if not abs_path.is_absolute_path():
			abs_path = ProjectSettings.globalize_path("res://" + _screenshot_path)
		var err: Error = img.save_png(abs_path)
		if err != OK:
			push_error("Failed to save screenshot to %s (err=%d)" % [abs_path, err])
			exit_code = 1
	else:
		exit_code = 1
	img = null
	# Free scene-owned sky/reflection textures before RenderingServer finalizes,
	# then leave enough idle frames for deferred GPU releases to drain.
	var scene := get_tree().current_scene
	if scene != null:
		scene.queue_free()
	for _frame: int in range(8):
		await get_tree().process_frame
	get_tree().quit(exit_code)

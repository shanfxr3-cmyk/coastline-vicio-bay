extends Node

## Graphics quality presets, auto-detection, and persistent user preferences.

enum QualityPreset {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
}

const EventBusScript := preload("res://core/event_bus.gd")
const SETTINGS_PATH := "user://settings.json"

var current_preset: QualityPreset = QualityPreset.MEDIUM
var build_tier: String = "STANDARD"
var renderer_method: String = "mobile"
var render_scale: float = 0.85
var target_fps: int = 60
var battery_saver: bool = false
var shadow_atlas_size: int = 2048


func _ready() -> void:
	renderer_method = _detect_renderer_method()
	build_tier = "ULTRA" if renderer_method == "forward_plus" else "STANDARD"
	if not _load_settings():
		current_preset = _auto_detect_preset()
	apply_preset(current_preset, false)
	var eb := _event_bus()
	if eb != null:
		eb.renderer_initialized.emit(build_tier, renderer_method)


func _event_bus() -> EventBusScript:
	return get_node_or_null("/root/EventBus") as EventBusScript


func _detect_renderer_method() -> String:
	var method: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "mobile"))
	for arg: String in OS.get_cmdline_args():
		if arg == "forward_plus":
			method = "forward_plus"
		elif arg == "mobile":
			method = "mobile"
	var rs_name: String = RenderingServer.get_current_rendering_method()
	if not rs_name.is_empty():
		return rs_name
	return method


func _auto_detect_preset() -> QualityPreset:
	var cores: int = OS.get_processor_count()
	if build_tier == "ULTRA":
		return QualityPreset.HIGH if cores >= 8 else QualityPreset.MEDIUM
	if cores >= 8:
		return QualityPreset.HIGH
	if cores >= 6:
		return QualityPreset.MEDIUM
	return QualityPreset.LOW


func apply_preset(preset: QualityPreset, persist: bool = true) -> void:
	current_preset = preset
	match preset:
		QualityPreset.LOW:
			render_scale = 0.67
			target_fps = 30
			shadow_atlas_size = 1024
		QualityPreset.MEDIUM:
			render_scale = 0.85
			target_fps = 60
			shadow_atlas_size = 2048
		QualityPreset.HIGH:
			render_scale = 1.0
			target_fps = 60
			shadow_atlas_size = 4096

	if battery_saver:
		target_fps = 30
		render_scale = minf(render_scale, 0.75)

	Engine.max_fps = target_fps
	_apply_viewport_scaling()
	if persist:
		save_settings()
	var eb := _event_bus()
	if eb != null:
		eb.quality_preset_changed.emit(get_preset_name())


func cycle_preset() -> void:
	var next_idx: int = (int(current_preset) + 1) % 3
	apply_preset(next_idx as QualityPreset, true)


func get_preset_name() -> String:
	match current_preset:
		QualityPreset.LOW:
			return "LOW"
		QualityPreset.MEDIUM:
			return "MEDIUM"
		QualityPreset.HIGH:
			return "HIGH"
	return "MEDIUM"


func _apply_viewport_scaling() -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	vp.scaling_3d_scale = render_scale
	if render_scale < 0.99 and build_tier == "ULTRA":
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	else:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR


func save_settings() -> void:
	var payload := {
		"schema": 1,
		"preset": int(current_preset),
		"battery_saver": battery_saver,
	}
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


func _load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return false
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var dict: Dictionary = parsed
	var p: int = clampi(int(dict.get("preset", 1)), 0, 2)
	current_preset = p as QualityPreset
	battery_saver = bool(dict.get("battery_saver", false))
	return true

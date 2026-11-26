extends Node

## Graphics quality presets, auto-detection, and persistent user preferences.

enum QualityPreset {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
}

const EventBusScript := preload("res://core/event_bus.gd")
const SETTINGS_PATH := "user://settings.json"

var current_preset: QualityPreset = QualityPreset.LOW
var build_tier: String = "STANDARD"
var renderer_method: String = "mobile"
var render_scale: float = 0.50
var target_fps: int = 30
var battery_saver: bool = false
var shadow_atlas_size: int = 512
var shadow_distance: float = 45.0
var dynamic_light_budget: int = 0
var detail_distance: float = 100.0
var reflection_probe_enabled: bool = false
var glow_enabled: bool = false
var fog_enabled: bool = false
var water_tier: int = 0
var shader_tier: int = 0
var adaptive_resolution: bool = true

var _preset_user_selected: bool = false
var _quality_override_active: bool = false
var _base_render_scale: float = 0.50
var _minimum_render_scale: float = 0.35
var _adaptive_elapsed: float = 0.0
var _sample_elapsed: float = 0.0
var _slow_samples: int = 0
var _fast_samples: int = 0


func _ready() -> void:
	renderer_method = _detect_renderer_method()
	build_tier = "ULTRA" if renderer_method == "forward_plus" else "STANDARD"
	var settings_loaded: bool = _load_settings()
	var requested_preset: int = _requested_preset_override()
	_quality_override_active = requested_preset >= 0
	if _quality_override_active:
		current_preset = requested_preset as QualityPreset
	elif not settings_loaded or not _preset_user_selected:
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


func _requested_preset_override() -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--quality="):
			match arg.trim_prefix("--quality=").to_lower():
				"low":
					return QualityPreset.LOW
				"medium":
					return QualityPreset.MEDIUM
				"high":
					return QualityPreset.HIGH
	return -1


func _auto_detect_preset() -> QualityPreset:
	var cores: int = OS.get_processor_count()
	if build_tier == "ULTRA":
		return QualityPreset.HIGH if cores >= 8 else QualityPreset.MEDIUM
	# Core count does not describe mobile GPU/fill-rate capability. STANDARD
	# starts conservatively on Android and lets the player opt into heavier tiers.
	if OS.has_feature("android"):
		return QualityPreset.LOW
	if cores >= 6:
		return QualityPreset.MEDIUM
	return QualityPreset.LOW


func apply_preset(preset: QualityPreset, persist: bool = true) -> void:
	current_preset = preset
	match preset:
		QualityPreset.LOW:
			render_scale = 0.50
			target_fps = 30
			shadow_atlas_size = 512
			shadow_distance = 45.0
			dynamic_light_budget = 0
			detail_distance = 100.0
			reflection_probe_enabled = false
			glow_enabled = false
			fog_enabled = false
			water_tier = 0
			shader_tier = 0
		QualityPreset.MEDIUM:
			render_scale = 0.70
			target_fps = 45
			shadow_atlas_size = 1024
			shadow_distance = 90.0
			dynamic_light_budget = 2
			detail_distance = 160.0
			reflection_probe_enabled = true
			glow_enabled = false
			fog_enabled = true
			water_tier = 1
			shader_tier = 1
		QualityPreset.HIGH:
			render_scale = 0.85
			target_fps = 60
			shadow_atlas_size = 2048
			shadow_distance = 150.0
			dynamic_light_budget = 5
			detail_distance = 240.0
			reflection_probe_enabled = true
			glow_enabled = true
			fog_enabled = true
			water_tier = 2
			shader_tier = 2

	_base_render_scale = render_scale
	_minimum_render_scale = [0.35, 0.50, 0.65][int(preset)] as float
	if battery_saver:
		target_fps = 30
		render_scale = minf(render_scale, 0.50)
		dynamic_light_budget = mini(dynamic_light_budget, 1)
	_adaptive_elapsed = 0.0
	_sample_elapsed = 0.0
	_slow_samples = 0
	_fast_samples = 0

	Engine.max_fps = target_fps
	_apply_viewport_scaling()
	if DisplayServer.get_name() != "headless":
		RenderingServer.directional_shadow_atlas_set_size(shadow_atlas_size, true)
	if persist:
		_preset_user_selected = true
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
	var use_fsr2: bool = build_tier == "ULTRA" and current_preset != QualityPreset.LOW
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2 if use_fsr2 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = render_scale
	vp.msaa_3d = Viewport.MSAA_2X if current_preset == QualityPreset.HIGH else Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED if current_preset == QualityPreset.LOW or use_fsr2 else Viewport.SCREEN_SPACE_AA_FXAA


func _process(delta: float) -> void:
	if not adaptive_resolution or _quality_override_active or build_tier != "STANDARD" or not OS.has_feature("android"):
		return
	_adaptive_elapsed += delta
	if _adaptive_elapsed < 8.0:
		return
	_sample_elapsed += delta
	if _sample_elapsed < 2.0:
		return
	_sample_elapsed = 0.0
	var fps: float = Engine.get_frames_per_second()
	if fps < float(target_fps) * 0.82:
		_slow_samples += 1
		_fast_samples = 0
	elif fps > float(target_fps) * 0.95:
		_fast_samples += 1
		_slow_samples = 0
	else:
		_slow_samples = 0
		_fast_samples = 0
	if _slow_samples >= 2 and render_scale > _minimum_render_scale:
		render_scale = maxf(_minimum_render_scale, render_scale - 0.05)
		_slow_samples = 0
		_apply_viewport_scaling()
	elif _fast_samples >= 5 and render_scale < _base_render_scale:
		render_scale = minf(_base_render_scale, render_scale + 0.05)
		_fast_samples = 0
		_apply_viewport_scaling()


func save_settings() -> void:
	var payload := {
		"schema": 2,
		"preset": int(current_preset),
		"user_selected": _preset_user_selected,
		"battery_saver": battery_saver,
		"adaptive_resolution": adaptive_resolution,
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
	_preset_user_selected = bool(dict.get("user_selected", false))
	battery_saver = bool(dict.get("battery_saver", false))
	adaptive_resolution = bool(dict.get("adaptive_resolution", true))
	return true

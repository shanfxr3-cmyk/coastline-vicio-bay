extends Node3D

## Phase 0 Bayfront Promenade prototype scene.
## Demonstrates Jolt physics character movement, touch/mouse camera orbit,
## 2026 Vicio Bay lighting/materials, and Standard vs Ultra renderer parity.

const WATER_SHADER := preload("res://shaders/bay_water_p0.gdshader")
const ASPHALT_SHADER := preload("res://shaders/wet_asphalt_p0.gdshader")
const SKY_SHADER := preload("res://shaders/coastal_sky_p2.gdshader")
const EventBusScript := preload("res://core/event_bus.gd")
const GameStateScript := preload("res://core/game_state.gd")
const SettingsScript := preload("res://core/settings.gd")
const StreamingScript := preload("res://world/streaming.gd")
const PLAYER_SCENE := preload("res://player/player.tscn")
const StaticMeshBatcherScript := preload("res://world/static_mesh_batcher.gd")

const DayNightCycleScript := preload("res://world/day_night_cycle.gd")

var _day_cycle := DayNightCycleScript.new()

var _sun: DirectionalLight3D = null
var _world_env: WorldEnvironment = null
var _sky_mat: ShaderMaterial = null
var _sky: Sky = null
var _actor: CharacterBody3D = null
var _led_materials: Array[StandardMaterial3D] = []
var _street_lights: Array[OmniLight3D] = []
var _environment: Environment = null
var _probe: ReflectionProbe = null
var _water_mesh: PlaneMesh = null
var _water_mat: ShaderMaterial = null
var _road_mat: ShaderMaterial = null
var _batcher: StaticMeshBatcherScript = null
var _palm_trunk_mesh: CylinderMesh = null
var _point_light_budget: int = 0
var _light_update_elapsed: float = 0.0


func _ready() -> void:
	_build_environment()
	_build_bayfront_world()
	_build_player_rig()
	_apply_day_night_sample()

	var eb := get_node_or_null("/root/EventBus") as EventBusScript
	if eb != null:
		eb.touch_action_triggered.connect(_on_touch_action)
		eb.quality_preset_changed.connect(_on_quality_changed)

	var st := get_node_or_null("/root/Settings") as SettingsScript
	_on_quality_changed(st.get_preset_name() if st != null else "MEDIUM")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--time-hours="):
			_day_cycle.set_hours(arg.trim_prefix("--time-hours=").to_float())
			_apply_day_night_sample()


func _build_environment() -> void:
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = SKY_SHADER
	_sky = Sky.new()
	_sky.sky_material = _sky_mat
	_sky.process_mode = Sky.PROCESS_MODE_AUTOMATIC
	_sky.radiance_size = Sky.RADIANCE_SIZE_128

	var env := Environment.new()
	_environment = env
	env.background_mode = Environment.BG_SKY
	env.sky = _sky
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.08
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.85
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.22
	env.glow_hdr_threshold = 1.05
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL

	_world_env = WorldEnvironment.new()
	_world_env.name = "WorldEnvironment"
	_world_env.environment = env
	add_child(_world_env)

	_sun = DirectionalLight3D.new()
	_sun.name = "SunLight"
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_sun.directional_shadow_max_distance = 160.0
	_sun.shadow_bias = 0.03
	add_child(_sun)

	_probe = ReflectionProbe.new()
	_probe.name = "BayfrontProbe"
	_probe.position = Vector3(0.0, 18.0, 0.0)
	_probe.size = Vector3(240.0, 90.0, 240.0)
	_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	_probe.cull_mask = 1
	_probe.mesh_lod_threshold = 2.0
	add_child(_probe)


func _build_bayfront_world() -> void:
	var city_root := Node3D.new()
	city_root.name = "BayfrontGeometry"
	add_child(city_root)
	_batcher = StaticMeshBatcherScript.new(city_root)

	# 1. Bay Ocean Surface (south/right side z > 10)
	_water_mesh = PlaneMesh.new()
	_water_mesh.size = Vector2(420.0, 260.0)
	_water_mesh.subdivide_width = 48
	_water_mesh.subdivide_depth = 32
	_water_mat = ShaderMaterial.new()
	_water_mat.shader = WATER_SHADER
	var water_inst := MeshInstance3D.new()
	water_inst.name = "VicioBayWater"
	water_inst.mesh = _water_mesh
	water_inst.material_override = _water_mat
	water_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_inst.position = Vector3(0.0, -1.1, 140.0)
	city_root.add_child(water_inst)

	# 2. Travertine Seawall Promenade (walkable strip z in [-4, 10])
	var prom_mat := StandardMaterial3D.new()
	prom_mat.albedo_color = Color(0.64, 0.60, 0.55)
	prom_mat.roughness = 0.72
	_add_static_box(city_root, "PromenadeDeck", Vector3(260.0, 1.4, 15.0), Vector3(0.0, -0.7, 2.5), prom_mat)

	# Seawall low glass/concrete parapet
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.68, 0.72, 0.76)
	wall_mat.roughness = 0.45
	_add_static_box(city_root, "SeawallCurb", Vector3(260.0, 0.75, 0.45), Vector3(0.0, 0.375, 9.8), wall_mat)

	# Waist-high obstacle near spawn provides a real, repeatable vault route.
	var vault_mat := StandardMaterial3D.new()
	vault_mat.albedo_color = Color(0.22, 0.29, 0.34)
	vault_mat.metallic = 0.55
	vault_mat.roughness = 0.32
	_add_static_box(city_root, "VaultPracticeBarrier", Vector3(2.2, 0.85, 0.35), Vector3(-42.0, 0.425, 1.45), vault_mat)
	_add_mesh_box(city_root, Vector3(2.24, 0.06, 0.38), Vector3(-42.0, 0.82, 1.45), _make_led_material(Color(0.0, 0.83, 1.0)))

	# 3. Wet Asphalt Boulevard (z in [-22, -5])
	_road_mat = ShaderMaterial.new()
	_road_mat.shader = ASPHALT_SHADER
	_add_static_box(city_root, "BayfrontBoulevard", Vector3(260.0, 0.4, 18.0), Vector3(0.0, -0.25, -14.0), _road_mat, false, false)

	# Crisp dashed lane markings
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.92, 0.90, 0.82)
	stripe_mat.roughness = 0.45
	for i: int in range(-14, 15):
		_batcher.queue_box(city_root, Vector3(3.4, 0.02, 0.22), Vector3(float(i) * 8.0, -0.04, -14.0), stripe_mat, Vector3.ZERO, true, false)

	# North sidewalk & tower plinths (z < -23)
	_add_static_box(city_root, "NorthSidewalk", Vector3(260.0, 0.6, 56.0), Vector3(0.0, -0.3, -51.0), prom_mat)

	# 4. Modern 2026 Glass & Aluminum Bayfront Towers
	var glass_a := StandardMaterial3D.new()
	glass_a.albedo_color = Color(0.24, 0.41, 0.50)
	glass_a.metallic = 0.42
	glass_a.roughness = 0.08

	var glass_b := StandardMaterial3D.new()
	glass_b.albedo_color = Color(0.16, 0.28, 0.37)
	glass_b.metallic = 0.55
	glass_b.roughness = 0.07

	var alum_mat := StandardMaterial3D.new()
	alum_mat.albedo_color = Color(0.72, 0.68, 0.64)
	alum_mat.metallic = 0.65
	alum_mat.roughness = 0.28

	var cyan_led := _make_led_material(Color(0.0, 0.83, 1.0))
	var amber_led := _make_led_material(Color(1.0, 0.68, 0.22))

	var tower_specs: Array[Dictionary] = [
		{"x": -48.0, "z": -40.0, "w": 20.0, "d": 18.0, "h": 42.0, "glass": glass_a, "led": cyan_led},
		{"x": -12.0, "z": -38.0, "w": 22.0, "d": 18.0, "h": 54.0, "glass": glass_b, "led": amber_led},
		{"x": 24.0, "z": -42.0, "w": 24.0, "d": 20.0, "h": 68.0, "glass": glass_a, "led": cyan_led},
		{"x": 58.0, "z": -37.0, "w": 20.0, "d": 18.0, "h": 48.0, "glass": glass_b, "led": amber_led},
		{"x": 90.0, "z": -44.0, "w": 26.0, "d": 20.0, "h": 60.0, "glass": glass_a, "led": cyan_led},
	]
	for idx: int in range(tower_specs.size()):
		var spec: Dictionary = tower_specs[idx]
		var tx: float = spec["x"]
		var tz: float = spec["z"]
		var tw: float = spec["w"]
		var td: float = spec["d"]
		var th: float = spec["h"]

		# Tower podium
		_add_static_box(city_root, "TowerPodium_%d" % idx, Vector3(tw + 4.0, 7.0, td + 4.0), Vector3(tx, 3.5, tz), alum_mat)
		# Main glass shaft
		_add_static_box(city_root, "TowerShaft_%d" % idx, Vector3(tw, th, td), Vector3(tx, th * 0.5, tz), spec["glass"])
		# Upper architectural setback + glowing LED crown
		_add_static_box(city_root, "TowerCrown_%d" % idx, Vector3(tw * 0.72, 6.0, td * 0.72), Vector3(tx, th + 3.0, tz), alum_mat)
		_add_mesh_box(city_root, Vector3(tw + 0.3, 0.7, td + 0.3), Vector3(tx, th - 0.6, tz), spec["led"])
		_add_mesh_box(city_root, Vector3(tw * 0.74, 0.55, td * 0.74), Vector3(tx, th + 6.1, tz), spec["led"])

	# 5. Royal Palms & Sleek LED Streetlamps along Promenade
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.42, 0.36, 0.31)
	trunk_mat.roughness = 0.88
	var frond_mat := StandardMaterial3D.new()
	frond_mat.albedo_color = Color(0.16, 0.38, 0.21)
	frond_mat.roughness = 0.68
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.18, 0.20, 0.23)
	pole_mat.metallic = 0.8
	pole_mat.roughness = 0.28
	var warm_led := _make_led_material(Color(1.0, 0.82, 0.55))

	for i: int in range(-4, 6):
		var px: float = float(i) * 20.0 + 6.0
		_spawn_palm_tree(city_root, Vector3(px, 0.0, 8.2), trunk_mat, frond_mat)
		_spawn_streetlamp(city_root, Vector3(px - 8.5, 0.0, -3.5), pole_mat, warm_led, abs(i) <= 2)

	# 6. Offshore Luxury Cruiser Silhouette on the Bay
	var hull_mat := StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.92, 0.93, 0.95)
	hull_mat.roughness = 0.22
	hull_mat.metallic = 0.1
	_add_mesh_box(city_root, Vector3(18.0, 2.2, 4.6), Vector3(26.0, 0.1, 46.0), hull_mat)
	_add_mesh_box(city_root, Vector3(10.0, 1.8, 3.6), Vector3(24.5, 2.0, 46.0), glass_b)
	_add_mesh_box(city_root, Vector3(11.0, 0.25, 3.8), Vector3(24.5, 1.15, 46.0), cyan_led)
	_batcher.flush(100.0)


func _make_led_material(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.6
	mat.roughness = 0.2
	_led_materials.append(mat)
	return mat


func _spawn_palm_tree(parent: Node3D, pos: Vector3, trunk_mat: Material, frond_mat: Material) -> void:
	var palm := Node3D.new()
	palm.position = pos
	parent.add_child(palm)

	if _palm_trunk_mesh == null:
		_palm_trunk_mesh = CylinderMesh.new()
		_palm_trunk_mesh.top_radius = 0.19
		_palm_trunk_mesh.bottom_radius = 0.30
		_palm_trunk_mesh.height = 7.4
		_palm_trunk_mesh.radial_segments = 10
	_batcher.queue_mesh(_palm_trunk_mesh, palm, Vector3(0.0, 3.7, 0.0), Vector3.ZERO, Vector3.ONE, trunk_mat, true)

	for f_idx: int in range(6):
		var angle: float = float(f_idx) * (TAU / 6.0)
		var frond_pos := Vector3(sin(angle) * 1.4, 7.2, cos(angle) * 1.4)
		_batcher.queue_box(palm, Vector3(0.45, 0.12, 3.2), frond_pos, frond_mat, Vector3(-0.34, angle, 0.0), true)


func _spawn_streetlamp(parent: Node3D, pos: Vector3, pole_mat: Material, led_mat: Material, add_point_light: bool) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	parent.add_child(lamp)

	_add_mesh_box(lamp, Vector3(0.18, 6.2, 0.18), Vector3(0.0, 3.1, 0.0), pole_mat, Vector3.ZERO, true)
	_add_mesh_box(lamp, Vector3(0.22, 0.16, 1.5), Vector3(0.0, 6.2, -0.65), pole_mat, Vector3.ZERO, true)
	_add_mesh_box(lamp, Vector3(0.18, 0.08, 0.9), Vector3(0.0, 6.1, -0.9), led_mat, Vector3.ZERO, true)

	if add_point_light:
		var light := OmniLight3D.new()
		light.position = Vector3(0.0, 5.7, -0.9)
		light.light_color = Color(1.0, 0.85, 0.65)
		light.light_energy = 1.6
		light.omni_range = 16.0
		light.distance_fade_enabled = true
		light.distance_fade_begin = 32.0
		light.distance_fade_length = 18.0
		light.shadow_enabled = false
		lamp.add_child(light)
		_street_lights.append(light)


func _add_static_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, mat: Material, detail: bool = false, casts_shadow: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	parent.add_child(body)
	_batcher.queue_box(body, size, Vector3.ZERO, mat, Vector3.ZERO, detail, casts_shadow)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


func _add_mesh_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rotation: Vector3 = Vector3.ZERO, detail: bool = false) -> void:
	_batcher.queue_box(parent, size, pos, mat, rotation, detail)


func _build_player_rig() -> void:
	_actor = PLAYER_SCENE.instantiate() as CharacterBody3D
	_actor.name = "PlayerPreview"
	_actor.position = Vector3(-42.0, 0.1, 3.2)
	_actor.rotation.y = 0.0
	add_child(_actor)


func _process(delta: float) -> void:
	if _day_cycle.advance(delta):
		_apply_day_night_sample()
	_light_update_elapsed += delta
	if _light_update_elapsed >= 0.5:
		_light_update_elapsed = 0.0
		_update_streetlight_budget()


func _physics_process(_delta: float) -> void:
	if _actor == null:
		return
	var stream := get_node_or_null("/root/Streaming") as StreamingScript
	if stream != null:
		stream.update_focus_position(_actor.global_position)


func _on_touch_action(action_name: String) -> void:
	if action_name == "cycle_tod":
		_day_cycle.jump_to_next_phase()
		_apply_day_night_sample()
		var eb := get_node_or_null("/root/EventBus") as EventBusScript
		if eb != null:
			eb.hud_message_requested.emit("TIME %s · %s" % [_day_cycle.get_clock_text(), _day_cycle.get_phase_name().to_upper()])


func _apply_day_night_sample() -> void:
	var sample: Dictionary = _day_cycle.sample()
	if _sun != null:
		_sun.rotation_degrees = Vector3(sample["light_pitch"], sample["light_yaw"], 0.0)
		_sun.light_color = sample["light_color"]
		_sun.light_energy = sample["light_energy"]

	if _sky_mat != null:
		_sky_mat.set_shader_parameter("sky_top_color", sample["sky_top"])
		_sky_mat.set_shader_parameter("sky_horizon_color", sample["sky_horizon"])
		_sky_mat.set_shader_parameter("ground_horizon_color", sample["ground_horizon"])
		_sky_mat.set_shader_parameter("sun_color", sample["sun_color"])
		_sky_mat.set_shader_parameter("sun_direction", sample["sun_direction"])
		_sky_mat.set_shader_parameter("moon_direction", sample["moon_direction"])
		_sky_mat.set_shader_parameter("moon_strength", sample["moon_strength"])
		_sky_mat.set_shader_parameter("night_factor", sample["night_factor"])
		_sky_mat.set_shader_parameter("cloud_offset", sample["cloud_offset"])

	if _world_env != null and _world_env.environment != null:
		_world_env.environment.ambient_light_energy = sample["ambient_energy"]
		_world_env.environment.fog_light_color = sample["fog_color"]
		_world_env.environment.fog_density = sample["fog_density"]

	var led_boost: float = sample["led_boost"]
	for mat: StandardMaterial3D in _led_materials:
		mat.emission_energy_multiplier = led_boost
	for light: OmniLight3D in _street_lights:
		light.light_energy = led_boost * 1.1

	var gs := get_node_or_null("/root/GameState") as GameStateScript
	if gs != null:
		gs.set_time_of_day(sample["phase"], sample["hours"])
	var eb := get_node_or_null("/root/EventBus") as EventBusScript
	if eb != null:
		eb.time_of_day_changed.emit(sample["phase"], sample["sun_elevation"])


func _on_quality_changed(preset_name: String) -> void:
	if _sun == null:
		return
	var st := get_node_or_null("/root/Settings") as SettingsScript
	if st == null:
		return
	_day_cycle.set_quality_tier(st.shader_tier)
	match preset_name:
		"LOW":
			_sun.shadow_enabled = false
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		"MEDIUM":
			_sun.shadow_enabled = true
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		"HIGH":
			_sun.shadow_enabled = true
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_sun.directional_shadow_max_distance = st.shadow_distance
	_point_light_budget = st.dynamic_light_budget
	_update_streetlight_budget()

	if _environment != null:
		_environment.glow_enabled = st.glow_enabled
		_environment.fog_enabled = st.fog_enabled
	if _sky != null:
		match preset_name:
			"LOW":
				_sky.radiance_size = Sky.RADIANCE_SIZE_64
			"MEDIUM":
				_sky.radiance_size = Sky.RADIANCE_SIZE_128
			"HIGH":
				_sky.radiance_size = Sky.RADIANCE_SIZE_256
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("quality_level", st.shader_tier)
	if _probe != null:
		_probe.visible = st.reflection_probe_enabled
	if _batcher != null:
		_batcher.apply_detail_distance(st.detail_distance)
	if _water_mesh != null:
		_water_mesh.subdivide_width = [8, 24, 48][st.water_tier] as int
		_water_mesh.subdivide_depth = [4, 12, 32][st.water_tier] as int
	if _water_mat != null:
		_water_mat.set_shader_parameter("quality_level", st.water_tier)
	if _road_mat != null:
		_road_mat.set_shader_parameter("quality_level", st.shader_tier)
	if _actor != null:
		var camera := _actor.get_camera_rig().get_camera() as Camera3D
		if camera != null:
			camera.far = [260.0, 380.0, 550.0][st.water_tier] as float


func _update_streetlight_budget() -> void:
	if _actor == null:
		return
	_street_lights.sort_custom(func(a: OmniLight3D, b: OmniLight3D) -> bool:
		return a.global_position.distance_squared_to(_actor.global_position) < b.global_position.distance_squared_to(_actor.global_position)
	)
	for index: int in range(_street_lights.size()):
		_street_lights[index].visible = index < _point_light_budget


func get_optimization_stats() -> Dictionary:
	var active_lights: int = 0
	for light: OmniLight3D in _street_lights:
		if light.visible:
			active_lights += 1
	return {
		"static_batches": _batcher.get_batch_count() if _batcher != null else 0,
		"static_instances": _batcher.get_instance_count() if _batcher != null else 0,
		"active_street_lights": active_lights,
		"water_subdivisions": Vector2i(_water_mesh.subdivide_width, _water_mesh.subdivide_depth) if _water_mesh != null else Vector2i.ZERO,
		"shadows_enabled": _sun.shadow_enabled if _sun != null else false,
		"probe_enabled": _probe.visible if _probe != null else false,
		"time_hours": _day_cycle.hours,
		"time_clock": _day_cycle.get_clock_text(),
		"sky_update_interval": _day_cycle.update_interval,
	}

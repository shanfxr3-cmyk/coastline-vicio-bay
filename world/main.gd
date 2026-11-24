extends Node3D

## Phase 0 Bayfront Promenade prototype scene.
## Demonstrates Jolt physics character movement, touch/mouse camera orbit,
## 2026 Vicio Bay lighting/materials, and Standard vs Ultra renderer parity.

const WATER_SHADER := preload("res://shaders/bay_water_p0.gdshader")
const ASPHALT_SHADER := preload("res://shaders/wet_asphalt_p0.gdshader")
const EventBusScript := preload("res://core/event_bus.gd")
const GameStateScript := preload("res://core/game_state.gd")
const SettingsScript := preload("res://core/settings.gd")
const StreamingScript := preload("res://world/streaming.gd")

const MOVE_SPEED := 7.2
const JUMP_VELOCITY := 5.6
const GRAVITY := 18.0

var _tod_index: int = 0
var _tod_presets: Array[Dictionary] = [
	{
		"name": "Golden",
		"sun_pitch": -13.0,
		"sun_yaw": -38.0,
		"sun_color": Color(1.0, 0.64, 0.34),
		"sun_energy": 1.85,
		"sky_top": Color(0.11, 0.30, 0.44),
		"sky_horizon": Color(0.95, 0.58, 0.32),
		"ground_horizon": Color(0.16, 0.24, 0.32),
		"ambient_energy": 0.42,
		"fog_color": Color(0.76, 0.56, 0.44),
		"fog_density": 0.0018,
		"led_boost": 1.6,
	},
	{
		"name": "Blue",
		"sun_pitch": -2.5,
		"sun_yaw": -55.0,
		"sun_color": Color(0.45, 0.62, 0.90),
		"sun_energy": 0.85,
		"sky_top": Color(0.05, 0.11, 0.22),
		"sky_horizon": Color(0.24, 0.41, 0.58),
		"ground_horizon": Color(0.06, 0.09, 0.14),
		"ambient_energy": 0.32,
		"fog_color": Color(0.13, 0.23, 0.35),
		"fog_density": 0.0030,
		"led_boost": 2.6,
	},
	{
		"name": "Night",
		"sun_pitch": -35.0,
		"sun_yaw": 120.0,
		"sun_color": Color(0.48, 0.61, 0.82),
		"sun_energy": 0.45,
		"sky_top": Color(0.02, 0.04, 0.09),
		"sky_horizon": Color(0.05, 0.11, 0.20),
		"ground_horizon": Color(0.02, 0.04, 0.07),
		"ambient_energy": 0.22,
		"fog_color": Color(0.04, 0.08, 0.14),
		"fog_density": 0.0035,
		"led_boost": 3.4,
	},
]

var _sun: DirectionalLight3D = null
var _world_env: WorldEnvironment = null
var _sky_mat: ProceduralSkyMaterial = null
var _actor: CharacterBody3D = null
var _cam_pivot: Node3D = null
var _camera: Camera3D = null
var _move_input: Vector2 = Vector2.ZERO
var _cam_yaw: float = -1.26
var _cam_pitch: float = -0.05
var _led_materials: Array[StandardMaterial3D] = []
var _street_lights: Array[OmniLight3D] = []


func _ready() -> void:
	_build_environment()
	_build_bayfront_world()
	_build_player_rig()
	_apply_tod(0)

	var eb := get_node_or_null("/root/EventBus") as EventBusScript
	if eb != null:
		eb.touch_move_updated.connect(func(v: Vector2) -> void:
			_move_input = v
		)
		eb.touch_look_updated.connect(_on_touch_look)
		eb.touch_action_triggered.connect(_on_touch_action)
		eb.quality_preset_changed.connect(_on_quality_changed)

	var st := get_node_or_null("/root/Settings") as SettingsScript
	_on_quality_changed(st.get_preset_name() if st != null else "MEDIUM")


func _build_environment() -> void:
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sun_angle_max = 18.0
	_sky_mat.sun_curve = 0.09

	var sky := Sky.new()
	sky.sky_material = _sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
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

	var probe := ReflectionProbe.new()
	probe.name = "BayfrontProbe"
	probe.position = Vector3(0.0, 18.0, 0.0)
	probe.size = Vector3(240.0, 90.0, 240.0)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(probe)


func _build_bayfront_world() -> void:
	var city_root := Node3D.new()
	city_root.name = "BayfrontGeometry"
	add_child(city_root)

	# 1. Bay Ocean Surface (south/right side z > 10)
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(420.0, 260.0)
	water_mesh.subdivide_width = 72
	water_mesh.subdivide_depth = 48
	var water_mat := ShaderMaterial.new()
	water_mat.shader = WATER_SHADER
	var water_inst := MeshInstance3D.new()
	water_inst.name = "VicioBayWater"
	water_inst.mesh = water_mesh
	water_inst.material_override = water_mat
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

	# 3. Wet Asphalt Boulevard (z in [-22, -5])
	var road_mat := ShaderMaterial.new()
	road_mat.shader = ASPHALT_SHADER
	var road_mesh := BoxMesh.new()
	road_mesh.size = Vector3(260.0, 0.4, 18.0)
	var road_inst := _add_static_box(city_root, "BayfrontBoulevard", Vector3(260.0, 0.4, 18.0), Vector3(0.0, -0.25, -14.0), null)
	(road_inst.get_child(0) as MeshInstance3D).material_override = road_mat

	# Crisp dashed lane markings
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.92, 0.90, 0.82)
	stripe_mat.roughness = 0.45
	for i: int in range(-14, 15):
		var stripe := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(3.4, 0.02, 0.22)
		stripe.mesh = sm
		stripe.material_override = stripe_mat
		stripe.position = Vector3(float(i) * 8.0, -0.04, -14.0)
		city_root.add_child(stripe)

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

	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.19
	cyl.bottom_radius = 0.30
	cyl.height = 7.4
	cyl.radial_segments = 10
	trunk.mesh = cyl
	trunk.material_override = trunk_mat
	trunk.position = Vector3(0.0, 3.7, 0.0)
	palm.add_child(trunk)

	for f_idx: int in range(6):
		var frond := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.45, 0.12, 3.2)
		frond.mesh = box
		frond.material_override = frond_mat
		var angle: float = float(f_idx) * (TAU / 6.0)
		frond.position = Vector3(sin(angle) * 1.4, 7.2, cos(angle) * 1.4)
		frond.rotation = Vector3(-0.34, angle, 0.0)
		palm.add_child(frond)


func _spawn_streetlamp(parent: Node3D, pos: Vector3, pole_mat: Material, led_mat: Material, add_point_light: bool) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	parent.add_child(lamp)

	_add_mesh_box(lamp, Vector3(0.18, 6.2, 0.18), Vector3(0.0, 3.1, 0.0), pole_mat)
	_add_mesh_box(lamp, Vector3(0.22, 0.16, 1.5), Vector3(0.0, 6.2, -0.65), pole_mat)
	_add_mesh_box(lamp, Vector3(0.18, 0.08, 0.9), Vector3(0.0, 6.1, -0.9), led_mat)

	if add_point_light:
		var light := OmniLight3D.new()
		light.position = Vector3(0.0, 5.7, -0.9)
		light.light_color = Color(1.0, 0.85, 0.65)
		light.light_energy = 1.6
		light.omni_range = 16.0
		light.shadow_enabled = false
		lamp.add_child(light)
		_street_lights.append(light)


func _add_static_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	parent.add_child(body)

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	if mat != null:
		mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


func _add_mesh_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	parent.add_child(mesh_inst)
	return mesh_inst


func _build_player_rig() -> void:
	_actor = CharacterBody3D.new()
	_actor.name = "PlayerPreview"
	_actor.position = Vector3(-42.0, 0.1, 3.2)
	_actor.rotation.y = -1.26
	add_child(_actor)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.75
	col.shape = cap
	col.position = Vector3(0.0, 0.875, 0.0)
	_actor.add_child(col)

	var body_mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.36
	cm.height = 1.72
	body_mesh.mesh = cm
	body_mesh.position = Vector3(0.0, 0.875, 0.0)
	var suit_mat := StandardMaterial3D.new()
	suit_mat.albedo_color = Color(0.11, 0.14, 0.18)
	suit_mat.roughness = 0.55
	body_mesh.material_override = suit_mat
	_actor.add_child(body_mesh)

	# Forward visor strip so facing direction is clearly readable
	var visor := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.42, 0.14, 0.22)
	visor.mesh = vm
	visor.position = Vector3(0.0, 1.48, -0.28)
	visor.material_override = _make_led_material(Color(0.0, 0.83, 1.0))
	_actor.add_child(visor)

	_cam_pivot = Node3D.new()
	_cam_pivot.name = "CameraPivot"
	_cam_pivot.position = Vector3(0.0, 1.55, 0.0)
	_actor.add_child(_cam_pivot)

	_camera = Camera3D.new()
	_camera.name = "MainCamera"
	_camera.fov = 62.0
	_camera.far = 650.0
	_camera.position = Vector3(0.45, 0.65, 5.2)
	_camera.current = true
	_cam_pivot.add_child(_camera)
	_update_camera_rig()


func _physics_process(delta: float) -> void:
	if _actor == null:
		return

	if not _actor.is_on_floor():
		_actor.velocity.y -= GRAVITY * delta

	var cam_basis: Basis = Basis(Vector3.UP, _cam_yaw)
	var forward: Vector3 = -cam_basis.z
	var right: Vector3 = cam_basis.x
	var wish_dir: Vector3 = (right * _move_input.x) + (forward * -_move_input.y)
	if wish_dir.length() > 1.0:
		wish_dir = wish_dir.normalized()

	_actor.velocity.x = lerpf(_actor.velocity.x, wish_dir.x * MOVE_SPEED, clampf(delta * 10.0, 0.0, 1.0))
	_actor.velocity.z = lerpf(_actor.velocity.z, wish_dir.z * MOVE_SPEED, clampf(delta * 10.0, 0.0, 1.0))
	_actor.move_and_slide()

	if wish_dir.length() > 0.08:
		var target_yaw: float = atan2(-wish_dir.x, -wish_dir.z)
		_actor.rotation.y = lerp_angle(_actor.rotation.y, target_yaw, clampf(delta * 12.0, 0.0, 1.0))
		_update_camera_rig()

	var stream := get_node_or_null("/root/Streaming") as StreamingScript
	if stream != null:
		stream.update_focus_position(_actor.global_position)


func _on_touch_look(look_delta: Vector2) -> void:
	_cam_yaw -= look_delta.x
	_cam_pitch = clampf(_cam_pitch - look_delta.y, -0.85, 0.35)
	_update_camera_rig()


func _update_camera_rig() -> void:
	if _cam_pivot == null or _actor == null:
		return
	_cam_pivot.global_rotation = Vector3(_cam_pitch, _cam_yaw, 0.0)


func _on_touch_action(action_name: String) -> void:
	if action_name == "jump" and _actor != null and _actor.is_on_floor():
		_actor.velocity.y = JUMP_VELOCITY
	elif action_name == "cycle_tod":
		_tod_index = (_tod_index + 1) % _tod_presets.size()
		_apply_tod(_tod_index)


func _apply_tod(idx: int) -> void:
	var preset: Dictionary = _tod_presets[idx]
	var tod_name: String = preset["name"]
	var pitch: float = preset["sun_pitch"]
	var yaw: float = preset["sun_yaw"]

	if _sun != null:
		_sun.rotation_degrees = Vector3(pitch, yaw, 0.0)
		_sun.light_color = preset["sun_color"]
		_sun.light_energy = preset["sun_energy"]

	if _sky_mat != null:
		_sky_mat.sky_top_color = preset["sky_top"]
		_sky_mat.sky_horizon_color = preset["sky_horizon"]
		_sky_mat.ground_horizon_color = preset["ground_horizon"]

	if _world_env != null and _world_env.environment != null:
		_world_env.environment.ambient_light_energy = preset["ambient_energy"]
		_world_env.environment.fog_light_color = preset["fog_color"]
		_world_env.environment.fog_density = preset["fog_density"]

	var led_boost: float = preset["led_boost"]
	for mat: StandardMaterial3D in _led_materials:
		mat.emission_energy_multiplier = led_boost
	for light: OmniLight3D in _street_lights:
		light.light_energy = led_boost * 1.1

	var gs := get_node_or_null("/root/GameState") as GameStateScript
	if gs != null:
		gs.set_time_of_day_phase(tod_name)
	var eb := get_node_or_null("/root/EventBus") as EventBusScript
	if eb != null:
		eb.time_of_day_changed.emit(tod_name, -pitch)


func _on_quality_changed(preset_name: String) -> void:
	if _sun == null:
		return
	match preset_name:
		"LOW":
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			_sun.directional_shadow_max_distance = 75.0
		"MEDIUM":
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			_sun.directional_shadow_max_distance = 120.0
		"HIGH":
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			_sun.directional_shadow_max_distance = 180.0

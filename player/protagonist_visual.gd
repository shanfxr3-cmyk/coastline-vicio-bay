extends Node3D

## Original articulated procedural character used by both Phase 1 protagonists.
## Joint pivots are animated directly so locomotion works without imported assets.

const PROFILES: Dictionary = {
	"kian": {
		"display_name": "Kian Cross",
		"skin": Color(0.52, 0.31, 0.20),
		"hair": Color(0.035, 0.045, 0.055),
		"jacket": Color(0.07, 0.16, 0.22),
		"shirt": Color(0.72, 0.78, 0.80),
		"pants": Color(0.055, 0.075, 0.10),
		"accent": Color(0.0, 0.83, 1.0),
	},
	"sera": {
		"display_name": "Sera Vale",
		"skin": Color(0.72, 0.47, 0.32),
		"hair": Color(0.16, 0.065, 0.035),
		"jacket": Color(0.26, 0.075, 0.10),
		"shirt": Color(0.16, 0.19, 0.23),
		"pants": Color(0.075, 0.085, 0.11),
		"accent": Color(1.0, 0.62, 0.24),
	},
}

var protagonist_id: String = "kian"
var _built: bool = false
var _stride: float = 0.0
var _crouch_blend: float = 0.0
var _visual_root: Node3D = null
var _torso: MeshInstance3D = null
var _left_arm: Node3D = null
var _right_arm: Node3D = null
var _left_leg: Node3D = null
var _right_leg: Node3D = null
var _skin_mat: StandardMaterial3D = null
var _hair_mat: StandardMaterial3D = null
var _jacket_mat: StandardMaterial3D = null
var _shirt_mat: StandardMaterial3D = null
var _pants_mat: StandardMaterial3D = null
var _accent_mat: StandardMaterial3D = null


func _ready() -> void:
	_build_rig()
	_apply_profile()


func configure(new_id: String) -> void:
	protagonist_id = new_id if PROFILES.has(new_id) else "kian"
	if _built:
		_apply_profile()


func get_display_name() -> String:
	return str(PROFILES[protagonist_id]["display_name"])


func update_pose(locomotion_state: String, planar_speed: float, delta: float) -> void:
	if not _built:
		return
	var moving: bool = locomotion_state == "WALK" or locomotion_state == "SPRINT" or locomotion_state == "CROUCH"
	if moving:
		_stride += delta * maxf(planar_speed, 1.5) * 2.2
	var swing_strength: float = clampf(planar_speed / 5.0, 0.0, 1.0)
	var swing: float = sin(_stride) * swing_strength * 0.72 if moving else 0.0
	var pose_weight: float = clampf(delta * 12.0, 0.0, 1.0)
	_left_leg.rotation.x = lerpf(_left_leg.rotation.x, swing, pose_weight)
	_right_leg.rotation.x = lerpf(_right_leg.rotation.x, -swing, pose_weight)
	_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -swing * 0.78, pose_weight)
	_right_arm.rotation.x = lerpf(_right_arm.rotation.x, swing * 0.78, pose_weight)

	if locomotion_state == "JUMP" or locomotion_state == "FALL":
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -0.85, pose_weight)
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -0.85, pose_weight)
	elif locomotion_state == "VAULT":
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -1.35, pose_weight)
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -1.35, pose_weight)

	_crouch_blend = move_toward(_crouch_blend, 1.0 if locomotion_state == "CROUCH" else 0.0, delta * 6.0)
	_visual_root.scale.y = lerpf(1.0, 0.70, _crouch_blend)
	_visual_root.rotation.x = lerpf(_visual_root.rotation.x, -0.65 if locomotion_state == "VAULT" else 0.0, pose_weight)
	_torso.position.y = 1.22 + (sin(_stride * 0.5) * 0.012 if locomotion_state == "IDLE" else 0.0)


func _apply_profile() -> void:
	var profile: Dictionary = PROFILES[protagonist_id]
	_skin_mat.albedo_color = profile["skin"]
	_hair_mat.albedo_color = profile["hair"]
	_jacket_mat.albedo_color = profile["jacket"]
	_shirt_mat.albedo_color = profile["shirt"]
	_pants_mat.albedo_color = profile["pants"]
	_accent_mat.albedo_color = profile["accent"]
	_accent_mat.emission = profile["accent"]


func _build_rig() -> void:
	if _built:
		return
	_built = true
	_skin_mat = _material(Color.WHITE, 0.58)
	_hair_mat = _material(Color.WHITE, 0.82)
	_jacket_mat = _material(Color.WHITE, 0.48)
	_shirt_mat = _material(Color.WHITE, 0.70)
	_pants_mat = _material(Color.WHITE, 0.76)
	_accent_mat = _material(Color.WHITE, 0.30)
	_accent_mat.emission_enabled = true
	_accent_mat.emission_energy_multiplier = 0.65
	var shoe_mat := _material(Color(0.035, 0.045, 0.055), 0.64)
	var eye_mat := _material(Color(0.025, 0.03, 0.035), 0.35)

	_visual_root = Node3D.new()
	_visual_root.name = "ArticulatedRig"
	add_child(_visual_root)

	_torso = _box(_visual_root, "Torso", Vector3(0.50, 0.62, 0.28), Vector3(0.0, 1.22, 0.0), _jacket_mat)
	_box(_visual_root, "ShirtPanel", Vector3(0.20, 0.46, 0.025), Vector3(0.0, 1.24, -0.151), _shirt_mat)
	_box(_visual_root, "JacketAccent", Vector3(0.38, 0.035, 0.03), Vector3(0.0, 1.40, -0.17), _accent_mat)
	_box(_visual_root, "Hips", Vector3(0.40, 0.22, 0.26), Vector3(0.0, 0.88, 0.0), _pants_mat)
	_cylinder(_visual_root, "Neck", 0.075, 0.13, Vector3(0.0, 1.52, 0.0), _skin_mat)
	_sphere(_visual_root, "Head", 0.17, Vector3(0.0, 1.69, 0.0), _skin_mat, Vector3(0.92, 1.08, 0.94))
	_sphere(_visual_root, "Hair", 0.174, Vector3(0.0, 1.76, 0.015), _hair_mat, Vector3(0.96, 0.58, 0.96))
	_box(_visual_root, "Nose", Vector3(0.045, 0.06, 0.045), Vector3(0.0, 1.69, -0.164), _skin_mat)
	_box(_visual_root, "LeftEye", Vector3(0.035, 0.022, 0.018), Vector3(-0.058, 1.72, -0.157), eye_mat)
	_box(_visual_root, "RightEye", Vector3(0.035, 0.022, 0.018), Vector3(0.058, 1.72, -0.157), eye_mat)

	_left_arm = _build_arm("LeftArm", -1.0)
	_right_arm = _build_arm("RightArm", 1.0)
	_left_leg = _build_leg("LeftLeg", -1.0, shoe_mat)
	_right_leg = _build_leg("RightLeg", 1.0, shoe_mat)


func _build_arm(part_name: String, side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = Vector3(side * 0.34, 1.43, 0.0)
	_visual_root.add_child(pivot)
	_cylinder(pivot, part_name + "Sleeve", 0.078, 0.46, Vector3(0.0, -0.20, 0.0), _jacket_mat)
	_cylinder(pivot, part_name + "Forearm", 0.064, 0.25, Vector3(0.0, -0.52, 0.0), _skin_mat)
	_sphere(pivot, part_name + "Hand", 0.075, Vector3(0.0, -0.68, 0.0), _skin_mat)
	return pivot


func _build_leg(part_name: String, side: float, shoe_mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = Vector3(side * 0.14, 0.86, 0.0)
	_visual_root.add_child(pivot)
	_cylinder(pivot, part_name + "Trouser", 0.095, 0.72, Vector3(0.0, -0.34, 0.0), _pants_mat)
	_box(pivot, part_name + "Shoe", Vector3(0.19, 0.13, 0.32), Vector3(0.0, -0.75, -0.065), shoe_mat)
	return pivot


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat


func _box(parent: Node3D, part_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = mat
	instance.layers = 2
	instance.position = pos
	parent.add_child(instance)
	return instance


func _cylinder(parent: Node3D, part_name: String, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 0.92
	mesh.height = height
	mesh.radial_segments = 10
	instance.mesh = mesh
	instance.material_override = mat
	instance.layers = 2
	instance.position = pos
	parent.add_child(instance)
	return instance


func _sphere(parent: Node3D, part_name: String, radius: float, pos: Vector3, mat: Material, part_scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	instance.mesh = mesh
	instance.material_override = mat
	instance.layers = 2
	instance.position = pos
	instance.scale = part_scale
	parent.add_child(instance)
	return instance

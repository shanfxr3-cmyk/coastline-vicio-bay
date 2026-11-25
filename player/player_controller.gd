extends CharacterBody3D

## Phase 1 on-foot controller: camera-relative movement, sprint lock, crouch,
## coyote-time jump, ray-checked vaulting, and two switchable protagonists.

const EventBusScript := preload("res://core/event_bus.gd")
const GameStateScript := preload("res://core/game_state.gd")
const ProtagonistVisualScript := preload("res://player/protagonist_visual.gd")
const ThirdPersonCameraScript := preload("res://player/third_person_camera.gd")

const WALK_SPEED := 4.8
const SPRINT_SPEED := 8.0
const CROUCH_SPEED := 2.35
const ACCELERATION := 22.0
const DECELERATION := 28.0
const GRAVITY := 20.0
const JUMP_VELOCITY := 6.4
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.14
const STAND_HEIGHT := 1.82
const CROUCH_HEIGHT := 1.16
const CAPSULE_RADIUS := 0.34
const VAULT_REACH := 1.65
const VAULT_DISTANCE := 2.75
const VAULT_DURATION := 0.62
const PROTAGONIST_IDS: Array[String] = ["kian", "sera"]

enum LocomotionState {
	IDLE,
	WALK,
	SPRINT,
	CROUCH,
	JUMP,
	FALL,
	VAULT,
}

@export var protagonist_id: String = "kian"

@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _visual: ProtagonistVisualScript = $Visual
@onready var _camera_rig: ThirdPersonCameraScript = $CameraRig

var _state: LocomotionState = LocomotionState.IDLE
var _stand_shape := CapsuleShape3D.new()
var _crouch_shape := CapsuleShape3D.new()
var _touch_move := Vector2.ZERO
var _crouched: bool = false
var _sprint_locked: bool = false
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _vault_available: bool = false
var _vault_candidate := Vector3.ZERO
var _vault_start := Vector3.ZERO
var _vault_target := Vector3.ZERO
var _vault_elapsed: float = 0.0


func _ready() -> void:
	floor_snap_length = 0.32
	floor_max_angle = deg_to_rad(46.0)
	safe_margin = 0.025
	_stand_shape.radius = CAPSULE_RADIUS
	_stand_shape.height = STAND_HEIGHT
	_crouch_shape.radius = CAPSULE_RADIUS
	_crouch_shape.height = CROUCH_HEIGHT
	_collision.shape = _stand_shape
	_collision.position.y = STAND_HEIGHT * 0.5
	_visual.configure(protagonist_id)
	_camera_rig.set_target(self)

	var eb := _event_bus()
	if eb != null:
		eb.touch_move_updated.connect(set_move_input)
		eb.touch_action_triggered.connect(_on_touch_action)
	_emit_protagonist()


func _physics_process(delta: float) -> void:
	_coyote_left = maxf(0.0, _coyote_left - delta)
	_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)
	if _state == LocomotionState.VAULT:
		_update_vault(delta)
		_visual.update_pose("VAULT", 3.0, delta)
		return

	if is_on_floor():
		_coyote_left = COYOTE_TIME
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0 and not _crouched:
		_perform_jump()

	var wish_dir := _get_wish_direction()
	var sprinting: bool = _is_sprint_requested() and not _crouched and wish_dir.length() > 0.08
	var speed: float = CROUCH_SPEED if _crouched else (SPRINT_SPEED if sprinting else WALK_SPEED)
	var acceleration: float = ACCELERATION if wish_dir.length() > 0.05 else DECELERATION
	velocity.x = move_toward(velocity.x, wish_dir.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, wish_dir.z * speed, acceleration * delta)
	if wish_dir.length() > 0.08:
		var target_yaw: float = atan2(-wish_dir.x, -wish_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 13.0, 0.0, 1.0))

	move_and_slide()
	refresh_vault_context()
	_update_locomotion_state(wish_dir, sprinting)
	_visual.update_pose(get_locomotion_state(), get_planar_speed(), delta)


func set_move_input(value: Vector2) -> void:
	_touch_move = value.limit_length(1.0)


func request_primary_action() -> void:
	if _state == LocomotionState.VAULT:
		return
	refresh_vault_context()
	if _vault_available and is_on_floor() and not _crouched:
		_begin_vault()
	else:
		_request_jump()


func set_sprint_lock(value: bool) -> void:
	if _sprint_locked == value:
		return
	_sprint_locked = value
	var eb := _event_bus()
	if eb != null:
		eb.sprint_lock_changed.emit(_sprint_locked)


func toggle_sprint_lock() -> void:
	set_sprint_lock(not _sprint_locked)


func is_sprint_locked() -> bool:
	return _sprint_locked


func set_crouched(value: bool) -> bool:
	if _crouched == value:
		return true
	if _state == LocomotionState.VAULT:
		return false
	if value and not is_on_floor():
		return false
	if not value and not _has_stand_clearance():
		return false
	_crouched = value
	_collision.shape = _crouch_shape if _crouched else _stand_shape
	_collision.position.y = (CROUCH_HEIGHT if _crouched else STAND_HEIGHT) * 0.5
	var eb := _event_bus()
	if eb != null:
		eb.crouch_changed.emit(_crouched)
	return true


func toggle_crouch() -> void:
	set_crouched(not _crouched)


func is_crouched() -> bool:
	return _crouched


func get_collision_height() -> float:
	return CROUCH_HEIGHT if _crouched else STAND_HEIGHT


func switch_protagonist() -> void:
	var next_index: int = (PROTAGONIST_IDS.find(protagonist_id) + 1) % PROTAGONIST_IDS.size()
	set_protagonist(PROTAGONIST_IDS[next_index])


func set_protagonist(new_id: String) -> void:
	if not PROTAGONIST_IDS.has(new_id):
		return
	protagonist_id = new_id
	_visual.configure(protagonist_id)
	_camera_rig.reset_follow()
	_emit_protagonist()


func get_display_name() -> String:
	return _visual.get_display_name()


func get_locomotion_state() -> String:
	match _state:
		LocomotionState.WALK:
			return "WALK"
		LocomotionState.SPRINT:
			return "SPRINT"
		LocomotionState.CROUCH:
			return "CROUCH"
		LocomotionState.JUMP:
			return "JUMP"
		LocomotionState.FALL:
			return "FALL"
		LocomotionState.VAULT:
			return "VAULT"
	return "IDLE"


func get_planar_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func can_vault() -> bool:
	return _vault_available


func get_vault_target() -> Vector3:
	return _vault_candidate


func get_camera_rig() -> ThirdPersonCameraScript:
	return _camera_rig


func refresh_vault_context() -> void:
	var available: bool = false
	if is_on_floor() and not _crouched and _state != LocomotionState.VAULT:
		available = _find_vault_target()
	if available != _vault_available:
		_vault_available = available
		var eb := _event_bus()
		if eb != null:
			eb.vault_context_changed.emit(available)


func _get_wish_direction() -> Vector3:
	var keyboard := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	var gamepad := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if gamepad.length() < 0.18:
		gamepad = Vector2.ZERO
	var input_vector: Vector2 = (_touch_move + keyboard + gamepad).limit_length(1.0)
	var cam_basis := Basis(Vector3.UP, _camera_rig.get_yaw())
	var wish: Vector3 = cam_basis.x * input_vector.x + (-cam_basis.z) * -input_vector.y
	wish.y = 0.0
	return wish.limit_length(1.0)


func _is_sprint_requested() -> bool:
	return _sprint_locked or Input.is_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_STICK)


func _request_jump() -> void:
	if _crouched:
		return
	if _coyote_left > 0.0 or is_on_floor():
		_perform_jump()
	else:
		_jump_buffer_left = JUMP_BUFFER_TIME


func _perform_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_set_state(LocomotionState.JUMP)


func _update_locomotion_state(wish_dir: Vector3, sprinting: bool) -> void:
	if not is_on_floor():
		_set_state(LocomotionState.JUMP if velocity.y > 0.0 else LocomotionState.FALL)
	elif _crouched:
		_set_state(LocomotionState.CROUCH)
	elif sprinting:
		_set_state(LocomotionState.SPRINT)
	elif wish_dir.length() > 0.08 or get_planar_speed() > 0.25:
		_set_state(LocomotionState.WALK)
	else:
		_set_state(LocomotionState.IDLE)


func _set_state(next_state: LocomotionState) -> void:
	if _state == next_state:
		return
	_state = next_state
	var state_name := get_locomotion_state()
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	if gs != null:
		gs.locomotion_state = state_name
	var eb := _event_bus()
	if eb != null:
		eb.locomotion_state_changed.emit(state_name)


func _find_vault_target() -> bool:
	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var low_hit: Dictionary = _ray(global_position + Vector3.UP * 0.55, global_position + Vector3.UP * 0.55 + forward * VAULT_REACH)
	if low_hit.is_empty() or absf((low_hit["normal"] as Vector3).y) > 0.35:
		return false
	var high_hit: Dictionary = _ray(global_position + Vector3.UP * 1.30, global_position + Vector3.UP * 1.30 + forward * (VAULT_REACH + 0.20))
	if not high_hit.is_empty():
		return false
	var landing_origin: Vector3 = global_position + forward * VAULT_DISTANCE + Vector3.UP * 1.45
	var landing: Dictionary = _ray(landing_origin, landing_origin + Vector3.DOWN * 1.80)
	if landing.is_empty() or (landing["normal"] as Vector3).y < 0.75:
		return false
	var candidate: Vector3 = (landing["position"] as Vector3) + Vector3.UP * 0.06
	if not _has_capsule_clearance(candidate, _stand_shape):
		return false
	_vault_candidate = candidate
	return true


func _begin_vault() -> void:
	_vault_start = global_position
	_vault_target = _vault_candidate
	_vault_elapsed = 0.0
	velocity = Vector3.ZERO
	_vault_available = false
	var eb := _event_bus()
	if eb != null:
		eb.vault_context_changed.emit(false)
	_set_state(LocomotionState.VAULT)


func _update_vault(delta: float) -> void:
	_vault_elapsed += delta
	var t: float = clampf(_vault_elapsed / VAULT_DURATION, 0.0, 1.0)
	var smooth_t: float = t * t * (3.0 - 2.0 * t)
	var desired: Vector3 = _vault_start.lerp(_vault_target, smooth_t)
	desired.y += sin(t * PI) * 1.12
	var motion: Vector3 = desired - global_position
	if motion.length() > 0.0001:
		move_and_collide(motion)
	if t >= 1.0:
		velocity = Vector3.ZERO
		_set_state(LocomotionState.IDLE)


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)


func _has_stand_clearance() -> bool:
	return _has_capsule_clearance(global_position, _stand_shape)


func _has_capsule_clearance(at_position: Vector3, shape: Shape3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, at_position + Vector3.UP * (STAND_HEIGHT * 0.5 + 0.06))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _emit_protagonist() -> void:
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	if gs != null:
		gs.active_protagonist_id = protagonist_id
	var eb := _event_bus()
	if eb != null:
		eb.protagonist_changed.emit(protagonist_id, get_display_name())


func _on_touch_action(action_name: String) -> void:
	match action_name:
		"jump", "primary_action":
			request_primary_action()
		"toggle_sprint":
			toggle_sprint_lock()
		"toggle_crouch":
			toggle_crouch()
		"switch_protagonist":
			switch_protagonist()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		match key.keycode:
			KEY_SPACE:
				request_primary_action()
			KEY_C:
				toggle_crouch()
			KEY_TAB:
				switch_protagonist()
	elif event is InputEventJoypadButton:
		var button := event as InputEventJoypadButton
		if not button.pressed:
			return
		match button.button_index:
			JOY_BUTTON_A:
				request_primary_action()
			JOY_BUTTON_B:
				toggle_crouch()
			JOY_BUTTON_Y:
				switch_protagonist()


func _event_bus() -> EventBusScript:
	return get_node_or_null("/root/EventBus") as EventBusScript

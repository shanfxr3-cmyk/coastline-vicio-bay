extends Node3D

## Collision-aware third-person orbit camera with smoothed target tracking.
## Touch, right-mouse and right-stick input all feed the same yaw/pitch controls.

const EventBusScript := preload("res://core/event_bus.gd")
const FOLLOW_HEIGHT := 1.42
const FOLLOW_SHARPNESS := 13.0
const GAMEPAD_LOOK_SPEED := 2.6
const MOUSE_SENSITIVITY := 0.0032
const STICK_DEADZONE := 0.18

var _target: Node3D = null
var _yaw: float = 0.0
var _pitch: float = -0.20
var _pitch_pivot: Node3D = null
var _spring: SpringArm3D = null
var _camera: Camera3D = null


func _ready() -> void:
	top_level = true
	rotation = Vector3(0.0, _yaw, 0.0)
	_pitch_pivot = Node3D.new()
	_pitch_pivot.name = "PitchPivot"
	_pitch_pivot.rotation.x = _pitch
	add_child(_pitch_pivot)

	_spring = SpringArm3D.new()
	_spring.name = "CollisionArm"
	_spring.spring_length = 5.4
	_spring.margin = 0.18
	_spring.collision_mask = 1
	var sphere := SphereShape3D.new()
	sphere.radius = 0.22
	_spring.shape = sphere
	_pitch_pivot.add_child(_spring)

	_camera = Camera3D.new()
	_camera.name = "ThirdPersonCamera"
	_camera.fov = 64.0
	_camera.near = 0.08
	_camera.far = 650.0
	_camera.current = true
	_spring.add_child(_camera)

	var eb := get_node_or_null("/root/EventBus") as EventBusScript
	if eb != null:
		eb.touch_look_updated.connect(add_look)


func set_target(new_target: Node3D) -> void:
	_target = new_target
	if _target is CollisionObject3D:
		_spring.add_excluded_object((_target as CollisionObject3D).get_rid())
	reset_follow()


func reset_follow() -> void:
	if _target != null:
		global_position = _target.global_position + Vector3.UP * FOLLOW_HEIGHT


func add_look(look_delta: Vector2) -> void:
	_yaw -= look_delta.x
	_pitch = clampf(_pitch - look_delta.y, -0.82, 0.32)
	rotation.y = _yaw
	if _pitch_pivot != null:
		_pitch_pivot.rotation.x = _pitch


func get_yaw() -> float:
	return _yaw


func get_hit_length() -> float:
	return _spring.get_hit_length() if _spring != null else 0.0


func get_spring_length() -> float:
	return _spring.spring_length if _spring != null else 0.0


func get_camera() -> Camera3D:
	return _camera


func _process(delta: float) -> void:
	if _target == null:
		return
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if stick.length() < STICK_DEADZONE:
		stick = Vector2.ZERO
	else:
		stick = stick.limit_length(1.0)
		add_look(stick * GAMEPAD_LOOK_SPEED * delta)
	var target_pos: Vector3 = _target.global_position + Vector3.UP * FOLLOW_HEIGHT
	var weight: float = 1.0 - exp(-FOLLOW_SHARPNESS * delta)
	global_position = global_position.lerp(target_pos, weight)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_RIGHT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if button.pressed else Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		add_look(motion.relative * MOUSE_SENSITIVITY)

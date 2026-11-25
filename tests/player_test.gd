extends SceneTree

## Physics-level Phase 1 regression tests against the real Bayfront scene.

const PlayerScript := preload("res://player/player_controller.gd")
const GameStateScript := preload("res://core/game_state.gd")

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
	await _frames(8)
	var player := main_inst.get_node_or_null("PlayerPreview") as PlayerScript
	if player == null:
		_failures.append("PlayerPreview missing or wrong controller type")
		main_inst.queue_free()
		_finish()
		return

	await _reset_player(player, Vector3(-30.0, 0.10, 6.0))
	var start_pos: Vector3 = player.global_position
	player.set_move_input(Vector2(0.0, -1.0))
	await _frames(35)
	_check(player.global_position.z < start_pos.z - 1.0, "Walk did not move the character forward")
	_check(player.get_locomotion_state() == "WALK", "Walk state was not entered")
	player.set_sprint_lock(true)
	await _frames(24)
	_check(player.get_locomotion_state() == "SPRINT", "Sprint state was not entered")
	_check(player.get_planar_speed() > 6.5, "Sprint speed did not exceed walk speed")
	player.set_move_input(Vector2.ZERO)
	player.set_sprint_lock(false)
	await _frames(20)

	await _reset_player(player, Vector3(-30.0, 0.10, 6.0))
	_check(player.set_crouched(true), "Crouch request failed on open ground")
	await _frames(3)
	_check(player.is_crouched() and player.get_collision_height() < 1.3, "Crouch collider did not shrink")
	_check(player.get_locomotion_state() == "CROUCH", "Crouch state was not entered")
	_check(player.set_crouched(false), "Stand request failed in open space")
	await _frames(3)
	player.request_primary_action()
	await _frames(5)
	_check(player.global_position.y > 0.30, "Jump did not produce upward motion")
	_check(player.get_locomotion_state() == "JUMP", "Jump state was not entered")
	await _frames(72)
	_check(player.is_on_floor(), "Jump did not land back on the promenade")

	await _reset_player(player, Vector3(-42.0, 0.10, 3.20))
	player.refresh_vault_context()
	_check(player.can_vault(), "Practice barrier was not detected as vaultable")
	player.request_primary_action()
	await _frames(4)
	_check(player.get_locomotion_state() == "VAULT", "Contextual action did not start vault")
	await _frames(46)
	_check(player.global_position.z < 0.95, "Vault did not carry the player past the barrier (pos=%s target=%s)" % [player.global_position, player.get_vault_target()])
	_check(player.get_locomotion_state() != "VAULT", "Vault did not finish")

	var previous_id: String = player.protagonist_id
	player.switch_protagonist()
	_check(player.protagonist_id != previous_id, "Protagonist switch did not change identity")
	var gs := root.get_node("GameState") as GameStateScript
	_check(gs.active_protagonist_id == player.protagonist_id, "GameState did not track protagonist switch")
	player.switch_protagonist()
	_check(player.protagonist_id == previous_id, "Second protagonist switch did not cycle back")

	await _reset_player(player, Vector3(-30.0, 0.10, 6.0))
	var blocker := _make_blocker(main_inst, player.global_position + Vector3(0.0, 1.4, 2.4), Vector3(3.0, 3.0, 0.30))
	await _frames(6)
	_check(player.get_camera_rig().get_hit_length() < player.get_camera_rig().get_spring_length() - 0.5, "SpringArm did not retract for a camera obstruction")
	blocker.queue_free()
	await _frames(3)

	_check(player.set_crouched(true), "Crouch failed before low-ceiling test")
	var ceiling := _make_blocker(main_inst, player.global_position + Vector3.UP * 1.42, Vector3(1.2, 0.35, 1.2))
	await _frames(3)
	_check(not player.set_crouched(false) and player.is_crouched(), "Stand clearance check allowed clipping through a low ceiling")
	ceiling.queue_free()
	await _frames(3)
	_check(player.set_crouched(false), "Player could not stand after ceiling removal")

	main_inst.queue_free()
	await process_frame
	_finish()


func _reset_player(player: PlayerScript, at_position: Vector3) -> void:
	player.set_move_input(Vector2.ZERO)
	player.set_sprint_lock(false)
	player.set_crouched(false)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.global_position = at_position
	player.get_camera_rig().reset_follow()
	await _frames(8)


func _make_blocker(parent: Node, at_position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Phase1TestBlocker"
	body.position = at_position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


func _frames(count: int) -> void:
	for _index: int in range(count):
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PLAYER_TEST_PASS: Walk, Sprint, Crouch, Jump, Vault, Switch, CameraCollision, StandClearance")
		quit(0)
		return
	for message: String in _failures:
		printerr("PLAYER_TEST_FAIL: " + message)
	quit(1)

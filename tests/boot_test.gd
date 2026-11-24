extends SceneTree

## Headless boot & system verification test run by tools/validate.sh.
## Verifies all 7 autoloads, Jolt physics config, SaveSystem round-trip,
## AudioBus topology, Streaming grid, and Main scene instantiation.

const AudioBusScript := preload("res://audio/audio_bus.gd")
const SaveSystemScript := preload("res://core/save_system.gd")
const StreamingScript := preload("res://world/streaming.gd")


func _fail(msg: String) -> void:
	printerr("BOOT_TEST_FAIL: " + msg)
	quit(1)


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var required_autoloads: Array[String] = [
		"EventBus",
		"Settings",
		"GameState",
		"SaveSystem",
		"AudioBus",
		"Streaming",
		"Debug",
	]
	for autoload_name: String in required_autoloads:
		if root.get_node_or_null(autoload_name) == null:
			_fail("Missing autoload: " + autoload_name)
			return

	var phys_engine: String = str(ProjectSettings.get_setting("physics/3d/physics_engine", ""))
	if phys_engine != "Jolt Physics":
		_fail("Expected Jolt Physics, got: " + phys_engine)
		return

	var audio_bus := root.get_node("AudioBus") as AudioBusScript
	if audio_bus.get_bus_count() < 7:
		_fail("AudioBus topology incomplete: %d buses" % audio_bus.get_bus_count())
		return

	var save_sys := root.get_node("SaveSystem") as SaveSystemScript
	if not save_sys.save_slot(0, {"boot_check": true}):
		_fail("SaveSystem.save_slot(0) failed")
		return
	var loaded: Dictionary = save_sys.load_slot(0)
	if not bool(loaded.get("data", {}).get("boot_check", false)):
		_fail("SaveSystem.load_slot(0) round-trip mismatch")
		return

	var main_packed: Resource = load("res://world/main.tscn")
	if main_packed == null or not (main_packed is PackedScene):
		_fail("Failed to load res://world/main.tscn")
		return
	var main_inst: Node = (main_packed as PackedScene).instantiate()
	root.add_child(main_inst)

	await process_frame
	await physics_frame
	await process_frame

	if main_inst.get_node_or_null("PlayerPreview") == null:
		_fail("PlayerPreview node missing in main scene")
		return
	if main_inst.get_node_or_null("HudLayer/TouchControls") == null:
		_fail("TouchControls HUD missing in main scene")
		return
	var streaming := root.get_node("Streaming") as StreamingScript
	if streaming.get_loaded_count() < 1:
		_fail("Streaming failed to register active chunks")
		return

	print("BOOT_TEST_PASS: Autoloads=%d, Physics=%s, Chunks=%d, Buses=%d" % [
		required_autoloads.size(),
		phys_engine,
		streaming.get_loaded_count(),
		audio_bus.get_bus_count(),
	])
	quit(0)

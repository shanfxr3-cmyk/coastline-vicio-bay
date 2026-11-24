extends Node

## Atomic JSON save/load system for slots under user://saves/.

const GameStateScript := preload("res://core/game_state.gd")
const SAVE_DIR := "user://saves"
const SCHEMA_VERSION := 1


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))


func get_slot_path(slot_index: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, clampi(slot_index, 0, 9)]


func save_slot(slot_index: int, extra_data: Dictionary = {}) -> bool:
	var path: String = get_slot_path(slot_index)
	var tmp_path: String = path + ".tmp"
	var gs := get_node_or_null("/root/GameState") as GameStateScript
	var payload: Dictionary = {
		"schema": SCHEMA_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"district": gs.active_district if gs != null else "",
		"protagonist": gs.active_protagonist_id if gs != null else "",
		"playtime_sec": gs.session_elapsed_sec if gs != null else 0.0,
		"data": extra_data,
	}
	var f: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()

	var abs_tmp: String = ProjectSettings.globalize_path(tmp_path)
	var abs_dst: String = ProjectSettings.globalize_path(path)
	var err: Error = DirAccess.rename_absolute(abs_tmp, abs_dst)
	return err == OK


func load_slot(slot_index: int) -> Dictionary:
	var path: String = get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var dict: Dictionary = parsed
	if int(dict.get("schema", 0)) != SCHEMA_VERSION:
		return {}
	return dict

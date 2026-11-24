extends Node

## 128m world chunk streaming coordinator and telemetry tracker.

const EventBusScript := preload("res://core/event_bus.gd")
const CHUNK_SIZE_M := 128.0

var active_chunk: Vector2i = Vector2i.ZERO
var loaded_chunks: Dictionary = {}
var pending_queue: Array[Vector2i] = []
var stream_radius_chunks: int = 2


func _ready() -> void:
	update_focus_position(Vector3.ZERO)


func world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / CHUNK_SIZE_M),
		floori(world_pos.z / CHUNK_SIZE_M)
	)


func update_focus_position(world_pos: Vector3) -> void:
	var center: Vector2i = world_to_chunk(world_pos)
	if center == active_chunk and not loaded_chunks.is_empty():
		return
	active_chunk = center
	var eb := get_node_or_null("/root/EventBus") as EventBusScript
	var desired: Dictionary = {}
	for dx: int in range(-stream_radius_chunks, stream_radius_chunks + 1):
		for dz: int in range(-stream_radius_chunks, stream_radius_chunks + 1):
			var coord := Vector2i(center.x + dx, center.y + dz)
			desired[coord] = true
			if not loaded_chunks.has(coord):
				loaded_chunks[coord] = true
				if eb != null:
					eb.chunk_loaded.emit(coord)

	var to_unload: Array[Vector2i] = []
	for coord_var: Variant in loaded_chunks.keys():
		var coord: Vector2i = coord_var
		if not desired.has(coord):
			to_unload.append(coord)
	for coord: Vector2i in to_unload:
		loaded_chunks.erase(coord)
		if eb != null:
			eb.chunk_unloaded.emit(coord)


func get_loaded_count() -> int:
	return loaded_chunks.size()


func get_pending_count() -> int:
	return pending_queue.size()

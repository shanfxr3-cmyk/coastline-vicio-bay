extends Node

## Programmatic AudioServer bus topology and volume routing.

const BUS_NAMES: Array[String] = [
	"Master",
	"SFX",
	"Music",
	"Radio",
	"Voice",
	"Ambience",
	"UI",
]


func _ready() -> void:
	_ensure_buses()


func _ensure_buses() -> void:
	for bus_name: String in BUS_NAMES:
		if bus_name == "Master":
			continue
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx: int = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func set_bus_volume_linear(bus_name: String, linear_vol: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var clamped: float = clampf(linear_vol, 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(clamped, 0.0001)))
	AudioServer.set_bus_mute(idx, clamped <= 0.001)


func get_bus_count() -> int:
	return AudioServer.bus_count

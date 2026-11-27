extends Node

## Central runtime game state container.

enum Mode {
	BOOT,
	EXPLORE,
	PAUSED,
}

const GAME_TITLE := "Coastline: Vicio Bay"
const VERSION_TAG := "0.4.0-p2"

var mode: Mode = Mode.BOOT
var active_district: String = "Bayfront Promenade"
var active_protagonist_id: String = "kian"
var locomotion_state: String = "IDLE"
var session_elapsed_sec: float = 0.0
var time_of_day_phase: String = "Golden"
var time_of_day_hours: float = 16.75


func _ready() -> void:
	mode = Mode.EXPLORE


func _process(delta: float) -> void:
	if mode == Mode.EXPLORE:
		session_elapsed_sec += delta


func set_time_of_day(phase_name: String, hours: float) -> void:
	time_of_day_phase = phase_name
	time_of_day_hours = fposmod(hours, 24.0)


func set_time_of_day_phase(phase_name: String) -> void:
	time_of_day_phase = phase_name


func get_clock_text() -> String:
	var total_minutes: int = int(time_of_day_hours * 60.0) % 1440
	return "%02d:%02d" % [total_minutes / 60, total_minutes % 60]

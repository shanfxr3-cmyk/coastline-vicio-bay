extends Node

## Central runtime game state container.

enum Mode {
	BOOT,
	EXPLORE,
	PAUSED,
}

const GAME_TITLE := "Coastline: Vicio Bay"
const VERSION_TAG := "0.3.0-p2"

var mode: Mode = Mode.BOOT
var active_district: String = "Bayfront Promenade"
var active_protagonist_id: String = "kian"
var locomotion_state: String = "IDLE"
var session_elapsed_sec: float = 0.0
var time_of_day_phase: String = "Golden Hour"


func _ready() -> void:
	mode = Mode.EXPLORE


func _process(delta: float) -> void:
	if mode == Mode.EXPLORE:
		session_elapsed_sec += delta


func set_time_of_day_phase(phase_name: String) -> void:
	time_of_day_phase = phase_name

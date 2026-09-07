class_name ShiftClock
extends Node
## The shift's phase and timer. Only counts down while RUNNING; the owner
## drives the count-in transitions (see data-model.md for the state machine).

signal phase_changed(phase: Phase)
signal tick(time_left: float, progress: float)
signal ended

enum Phase { IDLE, COUNT_IN, RUNNING, RESUME_COUNT_IN, ENDED }

const TAG := "Clock"

var config: TuningConfig
var phase: Phase = Phase.IDLE
var time_left: float = 0.0
var duration: float = 0.0


func _ready() -> void:
	if config == null:
		config = Tuning.config


var progress: float:
	get:
		if duration <= 0.0:
			return 0.0
		return clampf(1.0 - time_left / duration, 0.0, 1.0)


func start() -> void:
	duration = config.shift_length_sec
	time_left = duration
	_set_phase(Phase.COUNT_IN)


## Count-in finished: hand control to the player.
func begin_running() -> void:
	if phase == Phase.COUNT_IN:
		_set_phase(Phase.RUNNING)


## Focus was lost mid-shift; a resume count-in is owed before continuing.
func pause_for_focus() -> void:
	if phase == Phase.RUNNING:
		_set_phase(Phase.RESUME_COUNT_IN)


func resume_after_count_in() -> void:
	if phase == Phase.RESUME_COUNT_IN:
		_set_phase(Phase.RUNNING)


func _process(delta: float) -> void:
	if phase != Phase.RUNNING:
		return
	time_left = maxf(time_left - delta, 0.0)
	tick.emit(time_left, progress)
	if time_left <= 0.0:
		_set_phase(Phase.ENDED)
		ended.emit()


func _set_phase(new_phase: Phase) -> void:
	if new_phase == phase:
		return
	phase = new_phase
	DebugLog.info(TAG, "phase -> %s (%.1fs left)" % [Phase.keys()[phase], time_left])
	phase_changed.emit(phase)

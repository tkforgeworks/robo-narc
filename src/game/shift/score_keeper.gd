class_name ScoreKeeper
extends Node
## Turns capture outcomes and missed violations into score, counts, and
## feedback text. Point values come from the live TuningConfig.

signal score_changed(score: int, delta: int, feedback: String)

const TAG := "Score"

## Injected by the owner; falls back to the Tuning autoload when left null.
var config: TuningConfig

var _result: ShiftResult = ShiftResult.new()


func _ready() -> void:
	if config == null:
		config = Tuning.config


func begin(duration_sec: float) -> void:
	_result = ShiftResult.new()
	_result.duration_sec = duration_sec
	_result.played_at = int(Time.get_unix_time_from_system())
	score_changed.emit(0, 0, "")


var score: int:
	get:
		return _result.score


## Fills `points` and `feedback` on the outcome, updates counts, emits.
func apply_capture(outcome: CaptureOutcome) -> void:
	match outcome.kind:
		CaptureOutcome.Kind.CORRECT:
			_result.correct += 1
			outcome.points = config.points_correct
			outcome.feedback = "%+d %s" % [outcome.points, outcome.verdict.label]
		CaptureOutcome.Kind.WRONG:
			_result.wrong += 1
			outcome.points = config.points_wrong
			outcome.feedback = "%+d INNOCENT DRIVER" % outcome.points
		CaptureOutcome.Kind.TOO_FAR:
			_result.empty += 1
			outcome.feedback = "TOO FAR - PLATE UNREADABLE"
		CaptureOutcome.Kind.EMPTY:
			_result.empty += 1
			outcome.feedback = "NO PLATE IN FRAME"
		CaptureOutcome.Kind.ALREADY_CAPTURED:
			outcome.feedback = "ALREADY CAPTURED"
	_add(outcome.points, outcome.feedback)


func apply_miss(verdict: Verdict) -> void:
	_result.missed += 1
	var points := config.points_missed
	_add(points, "%+d MISSED %s" % [points, verdict.label])


func finish() -> ShiftResult:
	DebugLog.info(TAG, "shift over: %s" % _result.summary())
	return _result


func _add(points: int, feedback: String) -> void:
	_result.score += points
	if points != 0:
		DebugLog.info(TAG, "%+d (%s) -> %d" % [points, feedback, _result.score])
	score_changed.emit(_result.score, points, feedback)

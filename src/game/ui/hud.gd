class_name Hud
extends CanvasLayer
## Score, time, and (debug builds) frame time. Feedback text lives in the
## FeedbackBanner child.

## Children sit under Frame, a 1280 x 720 Control that GameplayScreen moves to
## the playfield offset so anchors stay relative to the playfield.
@onready var frame: Control = $Frame
@onready var _score_label: Label = $Frame/ScoreLabel
@onready var _time_label: Label = $Frame/TimeLabel
@onready var _frame_label: Label = $Frame/FrameLabel
@onready var banner: FeedbackBanner = $Frame/FeedbackBanner

var _frame_accum: float = 0.0


func _ready() -> void:
	_frame_label.visible = OS.is_debug_build()
	set_score(0)
	set_time(0.0)


func set_score(score: int) -> void:
	_score_label.text = "SCORE %+d" % score if score < 0 else "SCORE %d" % score


func set_time(time_left: float) -> void:
	var t := maxf(time_left, 0.0)
	_time_label.text = "TIME %02d:%04.1f" % [int(t) / 60, fmod(t, 60.0)]


func _process(delta: float) -> void:
	if not _frame_label.visible:
		return
	_frame_accum += delta
	if _frame_accum >= 0.5:
		_frame_accum = 0.0
		var ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		_frame_label.text = "%d fps  %.1f ms" % [Engine.get_frames_per_second(), ms]

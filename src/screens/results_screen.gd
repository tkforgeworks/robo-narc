class_name ResultsScreen
extends Control
## End-of-shift results: score, breakdown, local rank, Play Again / Title, and
## an idle auto-return so an unattended booth resets itself. The countdown is
## shown for its last seconds and any input cancels it (spec FR-046).

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"
const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"
const COUNTDOWN_VISIBLE_SEC := 10.0

var config: TuningConfig
## Injectable for tests; defaults to the shared local score file.
var score_store: ScoreStore

@onready var _score_label: Label = %ScoreLabel
@onready var _breakdown: GridContainer = %Breakdown
@onready var _rank_label: Label = %RankLabel
@onready var _countdown_label: Label = %CountdownLabel
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _title_button: Button = %TitleButton
@onready var _idle_timeout: IdleTimeout = $IdleTimeout


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if score_store == null:
		score_store = ScoreStore.new()
	_idle_timeout.cancel_on_input = true
	_play_again_button.pressed.connect(func() -> void: _go(GAMEPLAY_SCENE_PATH))
	_title_button.pressed.connect(func() -> void: _go(TITLE_SCENE_PATH))
	_idle_timeout.timed_out.connect(func() -> void: _go(TITLE_SCENE_PATH))
	_countdown_label.visible = false
	_play_again_button.grab_focus()


func enter(payload: Variant) -> void:
	var result: ShiftResult = payload if payload is ShiftResult else ShiftResult.new()
	score_store.append(result)
	_score_label.text = "%+d" % result.score if result.score < 0 else str(result.score)
	_fill_breakdown(result)
	var rank := RankCalculator.rank(result.score, score_store.scores())
	_rank_label.text = "Local rank: %d of %d" % [rank, score_store.records.size()]
	_idle_timeout.start(config.results_idle_timeout_sec)


func _fill_breakdown(result: ShiftResult) -> void:
	for child in _breakdown.get_children():
		child.queue_free()
	var rows := [["Correct", result.correct], ["Wrong", result.wrong],
			["Missed", result.missed], ["Empty", result.empty]]
	for row: Array in rows:
		var name := Label.new()
		name.text = str(row[0])
		_breakdown.add_child(name)
		var value := Label.new()
		value.text = str(row[1])
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_breakdown.add_child(value)


func _process(_delta: float) -> void:
	var show := _idle_timeout.running and _idle_timeout.time_left <= COUNTDOWN_VISIBLE_SEC
	_countdown_label.visible = show
	if show:
		_countdown_label.text = "Back to title in %d" % ceili(_idle_timeout.time_left)


func _go(path: String) -> void:
	_idle_timeout.stop()
	navigation_requested.emit(load(path), null)

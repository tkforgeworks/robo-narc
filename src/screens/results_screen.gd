class_name ResultsScreen
extends Control
## End-of-shift results: score, breakdown, local rank, Play Again / Title, and
## an idle auto-return so an unattended booth resets itself.

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"
const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"

var config: TuningConfig
## Injectable for tests; defaults to the shared local score file.
var score_store: ScoreStore

@onready var _score_label: Label = %ScoreLabel
@onready var _breakdown_label: Label = %BreakdownLabel
@onready var _rank_label: Label = %RankLabel
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _title_button: Button = %TitleButton
@onready var _idle_timeout: IdleTimeout = $IdleTimeout


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if score_store == null:
		score_store = ScoreStore.new()
	_play_again_button.pressed.connect(func() -> void: _go(GAMEPLAY_SCENE_PATH))
	_title_button.pressed.connect(func() -> void: _go(TITLE_SCENE_PATH))
	_idle_timeout.timed_out.connect(func() -> void: _go(TITLE_SCENE_PATH))
	_play_again_button.grab_focus()


func enter(payload: Variant) -> void:
	var result: ShiftResult = payload if payload is ShiftResult else ShiftResult.new()
	score_store.append(result)
	_score_label.text = "%+d" % result.score if result.score < 0 else str(result.score)
	_breakdown_label.text = "Correct %d   Wrong %d   Missed %d   Empty %d" % [
		result.correct, result.wrong, result.missed, result.empty
	]
	var rank := RankCalculator.rank(result.score, score_store.scores())
	_rank_label.text = "Local rank: %d of %d" % [rank, score_store.records.size()]
	_idle_timeout.start(config.results_idle_timeout_sec)


func _go(path: String) -> void:
	_idle_timeout.stop()
	navigation_requested.emit(load(path), null)

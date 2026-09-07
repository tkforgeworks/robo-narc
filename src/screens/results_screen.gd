class_name ResultsScreen
extends Control
## End-of-shift flow: name entry first, then score, breakdown, rank, the shared
## board with the player's row highlighted, Play Again / Title, and an idle
## auto-return. Results show before any network answer; a failed submit keeps
## the local record and says so (spec FR-040 to FR-043, FR-046).

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"
const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"
const COUNTDOWN_VISIBLE_SEC := 10.0

var config: TuningConfig
## Injectable for tests; defaults to the shared local score file.
var score_store: ScoreStore
## Injectable for tests; null lets the client load the active config.
var leaderboard_config: LeaderboardConfig

var _result: ShiftResult
var _record: ScoreRecord
var _settings: SettingsStore

@onready var _score_label: Label = %ScoreLabel
@onready var _name_entry: NameEntry = %NameEntry
@onready var _details: VBoxContainer = %Details
@onready var _breakdown: ScoreBreakdown = %Breakdown
@onready var _rank_label: Label = %RankLabel
@onready var _note_label: Label = %NoteLabel
@onready var _countdown_label: Label = %CountdownLabel
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _title_button: Button = %TitleButton
@onready var _board: LeaderboardPanel = %Board
@onready var _idle_timeout: IdleTimeout = $IdleTimeout
@onready var _client: LeaderboardClient = $LeaderboardClient


func _enter_tree() -> void:
	if leaderboard_config != null:
		$LeaderboardClient.config = leaderboard_config


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if score_store == null:
		score_store = ScoreStore.new()
	_play_again_button.pressed.connect(func() -> void: _go(GAMEPLAY_SCENE_PATH))
	_title_button.pressed.connect(func() -> void: _go(TITLE_SCENE_PATH))
	_idle_timeout.timed_out.connect(func() -> void: _go(TITLE_SCENE_PATH))
	_name_entry.name_chosen.connect(_on_name_chosen)
	_client.submitted.connect(_on_submitted)
	_client.top_scores_received.connect(_on_top_scores)
	_client.failed.connect(_on_client_failed)
	_countdown_label.visible = false
	_details.visible = false


func enter(payload: Variant) -> void:
	_result = payload if payload is ShiftResult else ShiftResult.new()
	_score_label.text = "%+d" % _result.score if _result.score < 0 else str(_result.score)
	_board.show_local(score_store.top(config.top_count))
	# While typing, input restarts the countdown; an abandoned prompt still returns.
	_idle_timeout.cancel_on_input = false
	_idle_timeout.start(config.results_idle_timeout_sec)


func bind_settings(settings: SettingsStore) -> void:
	_settings = settings
	_name_entry.prefill(settings.last_name)


func bind_input_source(input_source: InputSource) -> void:
	_name_entry.set_input_source(input_source.source)
	input_source.source_changed.connect(_name_entry.set_input_source)


func _on_name_chosen(name: String) -> void:
	_result.player_name = name
	if _settings != null and name != config.default_player_name:
		_settings.last_name = name
		_settings.save()
	_record = score_store.append(_result)
	_breakdown.show_result(_result)
	_show_local_rank()
	_name_entry.visible = false
	_details.visible = true
	_play_again_button.grab_focus()
	_idle_timeout.cancel_on_input = true
	_idle_timeout.start(config.results_idle_timeout_sec)
	_board.highlight(name, _result.score)
	_board.show_local(score_store.top(config.top_count))
	_note_label.text = "submitting to the board..." if _client.is_enabled() else ""
	_client.submit(_result)


func _on_submitted(rank: int) -> void:
	_record.submitted = true
	_record.remote_rank = rank
	score_store.save()
	_rank_label.text = "Global rank: #%d" % rank
	_note_label.text = ""
	_client.fetch_top(config.top_count)


func _on_top_scores(entries: Array[LeaderboardEntry]) -> void:
	_board.show_entries(entries)


func _on_client_failed(operation: String, reason: String) -> void:
	var note := "" if reason == LeaderboardClient.REASON_DISABLED else LeaderboardPanel.UNAVAILABLE_NOTE
	if operation == LeaderboardClient.OP_SUBMIT:
		_note_label.text = note
		if reason != LeaderboardClient.REASON_DISABLED:
			_client.fetch_top(config.top_count)
	else:
		_board.show_local(score_store.top(config.top_count), note)


func _show_local_rank() -> void:
	var rank := RankCalculator.rank(_result.score, score_store.scores())
	_rank_label.text = "Local rank: %d of %d" % [rank, score_store.records.size()]


func _process(_delta: float) -> void:
	var show := _idle_timeout.running and _idle_timeout.time_left <= COUNTDOWN_VISIBLE_SEC
	_countdown_label.visible = show
	if show:
		_countdown_label.text = "Back to title in %d" % ceili(_idle_timeout.time_left)


## Leaving mid-submit hands the client to the root so the submit completes.
func _go(path: String) -> void:
	_idle_timeout.stop()
	if _client.submit_pending():
		_client.reparent(get_tree().root)
		_client.release_when_idle()
	navigation_requested.emit(load(path), null)

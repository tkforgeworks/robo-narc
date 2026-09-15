class_name ResultsScreen
extends Control
## End-of-shift flow: identity entry first, then score, breakdown, the board
## with the player's row highlighted, Play Again / Title, and an idle
## auto-return. Results show before any network answer; the shift goes to the
## Leaderboard service, which posts it now or whenever the board is reachable
## again (spec FR-040 to FR-043, FR-046).

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"
const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"
const COUNTDOWN_VISIBLE_SEC := 10.0
const POSTING_TEXT := "Posting to the board..."
const WAITING_TEXT := "Saved. It will post when the board is back online."
const NOT_POSTED_TEXT := "Not posted: no board configured"
const EDITOR_TEXT := "Not posted: editor run"

var config: TuningConfig
## Injectable for tests; null uses the `Leaderboard` autoload.
var leaderboard: LeaderboardService

var _result: ShiftResult
var _submitted: bool = false

@onready var _score_label: Label = %ScoreLabel
@onready var _entry: IdentityEntry = %IdentityEntry
@onready var _details: VBoxContainer = %Details
@onready var _breakdown: ScoreBreakdown = %Breakdown
@onready var _rank_label: Label = %RankLabel
@onready var _note_label: Label = %NoteLabel
@onready var _countdown_label: Label = %CountdownLabel
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _title_button: Button = %TitleButton
@onready var _board: LeaderboardPanel = %Board
@onready var _idle_timeout: IdleTimeout = $IdleTimeout


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if leaderboard == null:
		leaderboard = get_tree().root.get_node_or_null(^"Leaderboard")
	if leaderboard == null:
		leaderboard = LeaderboardService.new()
		add_child(leaderboard)
	_play_again_button.pressed.connect(func() -> void: _go(GAMEPLAY_SCENE_PATH))
	_title_button.pressed.connect(func() -> void: _go(TITLE_SCENE_PATH))
	_idle_timeout.timed_out.connect(func() -> void: _go(TITLE_SCENE_PATH))
	_entry.identity_chosen.connect(_on_identity_chosen)
	leaderboard.board_updated.connect(_on_board_updated)
	leaderboard.receipt_received.connect(_on_receipt)
	leaderboard.status_changed.connect(_on_status_changed)
	_countdown_label.visible = false
	_details.visible = false


func enter(payload: Variant) -> void:
	_result = payload if payload is ShiftResult else ShiftResult.new()
	_score_label.text = "%+d" % _result.score if _result.score < 0 else str(_result.score)
	_on_board_updated(leaderboard.cached_entries())
	_on_status_changed(leaderboard.status)
	leaderboard.refresh_board()
	# While typing, input restarts the countdown; an abandoned prompt still returns.
	_idle_timeout.cancel_on_input = false
	_idle_timeout.start(config.results_idle_timeout_sec)


func _on_identity_chosen(identity: PlayerIdentity) -> void:
	_result.identity = identity
	_breakdown.show_result(_result)
	_entry.visible = false
	_details.visible = true
	_play_again_button.grab_focus()
	_idle_timeout.cancel_on_input = true
	_idle_timeout.start(config.results_idle_timeout_sec)
	_note_label.text = ""
	_submitted = leaderboard.submit(_result)
	if _submitted:
		_rank_label.text = POSTING_TEXT
		if not identity.is_anonymous():
			_board.highlight(identity.display_name(), _result.score)
	else:
		_rank_label.text = EDITOR_TEXT if leaderboard.is_enabled() else NOT_POSTED_TEXT
	_on_status_changed(leaderboard.status)


func _on_receipt(receipt: SubmitReceipt) -> void:
	if not _submitted or receipt.submission_id != _result.submission_id:
		return
	var text := "Global rank: #%d" % receipt.rank
	if receipt.best_score != _result.score:
		text += " (your best: %d)" % receipt.best_score
	_rank_label.text = text
	_note_label.text = ""
	_board.highlight(receipt.name, receipt.best_score)
	leaderboard.refresh_board()


func _on_board_updated(entries: Array[LeaderboardEntry]) -> void:
	_board.show_entries(entries, _board_note())


## The note under the heading follows the status, so rows are redrawn too.
func _on_status_changed(status: int) -> void:
	_board.show_sync(status, leaderboard.pending_count())
	_board.show_entries(leaderboard.cached_entries(), _board_note())
	if not _submitted or not leaderboard.is_pending(_result.submission_id):
		return
	if status == LeaderboardService.Status.OFFLINE:
		_rank_label.text = WAITING_TEXT
		_note_label.text = LeaderboardPanel.UNAVAILABLE_NOTE
	elif status == LeaderboardService.Status.SYNCING:
		_rank_label.text = POSTING_TEXT
		_note_label.text = ""


func _board_note() -> String:
	if leaderboard.status == LeaderboardService.Status.OFFLINE and leaderboard.cache.has_entries():
		return LeaderboardPanel.CACHED_NOTE
	return ""


func _process(_delta: float) -> void:
	var show := _idle_timeout.running and _idle_timeout.time_left <= COUNTDOWN_VISIBLE_SEC
	_countdown_label.visible = show
	if show:
		_countdown_label.text = "Back to title in %d" % ceili(_idle_timeout.time_left)


func _go(path: String) -> void:
	_idle_timeout.stop()
	navigation_requested.emit(load(path), null)

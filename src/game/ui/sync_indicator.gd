class_name SyncIndicator
extends HBoxContainer
## A coloured dot and a word for the leaderboard's sync status: green when the
## board and this machine agree, yellow while a request is out, red while
## offline (with how many shifts are waiting), grey when no board is configured.

const GREEN := Color(0.35, 0.85, 0.45)
const YELLOW := Color(1.0, 0.85, 0.3)
const RED := Color(0.95, 0.35, 0.35)
const GREY := Color(0.5, 0.5, 0.55)

@onready var _dot: ColorRect = %Dot
@onready var _label: Label = %StatusLabel


func show_status(status: int, pending: int = 0) -> void:
	match status:
		LeaderboardService.Status.SYNCED:
			_dot.color = GREEN
			_label.text = "board in sync"
		LeaderboardService.Status.SYNCING:
			_dot.color = YELLOW
			_label.text = "syncing..."
		LeaderboardService.Status.OFFLINE:
			_dot.color = RED
			_label.text = "offline" if pending == 0 else "offline, %d waiting to post" % pending
		_:
			_dot.color = GREY
			_label.text = "no board configured"


func status_text() -> String:
	return _label.text


func dot_color() -> Color:
	return _dot.color

class_name LeaderboardEntry
extends RefCounted
## One row of the shared board as displayed. Names that fail the name rules
## show as a placeholder and long ones are truncated (contracts/leaderboard-api.md).

const PLACEHOLDER_NAME := "???"
const MAX_NAME := 12

static var _letters := RegEx.create_from_string("^[A-Za-z]+$")

var rank: int = 0
var name: String = PLACEHOLDER_NAME
var score: int = 0


func _init(p_rank: int = 0, p_name: String = PLACEHOLDER_NAME, p_score: int = 0) -> void:
	rank = p_rank
	name = p_name
	score = p_score


static func from_dict(data: Dictionary) -> LeaderboardEntry:
	return LeaderboardEntry.new(int(data.get("rank", 0)),
			display_name(str(data.get("name", ""))), int(data.get("score", 0)))


static func display_name(raw: String) -> String:
	var text := raw.strip_edges()
	if text.is_empty() or _letters.search(text) == null:
		return PLACEHOLDER_NAME
	return text.left(MAX_NAME)

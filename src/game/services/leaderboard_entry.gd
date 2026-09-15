class_name LeaderboardEntry
extends RefCounted
## One row of the shared board as displayed. The server builds names ("Ava K."
## or "anonymous 07"); anything else shows as a placeholder and long ones are
## truncated (contracts/leaderboard-api.md). `f1` is the shift's F1 score in
## 0..1, or -1 when the board did not send one.

const PLACEHOLDER_NAME := "???"
const MAX_NAME := 16
const NO_F1 := -1.0

static var _shape := RegEx.create_from_string("^[A-Za-z0-9 .]+$")

var rank: int = 0
var name: String = PLACEHOLDER_NAME
var score: int = 0
var f1: float = NO_F1


func _init(p_rank: int = 0, p_name: String = PLACEHOLDER_NAME, p_score: int = 0,
		p_f1: float = NO_F1) -> void:
	rank = p_rank
	name = p_name
	score = p_score
	f1 = p_f1


static func from_dict(data: Dictionary) -> LeaderboardEntry:
	var raw_f1: Variant = data.get("f1")
	var f1_value := NO_F1 if raw_f1 == null else clampf(float(raw_f1), 0.0, 1.0)
	return LeaderboardEntry.new(int(data.get("rank", 0)),
			display_name(str(data.get("name", ""))), int(data.get("score", 0)), f1_value)


func to_dict() -> Dictionary:
	return {"rank": rank, "name": name, "score": score, "f1": f1}


static func display_name(raw: String) -> String:
	var text := raw.strip_edges()
	if text.is_empty() or _shape.search(text) == null:
		return PLACEHOLDER_NAME
	return text.left(MAX_NAME)

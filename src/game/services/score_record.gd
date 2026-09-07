class_name ScoreRecord
extends RefCounted
## A completed shift as kept in the local score history, with what the shared
## leaderboard said about it (if anything).

var result: ShiftResult
var submitted: bool = false
## -1 until the leaderboard reports a rank.
var remote_rank: int = -1


func _init(p_result: ShiftResult = ShiftResult.new()) -> void:
	result = p_result


func to_dict() -> Dictionary:
	var data := result.to_dict()
	data["submitted"] = submitted
	data["remote_rank"] = remote_rank
	return data


static func from_dict(data: Dictionary) -> ScoreRecord:
	var record := ScoreRecord.new(ShiftResult.from_dict(data))
	record.submitted = bool(data.get("submitted", false))
	record.remote_rank = int(data.get("remote_rank", -1))
	return record

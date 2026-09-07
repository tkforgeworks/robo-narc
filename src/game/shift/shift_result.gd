class_name ShiftResult
extends RefCounted
## The outcome of one shift. Built up by ScoreKeeper, then passed as a plain
## value from the gameplay screen to the results screen.

var score: int = 0
var correct: int = 0
var wrong: int = 0
var missed: int = 0
var empty: int = 0
var duration_sec: float = 0.0
var played_at: int = 0
var player_name: String = ""


func to_dict() -> Dictionary:
	return {
		"score": score,
		"correct": correct,
		"wrong": wrong,
		"missed": missed,
		"empty": empty,
		"duration_sec": duration_sec,
		"played_at": played_at,
		"player_name": player_name,
	}


static func from_dict(data: Dictionary) -> ShiftResult:
	var result := ShiftResult.new()
	result.score = int(data.get("score", 0))
	result.correct = int(data.get("correct", 0))
	result.wrong = int(data.get("wrong", 0))
	result.missed = int(data.get("missed", 0))
	result.empty = int(data.get("empty", 0))
	result.duration_sec = float(data.get("duration_sec", 0.0))
	result.played_at = int(data.get("played_at", 0))
	result.player_name = str(data.get("player_name", ""))
	return result


func summary() -> String:
	return "score=%d correct=%d wrong=%d missed=%d empty=%d" % [
		score, correct, wrong, missed, empty
	]

class_name SubmitReceipt
extends RefCounted
## What the board says about one submitted shift: the player's rank, the name
## as the board shows it (the server names anonymous shifts), and the score the
## rank is for (a returning player's best, which may beat this shift).

var submission_id: String = ""
var rank: int = 0
var name: String = ""
var best_score: int = 0


static func from_dict(data: Dictionary) -> SubmitReceipt:
	var receipt := SubmitReceipt.new()
	receipt.submission_id = str(data.get("submission_id", ""))
	receipt.rank = int(data.get("rank", 0))
	receipt.name = LeaderboardEntry.display_name(str(data.get("name", "")))
	receipt.best_score = int(data.get("best_score", 0))
	return receipt

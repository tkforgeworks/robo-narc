class_name RankCalculator
extends RefCounted
## 1-based rank of a score among others: one plus the number of strictly
## higher scores, so ties share the better rank. Used as the local fallback
## when the shared leaderboard is unavailable.


static func rank(score: int, others: PackedInt32Array) -> int:
	var higher := 0
	for other in others:
		if other > score:
			higher += 1
	return higher + 1

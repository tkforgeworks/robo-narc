extends GutTest


func test_rank_counts_strictly_higher_scores() -> void:
	var others := PackedInt32Array([500, 300, 100, -20])
	assert_eq(RankCalculator.rank(600, others), 1)
	assert_eq(RankCalculator.rank(300, others), 2, "ties share the better rank")
	assert_eq(RankCalculator.rank(150, others), 3)
	assert_eq(RankCalculator.rank(-50, others), 5)


func test_empty_board_is_first() -> void:
	assert_eq(RankCalculator.rank(0, PackedInt32Array()), 1)

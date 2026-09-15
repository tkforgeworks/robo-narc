extends GutTest


func test_precision_recall_and_f1_match_the_definitions() -> void:
	assert_almost_eq(F1Score.precision(8, 2), 0.8, 0.0001)
	assert_almost_eq(F1Score.recall(8, 4), 0.6667, 0.0001)
	assert_almost_eq(F1Score.f1(8, 2, 4), 2.0 * (0.8 * 0.6667) / (0.8 + 0.6667), 0.001)
	assert_almost_eq(F1Score.f1(10, 0, 0), 1.0, 0.0001, "perfect shift")


func test_undefined_ratios_score_zero() -> void:
	assert_eq(F1Score.precision(0, 0), 0.0, "no captures at all")
	assert_eq(F1Score.recall(0, 0), 0.0, "nothing to catch")
	assert_eq(F1Score.f1(0, 5, 0), 0.0, "only wrong captures")
	assert_eq(F1Score.f1(0, 0, 5), 0.0, "only misses")


func test_shift_result_maps_counts_to_the_confusion_matrix() -> void:
	var result := ShiftResult.new()
	result.correct = 20
	result.wrong = 3
	result.empty = 2
	result.missed = 4
	result.left_in_range = 1
	assert_eq(result.true_positives(), 20)
	assert_eq(result.false_positives(), 5, "wrong and empty captures")
	assert_eq(result.false_negatives(), 5, "passed uncaptured plus catchable at the buzzer")
	assert_almost_eq(result.precision(), 0.8, 0.0001)
	assert_almost_eq(result.recall(), 0.8, 0.0001)
	assert_almost_eq(result.f1(), 0.8, 0.0001)
	var copy := ShiftResult.from_dict(result.to_dict())
	assert_eq(copy.left_in_range, 1, "round-trips through the pending queue")
	assert_string_contains(result.summary(), "f1=0.80")


func test_format() -> void:
	assert_eq(F1Score.format(0.8666), "0.87")
	assert_eq(F1Score.format(1.0), "1.00")
	assert_eq(F1Score.format(-1.0), "-", "unknown")

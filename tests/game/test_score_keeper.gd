extends GutTest

var _keeper: ScoreKeeper
var _config: TuningConfig


func before_each() -> void:
	_config = TuningConfig.new()
	_keeper = ScoreKeeper.new()
	_keeper.config = _config
	add_child_autofree(_keeper)
	watch_signals(_keeper)
	_keeper.begin(90.0)


func test_correct_capture_scores_points_correct() -> void:
	var outcome := CaptureOutcome.new(CaptureOutcome.Kind.CORRECT, null,
			Verdict.of(Verdict.Kind.BUS_LANE))
	_keeper.apply_capture(outcome)
	assert_eq(outcome.points, 100)
	assert_eq(outcome.feedback, "+100 BUS LANE")
	assert_eq(_keeper.score, 100)
	assert_signal_emitted_with_parameters(_keeper, "score_changed", [100, 100, "+100 BUS LANE"])


func test_wrong_and_missed_use_reduced_penalties() -> void:
	_keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.WRONG, null, Verdict.innocent()))
	assert_eq(_keeper.score, -25)
	_keeper.apply_miss(Verdict.of(Verdict.Kind.BUS_STOP))
	assert_eq(_keeper.score, -35, "score may go negative")
	assert_signal_emitted_with_parameters(_keeper, "score_changed", [-35, -10, "-10 MISSED BUS STOP"])


func test_empty_and_too_far_do_not_score_but_count() -> void:
	_keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.TOO_FAR))
	_keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.EMPTY))
	assert_eq(_keeper.score, 0)
	var result := _keeper.finish()
	assert_eq(result.empty, 2)


func test_already_captured_is_not_counted() -> void:
	_keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.ALREADY_CAPTURED))
	var result := _keeper.finish()
	assert_eq(result.empty, 0)
	assert_eq(result.score, 0)


func test_finish_reports_counts_and_duration() -> void:
	_keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.CORRECT, null,
			Verdict.of(Verdict.Kind.BIKE_LANE)))
	_keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.WRONG, null, Verdict.innocent()))
	_keeper.apply_miss(Verdict.of(Verdict.Kind.DOUBLE_PARKING))
	var result := _keeper.finish()
	assert_eq(result.correct, 1)
	assert_eq(result.wrong, 1)
	assert_eq(result.missed, 1)
	assert_eq(result.score, 65)
	assert_eq(result.duration_sec, 90.0)
	assert_gt(result.played_at, 0)


func test_points_follow_live_config() -> void:
	_config.points_correct = 500
	_keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.CORRECT, null,
			Verdict.of(Verdict.Kind.BUS_LANE)))
	assert_eq(_keeper.score, 500)


func test_shift_result_round_trips_through_dict() -> void:
	var result := ShiftResult.new()
	result.score = -5
	result.player_name = "Ava"
	var copy := ShiftResult.from_dict(result.to_dict())
	assert_eq(copy.score, -5)
	assert_eq(copy.player_name, "Ava")

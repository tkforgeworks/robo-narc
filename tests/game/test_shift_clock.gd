extends GutTest

var _config: TuningConfig
var _clock: ShiftClock


func before_each() -> void:
	_config = TuningConfig.new()
	_config.shift_length_sec = 10.0
	_clock = ShiftClock.new()
	_clock.config = _config
	add_child_autofree(_clock)
	watch_signals(_clock)


func test_start_enters_count_in_without_ticking() -> void:
	_clock.start()
	assert_eq(_clock.phase, ShiftClock.Phase.COUNT_IN)
	_clock._process(1.0)
	assert_eq(_clock.time_left, 10.0)
	assert_signal_not_emitted(_clock, "tick")


func test_running_counts_down_and_ends() -> void:
	_clock.start()
	_clock.begin_running()
	assert_eq(_clock.phase, ShiftClock.Phase.RUNNING)
	_clock._process(4.0)
	assert_almost_eq(_clock.time_left, 6.0, 0.001)
	assert_almost_eq(_clock.progress, 0.4, 0.001)
	assert_signal_emitted(_clock, "tick")
	_clock._process(7.0)
	assert_eq(_clock.phase, ShiftClock.Phase.ENDED)
	assert_eq(_clock.time_left, 0.0)
	assert_signal_emitted(_clock, "ended")


func test_focus_pause_owes_a_resume_count_in() -> void:
	_clock.start()
	_clock.begin_running()
	_clock._process(2.0)
	_clock.pause_for_focus()
	assert_eq(_clock.phase, ShiftClock.Phase.RESUME_COUNT_IN)
	_clock._process(5.0)
	assert_almost_eq(_clock.time_left, 8.0, 0.001, "no ticking while waiting")
	_clock.resume_after_count_in()
	assert_eq(_clock.phase, ShiftClock.Phase.RUNNING)


func test_focus_pause_during_count_in_is_ignored() -> void:
	_clock.start()
	_clock.pause_for_focus()
	assert_eq(_clock.phase, ShiftClock.Phase.COUNT_IN)


func test_set_duration_keeps_elapsed_time() -> void:
	_clock.start()
	_clock.begin_running()
	_clock._process(4.0)
	_clock.set_duration(20.0)
	assert_almost_eq(_clock.time_left, 16.0, 0.001)
	assert_almost_eq(_clock.progress, 0.2, 0.001)
	_clock.set_duration(3.0)
	assert_eq(_clock.time_left, 0.0, "shortening below elapsed ends at the next tick")


func test_transitions_only_from_expected_phases() -> void:
	_clock.begin_running()
	assert_eq(_clock.phase, ShiftClock.Phase.IDLE)
	_clock.resume_after_count_in()
	assert_eq(_clock.phase, ShiftClock.Phase.IDLE)
	assert_signal_not_emitted(_clock, "phase_changed")

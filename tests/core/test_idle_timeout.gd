extends GutTest

var _timeout: IdleTimeout


func before_each() -> void:
	_timeout = IdleTimeout.new()
	_timeout.autostart = false
	add_child_autofree(_timeout)
	watch_signals(_timeout)


func test_times_out_after_duration() -> void:
	_timeout.start(0.05)
	await wait_seconds(0.2)
	assert_signal_emitted(_timeout, "timed_out")
	assert_false(_timeout.running)


func test_input_restarts_countdown() -> void:
	_timeout.start(1.0)
	_timeout._process(0.6)
	assert_almost_eq(_timeout.time_left, 0.4, 0.001)
	_timeout._input(InputEventKey.new())
	assert_almost_eq(_timeout.time_left, 1.0, 0.001)


func test_cancel_on_input_stops_instead_of_restarting() -> void:
	_timeout.cancel_on_input = true
	_timeout.start(1.0)
	_timeout._input(InputEventKey.new())
	assert_false(_timeout.running)


func test_stop_prevents_timeout() -> void:
	_timeout.start(0.05)
	_timeout.stop()
	await wait_seconds(0.15)
	assert_signal_not_emitted(_timeout, "timed_out")


func test_runs_while_tree_is_paused() -> void:
	_timeout.start(0.05)
	get_tree().paused = true
	# GUT's wait_seconds stalls while paused; a process-always timer does not.
	await get_tree().create_timer(0.2, true).timeout
	get_tree().paused = false
	assert_signal_emitted(_timeout, "timed_out")

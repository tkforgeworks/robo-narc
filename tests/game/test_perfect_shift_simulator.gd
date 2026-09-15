extends GutTest
## The simulator on a very short, dense shift, and the debug screen around it.
## Time scale is high, so waits use real time via ticks, not tree timers.

const SIM_SCENE: PackedScene = preload("res://scenes/screens/sim_screen.tscn")
const REAL_TIMEOUT_MSEC := 20000


func _config() -> TuningConfig:
	var config := TuningConfig.new()
	config.shift_length_sec = 10.0
	config.spawn_interval_start = 0.3
	config.spawn_interval_end = 0.3
	config.points_correct = 100
	return config


func _wait_until(done: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + REAL_TIMEOUT_MSEC
	while not done.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return true


func test_runs_shifts_and_scores_every_missed_violator() -> void:
	var sim := PerfectShiftSimulator.new()
	sim.config = _config()
	sim.runs = 2
	sim.time_scale = 50.0
	sim.first_seed = 7
	add_child_autofree(sim)
	watch_signals(sim)
	var master := AudioServer.get_bus_index("Master")
	sim.start()
	assert_true(sim.running)
	assert_eq(Engine.time_scale, 50.0)
	assert_true(AudioServer.is_bus_mute(master), "muted while running")
	assert_true(await _wait_until(func() -> bool: return not sim.running), "finished in time")
	assert_signal_emit_count(sim, "run_finished", 2)
	assert_signal_emitted(sim, "finished")
	assert_eq(sim.results.size(), 2)
	assert_eq(sim.results[0]["seed"], 7)
	assert_eq(sim.results[1]["seed"], 8)
	for run in sim.results:
		assert_eq(run["score"], run["missed"] * 100)
		assert_gt(run["spawned"], 0)
		assert_eq(run["thirds"][0] + run["thirds"][1] + run["thirds"][2], run["missed"])
	assert_eq(Engine.time_scale, 1.0, "restored")
	assert_false(AudioServer.is_bus_mute(master), "unmuted")
	assert_eq(sim.get_child_count(), 0, "no gameplay scene left behind")
	var stats := sim.stats()
	assert_eq(stats["runs"], 2)
	assert_between(stats["median"], stats["min"], stats["max"])
	assert_string_contains(sim.summary_lines()[0], "Perfect score")
	assert_string_contains(sim.summary_text(), "over 2 run(s)")
	assert_string_contains(PerfectShiftSimulator.run_line(1, sim.results[0]), "seed 7")


func test_cancel_restores_the_engine_and_frees_the_shift() -> void:
	var sim := PerfectShiftSimulator.new()
	sim.config = _config()
	sim.runs = 5
	sim.time_scale = 10.0
	add_child_autofree(sim)
	sim.start()
	await get_tree().process_frame
	assert_eq(sim.get_child_count(), 1, "a shift is running")
	sim.cancel()
	assert_false(sim.running)
	assert_eq(Engine.time_scale, 1.0)
	await get_tree().process_frame
	assert_eq(sim.get_child_count(), 0)


func test_screen_runs_and_shows_summary() -> void:
	var screen: SimScreen = SIM_SCENE.instantiate()
	add_child_autofree(screen)
	watch_signals(screen)
	# The screen re-reads the live Tuning config on Run (the 90 s default here).
	(screen.get_node("%RunsSpin") as SpinBox).value = 1
	(screen.get_node("%TimeScaleSpin") as SpinBox).value = 50
	screen.get_node("%RunButton").pressed.emit()
	assert_true(screen.is_running())
	assert_eq((screen.get_node("%RunButton") as Button).text, SimScreen.CANCEL_TEXT)
	assert_true(await _wait_until(func() -> bool: return not screen.is_running()), "finished in time")
	assert_eq((screen.get_node("%RunButton") as Button).text, SimScreen.RUN_TEXT)
	assert_string_contains((screen.get_node("%SummaryLabel") as Label).text, "over 1 run(s)")
	assert_string_contains((screen.get_node("%RunsLog") as Label).text, "run  1")
	screen.get_node("%BackButton").pressed.emit()
	assert_signal_emitted(screen, "navigation_requested")

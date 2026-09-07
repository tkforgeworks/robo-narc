extends GutTest


func test_endpoints_and_midpoint() -> void:
	var config := TuningConfig.new()
	var ramp := DifficultyRamp.new(config)
	assert_almost_eq(ramp.cruise_speed(0.0), 14.0, 0.001)
	assert_almost_eq(ramp.cruise_speed(1.0), 26.0, 0.001)
	assert_almost_eq(ramp.cruise_speed(0.5), 20.0, 0.001)
	assert_almost_eq(ramp.spawn_interval(0.0), 1.5, 0.001)
	assert_almost_eq(ramp.spawn_interval(1.0), 0.9, 0.001)


func test_progress_is_clamped() -> void:
	var ramp := DifficultyRamp.new(TuningConfig.new())
	assert_almost_eq(ramp.cruise_speed(-1.0), 14.0, 0.001)
	assert_almost_eq(ramp.cruise_speed(2.0), 26.0, 0.001)


func test_reads_live_config() -> void:
	var config := TuningConfig.new()
	var ramp := DifficultyRamp.new(config)
	config.cruise_speed_end = 60.0
	assert_almost_eq(ramp.cruise_speed(1.0), 60.0, 0.001)

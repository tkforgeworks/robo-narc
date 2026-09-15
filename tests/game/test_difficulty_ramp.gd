extends GutTest


func _config() -> TuningConfig:
	var config := TuningConfig.new()
	config.cruise_speed_start = 11.0
	config.cruise_speed_end = 32.0
	config.spawn_interval_start = 1.5
	config.spawn_interval_end = 0.9
	return config


func test_endpoints_and_midpoint() -> void:
	var ramp := DifficultyRamp.new(_config())
	assert_almost_eq(ramp.cruise_speed(0.0), 11.0, 0.001)
	assert_almost_eq(ramp.cruise_speed(1.0), 32.0, 0.001)
	assert_almost_eq(ramp.cruise_speed(0.5), 21.5, 0.001)
	assert_almost_eq(ramp.spawn_interval(0.0), 1.5, 0.001)
	assert_almost_eq(ramp.spawn_interval(1.0), 0.9, 0.001)


func test_progress_is_clamped() -> void:
	var ramp := DifficultyRamp.new(_config())
	assert_almost_eq(ramp.cruise_speed(-1.0), 11.0, 0.001)
	assert_almost_eq(ramp.cruise_speed(2.0), 32.0, 0.001)


func test_reads_live_config() -> void:
	var config := TuningConfig.new()
	var ramp := DifficultyRamp.new(config)
	config.cruise_speed_end = 60.0
	assert_almost_eq(ramp.cruise_speed(1.0), 60.0, 0.001)

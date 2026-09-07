extends GutTest


func test_defaults_match_contract_samples() -> void:
	var config := TuningConfig.new()
	assert_eq(config.shift_length_sec, 90.0)
	assert_eq(config.cruise_speed_start, 14.0)
	assert_eq(config.cruise_speed_end, 26.0)
	assert_eq(config.spawn_interval_start, 1.5)
	assert_eq(config.spawn_interval_end, 0.9)
	assert_eq(config.plate_readable_z, 30.0)
	assert_eq(config.capture_cooldown_sec, 0.35)
	assert_eq(config.box_size, Vector2(140.0, 90.0))
	assert_eq(config.points_correct, 100)
	assert_eq(config.points_wrong, -25)
	assert_eq(config.points_missed, -10)
	assert_eq(config.top_count, 20)
	assert_eq(config.results_idle_timeout_sec, 60.0)
	assert_eq(config.default_player_name, "Rookie")


func test_derived_lane_centres() -> void:
	var config := TuningConfig.new()
	assert_eq(config.lane_bus_center(), 345.0)
	assert_eq(config.lane_passing_center(), -48.5)
	assert_eq(config.lane_bike_center(), 621.0)


func test_defaults_validate_clean() -> void:
	assert_eq(TuningConfig.new().validate().size(), 0)


func test_shipped_defaults_resource_loads_and_validates() -> void:
	var config := TuningService.load_defaults()
	assert_not_null(config)
	assert_eq(config.validate().size(), 0)
	assert_eq(config.shift_length_sec, 90.0)


func test_invariants_are_flagged() -> void:
	var config := TuningConfig.new()
	config.cruise_speed_start = 50.0
	config.cruise_speed_end = 20.0
	config.spawn_interval_end = 3.0
	config.merge_trigger_z = 50.0
	config.default_player_name = "Bad Name 1"
	var problems := config.validate()
	assert_eq(problems.size(), 4, str(problems))


func test_every_tunable_is_enumerable() -> void:
	var names := TunableProperties.names(TuningConfig.new())
	assert_gt(names.size(), 55)
	assert_true(names.has("shift_length_sec"))
	assert_true(names.has("situation_weight_bus_stop_zone"))
	assert_true(names.has("show_plate_rects"))
	assert_false(names.has("resource_name"), "engine properties must be excluded")


func test_situation_weights_cover_all_seven_kinds() -> void:
	assert_eq(TuningConfig.new().situation_weights().size(), 7)

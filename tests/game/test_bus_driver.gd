extends GutTest

const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")

var _config: TuningConfig
var _driver: BusDriver
var _layer: VehicleLayer


func before_each() -> void:
	_config = TuningConfig.new()
	_layer = VehicleLayer.new()
	add_child_autofree(_layer)
	_driver = BusDriver.new()
	_driver.config = _config
	add_child_autofree(_driver)
	watch_signals(_driver)


func _vehicle(road_x: float, z: float, motion: Vehicle.Motion, speed: float = 0.0) -> Vehicle:
	var v: Vehicle = VEHICLE_SCENE.instantiate()
	v.config = _config
	v.setup(road_x, z, motion, speed, VehicleStyle.make_default("t"), 0)
	_layer.add(v)
	return v


func _run(seconds: float, cruise: float = 20.0, step: float = 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds:
		_driver.update(step, cruise, _layer.vehicles)
		t += step


func test_reset_uses_bus_lane_and_start_speed() -> void:
	assert_eq(_driver.camera_x, _config.lane_bus_center())
	assert_eq(_driver.road_speed, _config.cruise_speed_start)


func test_accelerates_toward_cruise_on_open_road() -> void:
	_run(3.0, 26.0)
	assert_almost_eq(_driver.road_speed, 26.0, 0.01)


func test_swerves_around_parked_blocker_and_returns() -> void:
	var blocker := _vehicle(_config.lane_bus_center(), _config.swerve_trigger_z - 5.0,
			Vehicle.Motion.STOPPED_IN_ROAD)
	_run(1.0)
	assert_signal_emitted(_driver, "swerve_started")
	assert_almost_eq(_driver.camera_x, _config.lane_passing_center(), 0.01)
	blocker.z = -1.0
	_run(1.0)
	assert_signal_emitted(_driver, "swerve_ended")
	assert_almost_eq(_driver.camera_x, _config.lane_bus_center(), 0.01)


func test_ignores_parked_blocker_beyond_trigger() -> void:
	_vehicle(_config.lane_bus_center(), _config.swerve_trigger_z + 5.0, Vehicle.Motion.STOPPED_IN_ROAD)
	_run(0.5)
	assert_signal_not_emitted(_driver, "swerve_started")


func test_brakes_behind_moving_lead_then_lead_merges() -> void:
	var lead := _vehicle(_config.lane_bus_center(), _config.follow_trigger_z - 2.0,
			Vehicle.Motion.MOVING, 8.0)
	_run(2.0, 26.0)
	assert_almost_eq(_driver.road_speed, 8.0, 0.01, "matched the lead's speed")
	assert_false(lead.merging)
	lead.z = _config.merge_trigger_z - 1.0
	_run(0.1, 26.0)
	assert_true(lead.merging)
	assert_lt(lead.target_road_x, _config.lane_bus_left)


func test_speed_changed_emitted_while_adjusting() -> void:
	_run(0.5, 26.0)
	assert_signal_emitted(_driver, "speed_changed")

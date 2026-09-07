extends GutTest

const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")

var _config: TuningConfig
var _layer: VehicleLayer
var _judge: MissJudge
var _no_zones: Array[ZoneSpan] = []


func before_each() -> void:
	_config = TuningConfig.new()
	_layer = VehicleLayer.new()
	add_child_autofree(_layer)
	_judge = MissJudge.new(_config)


func _vehicle(road_x: float, z: float, motion: Vehicle.Motion) -> Vehicle:
	var v: Vehicle = VEHICLE_SCENE.instantiate()
	v.config = _config
	v.setup(road_x, z, motion, 0.0, VehicleStyle.make_default("t"), 0)
	_layer.add(v)
	return v


func test_uncaptured_violator_is_a_miss() -> void:
	var v := _vehicle(_config.lane_bus_center(), 0.5, Vehicle.Motion.STOPPED_IN_ROAD)
	var passed: Array[Vehicle] = [v]
	var missed := _judge.judge_passed(passed, _no_zones, _layer.vehicles)
	assert_eq(missed.size(), 1)
	assert_eq(missed[0].kind, Verdict.Kind.BUS_LANE)


func test_captured_and_innocent_vehicles_are_not_misses() -> void:
	var captured := _vehicle(_config.lane_bus_center(), 0.5, Vehicle.Motion.STOPPED_IN_ROAD)
	captured.mark_captured()
	var innocent := _vehicle(_config.lane_curb_x - 100.0, 0.5, Vehicle.Motion.CURB_PARKED)
	var passed: Array[Vehicle] = [captured, innocent]
	assert_eq(_judge.judge_passed(passed, _no_zones, _layer.vehicles).size(), 0)


func test_double_park_pair_passing_together_judges_the_outer_car() -> void:
	var curb := _vehicle(_config.lane_curb_x - 100.0, 0.5, Vehicle.Motion.CURB_PARKED)
	var outer := _vehicle(_config.lane_bike_right - 30.0, 0.8, Vehicle.Motion.STOPPED_IN_ROAD)
	var passed: Array[Vehicle] = [curb, outer]
	var missed := _judge.judge_passed(passed, _no_zones, _layer.vehicles)
	assert_eq(missed.size(), 1)
	assert_eq(missed[0].kind, Verdict.Kind.DOUBLE_PARKING)


func test_advance_and_free_flow_keeps_neighbours_until_judged() -> void:
	var curb := _vehicle(_config.lane_curb_x - 100.0, 0.5, Vehicle.Motion.CURB_PARKED)
	var outer := _vehicle(_config.lane_bike_right - 30.0, 0.5, Vehicle.Motion.STOPPED_IN_ROAD)
	var passed := _layer.advance_all(0.1, 20.0, _config.lane_bus_center())
	assert_eq(passed.size(), 2)
	var missed := _judge.judge_passed(passed, _no_zones, _layer.vehicles)
	_layer.free_passed(passed)
	assert_eq(missed.size(), 1)
	assert_eq(_layer.vehicles.size(), 0)
	assert_true(curb.is_queued_for_deletion() and outer.is_queued_for_deletion())

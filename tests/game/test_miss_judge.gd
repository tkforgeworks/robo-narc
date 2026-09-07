extends GutTest
## Misses are judged from the sensor report, so the lanes must be in the tree
## and physics must settle before judging.

const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")
const ROAD_AREAS_SCENE: PackedScene = preload("res://scenes/game/road_areas.tscn")

var _config: TuningConfig
var _layer: VehicleLayer
var _zones: BusStopZones
var _judge: MissJudge


func before_each() -> void:
	_config = TuningConfig.new()
	var areas: RoadAreas = ROAD_AREAS_SCENE.instantiate()
	areas.config = _config
	add_child_autofree(areas)
	_zones = BusStopZones.new()
	_zones.config = _config
	add_child_autofree(_zones)
	_layer = VehicleLayer.new()
	_layer.config = _config
	add_child_autofree(_layer)
	_judge = MissJudge.new(_config)


func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func _vehicle(road_x: float, z: float, motion: Vehicle.Motion) -> Vehicle:
	var v: Vehicle = VEHICLE_SCENE.instantiate()
	v.config = _config
	v.setup(road_x, z, motion, 0.0, VehicleStyle.make_default("t"), 0)
	_layer.add(v)
	v.refresh(_config.lane_bus_center())
	return v


func _curb_x() -> float:
	return _config.lane_curb_x - 100.0


func test_uncaptured_violator_is_a_miss() -> void:
	var v := _vehicle(_config.lane_bus_center(), 0.5, Vehicle.Motion.STOPPED_IN_ROAD)
	await _settle()
	var passed: Array[Vehicle] = [v]
	var missed := _judge.judge_passed(passed)
	assert_eq(missed.size(), 1)
	assert_eq(missed[0].kind, Verdict.Kind.BUS_LANE)


func test_captured_and_innocent_vehicles_are_not_misses() -> void:
	var captured := _vehicle(_config.lane_bus_center(), 0.5, Vehicle.Motion.STOPPED_IN_ROAD)
	captured.mark_captured()
	var innocent := _vehicle(_curb_x(), 0.5, Vehicle.Motion.CURB_PARKED)
	await _settle()
	assert_true(innocent.report().at_curb(_config), "legal curb car reads as at the curb")
	var passed: Array[Vehicle] = [captured, innocent]
	assert_eq(_judge.judge_passed(passed).size(), 0)


func test_double_park_pair_passing_together_judges_the_outer_car() -> void:
	var curb := _vehicle(_curb_x(), 0.5, Vehicle.Motion.CURB_PARKED)
	var outer := _vehicle(_config.lane_bike_right - 30.0, 0.8, Vehicle.Motion.STOPPED_IN_ROAD)
	await _settle()
	assert_true(outer.report().curb_neighbour, "probe sees the curb car")
	assert_false(curb.report().curb_neighbour)
	var passed: Array[Vehicle] = [curb, outer]
	var missed := _judge.judge_passed(passed)
	assert_eq(missed.size(), 1)
	assert_eq(missed[0].kind, Verdict.Kind.DOUBLE_PARKING)


func test_bus_stop_zone_miss() -> void:
	_zones.spawn_zone(0.0, 10.0)
	var v := _vehicle(_curb_x(), 2.0, Vehicle.Motion.CURB_PARKED)
	await _settle()
	assert_true(v.report().in_zone)
	var passed: Array[Vehicle] = [v]
	assert_eq(_judge.judge_passed(passed)[0].kind, Verdict.Kind.BUS_STOP)


func test_advance_and_free_flow_keeps_neighbours_until_judged() -> void:
	var curb := _vehicle(_curb_x(), 0.5, Vehicle.Motion.CURB_PARKED)
	var outer := _vehicle(_config.lane_bike_right - 30.0, 0.5, Vehicle.Motion.STOPPED_IN_ROAD)
	await _settle()
	var passed := _layer.advance_all(0.1, 20.0, _config.lane_bus_center())
	assert_eq(passed.size(), 2)
	var missed := _judge.judge_passed(passed)
	_layer.free_passed(passed)
	assert_eq(missed.size(), 1)
	assert_eq(_layer.vehicles.size(), 0)
	assert_true(curb.is_queued_for_deletion() and outer.is_queued_for_deletion())

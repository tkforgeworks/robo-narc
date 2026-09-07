extends GutTest

var _config: TuningConfig


func before_each() -> void:
	_config = TuningConfig.new()


func test_bus_lane_bounds() -> void:
	assert_true(RoadGeometry.is_in_bus_lane(400.0, _config))
	assert_false(RoadGeometry.is_in_bus_lane(240.0, _config), "edge is exclusive")
	assert_false(RoadGeometry.is_in_bus_lane(600.0, _config))


func test_curb_threshold() -> void:
	assert_true(RoadGeometry.is_at_curb(700.0, _config))
	assert_true(RoadGeometry.is_at_curb(800.0, _config))
	assert_false(RoadGeometry.is_at_curb(650.0, _config))


func test_bike_lane_intrusion() -> void:
	assert_eq(RoadGeometry.bike_lane_intrusion(800.0, 45.0, _config), 0.0)
	assert_almost_eq(RoadGeometry.bike_lane_intrusion(700.0, 45.0, _config), 25.0, 0.001)
	assert_almost_eq(RoadGeometry.bike_lane_intrusion(600.0, 45.0, _config), 125.0, 0.001)


func test_lane_for() -> void:
	assert_eq(RoadGeometry.lane_for(-200.0, _config), RoadGeometry.Lane.MEDIAN)
	assert_eq(RoadGeometry.lane_for(80.0, _config), RoadGeometry.Lane.PASSING)
	assert_eq(RoadGeometry.lane_for(400.0, _config), RoadGeometry.Lane.BUS)
	assert_eq(RoadGeometry.lane_for(620.0, _config), RoadGeometry.Lane.BIKE)
	assert_eq(RoadGeometry.lane_for(800.0, _config), RoadGeometry.Lane.PARKING)
	assert_eq(RoadGeometry.lane_for(1000.0, _config), RoadGeometry.Lane.SIDEWALK)


func test_edges_follow_config() -> void:
	_config.lane_bus_left = 300.0
	assert_false(RoadGeometry.is_in_bus_lane(280.0, _config))
	assert_true(RoadGeometry.is_in_bus_lane(320.0, _config))

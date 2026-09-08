extends GutTest

var _config: TuningConfig


func before_each() -> void:
	_config = TuningConfig.new()
	_config.road_edge_left_x = -400.0
	_config.lane_road_left = -80.0
	_config.lane_bus_left = 240.0
	_config.lane_bus_right = 560.0
	_config.lane_bike_right = 680.0
	_config.lane_curb_x = 900.0
	_config.road_edge_right_x = 1400.0


func test_bounds_follow_the_lane_edges() -> void:
	assert_eq(RoadGeometry.bounds_for(RoadGeometry.Lane.MEDIAN, _config), Vector2(-400, -80))
	assert_eq(RoadGeometry.bounds_for(RoadGeometry.Lane.PASSING, _config), Vector2(-80, 240))
	assert_eq(RoadGeometry.bounds_for(RoadGeometry.Lane.BUS, _config), Vector2(240, 560))
	assert_eq(RoadGeometry.bounds_for(RoadGeometry.Lane.BIKE, _config), Vector2(560, 680))
	assert_eq(RoadGeometry.bounds_for(RoadGeometry.Lane.PARKING, _config), Vector2(680, 900))
	assert_eq(RoadGeometry.bounds_for(RoadGeometry.Lane.SIDEWALK, _config), Vector2(900, 1400))


func test_lane_for() -> void:
	assert_eq(RoadGeometry.lane_for(-200.0, _config), RoadGeometry.Lane.MEDIAN)
	assert_eq(RoadGeometry.lane_for(80.0, _config), RoadGeometry.Lane.PASSING)
	assert_eq(RoadGeometry.lane_for(400.0, _config), RoadGeometry.Lane.BUS)
	assert_eq(RoadGeometry.lane_for(620.0, _config), RoadGeometry.Lane.BIKE)
	assert_eq(RoadGeometry.lane_for(800.0, _config), RoadGeometry.Lane.PARKING)
	assert_eq(RoadGeometry.lane_for(1000.0, _config), RoadGeometry.Lane.SIDEWALK)


func test_edges_follow_config() -> void:
	_config.lane_bus_left = 300.0
	assert_eq(RoadGeometry.lane_for(280.0, _config), RoadGeometry.Lane.PASSING)
	assert_eq(RoadGeometry.lane_for(320.0, _config), RoadGeometry.Lane.BUS)

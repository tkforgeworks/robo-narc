extends GutTest

var _config: TuningConfig


func before_each() -> void:
	_config = TuningConfig.new()


func test_z_zero_lands_on_bus_screen_y_at_full_scale() -> void:
	var p := Perspective.project(_config.lane_bus_center(), 0.0, _config.lane_bus_center(), _config)
	assert_almost_eq(p.y, _config.bus_screen_y, 0.001)
	assert_almost_eq(Perspective.scale_at(0.0, _config), 1.0, 0.001)


func test_horizon_is_approached_at_z_max() -> void:
	var p := Perspective.project(0.0, _config.z_max, _config.lane_bus_center(), _config)
	var span := _config.bus_screen_y - _config.horizon_y
	assert_lt(p.y, _config.horizon_y + span * 0.15)
	assert_gt(p.y, _config.horizon_y)
	assert_lt(Perspective.scale_at(_config.z_max, _config), 0.2)


func test_straight_lines_stay_straight() -> void:
	var road_x := _config.lane_curb_x
	var cam := _config.lane_bus_center()
	var a := Perspective.project(road_x, 0.0, cam, _config)
	var b := Perspective.project(road_x, 50.0, cam, _config)
	var c := Perspective.project(road_x, 100.0, cam, _config)
	var cross := (b - a).cross(c - a)
	assert_almost_eq(cross, 0.0, 0.5)


func test_camera_shift_moves_world_opposite() -> void:
	var road_x := 500.0
	var centred := Perspective.project(road_x, 10.0, _config.lane_bus_center(), _config)
	var shifted := Perspective.project(road_x, 10.0, _config.lane_passing_center(), _config)
	assert_gt(shifted.x, centred.x, "bus moving left shifts the world right")


func test_negative_z_is_clamped() -> void:
	assert_almost_eq(Perspective.factor(-5.0, 15.0), 1.0, 0.001)

extends GutTest
## Lane trapezoids derive from the tunables; vehicle bodies report their share
## of each lane through the areas.

const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")
const ROAD_AREAS_SCENE: PackedScene = preload("res://scenes/game/road_areas.tscn")

var _config: TuningConfig
var _areas: RoadAreas
var _layer: VehicleLayer


func before_each() -> void:
	_config = TuningConfig.new()
	_areas = ROAD_AREAS_SCENE.instantiate()
	_areas.config = _config
	add_child_autofree(_areas)
	_layer = VehicleLayer.new()
	_layer.config = _config
	add_child_autofree(_layer)


func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func _vehicle(road_x: float, z: float) -> Vehicle:
	var v: Vehicle = VEHICLE_SCENE.instantiate()
	v.config = _config
	v.setup(road_x, z, Vehicle.Motion.STOPPED_IN_ROAD, 0.0, VehicleStyle.make_default("t"), 0)
	_layer.add(v)
	v.refresh(_config.lane_bus_center())
	return v


func test_one_area_per_lane_with_trapezoid_from_the_tunables() -> void:
	assert_eq(_areas.lanes.size(), 4)
	var bus := _areas.lane_area(RoadGeometry.Lane.BUS)
	var polygon: PackedVector2Array = bus.get_node("Shape").polygon
	assert_eq(polygon.size(), 4)
	var cam := _config.lane_bus_center()
	assert_eq(polygon[3], Perspective.project(_config.lane_bus_left, 0.0, cam, _config), "near left")
	assert_eq(polygon[2], Perspective.project(_config.lane_bus_right, 0.0, cam, _config), "near right")
	var near_y := polygon[2].y
	var span := bus.span_at_global_y(near_y)
	assert_almost_eq(span.x, polygon[3].x, 0.01)
	assert_almost_eq(span.y, polygon[2].x, 0.01)


func test_swerve_and_tuning_rebuild_the_shapes() -> void:
	var bus := _areas.lane_area(RoadGeometry.Lane.BUS)
	var before: Vector2 = bus.get_node("Shape").polygon[3]
	_areas.set_camera_x(_config.lane_bus_center() + 200.0)
	var after: Vector2 = bus.get_node("Shape").polygon[3]
	assert_lt(after.x, before.x, "the world shifts against the camera")
	_config.lane_bus_left += 50.0
	_areas.rebuild()
	assert_gt((bus.get_node("Shape").polygon[3] as Vector2).x, after.x)


func test_body_in_the_middle_of_the_bus_lane_reports_full_share() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0)
	await _settle()
	var ratios := v.report().lane_ratios
	assert_almost_eq(float(ratios.get(RoadGeometry.Lane.BUS, 0.0)), 1.0, 0.02)
	assert_eq(float(ratios.get(RoadGeometry.Lane.PARKING, 0.0)), 0.0)


func test_body_straddling_two_lanes_splits_its_width() -> void:
	var v := _vehicle(_config.lane_bike_right, 10.0)
	await _settle()
	var ratios := v.report().lane_ratios
	var bike := float(ratios.get(RoadGeometry.Lane.BIKE, 0.0))
	var parking := float(ratios.get(RoadGeometry.Lane.PARKING, 0.0))
	assert_almost_eq(bike, 0.5, 0.05)
	assert_almost_eq(parking, 0.5, 0.05)
	assert_almost_eq(bike + parking, 1.0, 0.05)


func test_outlines_follow_the_debug_tunable() -> void:
	var bus := _areas.lane_area(RoadGeometry.Lane.BUS)
	assert_false(bus._shown)
	_config.show_collision_shapes = true
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(bus._shown)

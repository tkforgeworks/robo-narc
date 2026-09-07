extends GutTest

var _config: TuningConfig
var _layer: VehicleLayer
var _zones: BusStopZones
var _spawner: VehicleSpawner


func before_each() -> void:
	_config = TuningConfig.new()
	_layer = VehicleLayer.new()
	add_child_autofree(_layer)
	_zones = BusStopZones.new()
	_zones.config = _config
	add_child_autofree(_zones)
	_spawner = VehicleSpawner.new()
	_spawner.config = _config
	_spawner.rng.seed = 99
	add_child_autofree(_spawner)
	_spawner.configure(_layer, _zones)
	watch_signals(_spawner)


func test_every_kind_spawns_without_error() -> void:
	var total := 0
	for kind: SituationTable.Kind in SituationTable.Kind.values():
		_layer.clear()
		_zones.clear()
		_spawner.configure(_layer, _zones)
		var spawned := _spawner.spawn_situation(kind)
		assert_gt(spawned.size(), 0, SituationTable.Kind.keys()[kind])
		total += spawned.size()
	assert_signal_emit_count(_spawner, "vehicle_spawned", total)


func test_spawned_vehicles_carry_no_label_only_position_and_motion() -> void:
	var blocker := _spawner.spawn_situation(SituationTable.Kind.BUS_LANE_BLOCKER)[0]
	assert_eq(RoadGeometry.lane_for(blocker.road_x, _config), RoadGeometry.Lane.BUS)
	assert_eq(blocker.motion, Vehicle.Motion.STOPPED_IN_ROAD)
	assert_false(blocker.has_method("is_violator"))


func test_moving_traffic_drives_slower_than_road() -> void:
	_spawner.set_road_speed(20.0)
	var car := _spawner.spawn_situation(SituationTable.Kind.MOVING_TRAFFIC)[0]
	assert_eq(car.motion, Vehicle.Motion.MOVING)
	assert_between(car.own_speed, 20.0 * _config.moving_speed_min_ratio,
			20.0 * _config.moving_speed_max_ratio)


func test_double_park_pair_is_side_by_side() -> void:
	var pair := _spawner.spawn_situation(SituationTable.Kind.DOUBLE_PARK_PAIR)
	assert_eq(pair.size(), 2)
	assert_lt(absf(pair[0].z - pair[1].z), 4.0)
	assert_eq(RoadGeometry.lane_for(pair[0].road_x, _config), RoadGeometry.Lane.PARKING)
	assert_eq(RoadGeometry.lane_for(pair[1].road_x, _config), RoadGeometry.Lane.BIKE)


func test_bus_stop_zone_spawns_a_zone_with_a_car_inside() -> void:
	var spawned := _spawner.spawn_situation(SituationTable.Kind.BUS_STOP_ZONE)
	assert_eq(_zones.zones.size(), 1)
	assert_true(_zones.zones[0].contains(spawned[0].z))
	assert_eq(RoadGeometry.lane_for(spawned[0].road_x, _config), RoadGeometry.Lane.PARKING)


func test_column_gap_blocks_back_to_back_spawns() -> void:
	var first := _spawner.spawn_situation(SituationTable.Kind.BUS_LANE_BLOCKER)
	var second := _spawner.spawn_situation(SituationTable.Kind.BUS_LANE_BLOCKER)
	assert_eq(first.size(), 1)
	assert_eq(second.size(), 0, "same column, no gap yet")
	_layer.advance_all(0.0, 0.0, _config.lane_bus_center())
	first[0].z = _config.z_max - _config.spawn_column_gap_bus_z - 1.0
	assert_eq(_spawner.spawn_situation(SituationTable.Kind.BUS_LANE_BLOCKER).size(), 1)


func test_curb_spawn_skipped_near_a_zone() -> void:
	_spawner.spawn_situation(SituationTable.Kind.BUS_STOP_ZONE)
	assert_eq(_spawner.spawn_situation(SituationTable.Kind.LEGAL_CURB).size(), 0)


func test_sloppy_parker_sits_in_parking_and_deep_parker_in_the_bike_lane() -> void:
	var sloppy := _spawner.spawn_situation(SituationTable.Kind.SLOPPY_PARKER)[0]
	assert_eq(RoadGeometry.lane_for(sloppy.road_x, _config), RoadGeometry.Lane.PARKING)
	assert_lt(sloppy.road_x - _config.lane_bike_right, 40.0, "just over the line")
	_layer.clear()
	_spawner.configure(_layer, _zones)
	var deep := _spawner.spawn_situation(SituationTable.Kind.BIKE_LANE_VIOLATOR)[0]
	assert_eq(RoadGeometry.lane_for(deep.road_x, _config), RoadGeometry.Lane.BIKE)

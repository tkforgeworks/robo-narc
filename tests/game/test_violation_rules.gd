extends GutTest

const HALF_W := 45.0

var _config: TuningConfig
var _no_zones: Array[ZoneSpan] = []
var _nobody: Array[VehicleState] = []


func before_each() -> void:
	_config = TuningConfig.new()
	_config.road_edge_left_x = -400.0
	_config.lane_road_left = -80.0
	_config.lane_bus_left = 240.0
	_config.lane_bus_right = 560.0
	_config.lane_bike_right = 680.0
	_config.lane_curb_x = 900.0
	_config.road_edge_right_x = 1400.0
	_config.curb_threshold_x = 700.0
	_config.rear_width_px = 90.0


func _vehicle(id: int, road_x: float, z: float, stationary: bool = true) -> VehicleState:
	return VehicleState.new(id, road_x, z, stationary, HALF_W)


func test_moving_vehicles_are_innocent_anywhere() -> void:
	var v := _vehicle(1, 400.0, 20.0, false)
	var verdict := ViolationRules.evaluate(v, _no_zones, _nobody, _config)
	assert_eq(verdict.kind, Verdict.Kind.INNOCENT)
	assert_false(verdict.is_violation)


func test_stationary_in_bus_lane() -> void:
	var verdict := ViolationRules.evaluate(_vehicle(1, 400.0, 20.0), _no_zones, _nobody, _config)
	assert_eq(verdict.kind, Verdict.Kind.BUS_LANE)
	assert_eq(verdict.label, "BUS LANE")


func test_legal_curb_parking_is_innocent() -> void:
	var verdict := ViolationRules.evaluate(_vehicle(1, 800.0, 20.0), _no_zones, _nobody, _config)
	assert_eq(verdict.kind, Verdict.Kind.INNOCENT)


func test_sloppy_parker_under_threshold_is_innocent() -> void:
	# Intrusion = 680 - (705 - 45) = 20 px, below the 60 px threshold.
	var verdict := ViolationRules.evaluate(_vehicle(1, 705.0, 20.0), _no_zones, _nobody, _config)
	assert_eq(verdict.kind, Verdict.Kind.INNOCENT)


func test_deep_bike_lane_parker_is_violation() -> void:
	# Intrusion = 680 - (615 - 45) = 110 px.
	var verdict := ViolationRules.evaluate(_vehicle(1, 615.0, 20.0), _no_zones, _nobody, _config)
	assert_eq(verdict.kind, Verdict.Kind.BIKE_LANE)


func test_double_park_pair() -> void:
	var curb_car := _vehicle(1, 805.0, 30.0)
	var outer_car := _vehicle(2, 645.0, 31.0)
	var all: Array[VehicleState] = [curb_car, outer_car]
	assert_eq(ViolationRules.evaluate(outer_car, _no_zones, all, _config).kind,
			Verdict.Kind.DOUBLE_PARKING)
	assert_eq(ViolationRules.evaluate(curb_car, _no_zones, all, _config).kind,
			Verdict.Kind.INNOCENT, "the curb car is innocent")


func test_double_park_requires_side_by_side() -> void:
	var curb_car := _vehicle(1, 805.0, 30.0)
	var outer_car := _vehicle(2, 645.0, 30.0 + _config.double_park_adjacent_z + 1.0)
	var all: Array[VehicleState] = [curb_car, outer_car]
	assert_eq(ViolationRules.evaluate(outer_car, _no_zones, all, _config).kind,
			Verdict.Kind.BIKE_LANE, "falls through to the bike lane rule")


func test_bus_stop_zone() -> void:
	var zones: Array[ZoneSpan] = [ZoneSpan.new(20.0, _config.bus_stop_zone_length)]
	assert_eq(ViolationRules.evaluate(_vehicle(1, 800.0, 25.0), zones, _nobody, _config).kind,
			Verdict.Kind.BUS_STOP)
	assert_eq(ViolationRules.evaluate(_vehicle(1, 800.0, 45.0), zones, _nobody, _config).kind,
			Verdict.Kind.INNOCENT, "just past the zone")
	assert_eq(ViolationRules.evaluate(_vehicle(1, 800.0, 40.0), zones, _nobody, _config).kind,
			Verdict.Kind.BUS_STOP, "zone end is inclusive")


func test_bus_stop_rule_needs_curb() -> void:
	var zones: Array[ZoneSpan] = [ZoneSpan.new(20.0, 20.0)]
	var verdict := ViolationRules.evaluate(_vehicle(1, 400.0, 25.0), zones, _nobody, _config)
	assert_eq(verdict.kind, Verdict.Kind.BUS_LANE, "bus lane rule wins first")


func test_rule_order_bus_lane_beats_double_park() -> void:
	var curb_car := _vehicle(1, 805.0, 30.0)
	var bus_lane_car := _vehicle(2, 400.0, 30.0)
	var all: Array[VehicleState] = [curb_car, bus_lane_car]
	assert_eq(ViolationRules.evaluate(bus_lane_car, _no_zones, all, _config).kind,
			Verdict.Kind.BUS_LANE)


func test_thresholds_follow_config() -> void:
	_config.bike_intrusion_min_px = 200.0
	var verdict := ViolationRules.evaluate(_vehicle(1, 615.0, 20.0), _no_zones, _nobody, _config)
	assert_eq(verdict.kind, Verdict.Kind.INNOCENT)

extends GutTest
## The rulebook is a pure function of a VehicleReport; these build reports by hand.

var _config: TuningConfig


func before_each() -> void:
	_config = TuningConfig.new()


func _report(stationary: bool = true, ratios: Dictionary = {}, in_zone: bool = false,
		neighbour: bool = false) -> VehicleReport:
	var r := VehicleReport.new()
	r.stationary = stationary
	r.lane_ratios = ratios
	r.in_zone = in_zone
	r.curb_neighbour = neighbour
	return r


func test_moving_vehicles_are_innocent_anywhere() -> void:
	var verdict := ViolationRules.evaluate(_report(false, {RoadGeometry.Lane.BUS: 1.0}), _config)
	assert_eq(verdict.kind, Verdict.Kind.INNOCENT)
	assert_false(verdict.is_violation)


func test_stationary_in_bus_lane_by_membership_ratio() -> void:
	assert_eq(ViolationRules.evaluate(_report(true, {RoadGeometry.Lane.BUS: 0.6}), _config).kind,
			Verdict.Kind.BUS_LANE)
	assert_eq(ViolationRules.evaluate(_report(true, {RoadGeometry.Lane.BUS: 0.3,
			RoadGeometry.Lane.PASSING: 0.7}), _config).kind, Verdict.Kind.INNOCENT,
			"mostly in the passing lane")
	assert_eq(ViolationRules.evaluate(_report(true, {RoadGeometry.Lane.BUS: 0.6}), _config).label,
			"BUS LANE")


func test_legal_curb_parking_is_innocent() -> void:
	var verdict := ViolationRules.evaluate(_report(true, {RoadGeometry.Lane.PARKING: 1.0}), _config)
	assert_eq(verdict.kind, Verdict.Kind.INNOCENT)


func test_bike_lane_intrusion_ratio() -> void:
	var sloppy := {RoadGeometry.Lane.BIKE: 0.2, RoadGeometry.Lane.PARKING: 0.8}
	assert_eq(ViolationRules.evaluate(_report(true, sloppy), _config).kind, Verdict.Kind.INNOCENT,
			"under the intrusion ratio and at the curb")
	var deep := {RoadGeometry.Lane.BIKE: 0.6, RoadGeometry.Lane.PARKING: 0.4}
	assert_eq(ViolationRules.evaluate(_report(true, deep), _config).kind, Verdict.Kind.BIKE_LANE)
	_config.bike_intrusion_ratio = 0.9
	assert_eq(ViolationRules.evaluate(_report(true, deep), _config).kind, Verdict.Kind.INNOCENT,
			"threshold follows config")


func test_at_curb_never_counts_as_bike_lane() -> void:
	_config.lane_membership_ratio = 0.5
	var report := _report(true, {RoadGeometry.Lane.BIKE: 0.4, RoadGeometry.Lane.PARKING: 0.6})
	assert_eq(ViolationRules.evaluate(report, _config).kind, Verdict.Kind.INNOCENT)


func test_double_parking_needs_a_curb_neighbour() -> void:
	var ratios := {RoadGeometry.Lane.BIKE: 0.7, RoadGeometry.Lane.PARKING: 0.3}
	assert_eq(ViolationRules.evaluate(_report(true, ratios, false, true), _config).kind,
			Verdict.Kind.DOUBLE_PARKING, "beats the bike-lane rule")
	assert_eq(ViolationRules.evaluate(_report(true, ratios, false, false), _config).kind,
			Verdict.Kind.BIKE_LANE, "falls through without a neighbour")


func test_bus_stop_zone_needs_the_curb() -> void:
	assert_eq(ViolationRules.evaluate(_report(true, {RoadGeometry.Lane.PARKING: 1.0}, true), _config).kind,
			Verdict.Kind.BUS_STOP)
	assert_eq(ViolationRules.evaluate(_report(true, {RoadGeometry.Lane.PARKING: 1.0}, false), _config).kind,
			Verdict.Kind.INNOCENT, "outside the zone")
	assert_eq(ViolationRules.evaluate(_report(true, {RoadGeometry.Lane.BUS: 1.0}, true), _config).kind,
			Verdict.Kind.BUS_LANE, "bus lane rule wins first")


func test_rule_order_bus_lane_beats_double_park() -> void:
	var report := _report(true, {RoadGeometry.Lane.BUS: 1.0}, false, true)
	assert_eq(ViolationRules.evaluate(report, _config).kind, Verdict.Kind.BUS_LANE)


func test_report_helpers() -> void:
	var report := _report(true, {RoadGeometry.Lane.PARKING: 0.5})
	assert_true(report.at_curb(_config))
	assert_eq(report.ratio(RoadGeometry.Lane.BUS), 0.0)
	_config.lane_membership_ratio = 0.6
	assert_false(report.at_curb(_config))

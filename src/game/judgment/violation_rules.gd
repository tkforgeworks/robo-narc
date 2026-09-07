class_name ViolationRules
extends RefCounted
## Derives whether a vehicle is violating from its CURRENT sensor report:
## motion, lane shares, zone, and neighbour. Nothing is pre-labeled; the
## spawner only sets up situations, and the player and this rulebook judge
## them the same way. Single source of truth for captures and misses.
##
## Rules, in order, first match wins:
##   1. Moving vehicles are never violators (normal traffic).
##   2. Stationary with >= lane_membership_ratio in the bus lane -> BUS_LANE
##   3. Stationary beside a stationary curb-parked vehicle      -> DOUBLE_PARKING
##   4. Stationary, not at the curb, >= bike_intrusion_ratio in
##      the bike lane                                            -> BIKE_LANE
##   5. Stationary at the curb inside a bus stop zone            -> BUS_STOP
##   6. Otherwise innocent.


static func evaluate(report: VehicleReport, config: TuningConfig) -> Verdict:
	if not report.stationary:
		return Verdict.innocent()
	if report.in_lane(RoadGeometry.Lane.BUS, config):
		return Verdict.of(Verdict.Kind.BUS_LANE)
	if report.curb_neighbour:
		return Verdict.of(Verdict.Kind.DOUBLE_PARKING)
	var at_curb := report.at_curb(config)
	if not at_curb and report.ratio(RoadGeometry.Lane.BIKE) >= config.bike_intrusion_ratio:
		return Verdict.of(Verdict.Kind.BIKE_LANE)
	if at_curb and report.in_zone:
		return Verdict.of(Verdict.Kind.BUS_STOP)
	return Verdict.innocent()

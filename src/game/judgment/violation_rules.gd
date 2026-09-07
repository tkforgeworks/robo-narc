class_name ViolationRules
extends RefCounted
## Derives whether a vehicle is violating from its CURRENT state: position,
## motion, and nearby landmarks. Nothing is pre-labeled; the spawner only sets
## up situations, and the player and this rulebook judge them the same way.
## Single source of truth for capture verdicts and missed-violation checks.
##
## Rules, in order, first match wins:
##   1. Moving vehicles are never violators (normal traffic).
##   2. Stationary in the bus/travel lane              -> BUS_LANE
##   3. Stationary beside a curb-parked vehicle        -> DOUBLE_PARKING
##   4. Stationary, deep enough into the bike lane     -> BIKE_LANE
##   5. Stationary at the curb inside a bus stop zone  -> BUS_STOP
##   6. Otherwise innocent.


static func evaluate(vehicle: VehicleState, zones: Array[ZoneSpan],
		neighbours: Array[VehicleState], config: TuningConfig) -> Verdict:
	if not vehicle.stationary:
		return Verdict.innocent()
	if RoadGeometry.is_in_bus_lane(vehicle.road_x, config):
		return Verdict.of(Verdict.Kind.BUS_LANE)
	if has_adjacent_curb_vehicle(vehicle, neighbours, config):
		return Verdict.of(Verdict.Kind.DOUBLE_PARKING)
	if is_bike_lane_intruder(vehicle, config):
		return Verdict.of(Verdict.Kind.BIKE_LANE)
	if RoadGeometry.is_at_curb(vehicle.road_x, config) and in_any_zone(vehicle.z, zones):
		return Verdict.of(Verdict.Kind.BUS_STOP)
	return Verdict.innocent()


## A stationary curb vehicle side by side (within adjacent_z) and clearly to
## the curb side of this one.
static func has_adjacent_curb_vehicle(vehicle: VehicleState,
		neighbours: Array[VehicleState], config: TuningConfig) -> bool:
	for other in neighbours:
		if other.id == vehicle.id or not other.stationary:
			continue
		if not RoadGeometry.is_at_curb(other.road_x, config):
			continue
		if absf(other.z - vehicle.z) < config.double_park_adjacent_z \
				and other.road_x - vehicle.road_x > config.double_park_min_x_gap:
			return true
	return false


## Not at the curb, right of the bus lane, and past the intrusion threshold.
static func is_bike_lane_intruder(vehicle: VehicleState, config: TuningConfig) -> bool:
	if RoadGeometry.is_at_curb(vehicle.road_x, config):
		return false
	if vehicle.road_x <= config.lane_bus_right - vehicle.half_width:
		return false
	var intrusion := RoadGeometry.bike_lane_intrusion(vehicle.road_x, vehicle.half_width, config)
	return intrusion >= config.bike_intrusion_min_px


static func in_any_zone(z: float, zones: Array[ZoneSpan]) -> bool:
	for zone in zones:
		if zone.contains(z):
			return true
	return false

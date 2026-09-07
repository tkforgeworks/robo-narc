class_name RoadGeometry
extends RefCounted
## Lane queries in road space. Every edge comes from TuningConfig so the lanes
## can be recalibrated live against the backdrop art.
##
## Left to right: median | passing lane | bus lane | bike lane | parking | sidewalk

enum Lane { MEDIAN, PASSING, BUS, BIKE, PARKING, SIDEWALK }

## Upper bound on reported bike-lane intrusion, so the value stays finite.
const MAX_INTRUSION := 400.0


static func is_in_bus_lane(road_x: float, config: TuningConfig) -> bool:
	return road_x > config.lane_bus_left and road_x < config.lane_bus_right


## "At the curb" means centred at or right of the curb threshold (parking lane).
static func is_at_curb(road_x: float, config: TuningConfig) -> bool:
	return road_x >= config.curb_threshold_x


## How far (px, road space) a vehicle's left edge reaches into the bike lane
## when approaching from the parking side. 0 = not intruding.
static func bike_lane_intrusion(road_x: float, half_width: float, config: TuningConfig) -> float:
	return clampf(config.lane_bike_right - (road_x - half_width), 0.0, MAX_INTRUSION)


static func lane_for(road_x: float, config: TuningConfig) -> Lane:
	if road_x < config.lane_road_left:
		return Lane.MEDIAN
	if road_x < config.lane_bus_left:
		return Lane.PASSING
	if road_x < config.lane_bus_right:
		return Lane.BUS
	if road_x < config.lane_bike_right:
		return Lane.BIKE
	if road_x < config.lane_curb_x:
		return Lane.PARKING
	return Lane.SIDEWALK

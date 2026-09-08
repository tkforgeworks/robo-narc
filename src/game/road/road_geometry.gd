class_name RoadGeometry
extends RefCounted
## Lane bounds in road space. Every edge comes from TuningConfig so the lanes
## can be recalibrated live against the backdrop art; LaneArea projects them
## to screen-space trapezoids and the rules work on overlap shares.
##
## Left to right: median | passing lane | bus lane | bike lane | parking | sidewalk

enum Lane { MEDIAN, PASSING, BUS, BIKE, PARKING, SIDEWALK }


## Left and right road-space x of a lane.
static func bounds_for(lane: Lane, config: TuningConfig) -> Vector2:
	match lane:
		Lane.MEDIAN:
			return Vector2(config.road_edge_left_x, config.lane_road_left)
		Lane.PASSING:
			return Vector2(config.lane_road_left, config.lane_bus_left)
		Lane.BUS:
			return Vector2(config.lane_bus_left, config.lane_bus_right)
		Lane.BIKE:
			return Vector2(config.lane_bus_right, config.lane_bike_right)
		Lane.PARKING:
			return Vector2(config.lane_bike_right, config.lane_curb_x)
	return Vector2(config.lane_curb_x, config.road_edge_right_x)


## The lane a road-space x falls in (used by spawner tests and layouts).
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

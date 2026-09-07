class_name SituationLayouts
extends RefCounted
## Where each traffic situation puts its cars, in road space. Returns
## placements in spawn order; VehicleSpawner stops at the first one its column
## rules reject, so pairs stay pairs. Positions derive from the lane tunables.

const COLUMN_BUS := "bus"
const COLUMN_BIKE := "bike"
const COLUMN_CURB := "curb"
const ZONE_SPAWN_OFFSET := 14.0
const CURB_CLEARANCE := 16.0
const ZONE_CLEARANCE := 30.0
const LEGAL_AFTER_ZONE_CHANCE := 0.4

var config: TuningConfig
var rng: RandomNumberGenerator
var zones: BusStopZones


func _init(p_config: TuningConfig, p_rng: RandomNumberGenerator, p_zones: BusStopZones) -> void:
	config = p_config
	rng = p_rng
	zones = p_zones


## Placements are `{x, z, motion, speed, column}`.
func for_kind(kind: SituationTable.Kind, road_speed: float) -> Array[Dictionary]:
	var z_max := config.z_max
	match kind:
		SituationTable.Kind.MOVING_TRAFFIC:
			var ratio := rng.randf_range(config.moving_speed_min_ratio, config.moving_speed_max_ratio)
			return [place(_bus_center(rng.randf_range(-40.0, 40.0)), z_max,
					Vehicle.Motion.MOVING, road_speed * ratio, COLUMN_BUS)]
		SituationTable.Kind.LEGAL_CURB:
			if zones.blocks_spawn_near_horizon(CURB_CLEARANCE):
				return []
			return [place(_curb_park_x(18.0), z_max, Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB)]
		SituationTable.Kind.SLOPPY_PARKER:
			if zones.blocks_spawn_near_horizon(CURB_CLEARANCE):
				return []
			var x := config.lane_bike_right + rng.randf_range(18.0, 34.0)
			return [place(x, z_max, Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB)]
		SituationTable.Kind.BIKE_LANE_VIOLATOR:
			var x := config.lane_bus_right + rng.randf_range(36.0, 74.0)
			return [place(x, z_max, Vehicle.Motion.STOPPED_IN_ROAD, 0.0, COLUMN_BIKE)]
		SituationTable.Kind.BUS_LANE_BLOCKER:
			return [place(_bus_center(rng.randf_range(-30.0, 30.0)), z_max,
					Vehicle.Motion.STOPPED_IN_ROAD, 0.0, COLUMN_BUS)]
		SituationTable.Kind.DOUBLE_PARK_PAIR:
			return _double_park_pair(z_max)
		SituationTable.Kind.BUS_STOP_ZONE:
			return _bus_stop_zone(z_max)
	return []


static func place(x: float, z: float, motion: Vehicle.Motion, speed: float,
		column: String) -> Dictionary:
	return {"x": x, "z": z, "motion": motion, "speed": speed, "column": column}


## Curb car first; the outer car only spawns if the curb car did.
func _double_park_pair(z_max: float) -> Array[Dictionary]:
	var pair_z := z_max + rng.randf_range(0.0, 4.0)
	var outer_x := config.lane_bike_right - rng.randf_range(24.0, 44.0)
	return [
		place(_curb_park_x(10.0), pair_z, Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB),
		place(outer_x, pair_z + rng.randf_range(-3.0, 3.0), Vehicle.Motion.STOPPED_IN_ROAD, 0.0,
				COLUMN_BIKE),
	]


## Opens a zone, parks a violator inside it, and sometimes a legal car past it.
func _bus_stop_zone(z_max: float) -> Array[Dictionary]:
	if zones.blocks_spawn_near_horizon(ZONE_CLEARANCE):
		return []
	var length := config.bus_stop_zone_length
	var zone := zones.spawn_zone(z_max - ZONE_SPAWN_OFFSET, length)
	var placements: Array[Dictionary] = [place(_curb_park_x(15.0),
			zone.z + rng.randf_range(4.0, length - 4.0), Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB)]
	if rng.randf() < LEGAL_AFTER_ZONE_CHANCE:
		placements.append(place(_curb_park_x(15.0), zone.end_z() + rng.randf_range(6.0, 10.0),
				Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB))
	return placements


func _bus_center(offset: float) -> float:
	return config.lane_bus_center() + offset


## Centre of a legally curb-parked car: half a lane inside the curb line.
func _curb_park_x(jitter: float) -> float:
	return config.lane_curb_x - 100.0 + rng.randf_range(-jitter, jitter)

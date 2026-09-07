class_name BusDriver
extends Node
## The bus's own driving: swerves into the passing lane around parked
## bus-lane blockers, brakes behind moving bus-lane traffic until it merges
## out, then accelerates back to cruise. Owns camera_x and road_speed; nothing
## else mutates them.

signal swerve_started
signal swerve_ended
signal speed_changed(road_speed: float)
## A moving bus-lane car was told to merge out of the bus's way.
signal vehicle_merging(vehicle: Vehicle)

enum LaneTarget { BUS_LANE, PASSING_LANE }

const MERGE_JITTER := 25.0

var config: TuningConfig
var rng := RandomNumberGenerator.new()
var camera_x: float = 0.0
var road_speed: float = 0.0
var lane_target: LaneTarget = LaneTarget.BUS_LANE


func _ready() -> void:
	if config == null:
		config = Tuning.config
	reset()


func reset() -> void:
	camera_x = config.lane_bus_center()
	road_speed = config.cruise_speed_start
	lane_target = LaneTarget.BUS_LANE


func update(delta: float, cruise_speed: float, vehicles: Array[Vehicle]) -> void:
	var nearest_parked: Vehicle = null
	var nearest_moving: Vehicle = null
	for vehicle in vehicles:
		if vehicle.z <= config.pass_z or not RoadGeometry.is_in_bus_lane(vehicle.road_x, config):
			continue
		if vehicle.is_stationary():
			if vehicle.z < config.swerve_trigger_z \
					and (nearest_parked == null or vehicle.z < nearest_parked.z):
				nearest_parked = vehicle
		elif nearest_moving == null or vehicle.z < nearest_moving.z:
			nearest_moving = vehicle

	_choose_lane(nearest_parked)
	var target_x := config.lane_passing_center() if lane_target == LaneTarget.PASSING_LANE \
			else config.lane_bus_center()
	camera_x = move_toward(camera_x, target_x, config.lane_change_speed * delta)

	var desired := cruise_speed
	if lane_target == LaneTarget.BUS_LANE and nearest_moving != null:
		if nearest_moving.z < config.follow_trigger_z:
			desired = minf(cruise_speed, nearest_moving.own_speed)
		if nearest_moving.z < config.merge_trigger_z and not nearest_moving.merging:
			nearest_moving.merge_to(config.lane_passing_center()
					+ rng.randf_range(-MERGE_JITTER, MERGE_JITTER))
			vehicle_merging.emit(nearest_moving)
	_approach_speed(desired, delta)


func _choose_lane(blocker: Vehicle) -> void:
	var wanted := LaneTarget.PASSING_LANE if blocker != null else LaneTarget.BUS_LANE
	if wanted == lane_target:
		return
	lane_target = wanted
	if wanted == LaneTarget.PASSING_LANE:
		swerve_started.emit()
	else:
		swerve_ended.emit()


func _approach_speed(desired: float, delta: float) -> void:
	var previous := road_speed
	if desired < road_speed:
		road_speed = maxf(desired, road_speed - config.brake_decel * delta)
	else:
		road_speed = minf(desired, road_speed + config.accel * delta)
	if not is_equal_approx(previous, road_speed):
		speed_changed.emit(road_speed)

class_name VehicleSpawner
extends Node
## Spawns traffic *situations*, never labeled violators. Each situation places
## vehicles by position, motion, and landmark; ViolationRules judges them later
## exactly as the player does. Positions derive from the lane tunables.

signal vehicle_spawned(vehicle: Vehicle)

const TAG := "Spawner"
const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")
const COLUMN_BUS := "bus"
const COLUMN_BIKE := "bike"
const COLUMN_CURB := "curb"
const ZONE_SPAWN_OFFSET := 14.0
const CURB_CLEARANCE := 16.0
const ZONE_CLEARANCE := 30.0

var config: TuningConfig
var rng := RandomNumberGenerator.new()
var spawn_count: int = 0

var _layer: VehicleLayer
var _zones: BusStopZones
## Any object with `random_style_and_color(rng) -> Dictionary {style, color_index}`.
var _style_source: Object = null
var _table: SituationTable
var _timer: Timer
var _road_speed: float = 14.0
var _last_in_column: Dictionary = {}


func _ready() -> void:
	if config == null:
		config = Tuning.config
	_table = SituationTable.new(config)
	_timer = Timer.new()
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)


func configure(layer: VehicleLayer, zones: BusStopZones, style_source: Object = null) -> void:
	_layer = layer
	_zones = zones
	_style_source = style_source
	_last_in_column.clear()
	spawn_count = 0


func start() -> void:
	_timer.wait_time = config.spawn_interval_start
	_timer.start()


func stop() -> void:
	_timer.stop()


func set_interval(seconds: float) -> void:
	_timer.wait_time = maxf(seconds, 0.05)


func set_road_speed(road_speed: float) -> void:
	_road_speed = road_speed


func _on_timeout() -> void:
	if _layer == null:
		DebugLog.error(TAG, "spawn tick before configure()")
		return
	spawn_situation(_table.pick(rng))


## Public so tests and the debug menu can force a situation.
func spawn_situation(kind: SituationTable.Kind) -> Array[Vehicle]:
	var z_max := config.z_max
	match kind:
		SituationTable.Kind.MOVING_TRAFFIC:
			var ratio := rng.randf_range(config.moving_speed_min_ratio, config.moving_speed_max_ratio)
			return _one(_spawn(_bus_center(rng.randf_range(-40.0, 40.0)), z_max,
					Vehicle.Motion.MOVING, _road_speed * ratio, COLUMN_BUS))
		SituationTable.Kind.LEGAL_CURB:
			if _zones.blocks_spawn_near_horizon(CURB_CLEARANCE):
				return []
			return _one(_spawn(_curb_park_x(18.0), z_max, Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB))
		SituationTable.Kind.SLOPPY_PARKER:
			if _zones.blocks_spawn_near_horizon(CURB_CLEARANCE):
				return []
			var x := config.lane_bike_right + rng.randf_range(18.0, 34.0)
			return _one(_spawn(x, z_max, Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB))
		SituationTable.Kind.BIKE_LANE_VIOLATOR:
			var x := config.lane_bus_right + rng.randf_range(36.0, 74.0)
			return _one(_spawn(x, z_max, Vehicle.Motion.STOPPED_IN_ROAD, 0.0, COLUMN_BIKE))
		SituationTable.Kind.BUS_LANE_BLOCKER:
			return _one(_spawn(_bus_center(rng.randf_range(-30.0, 30.0)), z_max,
					Vehicle.Motion.STOPPED_IN_ROAD, 0.0, COLUMN_BUS))
		SituationTable.Kind.DOUBLE_PARK_PAIR:
			var pair_z := z_max + rng.randf_range(0.0, 4.0)
			var curb_car := _spawn(_curb_park_x(10.0), pair_z, Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB)
			if curb_car == null:
				return []
			var outer_x := config.lane_bike_right - rng.randf_range(24.0, 44.0)
			var outer := _spawn(outer_x, pair_z + rng.randf_range(-3.0, 3.0),
					Vehicle.Motion.STOPPED_IN_ROAD, 0.0, COLUMN_BIKE)
			return _list([curb_car, outer])
		SituationTable.Kind.BUS_STOP_ZONE:
			if _zones.blocks_spawn_near_horizon(ZONE_CLEARANCE):
				return []
			var length := config.bus_stop_zone_length
			var zone := _zones.spawn_zone(z_max - ZONE_SPAWN_OFFSET, length)
			var inside := _spawn(_curb_park_x(15.0), zone.z + rng.randf_range(4.0, length - 4.0),
					Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB)
			var spawned := _list([inside])
			if rng.randf() < 0.4:
				var legal := _spawn(_curb_park_x(15.0), zone.end_z() + rng.randf_range(6.0, 10.0),
						Vehicle.Motion.CURB_PARKED, 0.0, COLUMN_CURB)
				spawned.append_array(_list([legal]))
			return spawned
	return []


func _bus_center(offset: float) -> float:
	return config.lane_bus_center() + offset


## Centre of a legally curb-parked car: half a lane inside the curb line.
func _curb_park_x(jitter: float) -> float:
	return config.lane_curb_x - 100.0 + rng.randf_range(-jitter, jitter)


func _spawn(road_x: float, z: float, motion: Vehicle.Motion, own_speed: float,
		column: String) -> Vehicle:
	if not _column_clear(column):
		return null
	var vehicle: Vehicle = VEHICLE_SCENE.instantiate()
	vehicle.config = config
	var pick := _pick_style()
	vehicle.setup(road_x, z, motion, own_speed, pick["style"], pick["color_index"])
	_layer.add(vehicle)
	_last_in_column[column] = vehicle
	spawn_count += 1
	vehicle_spawned.emit(vehicle)
	return vehicle


func _pick_style() -> Dictionary:
	if _style_source != null and _style_source.has_method("random_style_and_color"):
		return _style_source.random_style_and_color(rng)
	return {"style": VehicleStyle.make_default("placeholder"), "color_index": 0}


func _column_clear(column: String) -> bool:
	var last: Variant = _last_in_column.get(column)
	if last == null or not is_instance_valid(last):
		return true
	var gap := config.spawn_column_gap_bus_z if column == COLUMN_BUS else config.spawn_column_gap_curb_z
	return (last as Vehicle).z <= config.z_max - gap


func _one(vehicle: Vehicle) -> Array[Vehicle]:
	return _list([vehicle])


func _list(candidates: Array) -> Array[Vehicle]:
	var result: Array[Vehicle] = []
	for candidate: Variant in candidates:
		if candidate != null:
			result.append(candidate)
	return result

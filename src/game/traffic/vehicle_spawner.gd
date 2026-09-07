class_name VehicleSpawner
extends Node
## Spawns traffic *situations*, never labeled violators. SituationLayouts says
## where each situation's cars go; this node paces the spawns, enforces column
## gaps, and instantiates vehicles. ViolationRules judges them later exactly as
## the player does.

signal vehicle_spawned(vehicle: Vehicle)

const TAG := "Spawner"
const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")

var config: TuningConfig
var rng := RandomNumberGenerator.new()
var spawn_count: int = 0

var _layer: VehicleLayer
var _layouts: SituationLayouts
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
	_layouts = SituationLayouts.new(config, rng, zones)
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


## Public so tests and the debug menu can force a situation. Stops at the first
## placement the column gap rejects so multi-car situations stay coherent.
func spawn_situation(kind: SituationTable.Kind) -> Array[Vehicle]:
	var spawned: Array[Vehicle] = []
	for placement in _layouts.for_kind(kind, _road_speed):
		var vehicle := _spawn(placement)
		if vehicle == null:
			break
		spawned.append(vehicle)
	return spawned


func _spawn(placement: Dictionary) -> Vehicle:
	var column: String = placement["column"]
	if not _column_clear(column):
		return null
	var vehicle: Vehicle = VEHICLE_SCENE.instantiate()
	vehicle.config = config
	var pick := _pick_style()
	vehicle.setup(placement["x"], placement["z"], placement["motion"], placement["speed"],
			pick["style"], pick["color_index"])
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
	var gap := config.spawn_column_gap_bus_z if column == SituationLayouts.COLUMN_BUS \
			else config.spawn_column_gap_curb_z
	return (last as Vehicle).z <= config.z_max - gap

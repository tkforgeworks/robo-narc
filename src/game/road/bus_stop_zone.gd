class_name BusStopZones
extends Node2D
## The active bus stop zones: road-fixed spans that scroll toward the bus and
## are drawn as a stripe along the curb. Read by the spawner (placement) and
## the rulebook (judgment).

const STRIPE_PATH := "res://assets/road/bus-stop-stripe.png"
## Stripe edges in road space, offset from the curb line.
const STRIPE_INNER := 2.0
const STRIPE_OUTER := 32.0
const DESPAWN_Z := -25.0

var config: TuningConfig
var zones: Array[ZoneSpan] = []

var _camera_x: float = 0.0
var _texture: Texture2D


func _ready() -> void:
	if config == null:
		config = Tuning.config
	_camera_x = config.lane_bus_center()
	_texture = load(STRIPE_PATH) if ResourceLoader.exists(STRIPE_PATH) \
			else PlaceholderTexture.register_use("bus stop stripe")


func spawn_zone(z: float, length: float) -> ZoneSpan:
	var zone := ZoneSpan.new(z, length)
	zones.append(zone)
	return zone


func scroll(delta: float, road_speed: float) -> void:
	for zone in zones:
		zone.scroll(delta, road_speed)
	for i in range(zones.size() - 1, -1, -1):
		if zones[i].end_z() <= DESPAWN_Z:
			zones.remove_at(i)
	queue_redraw()


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	queue_redraw()


## True when any zone's far end is closer than `clearance` to the horizon.
func blocks_spawn_near_horizon(clearance: float) -> bool:
	for zone in zones:
		if zone.end_z() > config.z_max - clearance:
			return true
	return false


func clear() -> void:
	zones.clear()
	queue_redraw()


func _draw() -> void:
	var x0 := config.lane_curb_x + STRIPE_INNER
	var x1 := config.lane_curb_x + STRIPE_OUTER
	for zone in zones:
		var z0 := clampf(zone.z, 0.0, config.z_max)
		var z1 := clampf(zone.end_z(), 0.0, config.z_max)
		if z1 <= z0:
			continue
		var points := PackedVector2Array([
			Perspective.project(x0, z1, _camera_x, config),
			Perspective.project(x1, z1, _camera_x, config),
			Perspective.project(x1, z0, _camera_x, config),
			Perspective.project(x0, z0, _camera_x, config),
		])
		var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		var colors := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
		draw_polygon(points, colors, uvs, _texture)

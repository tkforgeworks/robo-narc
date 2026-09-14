class_name BusStopZones
extends Node2D
## The active bus stop zones: road-fixed spans that scroll toward the bus.
## Each is a ZoneArea child (the rulebook's landmark) marked by a shelter
## sprite on the right curb at its near end, plus an optional road stripe.
## Read by the spawner (placement) through `zones`.

const SHELTER_PATH := "res://assets/roadside/bus-stop.png"
## Optional: when present, drawn over each zone's span on the road.
const STRIPE_PATH := "res://assets/road/bus-stop-stripe.png"
## Stripe edges in road space, offset from the curb line.
## Direction of the shelter art's ground line (front pole bases, near to far)
## in unrotated sprite pixels; measured from bus-stop.png.
const ART_GROUND_DIR := Vector2(705.0 - 965.0, 1153.0 - 1550.0)
const MAX_SHEAR := 2.0
const STRIPE_INNER := 2.0
const STRIPE_OUTER := 32.0
const DESPAWN_Z := -25.0

var config: TuningConfig
var zones: Array[ZoneSpan] = []
var art_visible: bool = true:
	set(value):
		art_visible = value
		_rebuild()

var _areas: Array[ZoneArea] = []
var _shelters: Array[Sprite2D] = []
var _camera_x: float = 0.0
var _shelter_texture: Texture2D
var _stripe_texture: Texture2D = null


func _ready() -> void:
	if config == null:
		config = Tuning.config
	_camera_x = config.lane_bus_center()
	_shelter_texture = load(SHELTER_PATH) if ResourceLoader.exists(SHELTER_PATH) 			else PlaceholderTexture.register_use("bus stop shelter")
	if ResourceLoader.exists(STRIPE_PATH):
		_stripe_texture = load(STRIPE_PATH)


func spawn_zone(z: float, length: float) -> ZoneSpan:
	var zone := ZoneSpan.new(z, length)
	var area := ZoneArea.new(zone)
	area.config = config
	add_child(area)
	area.rebuild(_camera_x)
	var shelter := Sprite2D.new()
	shelter.texture = _shelter_texture
	shelter.centered = false
	shelter.offset = -Vector2(_shelter_texture.get_size())
	add_child(shelter)
	_place_shelter(shelter, zone)
	zones.append(zone)
	_areas.append(area)
	_shelters.append(shelter)
	return zone


## Shelter sprites currently placed (one per zone; for tests).
func shelter_count() -> int:
	return _shelters.size()


func scroll(delta: float, road_speed: float) -> void:
	for zone in zones:
		zone.scroll(delta, road_speed)
	for i in range(zones.size() - 1, -1, -1):
		if zones[i].end_z() <= DESPAWN_Z:
			_areas[i].queue_free()
			_shelters[i].queue_free()
			_areas.remove_at(i)
			_shelters.remove_at(i)
			zones.remove_at(i)
	_rebuild()


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	_rebuild()


## True when any zone's far end is closer than `clearance` to the horizon.
func blocks_spawn_near_horizon(clearance: float) -> bool:
	for zone in zones:
		if zone.end_z() > config.z_max - clearance:
			return true
	return false


func clear() -> void:
	for area in _areas:
		area.queue_free()
	for shelter in _shelters:
		shelter.queue_free()
	_areas.clear()
	_shelters.clear()
	zones.clear()
	queue_redraw()


func _rebuild() -> void:
	for i in _areas.size():
		_areas[i].rebuild(_camera_x)
		_place_shelter(_shelters[i], zones[i])
	queue_redraw()


## The shelter's bottom-right corner (its near pole) stands on the curb at the
## zone's near end. A vertical shear then swings the art's ground line onto the
## curb, which in this one-point perspective always aims at the vanishing point,
## while the poles stay upright. The shear is computed for the bus's home lane
## so the shelter keeps one rigid shape while the bus changes lanes.
func _place_shelter(shelter: Sprite2D, zone: ZoneSpan) -> void:
	var z := zone.z
	var f := Perspective.scale_at(z, config)
	var road_x := config.lane_curb_x + config.bus_stop_offset_px
	shelter.position = Perspective.project(road_x, z, _camera_x, config)
	var uniform := (config.bus_stop_height_px / shelter.texture.get_size().y) * f
	var k := ground_shear(Perspective.project(road_x, z, config.lane_bus_center(), config))
	# Transform2D(rotation, scale, skew): x basis = scale.x * (cos r, sin r) = (1, k)
	# and y basis = scale.y * (-sin(r + s), cos(r + s)) = (0, 1) when s = -r.
	var r := atan(k)
	shelter.rotation = r
	shelter.skew = -r
	shelter.scale = Vector2(uniform * sqrt(1.0 + k * k), uniform)
	# Behind anything parked inside the zone: order by the zone's far end.
	shelter.z_index = clampi(int(config.z_max - zone.end_z()), 0, 4000)
	shelter.visible = art_visible and z >= 0.0 and z <= config.z_max


## Vertical shear (dy per dx) that maps the art's ground line onto the curb
## direction from `anchor` (as seen from the home lane) toward the vanishing
## point, plus the tuned lean.
func ground_shear(anchor: Vector2) -> float:
	var target := Perspective.vanishing_point(config.lane_bus_center(), config) - anchor
	if absf(target.x) < 1.0:
		return 0.0
	var wanted := target.angle() + deg_to_rad(config.bus_stop_lean_deg)
	if absf(cos(wanted)) < 0.01:
		return 0.0
	var target_slope := tan(wanted)
	var art_slope := ART_GROUND_DIR.y / ART_GROUND_DIR.x
	return clampf(target_slope - art_slope, -MAX_SHEAR, MAX_SHEAR)


func _draw() -> void:
	if not art_visible or _stripe_texture == null:
		return
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
		draw_polygon(points, colors, uvs, _stripe_texture)

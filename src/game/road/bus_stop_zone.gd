class_name BusStopZones
extends Node2D
## The active bus stop zones: road-fixed spans that scroll toward the bus.
## Each is a ZoneArea child (the rulebook's landmark) marked on the road by a
## hazard-stripe patch over its curb-lane rectangle and a shelter sprite on the
## curb at its near end. Read by the spawner (placement) through `zones`.

const SHELTER_PATH := "res://assets/roadside/bus-stop.png"
## Direction of the shelter art's ground line (front pole bases, near to far)
## in unrotated sprite pixels; measured from bus-stop.png.
const ART_GROUND_DIR := Vector2(705.0 - 965.0, 1153.0 - 1550.0)
const MAX_SHEAR := 2.0
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
var _marks: ZoneMarks


func _ready() -> void:
	if config == null:
		config = Tuning.config
	_camera_x = config.lane_bus_center()
	_shelter_texture = load(SHELTER_PATH) if ResourceLoader.exists(SHELTER_PATH) \
			else PlaceholderTexture.register_use("bus stop shelter")
	_marks = ZoneMarks.new(self)
	add_child(_marks)


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
	_marks.queue_redraw()
	return zone


## Shelter sprites currently placed (one per zone; for tests).
func shelter_count() -> int:
	return _shelters.size()


## The road marking layer (for tests).
func marks() -> CanvasItem:
	return _marks


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
	_rebuild()


func _rebuild() -> void:
	for i in _areas.size():
		_areas[i].rebuild(_camera_x)
		_place_shelter(_shelters[i], zones[i])
	if _marks != null:
		_marks.visible = art_visible
		_marks.queue_redraw()


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


## Yellow hazard stripes over each zone's curb-lane rectangle, projected
## perspective-correct through the road surface shader. The pattern is a
## generated repeating texture so its edges filter cleanly at any distance.
class ZoneMarks extends Node2D:
	const COLOR := Color(1.0, 0.82, 0.1)
	## Road px one texture repeat covers; stripes run at 45 degrees in road space.
	const TEXTURE_ROAD_PX := 160
	const STRIPE_PX := 40

	static var _texture: Texture2D

	var _zones: BusStopZones
	var _material: ShaderMaterial

	func _init(zones: BusStopZones) -> void:
		_zones = zones
		if _texture == null:
			_texture = _build_texture()
		_material = ShaderMaterial.new()
		_material.shader = RoadSurface.SHADER
		material = _material
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	func _draw() -> void:
		var config := _zones.config
		_material.set_shader_parameter("opacity", config.bus_stop_marking_opacity)
		var x0 := config.lane_bike_right
		var x1 := config.lane_curb_x
		var u_max := (x1 - x0) / TEXTURE_ROAD_PX
		for zone in _zones.zones:
			var near := clampf(zone.z, 0.0, config.z_max)
			var far := clampf(zone.end_z(), 0.0, config.z_max)
			if far <= near:
				continue
			var px_per_z := config.road_tile_px_per_z / TEXTURE_ROAD_PX
			var v_near := (near - zone.z) * px_per_z
			var v_far := (far - zone.z) * px_per_z
			var f_near := Perspective.factor(near, config.perspective_c)
			var f_far := Perspective.factor(far, config.perspective_c)
			var points := PackedVector2Array([
				Perspective.project(x0, far, _zones._camera_x, config),
				Perspective.project(x1, far, _zones._camera_x, config),
				Perspective.project(x1, near, _zones._camera_x, config),
				Perspective.project(x0, near, _zones._camera_x, config),
			])
			draw_polygon(points, Perspective.projected_uv_colors(u_max, v_near, v_far, f_near, f_far),
					PackedVector2Array([Vector2(0, v_far), Vector2(u_max, v_far),
							Vector2(u_max, v_near), Vector2(0, v_near)]), _texture)

	## A seamless tile of diagonal stripes: paint and clear bands of STRIPE_PX.
	static func _build_texture() -> Texture2D:
		var image := Image.create(TEXTURE_ROAD_PX, TEXTURE_ROAD_PX, true, Image.FORMAT_RGBA8)
		var clear := Color(COLOR.r, COLOR.g, COLOR.b, 0.0)
		for y in TEXTURE_ROAD_PX:
			for x in TEXTURE_ROAD_PX:
				var band := ((x + y) / STRIPE_PX) % 2 == 0
				image.set_pixel(x, y, COLOR if band else clear)
		image.generate_mipmaps()
		return ImageTexture.create_from_image(image)

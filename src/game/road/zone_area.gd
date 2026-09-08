class_name ZoneArea
extends OutlinedArea
## One bus stop zone's footprint: the parking lane between the zone's start
## and end, scrolling with the road. A vehicle body overlapping it while at
## the curb is "in the zone" for the rulebook.

## Physics layer 4 ("bus_stop_zone").
const LAYER_ZONE := 8
const COLOR := Color(1.0, 0.6, 0.2)

var span: ZoneSpan

var _polygon: CollisionPolygon2D


func _init(p_span: ZoneSpan = ZoneSpan.new()) -> void:
	span = p_span
	_polygon = CollisionPolygon2D.new()
	_polygon.name = "Shape"
	add_child(_polygon)
	outline_color = COLOR


func _ready() -> void:
	super()
	collision_layer = LAYER_ZONE
	collision_mask = 0
	monitoring = false
	monitorable = true


func rebuild(camera_x: float) -> void:
	var z0 := clampf(span.z, 0.0, config.z_max)
	var z1 := clampf(span.end_z(), 0.0, config.z_max)
	if z1 <= z0:
		_polygon.polygon = PackedVector2Array()
		queue_redraw()
		return
	var x0 := config.lane_bike_right
	var x1 := config.lane_curb_x
	_polygon.polygon = PackedVector2Array([
		Perspective.project(x0, z1, camera_x, config),
		Perspective.project(x1, z1, camera_x, config),
		Perspective.project(x1, z0, camera_x, config),
		Perspective.project(x0, z0, camera_x, config),
	])
	queue_redraw()

@tool
class_name LaneArea
extends OutlinedArea
## One road lane as a screen-space trapezoid derived from the lane tunables,
## re-projected when the bus swerves. Vehicle bodies overlap it to learn which
## lane they are in; `span_at_global_y` gives the exact horizontal overlap.
## @tool so the editor shows the shape at the shipped defaults.

## Physics layer 3 ("lane").
const LAYER_LANE := 4
const LANE_COLORS: Dictionary = {
	RoadGeometry.Lane.PASSING: Color(0.6, 0.6, 1.0),
	RoadGeometry.Lane.BUS: Color(1.0, 0.35, 0.35),
	RoadGeometry.Lane.BIKE: Color(0.5, 1.0, 0.3),
	RoadGeometry.Lane.PARKING: Color(1.0, 0.85, 0.3),
}

@export var lane: RoadGeometry.Lane = RoadGeometry.Lane.BUS

var _polygon: CollisionPolygon2D
var _camera_x: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		config = TuningService.load_defaults()
	super()
	collision_layer = LAYER_LANE
	collision_mask = 0
	monitoring = false
	monitorable = true
	_polygon = get_node_or_null("Shape") as CollisionPolygon2D
	if _polygon == null:
		_polygon = CollisionPolygon2D.new()
		_polygon.name = "Shape"
		add_child(_polygon)
	outline_color = LANE_COLORS.get(lane, outline_color)
	set_camera_x(config.lane_bus_center())


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	rebuild()


## Far-left, far-right, near-right, near-left, in this node's local space.
func rebuild() -> void:
	var b := RoadGeometry.bounds_for(lane, config)
	_polygon.polygon = PackedVector2Array([
		Perspective.project(b.x, config.z_max, _camera_x, config),
		Perspective.project(b.y, config.z_max, _camera_x, config),
		Perspective.project(b.y, 0.0, _camera_x, config),
		Perspective.project(b.x, 0.0, _camera_x, config),
	])
	queue_redraw()


## Horizontal extent [x0, x1] of the lane at global `y`, clamped to its ends.
func span_at_global_y(y: float) -> Vector2:
	var p := _polygon.polygon
	if p.size() < 4:
		return Vector2.ZERO
	var local_y := to_local(Vector2(0.0, y)).y
	var height := p[3].y - p[0].y
	var t := 0.0 if is_zero_approx(height) else clampf((local_y - p[0].y) / height, 0.0, 1.0)
	var x0 := lerpf(p[0].x, p[3].x, t)
	var x1 := lerpf(p[1].x, p[2].x, t)
	return Vector2(to_global(Vector2(x0, local_y)).x, to_global(Vector2(x1, local_y)).x)

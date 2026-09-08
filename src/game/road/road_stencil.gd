class_name RoadStencil
extends Sprite2D
## A road-fixed lane marking (BUS ONLY / bike symbol) that sweeps toward the
## bus at road speed and wraps back to the horizon, carrying the motion cue
## the static backdrop cannot (spec FR-003).

enum Lane { BUS, BIKE }

@export var lane: Lane = Lane.BUS
## Width in road space at full scale, as a fraction of the lane width.
@export_range(0.2, 1.0, 0.05) var lane_fill: float = 0.6
@export var start_z: float = 50.0

var config: TuningConfig
var z: float = 0.0

var _camera_x: float = 0.0


func _ready() -> void:
	if config == null:
		config = Tuning.config
	centered = true
	z = start_z
	if texture == null:
		texture = PlaceholderTexture.register_use("road stencil")
	_camera_x = config.lane_bus_center()
	_project()


func scroll(delta: float, road_speed: float) -> void:
	z -= road_speed * delta
	if z < -5.0:
		z += config.stencil_period_z
	_project()


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	_project()


func _lane_bounds() -> Vector2:
	if lane == Lane.BIKE:
		return Vector2(config.lane_bus_right, config.lane_bike_right)
	return Vector2(config.lane_bus_left, config.lane_bus_right)


func _project() -> void:
	var bounds := _lane_bounds()
	var road_x := (bounds.x + bounds.y) * 0.5
	var f := Perspective.scale_at(z, config)
	position = Perspective.project(road_x, z, _camera_x, config)
	var width_px := (bounds.y - bounds.x) * lane_fill
	var s := width_px / texture.get_size().x
	scale = Vector2(s * f, s * f * config.stencil_flatten)
	# Anchor at the bottom edge so the mark sits on the road at its own z.
	offset = Vector2(0.0, -texture.get_size().y * 0.5)
	visible = z <= config.z_max and z > -5.0

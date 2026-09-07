class_name RoadView
extends Node2D
## The premade sky-and-road backdrop, scaled to the playfield height and slid
## sideways on swerves. Lane dashes do not scroll; road stencils, buildings,
## and parked cars carry the motion cue. Also draws the median placeholder and
## an optional lane-calibration overlay for debug builds.

const BACKDROP_PATH := "res://assets/road/backdrop.png"
const PLAYFIELD := Vector2(1280.0, 720.0)
const MEDIAN_LEFT := -320.0

var config: TuningConfig

var _camera_x: float = 0.0
var _slack: float = 0.0
var _median_texture: Texture2D

@onready var _backdrop: Sprite2D = $Backdrop


func _ready() -> void:
	if config == null:
		config = Tuning.config
	_camera_x = config.lane_bus_center()
	_median_texture = PlaceholderTexture.register_use("median")
	_fit_backdrop()


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	var slide := -(camera_x - config.lane_bus_center()) * config.backdrop_slide_factor
	_backdrop.position.x = (PLAYFIELD.x - _backdrop_width()) * 0.5 + clampf(slide, -_slack, _slack)
	queue_redraw()


func _fit_backdrop() -> void:
	if _backdrop.texture == null:
		_backdrop.texture = PlaceholderTexture.register_use("road backdrop")
	_backdrop.centered = false
	var tex_size := Vector2(_backdrop.texture.get_size())
	var s := PLAYFIELD.y / tex_size.y
	_backdrop.scale = Vector2.ONE * s
	_slack = maxf((tex_size.x * s - PLAYFIELD.x) * 0.5, 0.0)
	set_camera_x(_camera_x)


func _backdrop_width() -> float:
	return _backdrop.texture.get_size().x * _backdrop.scale.x


func _draw() -> void:
	_draw_quad(MEDIAN_LEFT, config.lane_road_left, _median_texture)
	if config.show_lane_overlay:
		for x: float in [config.lane_road_left, config.lane_bus_left, config.lane_bus_right,
				config.lane_bike_right, config.lane_curb_x]:
			draw_line(Perspective.project(x, 0.0, _camera_x, config),
					Perspective.project(x, config.z_max, _camera_x, config), Color.YELLOW, 2.0)
		draw_line(Vector2(0, config.horizon_y), Vector2(PLAYFIELD.x, config.horizon_y),
				Color.CYAN, 1.0)


func _draw_quad(x0: float, x1: float, texture: Texture2D) -> void:
	var points := PackedVector2Array([
		Perspective.project(x0, config.z_max, _camera_x, config),
		Perspective.project(x1, config.z_max, _camera_x, config),
		Perspective.project(x1, 0.0, _camera_x, config),
		Perspective.project(x0, 0.0, _camera_x, config),
	])
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var colors := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	draw_polygon(points, colors, uvs, texture)

class_name RoadView
extends Node2D
## The premade sky-and-road backdrop plus the road-fixed layers that carry the
## motion cue: lane stencils and building strips. On a swerve the backdrop is
## sheared about the horizon (a lateral camera move shifts near rows more than
## far ones, leaving the vanishing point put), so painted lanes stay under the
## projected vehicles. Mirrored edge padding keeps the image from running out.
## Also draws the median placeholder and a lane-calibration overlay.

const ROAD_PATH := "res://assets/road/road.png"
const PLAYFIELD := Vector2(1280.0, 720.0)
const MEDIAN_LEFT := -320.0
## Extra image shown beyond each edge (screen px) via mirrored repeat.
const EDGE_PAD_PX := 640.0
const MAX_SHEAR := 0.85

var config: TuningConfig

var _camera_x: float = 0.0
var _median_texture: Texture2D
var _image_scale: float = 1.0
var _pad_image_px: float = 0.0

@onready var _sky: Sprite2D = $Sky
@onready var _backdrop: Sprite2D = $Road
@onready var _stencils: Array[RoadStencil] = [$BusStencil, $BikeStencil]
@onready var _strips: Array[BuildingStrip] = [$BuildingsLeft, $BuildingsRight]


## Children read `config` in their own _ready, which runs before ours.
func _enter_tree() -> void:
	if config == null:
		config = Tuning.config
	for path: String in ["BusStencil", "BikeStencil", "BuildingsLeft", "BuildingsRight"]:
		get_node(path).config = config


func _ready() -> void:
	_camera_x = config.lane_bus_center()
	_median_texture = PlaceholderTexture.register_use("median")
	_fit_backdrop()


## Advances every road-fixed layer by the bus's motion.
func scroll(delta: float, road_speed: float) -> void:
	for stencil in _stencils:
		stencil.scroll(delta, road_speed)
	for strip in _strips:
		strip.scroll(delta, road_speed)


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	_layout_backdrop()
	for stencil in _stencils:
		stencil.set_camera_x(camera_x)
	for strip in _strips:
		strip.set_camera_x(camera_x)
	queue_redraw()


func _fit_backdrop() -> void:
	if _backdrop.texture == null:
		_backdrop.texture = PlaceholderTexture.register_use("road backdrop")
	if _sky.texture == null:
		_sky.texture = PlaceholderTexture.register_use("sky")
	_fit_sky()
	_backdrop.centered = false
	_backdrop.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	var tex_size := Vector2(_backdrop.texture.get_size())
	_image_scale = PLAYFIELD.y / tex_size.y
	_pad_image_px = ceilf(EDGE_PAD_PX / _image_scale)
	_backdrop.region_enabled = true
	_backdrop.region_rect = Rect2(-_pad_image_px, 0.0, tex_size.x + 2.0 * _pad_image_px, tex_size.y)
	_layout_backdrop()


## The sky is static: scaled to the playfield height and centred.
func _fit_sky() -> void:
	_sky.centered = false
	var s := PLAYFIELD.y / _sky.texture.get_size().y
	_sky.scale = Vector2.ONE * s
	_sky.position = Vector2((PLAYFIELD.x - _sky.texture.get_size().x * s) * 0.5, 0.0)


## Pivot at the horizon row; shear so a row's shift matches the perspective
## shift of road-fixed objects at that depth: shift(y) = -dx * (y - h) / (bus - h).
func _layout_backdrop() -> void:
	var s := _image_scale
	var span := maxf(config.bus_screen_y - config.horizon_y, 1.0)
	var dx := (_camera_x - config.lane_bus_center()) * config.backdrop_shear_factor
	var skew := asin(clampf(dx / span, -MAX_SHEAR, MAX_SHEAR))
	var image_left := (PLAYFIELD.x - _backdrop_width()) * 0.5
	_backdrop.offset = Vector2(0.0, -config.horizon_y / s)
	_backdrop.position = Vector2(image_left - _pad_image_px * s, config.horizon_y)
	_backdrop.skew = skew
	_backdrop.scale = Vector2(s, s / cos(skew))


func _backdrop_width() -> float:
	return _backdrop.texture.get_size().x * _image_scale


func _draw() -> void:
	_draw_quad(config.road_edge_left_x + MEDIAN_LEFT, config.road_edge_left_x, _median_texture)
	if config.show_lane_overlay:
		for x: float in [config.road_edge_left_x, config.lane_road_left, config.lane_bus_left,
				config.lane_bus_right, config.lane_bike_right, config.lane_curb_x,
				config.road_edge_right_x]:
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

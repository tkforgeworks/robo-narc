class_name RoadView
extends Node2D
## The static sky plus the road-fixed layers that carry the motion cue: the
## projected road surface (one repeating tile) and the building strips. Also
## draws the lane-calibration overlay on top when show_lane_overlay is on.

const PLAYFIELD := Vector2(1280.0, 720.0)

var config: TuningConfig

var _camera_x: float = 0.0
var _overlay: LaneOverlay

@onready var _sky: Sprite2D = $Sky
@onready var _surface: RoadSurface = $Surface
@onready var _strips: Array[BuildingStrip] = [$BuildingsLeft, $BuildingsRight]


## Children read `config` in their own _ready, which runs before ours.
func _enter_tree() -> void:
	if config == null:
		config = Tuning.config
	for path: String in ["Surface", "BuildingsLeft", "BuildingsRight"]:
		get_node(path).config = config


func _ready() -> void:
	_camera_x = config.lane_bus_center()
	_fit_sky()
	_overlay = LaneOverlay.new(self)
	add_child(_overlay)


## Advances every road-fixed layer by the bus's motion.
func scroll(delta: float, road_speed: float) -> void:
	_surface.scroll(delta, road_speed)
	for strip in _strips:
		strip.scroll(delta, road_speed)


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	_surface.set_camera_x(camera_x)
	for strip in _strips:
		strip.set_camera_x(camera_x)
	_overlay.queue_redraw()


## The sky is static: scaled to the playfield height and centred.
func _fit_sky() -> void:
	if _sky.texture == null:
		_sky.texture = PlaceholderTexture.register_use("sky")
	_sky.centered = false
	var s := PLAYFIELD.y / _sky.texture.get_size().y
	_sky.scale = Vector2.ONE * s
	_sky.position = Vector2((PLAYFIELD.x - _sky.texture.get_size().x * s) * 0.5, 0.0)


## Lane edges and the horizon, drawn above everything in the road view.
class LaneOverlay extends Node2D:
	var _view: RoadView

	func _init(view: RoadView) -> void:
		_view = view

	func _draw() -> void:
		var config := _view.config
		if not config.show_lane_overlay:
			return
		for x: float in [config.road_edge_left_x, config.lane_road_left, config.lane_bus_left,
				config.lane_bus_right, config.lane_bike_right, config.lane_curb_x,
				config.road_edge_right_x]:
			draw_line(Perspective.project(x, 0.0, _view._camera_x, config),
					Perspective.project(x, config.z_max, _view._camera_x, config), Color.YELLOW, 2.0)
		draw_line(Vector2(0, config.horizon_y), Vector2(RoadView.PLAYFIELD.x, config.horizon_y),
				Color.CYAN, 1.0)

class_name RoadMarkings
extends Node2D
## Paint that lies in the road surface and flows past the bus: the bus lane's
## dashed left edge, its solid right edge (the bike lane's left), and a
## continuous stream of lane stencils. Everything is a quad in road space
## projected through Perspective, so it foreshortens like the lanes do and
## wraps seamlessly instead of snapping (spec FR-003).

enum Lane { BUS, BIKE }

const LINE_COLOR := Color("#898e98")
const BUS_FILL := 0.6
const BIKE_FILL := 0.7
const STENCIL_SHADER: Shader = preload("res://src/game/road/perspective_stencil.gdshader")

@export var bus_stencil: Texture2D
@export var bike_stencil: Texture2D

var config: TuningConfig
## Distance travelled, used as the scroll phase for every marking.
var travelled: float = 0.0

var _camera_x: float = 0.0
## Stencils draw through a child that carries the perspective-correct shader,
## so the flat lane lines above stay on the plain canvas material.
var _stencil_layer: StencilLayer


func _ready() -> void:
	if config == null:
		config = Tuning.config
	_camera_x = config.lane_bus_center()
	if bus_stencil == null:
		bus_stencil = PlaceholderTexture.register_use("bus lane stencil")
	if bike_stencil == null:
		bike_stencil = PlaceholderTexture.register_use("bike lane stencil")
	_stencil_layer = StencilLayer.new(self)
	add_child(_stencil_layer)
	_redraw_all()


func scroll(delta: float, road_speed: float) -> void:
	travelled += road_speed * delta
	_redraw_all()


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	_redraw_all()


func _redraw_all() -> void:
	queue_redraw()
	if _stencil_layer != null:
		_stencil_layer.queue_redraw()


## Near-end z of every stencil instance in `lane` that touches the visible road.
func stencil_zs(lane: Lane) -> PackedFloat32Array:
	var length := _stencil_length(lane)
	var offset := 0.0 if lane == Lane.BUS else config.stencil_period_z * 0.5
	return _stream(config.stencil_period_z, length, offset)


## Near-end z of every dash of the bus lane's left edge that touches the road.
func dash_zs() -> PackedFloat32Array:
	return _stream(config.lane_dash_length_z + config.lane_dash_gap_z, config.lane_dash_length_z, 0.0)


## Instances of a repeating mark: one every `period`, each `length` long,
## drifting toward the bus as `travelled` grows. Returns near-end z values.
func _stream(period: float, length: float, offset: float) -> PackedFloat32Array:
	var zs := PackedFloat32Array()
	if period <= 0.0:
		return zs
	var phase := fposmod(offset - travelled, period)
	var z := phase - period
	while z < config.z_max:
		if z + length > 0.0:
			zs.append(z)
		z += period
	return zs


func _stencil_length(lane: Lane) -> float:
	return config.stencil_length_bus_z if lane == Lane.BUS else config.stencil_length_bike_z


func _draw() -> void:
	var half := config.lane_line_width_px * 0.5
	_quad(config.lane_bus_right - half, config.lane_bus_right + half, 0.0, config.z_max, LINE_COLOR)
	for z in dash_zs():
		_quad(config.lane_bus_left - half, config.lane_bus_left + half, z,
				z + config.lane_dash_length_z, LINE_COLOR)


## Called by the stencil layer from inside its own draw.
func _draw_stencils_on(layer: CanvasItem) -> void:
	_draw_stencils(layer, Lane.BUS, bus_stencil, config.lane_bus_left, config.lane_bus_right, BUS_FILL)
	_draw_stencils(layer, Lane.BIKE, bike_stencil, config.lane_bus_right, config.lane_bike_right,
			BIKE_FILL)


func _draw_stencils(layer: CanvasItem, lane: Lane, texture: Texture2D, lane_left: float,
		lane_right: float, fill: float) -> void:
	var centre := (lane_left + lane_right) * 0.5
	var half := (lane_right - lane_left) * fill * 0.5
	var length := _stencil_length(lane)
	for z in stencil_zs(lane):
		_textured_quad(layer, centre - half, centre + half, z, z + length, texture)


## A flat road-space rectangle, clipped to the visible road, as one polygon.
func _quad(x0: float, x1: float, z0: float, z1: float, color: Color) -> void:
	z0 = clampf(z0, 0.0, config.z_max)
	z1 = clampf(z1, 0.0, config.z_max)
	if z1 <= z0:
		return
	draw_polygon(_corners(x0, x1, z0, z1), PackedColorArray([color, color, color, color]))


## One textured rectangle per stencil, clipped to the visible road. Each
## corner's vertex colour carries (u * f, v * f, f) with f the perspective
## factor at its depth; the shader divides back, giving perspective-correct
## texturing across the whole quad with no slice seams. v = 1 at the near edge.
func _textured_quad(layer: CanvasItem, x0: float, x1: float, z0: float, z1: float,
		texture: Texture2D) -> void:
	var span := z1 - z0
	var near := clampf(z0, 0.0, config.z_max)
	var far := clampf(z1, 0.0, config.z_max)
	if span <= 0.0 or far <= near:
		return
	var v_near := 1.0 - (near - z0) / span
	var v_far := 1.0 - (far - z0) / span
	var f_near := Perspective.factor(near, config.perspective_c)
	var f_far := Perspective.factor(far, config.perspective_c)
	var colors := PackedColorArray([
		Color(0.0, v_far * f_far, f_far, 1.0),
		Color(f_far, v_far * f_far, f_far, 1.0),
		Color(f_near, v_near * f_near, f_near, 1.0),
		Color(0.0, v_near * f_near, f_near, 1.0),
	])
	var uvs := PackedVector2Array([Vector2(0, v_far), Vector2(1, v_far), Vector2(1, v_near), Vector2(0, v_near)])
	layer.draw_polygon(_corners(x0, x1, near, far), colors, uvs, texture)


func _corners(x0: float, x1: float, z_near: float, z_far: float) -> PackedVector2Array:
	return PackedVector2Array([
		Perspective.project(x0, z_far, _camera_x, config),
		Perspective.project(x1, z_far, _camera_x, config),
		Perspective.project(x1, z_near, _camera_x, config),
		Perspective.project(x0, z_near, _camera_x, config),
	])


## Child canvas item whose material does the perspective divide.
class StencilLayer extends Node2D:
	var _markings: RoadMarkings

	func _init(markings: RoadMarkings) -> void:
		_markings = markings
		var mat := ShaderMaterial.new()
		mat.shader = RoadMarkings.STENCIL_SHADER
		material = mat

	func _draw() -> void:
		_markings._draw_stencils_on(self)

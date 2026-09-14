class_name RoadSurface
extends Node2D
## The road as one repeating tile (assets/road/road-tile.png, built by
## tools/build_road_tile.gd) projected onto the ground plane through the same
## Perspective as everything else. Lane fills, edges, lines, dashes, and
## stencils are all baked into the tile, so the road flows past the bus at the
## right speed at every depth and converges at the vanishing point. A flat
## ground colour sits beneath it for whatever the tile does not cover.

const TILE_PATH := "res://assets/road/road-tile.png"
## Road px beyond each road edge that the tile covers; must match the builder.
const TILE_MARGIN := 500.0
const GROUND_COLOR := Color("#0e1626")
const GROUND_HALF_WIDTH := 100000.0
## Far enough that the road is a few pixels wide at the horizon.
const FAR_Z := 4000.0
const SHADER: Shader = preload("res://src/game/road/road_surface.gdshader")

var config: TuningConfig
## Set before adding to the tree to override the tile (tests); else loaded.
var tile: Texture2D
## Distance travelled; scrolls the tile toward the bus.
var travelled: float = 0.0

var _camera_x: float = 0.0
var _ground: GroundPlane


func _ready() -> void:
	if config == null:
		config = Tuning.config
	_camera_x = config.lane_bus_center()
	if tile == null:
		tile = load(TILE_PATH) if ResourceLoader.exists(TILE_PATH) \
				else PlaceholderTexture.register_use("road tile")
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	material = shader_material
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_ground = GroundPlane.new(self)
	_ground.show_behind_parent = true
	add_child(_ground)
	_redraw_all()


func scroll(delta: float, road_speed: float) -> void:
	travelled += road_speed * delta
	_redraw_all()


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	_redraw_all()


## Road length one tile repeat covers, in z units.
func tile_length_z() -> float:
	return tile.get_height() / config.road_tile_px_per_z


## Tile texture v at depth z. Rows go up (v decreases) with distance, and the
## whole pattern slides toward the bus as `travelled` grows. Kept positive by
## a whole number of repeats, which the repeating sampler ignores.
func tile_v(z: float) -> float:
	var period := tile_length_z()
	var offset := fposmod(-travelled, period)
	var bias := float(int(FAR_Z / period) + 2)
	return (offset - z) / period + bias


func _redraw_all() -> void:
	queue_redraw()
	if _ground != null:
		_ground.queue_redraw()


## One quad from the bus to the far horizon. Vertex colours carry
## (u * f, v * f, f); the shader divides back for perspective-correct sampling.
func _draw() -> void:
	var left := config.road_edge_left_x - TILE_MARGIN
	var right := config.road_edge_right_x + TILE_MARGIN
	var f_near := Perspective.factor(0.0, config.perspective_c)
	var f_far := Perspective.factor(FAR_Z, config.perspective_c)
	var v_near := tile_v(0.0)
	var v_far := tile_v(FAR_Z)
	var colors := PackedColorArray([
		Color(0.0, v_far * f_far, f_far, 1.0),
		Color(f_far, v_far * f_far, f_far, 1.0),
		Color(f_near, v_near * f_near, f_near, 1.0),
		Color(0.0, v_near * f_near, f_near, 1.0),
	])
	var uvs := PackedVector2Array([Vector2(0, v_far), Vector2(1, v_far), Vector2(1, v_near), Vector2(0, v_near)])
	draw_polygon(corners(left, right, 0.0, FAR_Z), colors, uvs, tile)


func corners(x0: float, x1: float, z_near: float, z_far: float) -> PackedVector2Array:
	return PackedVector2Array([
		Perspective.project(x0, z_far, _camera_x, config),
		Perspective.project(x1, z_far, _camera_x, config),
		Perspective.project(x1, z_near, _camera_x, config),
		Perspective.project(x0, z_near, _camera_x, config),
	])


## Flat ground colour under the tile, drawn on a plain material behind it.
class GroundPlane extends Node2D:
	var _surface: RoadSurface

	func _init(surface: RoadSurface) -> void:
		_surface = surface

	func _draw() -> void:
		var c := RoadSurface.GROUND_COLOR
		draw_polygon(_surface.corners(-RoadSurface.GROUND_HALF_WIDTH, RoadSurface.GROUND_HALF_WIDTH,
				0.0, RoadSurface.FAR_Z), PackedColorArray([c, c, c, c]))

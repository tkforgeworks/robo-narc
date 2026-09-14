extends SceneTree
## Builds assets/road/road-tile.png: one straight, top-down stretch of road with
## every lane fill, edge, line, dash, and stencil baked in. RoadSurface projects
## it onto the ground plane and repeats it, so this tile IS the road art.
##
## Horizontal scale is 1 px = 1 road px, spanning road x from
## road_edge_left_x - TILE_MARGIN_PX to road_edge_right_x + TILE_MARGIN_PX.
## Vertical scale is road_tile_px_per_z rows per z unit; the top row is far.
## Lane positions come from the shipped TuningConfig defaults, so re-run this
## after retuning any lane edge:
##   godot --headless --path . --script tools/build_road_tile.gd

const OUT_PATH := "res://assets/road/road-tile.png"
const CONFIG_SCRIPT := "res://src/core/tuning/tuning_config.gd"
const BUS_STENCIL_PATH := "res://assets/road/stencil-bus-only-straight.png"
const BIKE_STENCIL_PATH := "res://assets/road/stencil-bike-lane.png"

## Must match RoadSurface.TILE_MARGIN.
const TILE_MARGIN_PX := 500
## One repeat of the tile, in z units (one BUS ONLY + one bike stencil per repeat).
const TILE_LENGTH_Z := 45.0
## Dash/gap pairs on the bus lane's left edge per repeat (dash = gap).
const DASH_PAIRS := 5
const LANE_LINE_PX := 8
const EDGE_LINE_PX := 18
const CURB_LINE_PX := 28
## Stencil width as a share of its lane's width.
const BUS_STENCIL_FILL := 0.6
const BIKE_STENCIL_FILL := 0.7

const SIDEWALK := Color("#0e1626")
const EDGE_LINE := Color("#090f19")
const PLAIN_LANE := Color("#121d31")
const BUS_LANE := Color("#561224")
const BIKE_LANE := Color("#5a7619")
const PAINT := Color("#898e98")

var _image: Image
var _left: int
var _height: int


func _initialize() -> void:
	var config: Resource = load(CONFIG_SCRIPT).new()
	_left = int(config.road_edge_left_x) - TILE_MARGIN_PX
	var right := int(config.road_edge_right_x) + TILE_MARGIN_PX
	_height = int(round(TILE_LENGTH_Z * config.road_tile_px_per_z))
	_image = Image.create(right - _left, _height, false, Image.FORMAT_RGBA8)
	_image.fill(SIDEWALK)

	var road_left := int(config.lane_road_left)
	var bus_left := int(config.lane_bus_left)
	var bus_right := int(config.lane_bus_right)
	var bike_right := int(config.lane_bike_right)
	var curb := int(config.lane_curb_x)

	# Fills, left to right. The median strip left of the edge line and the
	# sidewalk right of the curb keep the base colour.
	_fill(road_left - EDGE_LINE_PX / 2, road_left + EDGE_LINE_PX / 2, EDGE_LINE)
	_fill(road_left + EDGE_LINE_PX / 2, bus_left, PLAIN_LANE)
	_fill(bus_left, bus_right, BUS_LANE)
	_fill(bus_right, bike_right, BIKE_LANE)
	_fill(bike_right, curb - CURB_LINE_PX / 2, PLAIN_LANE)
	_fill(curb - CURB_LINE_PX / 2, curb + CURB_LINE_PX / 2, EDGE_LINE)

	# Paint: solid lines on the bike lane's edges, dashes on the bus lane's left.
	_fill(bus_right - LANE_LINE_PX / 2, bus_right + LANE_LINE_PX / 2, PAINT)
	_fill(bike_right - LANE_LINE_PX / 2, bike_right + LANE_LINE_PX / 2, PAINT)
	var dash := _height / (DASH_PAIRS * 2)
	for i in DASH_PAIRS:
		_image.fill_rect(Rect2i(bus_left - LANE_LINE_PX / 2 - _left, i * 2 * dash, LANE_LINE_PX, dash), PAINT)

	_stencil(BUS_STENCIL_PATH, (bus_left + bus_right) * 0.5,
			(bus_right - bus_left) * BUS_STENCIL_FILL, _height * 0.25)
	_stencil(BIKE_STENCIL_PATH, (bus_right + bike_right) * 0.5,
			(bike_right - bus_right) * BIKE_STENCIL_FILL, _height * 0.75)

	var err := _image.save_png(OUT_PATH)
	print("road tile -> %s (%s) %s" % [OUT_PATH, error_string(err), _image.get_size()])
	quit(0 if err == OK else 1)


## Fills road x range [x0, x1) down the whole tile.
func _fill(x0: int, x1: int, color: Color) -> void:
	_image.fill_rect(Rect2i(x0 - _left, 0, x1 - x0, _height), color)


## Blends a stencil PNG, scaled to `width_px` wide, centred at road x / tile row.
func _stencil(path: String, centre_x: float, width_px: float, centre_row: float) -> void:
	var art := Image.load_from_file(path)
	art.convert(Image.FORMAT_RGBA8)
	var scale := width_px / art.get_width()
	var size := Vector2i(int(round(art.get_width() * scale)), int(round(art.get_height() * scale)))
	art.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	var dst := Vector2i(int(round(centre_x - size.x * 0.5)) - _left, int(round(centre_row - size.y * 0.5)))
	_image.blend_rect(art, Rect2i(Vector2i.ZERO, size), dst)

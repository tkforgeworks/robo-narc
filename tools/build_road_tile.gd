extends SceneTree
## Builds assets/road/road-tile.png: one straight, top-down stretch of road with
## every lane fill, edge, line, dash, and stencil baked in. RoadSurface projects
## it onto the ground plane and repeats it, so this tile IS the road art.
##
## Horizontal scale is TILE_SCALE px per road px, spanning road x from
## road_edge_left_x - TILE_MARGIN_PX to road_edge_right_x + TILE_MARGIN_PX.
## Vertical scale is road_tile_px_per_z * TILE_SCALE rows per z unit; the top row is far.
## Lane positions come from the shipped TuningConfig defaults, so re-run this
## after retuning any lane edge:
##   godot --headless --path . --script tools/build_road_tile.gd

const OUT_PATH := "res://assets/road/road-tile.png"
const CONFIG_SCRIPT := "res://src/core/tuning/tuning_config.gd"
const BUS_STENCIL_PATH := "res://assets/road/stencil-bus-only-straight.png"
const BIKE_STENCIL_PATH := "res://assets/road/stencil-bike-lane.png"

## Must match RoadSurface.TILE_MARGIN.
const TILE_MARGIN_PX := 500
## Raster px per road px. Half scale is still >= 1 texel per screen px everywhere
## above the dashboard overlay, at a quarter of the memory.
const TILE_SCALE := 0.5
## One repeat of the tile, in z units: one BUS ONLY and two bike stencils per repeat.
const TILE_LENGTH_Z := 90.0
## Dash/gap pairs on the bus lane's left edge per repeat (dash = gap).
const DASH_PAIRS := 10
const LANE_LINE_PX := 8
const EDGE_LINE_PX := 18
const CURB_LINE_PX := 28
## Stencil width as a share of its lane's width.
const BUS_STENCIL_FILL := 0.6
const BIKE_STENCIL_FILL := 0.7

## Ground beyond the buildings.
const SIDEWALK := Color("#0e1626")
## Paved sidewalk between the road edge and the building line: grey slabs
## with joints and a few hairline cracks.
const PAVEMENT := Color("#3d4351")
const PAVEMENT_JOINT := Color("#2f3441")
const PAVEMENT_CRACK := Color("#262b36")
## Transverse slab joints this far apart along the road (z units).
const SLAB_LENGTH_Z := 4.5
const JOINT_PX := 6
const CRACKS_PER_SIDE := 14
const EDGE_LINE := Color("#090f19")
const PLAIN_LANE := Color("#121d31")
const BUS_LANE := Color("#561224")
const BIKE_LANE := Color("#5a7619")
const PAINT := Color("#898e98")

var _image: Image
var _left: int
var _height: int
var _scale: float = TILE_SCALE


func _initialize() -> void:
	var config: Resource = load(CONFIG_SCRIPT).new()
	_left = int(config.road_edge_left_x) - TILE_MARGIN_PX
	var right := int(config.road_edge_right_x) + TILE_MARGIN_PX
	_height = int(round(TILE_LENGTH_Z * config.road_tile_px_per_z * _scale))
	_image = Image.create(_px(right - _left), _height, false, Image.FORMAT_RGBA8)
	_image.fill(SIDEWALK)

	var road_left := int(config.lane_road_left)
	var bus_left := int(config.lane_bus_left)
	var bus_right := int(config.lane_bus_right)
	var bike_right := int(config.lane_bike_right)
	var curb := int(config.lane_curb_x)

	# Fills, left to right. Pavement runs from each road edge out to where the
	# buildings stand; beyond that the base colour is the ground behind them.
	_pavement(int(config.road_edge_left_x), road_left - EDGE_LINE_PX / 2, 1)
	_pavement(curb + CURB_LINE_PX / 2, int(config.road_edge_right_x), 2)
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
		_image.fill_rect(Rect2i(_px(bus_left - LANE_LINE_PX / 2 - _left), i * 2 * dash,
				_px(LANE_LINE_PX), dash), PAINT)

	_stencil(BUS_STENCIL_PATH, (bus_left + bus_right) * 0.5,
			(bus_right - bus_left) * BUS_STENCIL_FILL, _height * 0.5)
	for row_share in [0.25, 0.75]:
		_stencil(BIKE_STENCIL_PATH, (bus_right + bike_right) * 0.5,
				(bike_right - bus_right) * BIKE_STENCIL_FILL, _height * row_share)

	var err := _image.save_png(OUT_PATH)
	print("road tile -> %s (%s) %s" % [OUT_PATH, error_string(err), _image.get_size()])
	quit(0 if err == OK else 1)


## Road px (relative to the tile's left edge) to raster px.
func _px(road_px: float) -> int:
	return int(round(road_px * _scale))


## Fills road x range [x0, x1) down the whole tile.
func _fill(x0: int, x1: int, color: Color) -> void:
	_image.fill_rect(Rect2i(_px(x0 - _left), 0, _px(x1) - _px(x0), _height), color)


## Grey slabs over road x range [x0, x1): a lengthwise joint down the middle,
## transverse joints every SLAB_LENGTH_Z, and seeded hairline cracks.
func _pavement(x0: int, x1: int, seed_value: int) -> void:
	_fill(x0, x1, PAVEMENT)
	var mid := (x0 + x1) / 2
	_fill(mid - JOINT_PX / 2, mid + JOINT_PX / 2, PAVEMENT_JOINT)
	var slabs := int(round(TILE_LENGTH_Z / SLAB_LENGTH_Z))
	var joint_rows := maxi(_px(JOINT_PX), 1)
	for i in slabs:
		_image.fill_rect(Rect2i(_px(x0 - _left), i * _height / slabs, _px(x1) - _px(x0), joint_rows),
				PAVEMENT_JOINT)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in CRACKS_PER_SIDE:
		var point := Vector2i(rng.randi_range(_px(x0 - _left) + 4, _px(x1 - _left) - 4),
				rng.randi_range(0, _height - 80))
		for segment in rng.randi_range(3, 6):
			var next := point + Vector2i(rng.randi_range(-14, 14), rng.randi_range(6, 22))
			next.x = clampi(next.x, _px(x0 - _left) + 1, _px(x1 - _left) - 2)
			_line(point, next, PAVEMENT_CRACK)
			point = next


## One-pixel Bresenham line.
func _line(a: Vector2i, b: Vector2i, color: Color) -> void:
	var d := (b - a).abs()
	var step := Vector2i(1 if b.x > a.x else -1, 1 if b.y > a.y else -1)
	var err := d.x - d.y
	var p := a
	while true:
		if p.y >= 0 and p.y < _height:
			_image.set_pixelv(p, color)
		if p == b:
			break
		var e2 := err * 2
		if e2 > -d.y:
			err -= d.y
			p.x += step.x
		if e2 < d.x:
			err += d.x
			p.y += step.y


## Blends a stencil PNG, scaled to `width_px` wide, centred at road x / tile row.
func _stencil(path: String, centre_x: float, width_px: float, centre_row: float) -> void:
	var art := Image.load_from_file(path)
	art.convert(Image.FORMAT_RGBA8)
	var scale := width_px * _scale / art.get_width()
	var size := Vector2i(int(round(art.get_width() * scale)), int(round(art.get_height() * scale)))
	art.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	var dst := Vector2i(_px(centre_x - _left) - size.x / 2, int(round(centre_row - size.y * 0.5)))
	_image.blend_rect(art, Rect2i(Vector2i.ZERO, size), dst)

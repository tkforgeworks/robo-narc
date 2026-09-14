extends GutTest

const TILE_ROWS := 1350
const RASTER_SCALE := 0.5

var _config: TuningConfig
var _surface: RoadSurface


func before_each() -> void:
	_config = TuningConfig.new()
	_surface = RoadSurface.new()
	_surface.config = _config
	var width := int(_surface.tile_span() * RASTER_SCALE)
	_surface.tile = ImageTexture.create_from_image(Image.create(width, TILE_ROWS, false, Image.FORMAT_RGBA8))
	add_child_autofree(_surface)


func _frac(v: float) -> float:
	return fposmod(v, 1.0)


func test_tile_length_comes_from_rows_per_z_at_the_raster_scale() -> void:
	assert_almost_eq(_surface.tile_length_z(), TILE_ROWS / (_config.road_tile_px_per_z * RASTER_SCALE), 0.01)


func test_pattern_slides_toward_the_bus_and_repeats_every_tile_length() -> void:
	var period := _surface.tile_length_z()
	var mark := _frac(_surface.tile_v(20.0))
	_surface.scroll(1.0, 5.0)
	assert_almost_eq(_frac(_surface.tile_v(15.0)), mark, 0.0001,
			"after 5 units of travel the same rows sit 5 units nearer")
	_surface.scroll(1.0, period)
	assert_almost_eq(_frac(_surface.tile_v(15.0)), mark, 0.0001,
			"one full tile later the pattern is identical")


func test_far_rows_sit_higher_in_the_tile_and_v_stays_positive() -> void:
	assert_gt(_surface.tile_v(0.0), _surface.tile_v(50.0))
	assert_gt(_surface.tile_v(RoadSurface.FAR_Z), 0.0)

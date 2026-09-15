extends GutTest

var _config: TuningConfig
var _strip: BuildingStrip


func before_each() -> void:
	_config = TuningConfig.new()
	_strip = _make_strip(BuildingStrip.RoadSide.LEFT)


func _make_strip(side: BuildingStrip.RoadSide) -> BuildingStrip:
	var strip := BuildingStrip.new()
	strip.config = _config
	strip.side = side
	strip.rng_seed = 7
	add_child_autofree(strip)
	return strip


func _sprites() -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	for child in _strip.get_children():
		if child is Sprite2D:
			sprites.append(child)
	sprites.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool:
		return float(a.get_meta("z")) < float(b.get_meta("z")))
	return sprites


func _zs() -> Array:
	return _sprites().map(func(s: Sprite2D) -> float: return float(s.get_meta("z")))


func test_road_is_lined_with_buildings_from_the_start() -> void:
	var sprites := _sprites()
	assert_gt(sprites.size(), 3)
	assert_lt(float(sprites[0].get_meta("z")), 0.0, "the nearest building starts behind the bus line")
	assert_gt(_strip._next_z(sprites[-1]), _config.z_max, "the row covers the road to the horizon")
	assert_lte(float(sprites[-1].get_meta("z")), _config.z_max, "nothing waits invisibly past it")


func test_neighbours_butt_up_footprint_plus_gap_apart() -> void:
	var sprites := _sprites()
	for i in sprites.size() - 1:
		var expected := float(sprites[i].get_meta("z")) + _strip.footprint_z(sprites[i].texture) + _config.building_gap_z
		assert_almost_eq(float(sprites[i + 1].get_meta("z")), expected, 0.001, "building %d" % i)


func test_every_building_shares_one_pixel_scale() -> void:
	assert_almost_eq(_strip.pixel_scale(), 0.7, 0.0001, "700 px for 1000 px art")
	for sprite in _sprites():
		var z := float(sprite.get_meta("z"))
		var expected := _strip.pixel_scale() * Perspective.scale_at(z, _config)
		assert_almost_eq(sprite.scale.x, expected, 0.0001)
		assert_almost_eq(sprite.scale.y, expected, 0.0001)
	var wide := ImageTexture.create_from_image(Image.create(400, 200, false, Image.FORMAT_RGBA8))
	assert_almost_eq(_strip.footprint_z(wide), 400.0 * 0.7 / _config.building_footprint_px_per_z, 0.0001)


func test_road_facing_corner_stands_on_the_edge() -> void:
	for sprite in _sprites():
		var size := sprite.texture.get_size()
		assert_eq(sprite.offset, Vector2(-size.x, -size.y), "left side: right edge on the road")
	_strip = _make_strip(BuildingStrip.RoadSide.RIGHT)
	for sprite in _sprites():
		var size := sprite.texture.get_size()
		assert_eq(sprite.offset, Vector2(0.0, -size.y), "right side: left edge on the road")


func test_scrolling_keeps_the_road_lined() -> void:
	var before := _strip.building_count()
	_strip.scroll(1.0, 15.0)
	var zs := _zs()
	assert_between(_strip.building_count(), before - 3, before + 3)
	assert_lt(zs[0], 0.0)
	assert_gt(_strip._next_z(_sprites()[-1]), _config.z_max, "still covered to the horizon")
	for i in zs.size() - 1:
		assert_gt(zs[i + 1], zs[i], "still in order after a scroll")

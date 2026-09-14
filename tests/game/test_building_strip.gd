extends GutTest

var _config: TuningConfig
var _strip: BuildingStrip


func before_each() -> void:
	_config = TuningConfig.new()
	_strip = BuildingStrip.new()
	_strip.config = _config
	_strip.rng_seed = 7
	add_child_autofree(_strip)


func _zs() -> Array:
	var zs: Array = []
	for child in _strip.get_children():
		if child is Sprite2D:
			zs.append(float(child.get_meta("z")))
	zs.sort()
	return zs


func test_road_is_lined_with_buildings_from_the_start() -> void:
	var zs := _zs()
	var expected := int((_config.z_max - BuildingStrip.DESPAWN_Z) / _config.building_gap_z)
	assert_between(zs.size(), expected - 1, expected + 2)
	assert_lt(zs[0], _config.building_gap_z, "the nearest building starts beside the bus")
	assert_gte(zs[-1], _config.z_max, "the farthest waits at the horizon")
	for i in zs.size() - 1:
		assert_almost_eq(zs[i + 1] - zs[i], _config.building_gap_z, 0.001)


func test_scrolling_keeps_the_road_lined() -> void:
	var before := _strip.building_count()
	_strip.scroll(1.0, _config.building_gap_z * 3.0)
	var zs := _zs()
	assert_between(_strip.building_count(), before - 1, before + 1)
	assert_lt(zs[0], _config.building_gap_z)
	assert_gte(zs[-1], _config.z_max)

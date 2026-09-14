extends GutTest

var _config: TuningConfig
var _zones: BusStopZones


func before_each() -> void:
	_config = TuningConfig.new()
	_zones = BusStopZones.new()
	_zones.config = _config
	add_child_autofree(_zones)


func test_each_zone_gets_a_shelter_that_leaves_with_it() -> void:
	_zones.spawn_zone(60.0, _config.bus_stop_zone_length)
	_zones.spawn_zone(90.0, _config.bus_stop_zone_length)
	assert_eq(_zones.shelter_count(), 2)
	# Scroll the first zone past the despawn line; the second stays.
	_zones.scroll(1.0, 60.0 + _config.bus_stop_zone_length + 30.0)
	assert_eq(_zones.zones.size(), 1)
	assert_eq(_zones.shelter_count(), 1)
	_zones.clear()
	assert_eq(_zones.shelter_count(), 0)


func test_shelter_ground_line_aims_at_the_vanishing_point_with_upright_poles() -> void:
	_zones.spawn_zone(12.0, _config.bus_stop_zone_length)
	await get_tree().process_frame
	var shelter: Sprite2D = null
	for child in _zones.get_children():
		if child is Sprite2D:
			shelter = child
	var ground := shelter.transform.basis_xform(BusStopZones.ART_GROUND_DIR).normalized()
	var to_vanishing := (Vector2(_config.vanishing_point_x, _config.horizon_y)
			- shelter.position).normalized()
	assert_almost_eq(ground.cross(to_vanishing), 0.0, 0.01, "ground line points at the vanishing point")
	var up := shelter.transform.basis_xform(Vector2.UP).normalized()
	assert_almost_eq(up.x, 0.0, 0.001, "poles stay vertical")


func test_shelter_shrinks_with_distance_and_hides_when_art_is_off() -> void:
	_zones.spawn_zone(10.0, _config.bus_stop_zone_length)
	_zones.spawn_zone(80.0, _config.bus_stop_zone_length)
	await get_tree().process_frame
	var sprites: Array[Sprite2D] = []
	for child in _zones.get_children():
		if child is Sprite2D:
			sprites.append(child)
	assert_eq(sprites.size(), 2)
	assert_gt(sprites[0].scale.y, sprites[1].scale.y, "nearer shelter draws larger")
	assert_true(sprites[0].visible)
	_zones.art_visible = false
	assert_false(sprites[0].visible)
	assert_false(sprites[1].visible)

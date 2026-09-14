extends GutTest

var _config: TuningConfig
var _markings: RoadMarkings


func before_each() -> void:
	_config = TuningConfig.new()
	_markings = RoadMarkings.new()
	_markings.config = _config
	add_child_autofree(_markings)


func _sorted(values: PackedFloat32Array) -> Array:
	var out := Array(values)
	out.sort()
	return out


func test_stencils_form_a_continuous_stream_that_drifts_without_snapping() -> void:
	var before := _sorted(_markings.stencil_zs(RoadMarkings.Lane.BUS))
	assert_gt(before.size(), 1, "several stencils share the visible road")
	for i in before.size() - 1:
		assert_almost_eq(before[i + 1] - before[i], _config.stencil_period_z, 0.001)
	_markings.scroll(1.0, 3.0)
	var after := _sorted(_markings.stencil_zs(RoadMarkings.Lane.BUS))
	# Every surviving instance moved 3 units closer; none jumped elsewhere.
	for z in after:
		var moved_from: float = z + 3.0
		var matched := before.any(func(b: float) -> bool: return absf(b - moved_from) < 0.001)
		assert_true(matched or moved_from >= _config.z_max,
				"z=%.1f came from a visible instance or the horizon" % z)
	_markings.scroll(1.0, _config.stencil_period_z - 3.0)
	assert_eq(_sorted(_markings.stencil_zs(RoadMarkings.Lane.BUS)), before,
			"one full period later the stream looks identical")


func test_dashes_cover_the_road_at_their_rhythm() -> void:
	var zs := _sorted(_markings.dash_zs())
	var period := _config.lane_dash_length_z + _config.lane_dash_gap_z
	assert_gt(zs.size(), 2)
	for i in zs.size() - 1:
		assert_almost_eq(zs[i + 1] - zs[i], period, 0.001)
	assert_lt(zs[0] + _config.lane_dash_length_z, period, "first dash starts at or before the bus")
	assert_lt(zs[-1], _config.z_max, "last dash starts before the horizon")

extends GutTest


func test_offset_is_zero_at_base_size() -> void:
	assert_eq(Playfield.offset_for(Vector2(1280, 720)), Vector2.ZERO)
	assert_eq(Playfield.gutter_width_for(Vector2(1280, 720)), 0.0)


func test_wide_window_centres_horizontally() -> void:
	assert_eq(Playfield.offset_for(Vector2(1600, 720)), Vector2(160, 0))
	assert_eq(Playfield.gutter_width_for(Vector2(1600, 720)), 160.0)


func test_tall_window_centres_vertically() -> void:
	assert_eq(Playfield.offset_for(Vector2(1280, 900)), Vector2(0, 90))


func test_offset_is_never_negative_and_whole_pixels() -> void:
	assert_eq(Playfield.offset_for(Vector2(1000, 500)), Vector2.ZERO)
	assert_eq(Playfield.offset_for(Vector2(1281, 721)), Vector2.ZERO)


func test_rect_uses_live_viewport() -> void:
	var rect := Playfield.rect(get_viewport())
	assert_eq(rect.size, Playfield.BASE)


func test_letterbox_bars_cover_only_the_gutters() -> void:
	var letterbox := Letterbox.new()
	add_child_autofree(letterbox)
	letterbox.layout_for(Vector2(1600, 720))
	var bars := letterbox.bar_rects()
	assert_eq(bars[0], Rect2(0, 0, 160, 720), "left")
	assert_eq(bars[1], Rect2(1440, 0, 160, 720), "right")
	assert_eq(bars[2], Rect2(), "top hidden")
	assert_eq(bars[3], Rect2(), "bottom hidden")
	letterbox.layout_for(Vector2(1280, 720))
	for bar in letterbox.bar_rects():
		assert_eq(bar, Rect2(), "no bars at 16:9")

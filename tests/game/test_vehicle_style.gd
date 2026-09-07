extends GutTest


func test_default_style_has_centred_plate_and_no_textures() -> void:
	var style := VehicleStyle.make_default("car9")
	assert_eq(style.key, "car9")
	assert_false(style.has_textures())
	assert_null(style.texture_at(0))
	assert_almost_eq(style.plate_rect.get_center().x, 0.5, 0.001)
	assert_gt(style.plate_rect.position.y, 0.6, "plate sits in the lower part of the sprite")


func test_texture_at_wraps_index() -> void:
	var style := VehicleStyle.make_default("car1")
	var a := PlaceholderTexture.get_texture()
	var b := ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGBA8))
	style.textures = [a, b]
	assert_eq(style.texture_at(0), a)
	assert_eq(style.texture_at(1), b)
	assert_eq(style.texture_at(2), a)
	assert_eq(style.texture_at(-1), b)


func test_rects_are_tunable_properties() -> void:
	var names := TunableProperties.names(VehicleStyle.new())
	assert_true(names.has("plate_rect"))
	assert_true(names.has("left_light_rect"))
	assert_true(names.has("right_light_rect"))
	assert_false(names.has("textures"), "runtime textures are not persisted")

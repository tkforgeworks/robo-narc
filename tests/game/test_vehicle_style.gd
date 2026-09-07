extends GutTest


func test_default_style_has_no_textures_or_scene() -> void:
	var style := VehicleStyle.make_default("car9")
	assert_eq(style.key, "car9")
	assert_false(style.has_textures())
	assert_null(style.texture_at(0))
	assert_null(style.scene)


func test_texture_at_wraps_index() -> void:
	var style := VehicleStyle.make_default("car1")
	var a := PlaceholderTexture.get_texture()
	var b := ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGBA8))
	style.textures = [a, b]
	assert_eq(style.texture_at(0), a)
	assert_eq(style.texture_at(1), b)
	assert_eq(style.texture_at(2), a)
	assert_eq(style.texture_at(-1), b)


func test_only_light_rects_are_tunable() -> void:
	var names := TunableProperties.names(VehicleStyle.new())
	assert_true(names.has("left_light_rect"))
	assert_true(names.has("right_light_rect"))
	assert_false(names.has("plate_rect"), "plate placement is authored in the style scene")
	assert_false(names.has("textures"), "runtime textures are not persisted")
	assert_false(names.has("scene"))

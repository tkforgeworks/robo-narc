extends GutTest


func test_texture_is_available_and_square() -> void:
	var texture := PlaceholderTexture.get_texture()
	assert_not_null(texture)
	assert_eq(texture.get_width(), 64)
	assert_eq(texture.get_height(), 64)


func test_generated_fallback_is_checkerboard() -> void:
	var image := PlaceholderTexture._generate().get_image()
	assert_eq(image.get_pixel(0, 0), PlaceholderTexture.PINK)
	assert_eq(image.get_pixel(8, 0), PlaceholderTexture.BLACK)
	assert_eq(image.get_pixel(8, 8), PlaceholderTexture.PINK)


func test_register_use_records_each_name_once() -> void:
	var before := PlaceholderTexture.uses().size()
	PlaceholderTexture.register_use("test_element_a")
	PlaceholderTexture.register_use("test_element_a")
	PlaceholderTexture.register_use("test_element_b")
	assert_eq(PlaceholderTexture.uses().size(), before + 2)
	assert_true(PlaceholderTexture.uses().has("test_element_a"))

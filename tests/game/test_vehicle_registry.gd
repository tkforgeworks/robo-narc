extends GutTest

const TMP_VEHICLES := "user://test_registry_vehicles"


func after_each() -> void:
	var abs_path := ProjectSettings.globalize_path(TMP_VEHICLES)
	if DirAccess.dir_exists_absolute(abs_path):
		for sub in DirAccess.get_directories_at(abs_path):
			for f in DirAccess.get_files_at(abs_path.path_join(sub)):
				DirAccess.remove_absolute(abs_path.path_join(sub).path_join(f))
			DirAccess.remove_absolute(abs_path.path_join(sub))
		DirAccess.remove_absolute(abs_path)


func test_registers_the_four_premade_styles_with_data() -> void:
	var registry := VehicleRegistry.new()
	assert_eq(registry.keys(), PackedStringArray(["car1", "car2", "car3", "car4"]))
	for style in registry.styles:
		assert_eq(style.textures.size(), 6, style.key)
		assert_ne(style.plate_rect, VehicleStyle.new().plate_rect,
				"%s has its own tuned plate rect" % style.key)


func test_random_pick_returns_registered_style_and_valid_colour() -> void:
	var registry := VehicleRegistry.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var seen := {}
	for i in 200:
		var pick := registry.random_style_and_color(rng)
		var style: VehicleStyle = pick["style"]
		assert_true(registry.styles.has(style))
		assert_between(int(pick["color_index"]), 0, style.textures.size() - 1)
		seen[style.key] = true
	assert_eq(seen.size(), 4, "all styles get picked")


func test_drop_in_folder_without_data_gets_default_style_and_warning() -> void:
	var folder := TMP_VEHICLES.path_join("car9")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	image.save_png(folder.path_join("car9-blue.png"))
	var registry := VehicleRegistry.new(TMP_VEHICLES, "res://data/game/vehicle_styles")
	assert_eq(registry.keys(), PackedStringArray(["car9"]))
	assert_eq(registry.styles[0].textures.size(), 1)
	assert_eq(registry.styles[0].plate_rect, VehicleStyle.new().plate_rect, "defaults")


func test_style_provider_interface() -> void:
	var registry := VehicleRegistry.new()
	assert_eq(registry.get_styles().size(), 4)
	assert_true(registry.get_styles()[0] is VehicleStyle)

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


func test_registers_the_four_premade_styles_with_data_and_scenes() -> void:
	var registry := VehicleRegistry.new()
	assert_eq(registry.keys(), PackedStringArray(["car1", "car2", "car3", "car4"]))
	for style in registry.styles:
		assert_eq(style.textures.size(), 6, style.key)
		assert_not_null(style.scene, style.key)
		assert_string_contains(style.scene.resource_path, "vehicles/%s.tscn" % style.key)
		var vehicle: Vehicle = style.scene.instantiate()
		var plate := PlateOverlay.local_rect(vehicle.get_node("PlateArea"))
		assert_gt(plate.size.x, 20.0, "%s has an authored plate" % style.key)
		assert_lt(plate.position.y, 0.0, "%s plate sits above the bumper line" % style.key)
		vehicle.free()


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


func test_drop_in_folder_without_data_gets_defaults_base_scene_and_warnings() -> void:
	var folder := TMP_VEHICLES.path_join("car9")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	image.save_png(folder.path_join("car9-blue.png"))
	var registry := VehicleRegistry.new(TMP_VEHICLES, "res://data/game/vehicle_styles")
	assert_eq(registry.keys(), PackedStringArray(["car9"]))
	assert_eq(registry.styles[0].textures.size(), 1)
	assert_eq(registry.styles[0].left_light_rect, VehicleStyle.new().left_light_rect, "defaults")
	assert_eq(registry.styles[0].scene.resource_path, VehicleRegistry.BASE_SCENE_PATH)


func test_style_provider_interface() -> void:
	var registry := VehicleRegistry.new()
	assert_eq(registry.get_styles().size(), 4)
	assert_true(registry.get_styles()[0] is VehicleStyle)

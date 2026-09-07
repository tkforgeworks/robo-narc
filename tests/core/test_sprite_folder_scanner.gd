extends GutTest

const TMP_DIR := "user://test_scanner"


func before_each() -> void:
	_remove_tmp()


func after_each() -> void:
	_remove_tmp()


func _remove_tmp() -> void:
	var abs_path := ProjectSettings.globalize_path(TMP_DIR)
	if DirAccess.dir_exists_absolute(abs_path):
		for sub in DirAccess.get_directories_at(abs_path):
			for f in DirAccess.get_files_at(abs_path.path_join(sub)):
				DirAccess.remove_absolute(abs_path.path_join(sub).path_join(f))
			DirAccess.remove_absolute(abs_path.path_join(sub))
		for f in DirAccess.get_files_at(abs_path):
			DirAccess.remove_absolute(abs_path.path_join(f))
		DirAccess.remove_absolute(abs_path)


func test_lists_premade_vehicle_folders_and_textures() -> void:
	var subdirs := SpriteFolderScanner.list_subdirs("res://assets/vehicles")
	assert_true(subdirs.has("car1"))
	assert_true(subdirs.has("car4"))
	var textures := SpriteFolderScanner.list_textures("res://assets/vehicles/car1")
	assert_eq(textures.size(), 6, "six colours, svg sources ignored")
	assert_gt(textures[0].get_width(), 100)


func test_import_markers_are_normalized_and_deduplicated() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP_DIR.path_join("car9")))
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	image.save_png(TMP_DIR.path_join("car9/car9-red.png"))
	var marker := FileAccess.open(TMP_DIR.path_join("car9/car9-red.png.import"), FileAccess.WRITE)
	marker.store_string("[remap]")
	marker.close()
	var notes := FileAccess.open(TMP_DIR.path_join("car9/notes.txt"), FileAccess.WRITE)
	notes.store_string("ignored")
	notes.close()
	var paths := SpriteFolderScanner.list_texture_paths(TMP_DIR.path_join("car9"))
	assert_eq(paths.size(), 1)
	assert_true(paths[0].ends_with("car9-red.png"))
	var textures := SpriteFolderScanner.list_textures(TMP_DIR.path_join("car9"))
	assert_eq(textures.size(), 1, "raw file outside res:// loads as an image")
	assert_eq(textures[0].get_width(), 4)


func test_missing_folder_is_empty_not_error() -> void:
	assert_eq(SpriteFolderScanner.list_subdirs("res://nope").size(), 0)
	assert_eq(SpriteFolderScanner.list_textures("res://nope").size(), 0)

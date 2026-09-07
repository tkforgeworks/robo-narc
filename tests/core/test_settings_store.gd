extends GutTest

const TEST_PATH := "user://test_settings.cfg"


func before_each() -> void:
	_remove()


func after_each() -> void:
	_remove()


func _remove() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_defaults_come_from_tuning_config() -> void:
	var config := TuningConfig.new()
	config.volume_music_default = 0.25
	var store := SettingsStore.new(TEST_PATH, config)
	assert_eq(store.master, 1.0)
	assert_eq(store.music, 0.25)
	assert_eq(store.sfx, 1.0)
	assert_eq(store.last_name, "")


func test_round_trip() -> void:
	var store := SettingsStore.new(TEST_PATH)
	store.master = 0.5
	store.sfx = 0.0
	store.last_name = "Ava"
	assert_eq(store.save(), OK)

	var reloaded := SettingsStore.new(TEST_PATH)
	assert_eq(reloaded.master, 0.5)
	assert_eq(reloaded.sfx, 0.0)
	assert_eq(reloaded.music, 0.7, "untouched value keeps its default")
	assert_eq(reloaded.last_name, "Ava")


func test_volumes_are_clamped() -> void:
	var store := SettingsStore.new(TEST_PATH)
	store.master = 4.0
	store.music = -1.0
	assert_eq(store.master, 1.0)
	assert_eq(store.music, 0.0)


func test_missing_file_is_not_an_error() -> void:
	var store := SettingsStore.new(TEST_PATH)
	assert_false(store.read())

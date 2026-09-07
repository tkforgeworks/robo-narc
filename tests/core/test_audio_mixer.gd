extends GutTest

const TEST_SETTINGS := "user://test_mixer_settings.cfg"

var _mixer: AudioMixer


func before_each() -> void:
	var settings := SettingsStore.new(TEST_SETTINGS)
	settings.master = 1.0
	settings.music = 0.5
	settings.sfx = 0.0
	_mixer = AudioMixer.new()
	_mixer.settings = settings
	add_child_autofree(_mixer)


func after_each() -> void:
	for bus in AudioMixer.BUSES:
		_mixer.set_volume(bus, 1.0)
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func test_buses_exist_and_route_to_master() -> void:
	for bus in AudioMixer.BUSES:
		var index := AudioMixer.bus_index(bus)
		assert_ne(index, -1, bus)
	assert_eq(String(AudioServer.get_bus_send(AudioMixer.bus_index("Music"))), "Master")
	assert_eq(String(AudioServer.get_bus_send(AudioMixer.bus_index("SFX"))), "Master")


func test_settings_applied_on_ready() -> void:
	assert_almost_eq(_mixer.get_volume("Master"), 1.0, 0.01)
	assert_almost_eq(_mixer.get_volume("Music"), 0.5, 0.01)
	assert_eq(_mixer.get_volume("SFX"), 0.0, "zero mutes the bus")
	assert_true(AudioServer.is_bus_mute(AudioMixer.bus_index("SFX")))


func test_set_volume_is_case_insensitive_and_clamped() -> void:
	_mixer.set_volume("sfx", 0.25)
	assert_almost_eq(_mixer.get_volume("SFX"), 0.25, 0.01)
	assert_false(AudioServer.is_bus_mute(AudioMixer.bus_index("SFX")))
	_mixer.set_volume("music", 5.0)
	assert_almost_eq(_mixer.get_volume("Music"), 1.0, 0.01)


func test_unknown_bus_is_ignored() -> void:
	_mixer.set_volume("Nope", 0.5)
	assert_eq(_mixer.get_volume("Nope"), 0.0)

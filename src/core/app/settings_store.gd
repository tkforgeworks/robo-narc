class_name SettingsStore
extends RefCounted
## Player preferences persisted in user://settings.cfg: audio volumes (linear
## 0..1) and the last accepted leaderboard name. Defaults come from TuningConfig.

const TAG := "Settings"
const DEFAULT_PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_PLAYER := "player"

var path: String

var master: float:
	set(value):
		master = clampf(value, 0.0, 1.0)
var music: float:
	set(value):
		music = clampf(value, 0.0, 1.0)
var sfx: float:
	set(value):
		sfx = clampf(value, 0.0, 1.0)
var last_name: String = ""


func _init(p_path: String = DEFAULT_PATH, defaults: TuningConfig = null) -> void:
	path = p_path
	var config := defaults if defaults != null else TuningConfig.new()
	master = config.volume_master_default
	music = config.volume_music_default
	sfx = config.volume_sfx_default
	read()


## Loads values from disk over the current ones; missing keys keep their values.
func read() -> bool:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return false
	master = file.get_value(SECTION_AUDIO, "master", master)
	music = file.get_value(SECTION_AUDIO, "music", music)
	sfx = file.get_value(SECTION_AUDIO, "sfx", sfx)
	last_name = file.get_value(SECTION_PLAYER, "last_name", last_name)
	return true


func save() -> Error:
	var file := ConfigFile.new()
	file.set_value(SECTION_AUDIO, "master", master)
	file.set_value(SECTION_AUDIO, "music", music)
	file.set_value(SECTION_AUDIO, "sfx", sfx)
	file.set_value(SECTION_PLAYER, "last_name", last_name)
	var err := file.save(path)
	if err != OK:
		DebugLog.error(TAG, "failed to save %s (error %d)" % [path, err])
	return err

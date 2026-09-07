class_name TuningStore
extends RefCounted
## Persists debug-menu overrides to a ConfigFile under user:// and applies them
## back onto a TuningConfig and any registered style resources.
##
## Layout: `[tuning] <property>=<value>` and `[style.<key>] <property>=<value>`.

const TAG := "TuningStore"
const DEFAULT_PATH := "user://tuning_overrides.cfg"
const SECTION_TUNING := "tuning"
const STYLE_PREFIX := "style."

var path: String


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func exists() -> bool:
	return FileAccess.file_exists(path)


## Writes every exported property of `config` and of each style (a Resource with
## a `key` property) to disk.
func save(config: TuningConfig, styles: Array[Resource] = []) -> Error:
	var file := ConfigFile.new()
	for property_name in TunableProperties.names(config):
		file.set_value(SECTION_TUNING, property_name, config.get(property_name))
	for style in styles:
		var section := STYLE_PREFIX + str(style.get("key"))
		for property_name in TunableProperties.names(style):
			if property_name == "key":
				continue
			file.set_value(section, property_name, style.get(property_name))
	var err := file.save(path)
	if err != OK:
		DebugLog.error(TAG, "failed to save %s (error %d)" % [path, err])
	return err


## Applies stored values onto `config` and matching styles. Unknown properties
## and type mismatches are skipped with a warning. Returns the number applied.
func load_into(config: TuningConfig, styles: Array[Resource] = []) -> int:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return 0
	var applied := 0
	if file.has_section(SECTION_TUNING):
		for property_name in file.get_section_keys(SECTION_TUNING):
			if _apply(config, property_name, file.get_value(SECTION_TUNING, property_name)):
				applied += 1
	for style in styles:
		var section := STYLE_PREFIX + str(style.get("key"))
		if not file.has_section(section):
			continue
		for property_name in file.get_section_keys(section):
			if _apply(style, property_name, file.get_value(section, property_name)):
				applied += 1
	return applied


func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _apply(target: Object, property_name: String, value: Variant) -> bool:
	if not TunableProperties.has(target, property_name):
		DebugLog.warn(TAG, "ignoring unknown override '%s'" % property_name)
		return false
	var current: Variant = target.get(property_name)
	if typeof(current) != typeof(value):
		DebugLog.warn(TAG, "ignoring override '%s': type mismatch" % property_name)
		return false
	target.set(property_name, value)
	return true

class_name TuningService
extends Node
## The project's single autoload, registered as `Tuning`.
##
## Holds the live TuningConfig every node reads, applies saved overrides in debug
## builds, and brokers per-style tunables through a registered provider (any
## object with `get_styles() -> Array[Resource]`, each style having a `key`).
## Tests create their own instance and never touch the autoload.

signal changed(property_name: String)
signal reset
signal style_changed(style_key: String, property_name: String)

const TAG := "Tuning"
const DEFAULTS_PATH := "res://data/core/tuning_defaults.tres"

var config: TuningConfig
## Set before adding to the tree to redirect the override file (tests).
var store_path: String = TuningStore.DEFAULT_PATH
## Set false before adding to the tree to skip reading overrides (tests).
var apply_overrides_on_ready: bool = true

var _store: TuningStore
var _style_provider: Object = null


func _ready() -> void:
	_store = TuningStore.new(store_path)
	load_config(load_defaults())
	if apply_overrides_on_ready and OS.is_debug_build() and _store.exists():
		var applied := _store.load_into(config, get_styles())
		DebugLog.info(TAG, "applied %d override(s) from %s" % [applied, _store.path])


func load_config(new_config: TuningConfig) -> void:
	config = new_config
	for problem in config.validate():
		DebugLog.warn(TAG, "config problem: %s" % problem)
	reset.emit()


func set_value(property_name: String, value: Variant) -> bool:
	if not TunableProperties.has(config, property_name):
		DebugLog.warn(TAG, "no tunable named '%s'" % property_name)
		return false
	config.set(property_name, value)
	changed.emit(property_name)
	return true


## Restores the shipped defaults IN PLACE, so every node that was handed
## `config` keeps a valid reference, then emits `reset`.
func reset_to_defaults() -> void:
	_store.clear()
	TunableProperties.copy_values(load_defaults(), config)
	for problem in config.validate():
		DebugLog.warn(TAG, "config problem: %s" % problem)
	DebugLog.info(TAG, "reset to defaults")
	reset.emit()


## Debug builds only: writes current values (and styles) to the override file.
func save_overrides() -> Error:
	if not OS.is_debug_build():
		return ERR_UNAVAILABLE
	return _store.save(config, get_styles())


func register_style_provider(provider: Object) -> void:
	_style_provider = provider


func get_styles() -> Array[Resource]:
	var styles: Array[Resource] = []
	if _style_provider != null and _style_provider.has_method("get_styles"):
		styles.assign(_style_provider.get_styles())
	return styles


func set_style_value(style_key: String, property_name: String, value: Variant) -> bool:
	for style in get_styles():
		if str(style.get("key")) != style_key:
			continue
		if not TunableProperties.has(style, property_name):
			DebugLog.warn(TAG, "style '%s' has no tunable '%s'" % [style_key, property_name])
			return false
		style.set(property_name, value)
		style_changed.emit(style_key, property_name)
		return true
	DebugLog.warn(TAG, "no style registered with key '%s'" % style_key)
	return false


## A fresh copy of the shipped defaults, never the cached resource.
static func load_defaults() -> TuningConfig:
	var resource := ResourceLoader.load(DEFAULTS_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource is TuningConfig:
		return resource
	DebugLog.error(TAG, "could not load %s; using script defaults" % DEFAULTS_PATH)
	return TuningConfig.new()

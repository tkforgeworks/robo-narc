class_name VehicleRegistry
extends RefCounted
## Discovers vehicle body styles from assets/vehicles/<style>/ and pairs each
## with its VehicleStyle data (or a logged default) and its authored scene
## under scenes/game/vehicles/<style>.tscn (or the base vehicle scene). Also
## serves as the Tuning style provider and the spawner's style source.

const TAG := "Vehicles"
const VEHICLES_DIR := "res://assets/vehicles"
const STYLES_DIR := "res://data/game/vehicle_styles"
const SCENES_DIR := "res://scenes/game/vehicles"
const BASE_SCENE_PATH := "res://scenes/game/vehicle.tscn"

var styles: Array[VehicleStyle] = []

var _vehicles_dir: String
var _styles_dir: String
var _scenes_dir: String


func _init(vehicles_dir: String = VEHICLES_DIR, styles_dir: String = STYLES_DIR,
		scenes_dir: String = SCENES_DIR) -> void:
	_vehicles_dir = vehicles_dir
	_styles_dir = styles_dir
	_scenes_dir = scenes_dir
	scan()


func scan() -> void:
	styles.clear()
	for key in SpriteFolderScanner.list_subdirs(_vehicles_dir):
		var textures := SpriteFolderScanner.list_textures(_vehicles_dir.path_join(key))
		if textures.is_empty():
			DebugLog.warn(TAG, "style folder '%s' has no textures; skipped" % key)
			continue
		var style := _load_style(key)
		style.textures = textures
		style.scene = _load_scene(key)
		styles.append(style)
	DebugLog.info(TAG, "registered %d style(s): %s" % [styles.size(), ", ".join(keys())])


func keys() -> PackedStringArray:
	var result := PackedStringArray()
	for style in styles:
		result.append(style.key)
	return result


func is_empty() -> bool:
	return styles.is_empty()


## Tuning style-provider interface.
func get_styles() -> Array[Resource]:
	var result: Array[Resource] = []
	result.assign(styles)
	return result


## Spawner style-source interface.
func random_style_and_color(rng: RandomNumberGenerator) -> Dictionary:
	if styles.is_empty():
		return {"style": VehicleStyle.make_default("placeholder"), "color_index": 0}
	var style := styles[rng.randi() % styles.size()]
	return {"style": style, "color_index": rng.randi() % style.textures.size()}


func _load_style(key: String) -> VehicleStyle:
	var path := _styles_dir.path_join(key + ".tres")
	if ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is VehicleStyle:
			(resource as VehicleStyle).key = key
			return resource
	DebugLog.warn(TAG, "no style data for '%s' (expected %s); using defaults" % [key, path])
	return VehicleStyle.make_default(key)


func _load_scene(key: String) -> PackedScene:
	var path := _scenes_dir.path_join(key + ".tscn")
	if ResourceLoader.exists(path):
		return load(path)
	DebugLog.warn(TAG, "no scene for '%s' (expected %s); using %s" % [key, path, BASE_SCENE_PATH])
	return load(BASE_SCENE_PATH)

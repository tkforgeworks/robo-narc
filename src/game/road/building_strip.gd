class_name BuildingStrip
extends Node2D
## One side's row of buildings, discovered from assets/roadside/buildings/<side>/
## and cycled in a shuffled order. Road-fixed, so they sweep past at road speed.

enum RoadSide { LEFT, RIGHT }

const BUILDINGS_DIR := "res://assets/roadside/buildings"

@export var side: RoadSide = RoadSide.LEFT
@export var rng_seed: int = 0

var config: TuningConfig
var rng := RandomNumberGenerator.new()

var _textures: Array[Texture2D] = []
var _queue: Array[Texture2D] = []
var _sprites: Array[Sprite2D] = []
var _camera_x: float = 0.0


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if rng_seed != 0:
		rng.seed = rng_seed
	_camera_x = config.lane_bus_center()
	var folder := BUILDINGS_DIR.path_join("left" if side == RoadSide.LEFT else "right")
	_textures = SpriteFolderScanner.list_textures(folder)
	if _textures.is_empty():
		_textures = [PlaceholderTexture.register_use("buildings %s" % RoadSide.keys()[side].to_lower())]
	_fill_to_horizon()


func building_count() -> int:
	return _sprites.size()


func scroll(delta: float, road_speed: float) -> void:
	for sprite in _sprites:
		sprite.set_meta("z", float(sprite.get_meta("z")) - road_speed * delta)
	for i in range(_sprites.size() - 1, -1, -1):
		if float(_sprites[i].get_meta("z")) < -20.0:
			_sprites[i].queue_free()
			_sprites.remove_at(i)
	_fill_to_horizon()
	_project_all()


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	_project_all()


func _fill_to_horizon() -> void:
	var next_z := config.z_max
	if not _sprites.is_empty():
		next_z = float(_sprites.back().get_meta("z")) + config.building_gap_z
	while next_z <= config.z_max + config.building_gap_z:
		_spawn(maxf(next_z, config.z_max))
		next_z += config.building_gap_z


func _spawn(z: float) -> void:
	if _queue.is_empty():
		_queue = _textures.duplicate()
		_queue.shuffle()
	var sprite := Sprite2D.new()
	sprite.texture = _queue.pop_back()
	sprite.centered = false
	var size := Vector2(sprite.texture.get_size())
	sprite.offset = Vector2(-size.x * 0.5, -size.y)
	sprite.set_meta("z", z)
	add_child(sprite)
	_sprites.append(sprite)


func _road_x() -> float:
	if side == RoadSide.LEFT:
		return config.road_edge_left_x - config.building_offset_px
	return config.road_edge_right_x + config.building_offset_px


func _project_all() -> void:
	var road_x := _road_x()
	for sprite in _sprites:
		var z := float(sprite.get_meta("z"))
		var f := Perspective.scale_at(z, config)
		sprite.position = Perspective.project(road_x, z, _camera_x, config)
		sprite.scale = Vector2.ONE * (config.building_height_px / sprite.texture.get_size().y) * f
		sprite.z_index = clampi(int(config.z_max - z), 0, 4000)
		sprite.visible = z <= config.z_max and z > -20.0

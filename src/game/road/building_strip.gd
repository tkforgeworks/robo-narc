class_name BuildingStrip
extends Node2D
## One side's row of buildings, discovered from assets/roadside/buildings/<side>/
## and cycled in a shuffled order. Road-fixed, so they sweep past at road speed.
## Every sprite shares one pixel scale (so short art stays short), stands on
## the road edge by the bottom corner of its road-facing side, and takes up
## as much road as it is wide, so neighbours butt up instead of overlapping.

enum RoadSide { LEFT, RIGHT }

const BUILDINGS_DIR := "res://assets/roadside/buildings"
## Buildings live from here (behind the bus) to the horizon.
const DESPAWN_Z := -20.0
## Art height that `building_height_px` refers to: the tallest buildings.
const REFERENCE_HEIGHT_PX := 1000.0

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
	_prefill_road()
	_fill_to_horizon()
	_project_all()


func building_count() -> int:
	return _sprites.size()


func scroll(delta: float, road_speed: float) -> void:
	for sprite in _sprites:
		sprite.set_meta("z", float(sprite.get_meta("z")) - road_speed * delta)
	for i in range(_sprites.size() - 1, -1, -1):
		if float(_sprites[i].get_meta("z")) < DESPAWN_Z:
			_sprites[i].queue_free()
			_sprites.remove_at(i)
	_fill_to_horizon()
	_project_all()


func set_camera_x(camera_x: float) -> void:
	_camera_x = camera_x
	_project_all()


## Road px per art px at z = 0, the same for every building.
func pixel_scale() -> float:
	return config.building_height_px / REFERENCE_HEIGHT_PX


## How much road (z units) a texture occupies: its full-scale width at the
## tunable px-per-z. The art's side faces are not true depth, so this is a
## density knob rather than geometry.
func footprint_z(texture: Texture2D) -> float:
	return texture.get_size().x * pixel_scale() / config.building_footprint_px_per_z


## Lines the whole visible road at start so the roadside is never empty while
## the first buildings scroll in from the horizon.
func _prefill_road() -> void:
	var z := DESPAWN_Z
	while z < config.z_max:
		z = _next_z(_spawn(z))


## The next building appears the moment its start scrolls inside the horizon,
## so the row always covers the road up to z_max.
func _fill_to_horizon() -> void:
	var next_z := config.z_max
	if not _sprites.is_empty():
		next_z = _next_z(_sprites.back())
	while next_z <= config.z_max:
		next_z = _next_z(_spawn(next_z))


## Where the building after `sprite` starts: past its footprint plus the gap.
func _next_z(sprite: Sprite2D) -> float:
	return float(sprite.get_meta("z")) + footprint_z(sprite.texture) + config.building_gap_z


func _spawn(z: float) -> Sprite2D:
	if _queue.is_empty():
		_queue = _textures.duplicate()
		_queue.shuffle()
	var sprite := Sprite2D.new()
	sprite.texture = _queue.pop_back()
	sprite.centered = false
	var size := Vector2(sprite.texture.get_size())
	# The road-facing side is the right edge of left-side art and the left
	# edge of right-side art; its bottom corner stands on the road edge.
	sprite.offset = Vector2(-size.x if side == RoadSide.LEFT else 0.0, -size.y)
	sprite.set_meta("z", z)
	add_child(sprite)
	_sprites.append(sprite)
	return sprite


func _road_x() -> float:
	if side == RoadSide.LEFT:
		return config.road_edge_left_x - config.building_offset_px
	return config.road_edge_right_x + config.building_offset_px


func _project_all() -> void:
	var road_x := _road_x()
	var px_scale := pixel_scale()
	for sprite in _sprites:
		var z := float(sprite.get_meta("z"))
		var f := Perspective.scale_at(z, config)
		sprite.position = Perspective.project(road_x, z, _camera_x, config)
		sprite.scale = Vector2.ONE * px_scale * f
		sprite.z_index = clampi(int(config.z_max - z), 0, 4000)
		sprite.visible = z <= config.z_max and z > DESPAWN_Z

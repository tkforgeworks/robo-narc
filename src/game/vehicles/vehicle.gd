class_name Vehicle
extends Node2D
## One vehicle ahead of the bus, seen from behind. Lives in road space
## (road_x, z) and is projected to the screen every frame. Carries no
## violation label; ViolationRules judges its VehicleState.

enum Motion { MOVING, STOPPED_IN_ROAD, CURB_PARKED }

const PLATE_CHARS := "ABCDEFGHJKLMNPRSTUVWXYZ"
const CAPTURED_TINT := Color(0.45, 1.0, 0.55)

static var _next_id: int = 1

var id: int = 0
var road_x: float = 0.0
var z: float = 0.0
var motion: Motion = Motion.CURB_PARKED
var own_speed: float = 0.0
var style: VehicleStyle
var color_index: int = 0
var plate_text: String = ""
var captured: bool = false
var target_road_x: float = 0.0
var merging: bool = false
## Injected by the spawner; falls back to the Tuning autoload.
var config: TuningConfig

@onready var _body: Sprite2D = $Body
@onready var _plate: PlateOverlay = $PlateOverlay
@onready var _lights: VehicleLights = $VehicleLights
@onready var _captured_mark: Label = $CapturedMark


## Call before add_child.
func setup(p_road_x: float, p_z: float, p_motion: Motion, p_own_speed: float,
		p_style: VehicleStyle, p_color_index: int) -> void:
	road_x = p_road_x
	target_road_x = p_road_x
	z = p_z
	motion = p_motion
	own_speed = p_own_speed if p_motion == Motion.MOVING else 0.0
	style = p_style
	color_index = p_color_index
	plate_text = _generate_plate_text()


func _ready() -> void:
	id = _next_id
	_next_id += 1
	if config == null:
		config = Tuning.config
	if style == null:
		style = VehicleStyle.make_default("default")
	apply_style()
	_captured_mark.visible = false


func is_stationary() -> bool:
	return motion != Motion.MOVING


func to_state() -> VehicleState:
	return VehicleState.new(id, road_x, z, is_stationary(), style.rear_width_px * 0.5, captured)


## Moves the vehicle by the road's motion relative to its own, re-projects it,
## and returns true once it has passed under the bus.
func advance(delta: float, road_speed: float, camera_x: float) -> bool:
	z -= (road_speed - own_speed) * delta
	if merging:
		road_x = move_toward(road_x, target_road_x, config.merge_lateral_speed * delta)
		if is_equal_approx(road_x, target_road_x):
			merging = false
	refresh(camera_x)
	return z <= config.pass_z


## Re-projects without moving (used when only the camera changed).
func refresh(camera_x: float) -> void:
	position = Perspective.project(road_x, z, camera_x, config)
	scale = Vector2.ONE * Perspective.scale_at(z, config)
	z_index = clampi(int(config.z_max - z), 0, 4000)
	visible = z <= config.z_max and z > -10.0
	_lights.set_motion(motion)


func merge_to(p_road_x: float) -> void:
	target_road_x = p_road_x
	merging = true


func get_plate_rect() -> Rect2:
	return _plate.screen_rect()


func mark_captured() -> void:
	captured = true
	_captured_mark.visible = true
	_plate.modulate = CAPTURED_TINT


## (Re)applies the body style: texture, size, plate placement, light regions.
## Public so live style tuning can refresh vehicles already on the road.
func apply_style() -> void:
	var texture := style.texture_at(color_index)
	if texture == null:
		texture = PlaceholderTexture.register_use("vehicle body")
	_body.texture = texture
	_body.centered = false
	var size := Vector2(texture.get_size())
	_body.scale = Vector2.ONE * (style.rear_width_px / size.x)
	_body.offset = Vector2(-size.x * 0.5, -size.y)
	_plate.apply(style, _body)
	_lights.attach(_body, style, config)
	_lights.set_motion(motion)
	_captured_mark.position = _plate.position + Vector2(0.0, -_captured_mark.size.y)


func _generate_plate_text() -> String:
	var text := ""
	for i in 3:
		text += PLATE_CHARS[randi() % PLATE_CHARS.length()]
	return "%s%03d" % [text, randi() % 1000]

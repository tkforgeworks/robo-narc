class_name CaptureBox
extends Control
## The camera reticle. Deliberately drawn, not an art asset. Moves from the
## named input actions at a per-device speed; its CaptureArea child (an Area2D
## kept the same size) overlaps vehicle plate areas, and a capture press
## reports each overlapped plate with how much of it is inside the box.

signal capture_attempted(hits: Array[PlateHit])

const COLOR_FRAME := Color(1.0, 1.0, 1.0, 0.9)
const COLOR_COOLDOWN := Color(1.0, 0.8, 0.3, 0.9)
const LINE_WIDTH := 3.0
const TICK := 14.0

var config: TuningConfig
var enabled: bool = false
var source: InputSource.Source = InputSource.Source.KEYBOARD

var _cooldown_left: float = 0.0

@onready var _area: OutlinedArea = $CaptureArea
@onready var _shape: CollisionShape2D = $CaptureArea/Shape


func _enter_tree() -> void:
	if config == null:
		config = Tuning.config
	$CaptureArea.config = config


func _ready() -> void:
	size = config.box_size
	_fit_area()
	center_in_playfield()


func center_in_playfield() -> void:
	position = (Playfield.BASE - size) * 0.5


func speed() -> float:
	match source:
		InputSource.Source.TOUCH:
			return config.box_speed_touch
		InputSource.Source.GAMEPAD:
			return config.box_speed_gamepad
	return config.box_speed_keyboard


func screen_rect() -> Rect2:
	return Rect2(global_position, size)


## Every plate the area overlaps right now, with its coverage by the box.
func plate_hits() -> Array[PlateHit]:
	var hits: Array[PlateHit] = []
	var box := screen_rect()
	for area in _area.get_overlapping_areas():
		var vehicle := area.get_parent() as Vehicle
		if vehicle != null and area == vehicle.plate_area:
			hits.append(PlateHit.new(vehicle, AreaRects.coverage(AreaRects.global_rect(area), box)))
	return hits


func _process(delta: float) -> void:
	if size != config.box_size:
		size = config.box_size
		_fit_area()
		queue_redraw()
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
		queue_redraw()
	if not enabled:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		position += direction * speed() * delta
		var limit := Playfield.BASE - size
		position = position.clamp(Vector2.ZERO, limit)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not event.is_action_pressed("capture"):
		return
	try_capture()
	get_viewport().set_input_as_handled()


## Fires a capture if the cooldown allows. Returns true when it fired.
func try_capture() -> bool:
	if _cooldown_left > 0.0:
		return false
	_cooldown_left = config.capture_cooldown_sec
	capture_attempted.emit(plate_hits())
	queue_redraw()
	return true


func _fit_area() -> void:
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = size * 0.5


func _draw() -> void:
	var color := COLOR_COOLDOWN if _cooldown_left > 0.0 else COLOR_FRAME
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, color, false, LINE_WIDTH)
	for corner: Vector2 in [Vector2.ZERO, Vector2(size.x, 0), Vector2(0, size.y), size]:
		var dx := TICK if corner.x == 0.0 else -TICK
		var dy := TICK if corner.y == 0.0 else -TICK
		draw_line(corner, corner + Vector2(dx, 0), color, LINE_WIDTH + 2.0)
		draw_line(corner, corner + Vector2(0, dy), color, LINE_WIDTH + 2.0)

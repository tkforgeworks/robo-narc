class_name VirtualJoystick
extends Control
## On-screen stick for touch play. Fixed position: the thumb follows the finger
## within `radius()` of the centre and snaps back on release. Feeds the four
## move actions through Input.action_press with analog strength so CaptureBox
## reads the same Input.get_vector as a real stick (spec FR-031, FR-033).

signal direction_changed(direction: Vector2)

const BASE_PATH := "res://assets/ui/joystick-base.png"
const THUMB_PATH := "res://assets/ui/joystick-thumb.png"
const THUMB_RATIO := 0.45
const NO_TOUCH := -1

var direction: Vector2 = Vector2.ZERO

var _touch_index: int = NO_TOUCH

@onready var _base: TextureRect = $Base
@onready var _thumb: TextureRect = $Thumb


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base.texture = _art(BASE_PATH, "touch joystick base")
	_thumb.texture = _art(THUMB_PATH, "touch joystick thumb")
	resized.connect(_layout)
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release()
	elif what == NOTIFICATION_PAUSED or what == NOTIFICATION_EXIT_TREE:
		release()


func _input(event: InputEvent) -> void:
	if is_visible_in_tree():
		feed(event)


## Tracks the one touch that started on the stick. Public so tests can drive it.
func feed(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == NO_TOUCH and get_global_rect().has_point(touch.position):
			_touch_index = touch.index
			_track(touch.position)
		elif not touch.pressed and touch.index == _touch_index:
			release()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_track(drag.position)


func is_held() -> bool:
	return _touch_index != NO_TOUCH


## How far the thumb centre can travel from the stick centre, in pixels.
func radius() -> float:
	return size.x * 0.5 * (1.0 - THUMB_RATIO)


func release() -> void:
	_touch_index = NO_TOUCH
	_set_direction(Vector2.ZERO)


func _track(point: Vector2) -> void:
	var offset := (point - get_global_rect().get_center()) / maxf(radius(), 1.0)
	_set_direction(offset.limit_length(1.0))


func _set_direction(value: Vector2) -> void:
	if value == direction:
		return
	direction = value
	_apply_axis(&"move_left", &"move_right", value.x)
	_apply_axis(&"move_up", &"move_down", value.y)
	_place_thumb()
	direction_changed.emit(direction)


static func _apply_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	elif value > 0.0:
		Input.action_release(negative)
		Input.action_press(positive, value)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _layout() -> void:
	_base.position = Vector2.ZERO
	_base.size = size
	_thumb.size = size * THUMB_RATIO
	_place_thumb()


func _place_thumb() -> void:
	if _thumb == null:
		return
	_thumb.position = (size - _thumb.size) * 0.5 + direction * radius()


static func _art(path: String, element_name: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return PlaceholderTexture.register_use(element_name)

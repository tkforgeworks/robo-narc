class_name VirtualButton
extends Control
## On-screen action button for touch play. Holds `action` for the duration of
## the touch, both in Input's action state and as an InputEventAction pushed
## through the viewport, so `_unhandled_input` handlers such as CaptureBox see
## it exactly like a key press (spec FR-031). Mirrors what TouchScreenButton does.

signal pressed
signal released

const ART_PATH := "res://assets/ui/capture-button.png"
const HELD_TINT := Color(0.7, 0.7, 0.7)
const NO_TOUCH := -1

@export var action: StringName = &"capture"
@export var element_name: String = "touch capture button"

var _touch_index: int = NO_TOUCH

@onready var _icon: TextureRect = $Icon


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(ART_PATH):
		_icon.texture = load(ART_PATH)
	else:
		_icon.texture = PlaceholderTexture.register_use(element_name)
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


## Tracks the one touch that started on the button. Public so tests can drive it.
func feed(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return
	var touch := event as InputEventScreenTouch
	if touch.pressed and _touch_index == NO_TOUCH and get_global_rect().has_point(touch.position):
		_touch_index = touch.index
		_set_held(true)
	elif not touch.pressed and touch.index == _touch_index:
		release()


func is_held() -> bool:
	return _touch_index != NO_TOUCH


func release() -> void:
	if _touch_index == NO_TOUCH:
		return
	_touch_index = NO_TOUCH
	_set_held(false)


func _set_held(held: bool) -> void:
	_icon.modulate = HELD_TINT if held else Color.WHITE
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)
	# push_input dispatches now; Input.parse_input_event would wait for the next
	# frame's flush.
	if is_inside_tree():
		var simulated := InputEventAction.new()
		simulated.action = action
		simulated.pressed = held
		get_viewport().push_input(simulated)
	if held:
		pressed.emit()
	else:
		released.emit()


func _layout() -> void:
	_icon.position = Vector2.ZERO
	_icon.size = size

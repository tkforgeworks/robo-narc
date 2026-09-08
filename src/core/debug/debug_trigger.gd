class_name DebugTrigger
extends Node
## Requests the debug menu from the `debug_menu` action (F1) or a
## three-finger tap on touch. Instanced only in debug builds.

signal toggle_requested

const FINGERS_REQUIRED := 3

var _touches: Dictionary = {}
var _fired: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	feed(event)


## Public so tests can drive it.
func feed(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		toggle_requested.emit()
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = true
		else:
			_touches.erase(touch.index)
		if _touches.size() >= FINGERS_REQUIRED and not _fired:
			_fired = true
			toggle_requested.emit()
		elif _touches.is_empty():
			_fired = false

class_name InputSource
extends Node
## Tracks which kind of device the player last used so touch controls can show
## or hide and the capture box can pick a per-device speed. Gameplay never
## inspects device types itself (spec FR-031).

signal source_changed(source: Source)

enum Source { KEYBOARD, TOUCH, GAMEPAD }

const NONE := -1

@export var joypad_deadzone: float = 0.2

var source: Source = Source.KEYBOARD


func _input(event: InputEvent) -> void:
	feed(event)


## Classifies `event` and updates `source`, emitting `source_changed` on change.
## Public so virtual controls and tests can drive it directly.
func feed(event: InputEvent) -> void:
	var detected := classify(event, joypad_deadzone)
	if detected == NONE or detected == source:
		return
	source = detected as Source
	source_changed.emit(source)


## The Source an event implies, or NONE when the event carries no device signal
## (for example a joypad axis inside the deadzone).
static func classify(event: InputEvent, deadzone: float = 0.2) -> int:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return Source.TOUCH
	if event is InputEventJoypadButton:
		return Source.GAMEPAD
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return Source.GAMEPAD if absf(motion.axis_value) > deadzone else NONE
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		return Source.KEYBOARD
	return NONE

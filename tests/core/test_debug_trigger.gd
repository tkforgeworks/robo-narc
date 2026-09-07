extends GutTest

var _trigger: DebugTrigger


func before_each() -> void:
	_trigger = DebugTrigger.new()
	add_child_autofree(_trigger)
	watch_signals(_trigger)


func _touch(index: int, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	return event


func test_debug_action_toggles() -> void:
	var event := InputEventAction.new()
	event.action = "debug_menu"
	event.pressed = true
	_trigger.feed(event)
	assert_signal_emit_count(_trigger, "toggle_requested", 1)


func test_three_finger_tap_fires_once_until_all_released() -> void:
	_trigger.feed(_touch(0, true))
	_trigger.feed(_touch(1, true))
	assert_signal_not_emitted(_trigger, "toggle_requested")
	_trigger.feed(_touch(2, true))
	assert_signal_emit_count(_trigger, "toggle_requested", 1)
	_trigger.feed(_touch(2, false))
	_trigger.feed(_touch(2, true))
	assert_signal_emit_count(_trigger, "toggle_requested", 1, "held fingers do not refire")
	for i in 3:
		_trigger.feed(_touch(i, false))
	for i in 3:
		_trigger.feed(_touch(i, true))
	assert_signal_emit_count(_trigger, "toggle_requested", 2)

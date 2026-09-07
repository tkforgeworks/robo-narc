extends GutTest

var _source: InputSource


func before_each() -> void:
	_source = InputSource.new()
	add_child_autofree(_source)
	watch_signals(_source)


func test_classifies_each_device() -> void:
	assert_eq(InputSource.classify(InputEventKey.new()), InputSource.Source.KEYBOARD)
	assert_eq(InputSource.classify(InputEventMouseMotion.new()), InputSource.Source.KEYBOARD)
	assert_eq(InputSource.classify(InputEventScreenTouch.new()), InputSource.Source.TOUCH)
	assert_eq(InputSource.classify(InputEventScreenDrag.new()), InputSource.Source.TOUCH)
	assert_eq(InputSource.classify(InputEventJoypadButton.new()), InputSource.Source.GAMEPAD)


func test_joypad_motion_respects_deadzone() -> void:
	var small := InputEventJoypadMotion.new()
	small.axis_value = 0.1
	var large := InputEventJoypadMotion.new()
	large.axis_value = 0.8
	assert_eq(InputSource.classify(small), InputSource.NONE)
	assert_eq(InputSource.classify(large), InputSource.Source.GAMEPAD)


func test_unknown_events_are_ignored() -> void:
	assert_eq(InputSource.classify(InputEventAction.new()), InputSource.NONE)


func test_emits_only_on_change() -> void:
	_source.feed(InputEventKey.new())
	assert_signal_not_emitted(_source, "source_changed", "keyboard is the initial source")
	_source.feed(InputEventScreenTouch.new())
	_source.feed(InputEventScreenTouch.new())
	assert_signal_emit_count(_source, "source_changed", 1)
	assert_eq(_source.source, InputSource.Source.TOUCH)
	_source.feed(InputEventJoypadButton.new())
	assert_signal_emit_count(_source, "source_changed", 2)
	assert_eq(_source.source, InputSource.Source.GAMEPAD)

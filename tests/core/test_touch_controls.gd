extends GutTest

const SCENE: PackedScene = preload("res://scenes/core/touch_controls.tscn")
const WIDE := Vector2(1600, 720)
const BASE := Vector2(1280, 720)

var _controls: TouchControls
var _source: InputSource
var _config: TuningConfig


func before_each() -> void:
	_config = TuningConfig.new()
	_source = InputSource.new()
	add_child_autofree(_source)
	_controls = SCENE.instantiate()
	_controls.config = _config
	add_child_autofree(_controls)
	_controls.bind_input_source(_source)


func after_each() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down", "capture"]:
		Input.action_release(action)


func test_visible_only_for_touch_on_a_playfield_screen() -> void:
	assert_false(_controls.visible, "hidden at start")
	_controls.set_playfield_active(true)
	assert_false(_controls.visible, "keyboard is the source")
	_source.feed(InputEventScreenTouch.new())
	assert_true(_controls.visible, "touch on the playfield")
	_source.feed(InputEventKey.new())
	assert_false(_controls.visible, "keyboard takes over")
	_source.feed(InputEventScreenTouch.new())
	_controls.set_playfield_active(false)
	assert_false(_controls.visible, "menu screens never show them")


func test_wide_viewport_places_controls_in_the_gutters() -> void:
	_controls.layout_for(WIDE)
	assert_true(_controls.in_gutters)
	var joystick := _controls.joystick
	var button := _controls.button
	assert_lte(joystick.position.x + joystick.size.x, 160.0, "joystick inside left gutter")
	assert_gte(button.position.x, 1440.0, "button inside right gutter")
	assert_lte(button.position.x + button.size.x, 1600.0)
	assert_eq(joystick.modulate.a, 1.0)
	assert_gte(joystick.size.x, TouchControls.CONTROL_MIN)


func test_no_gutter_falls_back_to_faded_overlay_on_the_playfield_edges() -> void:
	_controls.layout_for(BASE)
	assert_false(_controls.in_gutters)
	var joystick := _controls.joystick
	var button := _controls.button
	assert_almost_eq(joystick.modulate.a, TouchControls.OVERLAY_ALPHA, 0.001)
	assert_gte(joystick.position.x, 0.0)
	assert_lte(button.position.x + button.size.x, 1280.0)
	assert_eq(joystick.size.x, TouchControls.JOYSTICK_MAX)


func test_gutter_threshold_is_tunable() -> void:
	_config.touch_gutter_min_px = 300.0
	_controls.layout_for(WIDE)
	assert_false(_controls.in_gutters, "160 px gutter is under the raised minimum")
	_config.touch_gutter_min_px = 0.0
	_controls.layout_for(Vector2(1400, 720))
	assert_false(_controls.in_gutters, "60 px cannot fit the 96 px control minimum")


func test_hiding_releases_held_controls() -> void:
	_controls.set_playfield_active(true)
	_source.feed(InputEventScreenTouch.new())
	_controls.layout_for(BASE)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = _controls.button.get_global_rect().get_center()
	_controls.button.feed(touch)
	assert_true(Input.is_action_pressed("capture"))
	_source.feed(InputEventKey.new())
	assert_false(_controls.visible)
	assert_false(Input.is_action_pressed("capture"), "hidden controls let go")

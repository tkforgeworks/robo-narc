extends GutTest

const SCENE: PackedScene = preload("res://scenes/core/virtual_joystick.tscn")
const MOVE_ACTIONS := ["move_left", "move_right", "move_up", "move_down"]
const ORIGIN := Vector2(100, 100)
const SIZE := Vector2(160, 160)

var _stick: VirtualJoystick


func before_each() -> void:
	_stick = SCENE.instantiate()
	_stick.position = ORIGIN
	_stick.size = SIZE
	add_child_autofree(_stick)
	watch_signals(_stick)


func after_each() -> void:
	for action: String in MOVE_ACTIONS:
		Input.action_release(action)


func _centre() -> Vector2:
	return ORIGIN + SIZE * 0.5


func _touch(at: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	event.index = index
	return event


func _drag(at: Vector2, index: int = 0) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.position = at
	event.index = index
	return event


func test_press_at_centre_holds_with_no_direction() -> void:
	_stick.feed(_touch(_centre(), true))
	assert_true(_stick.is_held())
	assert_eq(_stick.direction, Vector2.ZERO)


func test_drag_feeds_move_actions_with_analog_strength() -> void:
	_stick.feed(_touch(_centre(), true))
	_stick.feed(_drag(_centre() + Vector2(_stick.radius() * 0.5, 0.0)))
	assert_almost_eq(_stick.direction.x, 0.5, 0.01)
	assert_almost_eq(Input.get_action_strength("move_right"), 0.5, 0.01)
	assert_eq(Input.get_action_strength("move_left"), 0.0)
	assert_gt(Input.get_vector("move_left", "move_right", "move_up", "move_down").x, 0.0)
	assert_signal_emitted(_stick, "direction_changed")


func test_direction_is_clamped_to_unit_length() -> void:
	_stick.feed(_touch(_centre(), true))
	_stick.feed(_drag(_centre() + Vector2(_stick.radius() * 3.0, _stick.radius() * 3.0)))
	assert_almost_eq(_stick.direction.length(), 1.0, 0.001)
	assert_almost_eq(Input.get_action_strength("move_right"), 0.7071, 0.01)
	assert_almost_eq(Input.get_action_strength("move_down"), 0.7071, 0.01)


func test_release_clears_direction_and_actions() -> void:
	_stick.feed(_touch(_centre(), true))
	_stick.feed(_drag(_centre() + Vector2(0.0, -_stick.radius())))
	assert_almost_eq(Input.get_action_strength("move_up"), 1.0, 0.01)
	_stick.feed(_touch(_centre(), false))
	assert_false(_stick.is_held())
	assert_eq(_stick.direction, Vector2.ZERO)
	assert_eq(Input.get_action_strength("move_up"), 0.0)


func test_touch_outside_the_stick_is_ignored() -> void:
	_stick.feed(_touch(Vector2(10, 10), true))
	assert_false(_stick.is_held())
	_stick.feed(_drag(_centre()))
	assert_eq(_stick.direction, Vector2.ZERO)


func test_only_the_first_finger_steers() -> void:
	_stick.feed(_touch(_centre(), true, 0))
	_stick.feed(_touch(_centre(), true, 1))
	_stick.feed(_drag(_centre() + Vector2(_stick.radius(), 0.0), 1))
	assert_eq(_stick.direction, Vector2.ZERO, "second finger ignored")
	_stick.feed(_touch(_centre(), false, 1))
	assert_true(_stick.is_held(), "releasing the second finger keeps the first")


func test_hiding_releases_the_stick() -> void:
	_stick.feed(_touch(_centre(), true))
	_stick.feed(_drag(_centre() + Vector2(_stick.radius(), 0.0)))
	_stick.visible = false
	assert_false(_stick.is_held())
	assert_eq(Input.get_action_strength("move_right"), 0.0)


func test_uses_placeholder_art_until_assets_exist() -> void:
	assert_true(PlaceholderTexture.uses().has("touch joystick base"))
	assert_true(PlaceholderTexture.uses().has("touch joystick thumb"))

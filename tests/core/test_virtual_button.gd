extends GutTest

const SCENE: PackedScene = preload("res://scenes/core/virtual_button.tscn")
const ORIGIN := Vector2(50, 50)
const SIZE := Vector2(120, 120)

var _button: VirtualButton
var _probe: ActionProbe


## Sees the InputEventAction the button pushes, the way CaptureBox does.
class ActionProbe:
	extends Node
	var presses: int = 0
	var releases: int = 0

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("capture"):
			presses += 1
		elif event.is_action_released("capture"):
			releases += 1


func before_each() -> void:
	_probe = ActionProbe.new()
	add_child_autofree(_probe)
	_button = SCENE.instantiate()
	_button.position = ORIGIN
	_button.size = SIZE
	add_child_autofree(_button)
	watch_signals(_button)


func after_each() -> void:
	Input.action_release("capture")


func _touch(at: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	event.index = index
	return event


func test_touch_inside_presses_the_action_and_pushes_an_event() -> void:
	_button.feed(_touch(ORIGIN + SIZE * 0.5, true))
	assert_true(_button.is_held())
	assert_true(Input.is_action_pressed("capture"))
	assert_signal_emitted(_button, "pressed")
	await get_tree().process_frame
	assert_eq(_probe.presses, 1, "_unhandled_input saw the press")


func test_releasing_the_tracked_finger_releases_the_action() -> void:
	_button.feed(_touch(ORIGIN + SIZE * 0.5, true))
	_button.feed(_touch(ORIGIN + SIZE * 0.5, false))
	assert_false(_button.is_held())
	assert_false(Input.is_action_pressed("capture"))
	assert_signal_emitted(_button, "released")
	await get_tree().process_frame
	assert_eq(_probe.releases, 1)


func test_other_fingers_are_ignored() -> void:
	_button.feed(_touch(Vector2(5, 5), true, 0))
	assert_false(_button.is_held(), "outside")
	_button.feed(_touch(ORIGIN + SIZE * 0.5, true, 1))
	_button.feed(_touch(ORIGIN + SIZE * 0.5, false, 2))
	assert_true(_button.is_held(), "release of an untracked finger keeps the hold")


func test_hiding_releases_the_action() -> void:
	_button.feed(_touch(ORIGIN + SIZE * 0.5, true))
	_button.visible = false
	assert_false(_button.is_held())
	assert_false(Input.is_action_pressed("capture"))


func test_uses_placeholder_art_until_the_asset_exists() -> void:
	assert_true(PlaceholderTexture.uses().has("touch capture button"))

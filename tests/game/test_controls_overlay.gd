extends GutTest

const SCENE: PackedScene = preload("res://scenes/game/controls_overlay.tscn")

var _card: ControlsOverlay


func before_each() -> void:
	_card = SCENE.instantiate()
	add_child_autofree(_card)
	watch_signals(_card)


func test_opt_out_box_only_when_asked_and_reported_on_close() -> void:
	_card.open(false)
	assert_true(_card.is_open())
	assert_false((_card.get_node("%OptOut") as CheckBox).visible)
	_card.close()
	assert_signal_emitted_with_parameters(_card, "dismissed", [false])
	_card.open(true)
	var box: CheckBox = _card.get_node("%OptOut")
	assert_true(box.visible)
	box.button_pressed = true
	_card.close()
	assert_signal_emitted_with_parameters(_card, "dismissed", [true])
	assert_false(_card.is_open())


func test_accept_press_dismisses() -> void:
	_card.open(false)
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	_card._unhandled_input(press)
	assert_false(_card.is_open())
	assert_signal_emitted(_card, "dismissed")


func test_close_when_closed_is_a_no_op() -> void:
	_card.close()
	assert_signal_not_emitted(_card, "dismissed")

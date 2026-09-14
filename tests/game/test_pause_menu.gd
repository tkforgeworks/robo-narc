extends GutTest

const MENU_SCENE: PackedScene = preload("res://scenes/game/pause_menu.tscn")

var _menu: PauseMenu


func before_each() -> void:
	_menu = MENU_SCENE.instantiate()
	add_child_autofree(_menu)
	watch_signals(_menu)


func after_each() -> void:
	get_tree().paused = false


func _press_pause() -> void:
	var event := InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	_menu._unhandled_input(event)


func test_escape_opens_and_pauses_then_resumes() -> void:
	_press_pause()
	assert_true(_menu.is_open())
	assert_true(get_tree().paused)
	assert_signal_emitted(_menu, "opened")
	_press_pause()
	assert_false(_menu.is_open())
	assert_false(get_tree().paused)
	assert_signal_emitted(_menu, "resume_requested")


func test_owner_can_refuse_to_open() -> void:
	_menu.can_open = func() -> bool: return false
	_press_pause()
	assert_false(_menu.is_open())
	assert_false(get_tree().paused)


func test_does_not_open_over_another_pause() -> void:
	get_tree().paused = true
	_press_pause()
	assert_false(_menu.is_open(), "something else owns the pause")


func test_quit_unpauses_and_asks_the_owner_to_leave() -> void:
	_menu.open()
	_menu.quit()
	assert_false(_menu.is_open())
	assert_false(get_tree().paused)
	assert_signal_emitted(_menu, "quit_requested")
	assert_signal_not_emitted(_menu, "resume_requested")

extends GutTest

const FAKE_SCREEN: PackedScene = preload("res://tests/core/helpers/fake_screen.tscn")

var _host: ScreenHost


func before_each() -> void:
	_host = ScreenHost.new()
	add_child_autofree(_host)
	watch_signals(_host)


func test_show_screen_instantiates_and_enters_with_payload() -> void:
	assert_true(_host.show_screen(FAKE_SCREEN, "hello"))
	assert_not_null(_host.current)
	assert_eq(_host.current.entered_payload, "hello")
	assert_eq(_host.current.enter_count, 1)
	assert_signal_emitted(_host, "screen_changed")


func test_navigation_signal_swaps_screen() -> void:
	_host.show_screen(FAKE_SCREEN)
	var first: Node = _host.current
	first.go(FAKE_SCREEN, 42)
	assert_ne(_host.current, first)
	assert_eq(_host.current.entered_payload, 42)
	assert_true(first.is_queued_for_deletion())
	await get_tree().process_frame
	assert_false(is_instance_valid(first), "retired screen is freed")


func test_navigation_from_retired_screen_is_ignored() -> void:
	_host.show_screen(FAKE_SCREEN)
	var first: Node = _host.current
	first.go(FAKE_SCREEN)
	var second: Node = _host.current
	first.go(FAKE_SCREEN, "stale")
	assert_eq(_host.current, second, "double-press must not start a third screen")
	assert_signal_emit_count(_host, "screen_changed", 2)


func test_null_scene_is_rejected() -> void:
	assert_false(_host.show_screen(null))
	assert_null(_host.current)

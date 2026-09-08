extends GutTest

const SCENE: PackedScene = preload("res://scenes/core/splash_screen.tscn")
const NEXT: PackedScene = preload("res://tests/core/helpers/fake_screen.tscn")

var _splash: SplashScreen


func before_each() -> void:
	_splash = SCENE.instantiate()
	_splash.next_screen = NEXT
	_splash.hold_sec = 0.5
	add_child_autofree(_splash)
	watch_signals(_splash)


func test_uses_placeholder_until_a_logo_exists() -> void:
	assert_true(PlaceholderTexture.uses().has("studio logo"))
	assert_not_null((_splash.get_node("%Logo") as TextureRect).texture)


func test_navigates_after_the_hold() -> void:
	_splash._process(0.3)
	assert_signal_not_emitted(_splash, "navigation_requested")
	_splash._process(0.3)
	assert_signal_emitted_with_parameters(_splash, "navigation_requested", [NEXT, null])
	_splash._process(1.0)
	assert_signal_emit_count(_splash, "navigation_requested", 1, "only once")


func test_any_input_skips_when_skippable() -> void:
	var key := InputEventKey.new()
	key.pressed = true
	_splash._unhandled_input(key)
	assert_signal_emitted(_splash, "navigation_requested")


func test_not_skippable_waits_for_the_hold() -> void:
	_splash.skippable = false
	var key := InputEventKey.new()
	key.pressed = true
	_splash._unhandled_input(key)
	assert_signal_not_emitted(_splash, "navigation_requested")

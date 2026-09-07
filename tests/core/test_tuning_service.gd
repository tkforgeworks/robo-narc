extends GutTest

const TEST_PATH := "user://test_tuning_service_overrides.cfg"

var _tuning: TuningService


func before_each() -> void:
	_tuning = TuningService.new()
	_tuning.store_path = TEST_PATH
	_tuning.apply_overrides_on_ready = false
	watch_signals(_tuning)
	add_child_autofree(_tuning)


func after_each() -> void:
	TuningStore.new(TEST_PATH).clear()


func test_ready_loads_defaults() -> void:
	assert_not_null(_tuning.config)
	assert_eq(_tuning.config.shift_length_sec, 90.0)
	assert_signal_emitted(_tuning, "reset")


func test_set_value_updates_and_emits() -> void:
	assert_true(_tuning.set_value("shift_length_sec", 30.0))
	assert_eq(_tuning.config.shift_length_sec, 30.0)
	assert_signal_emitted_with_parameters(_tuning, "changed", ["shift_length_sec"])


func test_set_value_rejects_unknown() -> void:
	assert_false(_tuning.set_value("nope", 1))
	assert_signal_not_emitted(_tuning, "changed")


func test_reset_restores_defaults_in_place() -> void:
	var held := _tuning.config
	_tuning.set_value("points_correct", 999)
	_tuning.reset_to_defaults()
	assert_eq(_tuning.config.points_correct, 100)
	assert_same(_tuning.config, held, "nodes holding the config must not go stale")
	assert_signal_emit_count(_tuning, "reset", 2)


func test_style_provider_round_trip() -> void:
	var provider := FakeProvider.new()
	_tuning.register_style_provider(provider)
	assert_eq(_tuning.get_styles().size(), 1)
	assert_true(_tuning.set_style_value("car1", "plate_rect", Rect2(0.1, 0.2, 0.3, 0.4)))
	assert_eq(provider.style.plate_rect, Rect2(0.1, 0.2, 0.3, 0.4))
	assert_signal_emitted_with_parameters(_tuning, "style_changed", ["car1", "plate_rect"])
	assert_false(_tuning.set_style_value("car9", "plate_rect", Rect2()))
	assert_false(_tuning.set_style_value("car1", "missing", 1))


func test_get_styles_without_provider_is_empty() -> void:
	assert_eq(_tuning.get_styles().size(), 0)


class FakeStyle:
	extends Resource
	@export var key: String = "car1"
	@export var plate_rect: Rect2 = Rect2()


class FakeProvider:
	extends RefCounted
	var style := FakeStyle.new()

	func get_styles() -> Array[Resource]:
		var styles: Array[Resource] = [style]
		return styles


func test_tuned_values_and_export_list_only_changes() -> void:
	var tuning := TuningService.new()
	tuning.apply_overrides_on_ready = false
	add_child_autofree(tuning)
	assert_true(tuning.tuned_values()["tuning"].is_empty())
	assert_string_contains(tuning.export_text(), "(none")
	tuning.set_value("cruise_speed_end", 24.0)
	tuning.set_value("box_size", Vector2(150, 90))
	var values := tuning.tuned_values()
	assert_eq(values["tuning"].keys(), ["cruise_speed_end", "box_size"])
	var text := tuning.export_text()
	assert_string_contains(text, "cruise_speed_end = 24.0")
	assert_string_contains(text, "box_size = Vector2(150, 90)")
	assert_false(text.contains("shift_length_sec"))

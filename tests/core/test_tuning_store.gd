extends GutTest

const TEST_PATH := "user://test_tuning_overrides.cfg"

var _store: TuningStore


func before_each() -> void:
	_store = TuningStore.new(TEST_PATH)
	_store.clear()


func after_each() -> void:
	_store.clear()


func test_round_trips_config_values() -> void:
	var config := TuningConfig.new()
	config.shift_length_sec = 45.0
	config.points_wrong = -5
	config.box_size = Vector2(200.0, 120.0)
	assert_eq(_store.save(config), OK)
	assert_true(_store.exists())

	var loaded := TuningConfig.new()
	var applied := _store.load_into(loaded)
	assert_gt(applied, 50)
	assert_eq(loaded.shift_length_sec, 45.0)
	assert_eq(loaded.points_wrong, -5)
	assert_eq(loaded.box_size, Vector2(200.0, 120.0))


func test_round_trips_style_values() -> void:
	var style := FakeStyle.new()
	style.key = "car1"
	style.plate_rect = Rect2(0.4, 0.8, 0.2, 0.1)
	var styles: Array[Resource] = [style]
	_store.save(TuningConfig.new(), styles)

	var fresh := FakeStyle.new()
	fresh.key = "car1"
	var fresh_styles: Array[Resource] = [fresh]
	_store.load_into(TuningConfig.new(), fresh_styles)
	assert_eq(fresh.plate_rect, Rect2(0.4, 0.8, 0.2, 0.1))


func test_unknown_and_mismatched_keys_are_ignored() -> void:
	var file := ConfigFile.new()
	file.set_value("tuning", "not_a_tunable", 1)
	file.set_value("tuning", "shift_length_sec", "text")
	file.set_value("tuning", "points_correct", 250)
	file.save(TEST_PATH)
	var config := TuningConfig.new()
	assert_eq(_store.load_into(config), 1)
	assert_eq(config.points_correct, 250)
	assert_eq(config.shift_length_sec, 90.0)


func test_save_with_defaults_writes_only_differences() -> void:
	var config := TuningConfig.new()
	config.shift_length_sec = 45.0
	config.points_correct = 250
	var style := FakeStyle.new()
	style.key = "car1"
	style.plate_rect = Rect2(0.4, 0.8, 0.2, 0.1)
	var styles: Array[Resource] = [style]
	var baseline := FakeStyle.new()
	baseline.plate_rect = Rect2(0.4, 0.8, 0.2, 0.1)
	assert_eq(_store.save(config, styles, TuningConfig.new(), {"car1": baseline}), OK)

	var file := ConfigFile.new()
	file.load(TEST_PATH)
	assert_eq(file.get_section_keys("tuning").size(), 2, "only the two changed values")
	assert_true(file.has_section_key("tuning", "shift_length_sec"))
	assert_true(file.has_section_key("tuning", "points_correct"))
	assert_false(file.has_section("style.car1"), "unchanged style is not written")

	var fresh := TuningConfig.new()
	fresh.lane_bus_left = 999.0
	_store.load_into(fresh)
	assert_eq(fresh.lane_bus_left, 999.0, "a later default change is not masked")
	assert_eq(fresh.shift_length_sec, 45.0)


func test_clear_removes_file() -> void:
	_store.save(TuningConfig.new())
	_store.clear()
	assert_false(_store.exists())
	assert_eq(_store.load_into(TuningConfig.new()), 0)


class FakeStyle:
	extends Resource
	@export var key: String = ""
	@export var plate_rect: Rect2 = Rect2()

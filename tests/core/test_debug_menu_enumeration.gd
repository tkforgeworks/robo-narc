extends GutTest

const MENU_SCENE: PackedScene = preload("res://scenes/core/debug_menu.tscn")
const TEST_OVERRIDES := "user://test_debug_menu_overrides.cfg"
const TEST_SETTINGS := "user://test_debug_menu_settings.cfg"

var _tuning: TuningService
var _menu: DebugMenu


func before_each() -> void:
	_tuning = TuningService.new()
	_tuning.store_path = TEST_OVERRIDES
	_tuning.apply_overrides_on_ready = false
	add_child_autofree(_tuning)
	_menu = MENU_SCENE.instantiate()
	_menu.tuning = _tuning
	add_child_autofree(_menu)
	watch_signals(_menu)


func after_each() -> void:
	get_tree().paused = false
	TuningStore.new(TEST_OVERRIDES).clear()
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func test_open_enumerates_every_tunable_and_pauses() -> void:
	_menu.open()
	assert_true(_menu.is_open())
	assert_true(get_tree().paused)
	assert_eq(_menu.control_count(), TunableProperties.names(_tuning.config).size())
	assert_signal_emitted(_menu, "opened")
	_menu.close()
	assert_false(get_tree().paused)
	assert_signal_emitted(_menu, "closed")


func test_close_does_not_unpause_a_tree_it_did_not_pause() -> void:
	get_tree().paused = true
	_menu.open()
	_menu.close()
	assert_true(get_tree().paused)


func test_style_sections_appear_for_registered_styles() -> void:
	var provider := FakeProvider.new()
	_tuning.register_style_provider(provider)
	_menu.open()
	var style_props := TunableProperties.names(provider.style).size() - 1
	assert_eq(_menu.control_count(),
			TunableProperties.names(_tuning.config).size() + style_props)


func test_volume_section_edits_settings_and_emits() -> void:
	_menu.settings = SettingsStore.new(TEST_SETTINGS)
	_menu.open()
	var sliders: Array = []
	_collect(_menu.get_node("%Sections"), HSlider, sliders)
	assert_eq(sliders.size(), 3)
	(sliders[1] as HSlider).value = 0.25
	assert_almost_eq(_menu.settings.music, 0.25, 0.001)
	assert_signal_emitted_with_parameters(_menu, "volume_changed", ["music", 0.25])


func test_registered_action_button_is_replaced_by_label() -> void:
	var hits := [0]
	_menu.register_action("Do thing", func() -> void: hits[0] += 1)
	_menu.register_action("Do thing", func() -> void: hits[0] += 10)
	await get_tree().process_frame
	var buttons: Array = []
	_collect(_menu.get_node("%Actions"), Button, buttons)
	assert_eq(buttons.size(), 1)
	(buttons[0] as Button).pressed.emit()
	assert_eq(hits[0], 10)


func test_reset_rebuilds_with_default_values() -> void:
	_tuning.set_value("shift_length_sec", 20.0)
	_menu.open()
	_tuning.reset_to_defaults()
	assert_eq(_tuning.config.shift_length_sec, 90.0)
	assert_eq(_menu.control_count(), TunableProperties.names(_tuning.config).size())


func _collect(node: Node, type: Variant, out: Array) -> void:
	for child in node.get_children():
		if is_instance_of(child, type):
			out.append(child)
		_collect(child, type, out)


class FakeStyle:
	extends Resource
	@export var key: String = "car1"
	@export var plate_rect: Rect2 = Rect2()
	@export var left_light_rect: Rect2 = Rect2()


class FakeProvider:
	extends RefCounted
	var style := FakeStyle.new()

	func get_styles() -> Array[Resource]:
		var styles: Array[Resource] = [style]
		return styles

extends GutTest

var _factory: TunableControlFactory
var _config: TuningConfig
var _committed: Array = []


func before_each() -> void:
	_factory = TunableControlFactory.new()
	_config = TuningConfig.new()
	_committed.clear()
	_factory.value_committed.connect(func(n: String, v: Variant) -> void: _committed.append([n, v]))


func _property(name: String) -> Dictionary:
	for property in TunableProperties.list(_config):
		if property["name"] == name:
			return property
	return {}


func test_builds_a_control_for_every_tunable() -> void:
	var count := 0
	for property in TunableProperties.list(_config):
		var control := _factory.build(_config, property)
		assert_not_null(control, property["name"])
		assert_false(control is Label, "%s should not be unsupported" % property["name"])
		control.free()
		count += 1
	assert_gt(count, 55)


func test_float_spinbox_uses_range_hint_and_commits_float() -> void:
	var spin: SpinBox = _factory.build(_config, _property("shift_length_sec"))
	add_child_autofree(spin)
	assert_eq(spin.min_value, 10.0)
	assert_eq(spin.max_value, 600.0)
	assert_eq(spin.step, 5.0)
	assert_eq(spin.value, 90.0)
	spin.value = 45.0
	await get_tree().process_frame
	assert_eq(_committed.size(), 1)
	assert_eq(_committed[0][0], "shift_length_sec")
	assert_eq(typeof(_committed[0][1]), TYPE_FLOAT)


func test_int_spinbox_commits_int() -> void:
	var spin: SpinBox = _factory.build(_config, _property("points_correct"))
	add_child_autofree(spin)
	spin.value = 150
	await get_tree().process_frame
	assert_eq(typeof(_committed[0][1]), TYPE_INT)
	assert_eq(_committed[0][1], 150)


func test_bool_checkbox() -> void:
	var box: CheckBox = _factory.build(_config, _property("show_lane_overlay"))
	add_child_autofree(box)
	assert_false(box.button_pressed)
	box.button_pressed = true
	assert_eq(_committed[0], ["show_lane_overlay", true])


func test_vector2_composite_reassembles() -> void:
	var row: HBoxContainer = _factory.build(_config, _property("box_size"))
	add_child_autofree(row)
	var spins: Array = []
	for child in row.get_children():
		if child is SpinBox:
			spins.append(child)
	assert_eq(spins.size(), 2)
	(spins[0] as SpinBox).value = 200.0
	await get_tree().process_frame
	assert_eq(_committed[-1][1], Vector2(200.0, 90.0))


func test_rect2_composite_uses_fine_step_for_normalized_values() -> void:
	var style := VehicleStyle.make_default("car1")
	var property: Dictionary = {}
	for p in TunableProperties.list(style):
		if p["name"] == "plate_rect":
			property = p
	var row: HBoxContainer = _factory.build(style, property)
	add_child_autofree(row)
	var spins: Array = []
	for child in row.get_children():
		if child is SpinBox:
			spins.append(child)
	assert_eq(spins.size(), 4)
	assert_almost_eq((spins[0] as SpinBox).step, 0.005, 0.0001)
	(spins[2] as SpinBox).value = 0.2
	await get_tree().process_frame
	assert_almost_eq((_committed[-1][1] as Rect2).size.x, 0.2, 0.0001)


func test_range_parse_defaults_without_hint() -> void:
	var info := TunableControlFactory.parse_range({"type": TYPE_FLOAT, "hint": 0, "hint_string": ""})
	assert_eq(info["step"], 0.01)
	var int_info := TunableControlFactory.parse_range({"type": TYPE_INT, "hint": 0, "hint_string": ""})
	assert_eq(int_info["step"], 1.0)

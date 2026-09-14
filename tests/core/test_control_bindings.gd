extends GutTest


func test_keyboard_names_come_from_the_input_map() -> void:
	var up := ControlBindings.keyboard("move_up")
	assert_true(up.has("W"), "W is bound: %s" % up)
	assert_true(up.has("Up"), "Up arrow is bound: %s" % up)
	assert_true(ControlBindings.keyboard("capture").has("Space"))
	assert_true(ControlBindings.keyboard("pause").has("Escape"))


func test_describe_lists_keys_then_whatever_gamepad_input_is_bound() -> void:
	assert_string_contains(ControlBindings.describe("capture"), "Space")
	var text := ControlBindings.describe("move_up")
	assert_string_contains(text, "W")
	for pad_name in ControlBindings.gamepad("move_up"):
		assert_string_contains(text, pad_name, "gamepad binding listed after the keys")
	assert_eq(ControlBindings.describe("no_such_action"), "(unbound)")


func test_sheet_has_one_row_per_action_with_live_bindings() -> void:
	var sheet: ControlsSheet = preload("res://scenes/game/controls_sheet.tscn").instantiate()
	add_child_autofree(sheet)
	assert_eq(sheet.row_count(), ControlsSheet.ACTIONS.size())
	assert_string_contains(sheet.binding_text(0), "W")
	assert_string_contains(sheet.binding_text(4), "Space")

extends GutTest


func test_keyboard_names_come_from_the_input_map() -> void:
	var up := ControlBindings.keyboard("move_up")
	assert_true(up.has("W"), "W is bound: %s" % up)
	assert_true(up.has("Up"), "Up arrow is bound: %s" % up)
	assert_true(ControlBindings.keyboard("capture").has("Space"))
	assert_true(ControlBindings.keyboard("pause").has("Escape"))


func test_describe_lists_keys_then_gamepad() -> void:
	var text := ControlBindings.describe("capture")
	assert_string_contains(text, "Space")
	assert_string_contains(text, "A", "gamepad A is bound to capture")
	assert_eq(ControlBindings.describe("no_such_action"), "(unbound)")


func test_sheet_has_one_row_per_action_with_live_bindings() -> void:
	var sheet: ControlsSheet = preload("res://scenes/game/controls_sheet.tscn").instantiate()
	add_child_autofree(sheet)
	assert_eq(sheet.row_count(), ControlsSheet.ACTIONS.size())
	assert_string_contains(sheet.binding_text(0), "W")
	assert_string_contains(sheet.binding_text(4), "Space")

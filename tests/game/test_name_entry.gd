extends GutTest

const SCENE: PackedScene = preload("res://scenes/game/name_entry.tscn")

var _entry: NameEntry


func before_each() -> void:
	_entry = SCENE.instantiate()
	_entry.config = TuningConfig.new()
	_entry.validator = NameValidator.new(ProfanityFilter.new(PackedStringArray(["badword"])))
	add_child_autofree(_entry)
	watch_signals(_entry)


func test_valid_name_submits_cleaned() -> void:
	_entry.prefill("  Ava ")
	_entry.submit()
	assert_signal_emitted_with_parameters(_entry, "name_chosen", ["Ava"])
	_entry.submit()
	assert_signal_emit_count(_entry, "name_chosen", 1, "only once")


func test_invalid_name_shows_message_and_disables_submit() -> void:
	_entry.prefill("Ava1")
	assert_eq(_entry.get_node("%Message").text, "Letters only, A to Z")
	assert_true((_entry.get_node("%SubmitButton") as Button).disabled)
	_entry.submit()
	assert_signal_not_emitted(_entry, "name_chosen")
	_entry.prefill("badword")
	assert_eq(_entry.get_node("%Message").text, "Pick another name")
	_entry.prefill("")
	assert_eq(_entry.get_node("%Message").text, "", "empty field shows no complaint")
	assert_true((_entry.get_node("%SubmitButton") as Button).disabled)


func test_skip_uses_the_default_name() -> void:
	_entry.prefill("whatever!!")
	_entry.skip()
	assert_signal_emitted_with_parameters(_entry, "name_chosen", ["Rookie"])


func test_letter_grid_appears_for_touch_and_gamepad_and_types() -> void:
	var grid: GridContainer = _entry.get_node("%LetterGrid")
	assert_false(grid.visible)
	_entry.set_input_source(InputSource.Source.GAMEPAD)
	assert_true(grid.visible)
	assert_eq(grid.get_child_count(), 27, "26 letters and backspace")
	(grid.get_child(0) as Button).pressed.emit()
	(grid.get_child(21) as Button).pressed.emit()
	(grid.get_child(0) as Button).pressed.emit()
	assert_eq(_entry.current_text(), "AVA")
	(grid.get_child(26) as Button).pressed.emit()
	assert_eq(_entry.current_text(), "AV")
	_entry.set_input_source(InputSource.Source.TOUCH)
	assert_true(grid.visible)
	_entry.set_input_source(InputSource.Source.KEYBOARD)
	assert_false(grid.visible)


func test_grid_respects_the_length_limit() -> void:
	_entry.prefill("abcdefghijkl")
	var grid: GridContainer = _entry.get_node("%LetterGrid")
	(grid.get_child(0) as Button).pressed.emit()
	assert_eq(_entry.current_text(), "abcdefghijkl")

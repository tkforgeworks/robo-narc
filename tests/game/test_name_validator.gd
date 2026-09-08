extends GutTest

var _validator: NameValidator


func before_each() -> void:
	_validator = NameValidator.new(ProfanityFilter.new(PackedStringArray(["badword"])))


func test_accepts_letters_up_to_twelve() -> void:
	assert_true(_validator.validate("Ava").ok)
	assert_true(_validator.validate("abcdefghijkl").ok)
	assert_true(_validator.validate("  Ava  ").ok, "surrounding whitespace ignored")
	assert_eq(NameValidator.clean("  Ava  "), "Ava")


func test_rejects_with_reason_and_message() -> void:
	var empty := _validator.validate("   ")
	assert_eq(empty.reason, NameValidator.Reason.EMPTY)
	assert_eq(empty.message, "Enter a name")
	var long := _validator.validate("abcdefghijklm")
	assert_eq(long.reason, NameValidator.Reason.TOO_LONG)
	assert_false(long.ok)
	for bad: String in ["Ava1", "A va", "Ava!", "Ævа"]:
		assert_eq(_validator.validate(bad).reason, NameValidator.Reason.INVALID_CHARS, bad)
	var profane := _validator.validate("xBadWordx")
	assert_eq(profane.reason, NameValidator.Reason.PROFANE)
	assert_eq(profane.message, "Pick another name")


func test_length_is_checked_before_characters_and_profanity() -> void:
	assert_eq(_validator.validate("badword badword").reason, NameValidator.Reason.TOO_LONG)
	assert_eq(_validator.validate("badword1").reason, NameValidator.Reason.INVALID_CHARS)

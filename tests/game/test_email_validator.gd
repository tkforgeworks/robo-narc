extends GutTest
## EmailValidator on its own, then IdentityValidator, which combines it with
## the name rules into the entry form's verdict.

var _identity: IdentityValidator


func before_each() -> void:
	_identity = IdentityValidator.new(NameValidator.new(ProfanityFilter.new(PackedStringArray(["badword"]))))


func test_accepts_ordinary_addresses_and_normalises_them() -> void:
	for good: String in ["ava@example.com", "a.b+tag@sub.example.co.uk", "  Ava@Example.COM  "]:
		assert_true(EmailValidator.validate(good).ok, good)
	assert_eq(EmailValidator.clean("  Ava@Example.COM  "), "ava@example.com")


func test_rejects_with_reason_and_message() -> void:
	var empty := EmailValidator.validate("  ")
	assert_eq(empty.reason, EmailValidator.Reason.EMPTY)
	assert_eq(empty.message, "Enter an email")
	for bad: String in ["ava", "ava@", "@example.com", "ava@example", "ava@example.c",
			"ava example@x.com", "ava@@example.com", "ava@.com", "ava@example.c0m"]:
		assert_eq(EmailValidator.validate(bad).reason, EmailValidator.Reason.INVALID, bad)
	var long := EmailValidator.validate("a".repeat(250) + "@x.com")
	assert_eq(long.reason, EmailValidator.Reason.TOO_LONG)


func test_blank_form_is_an_anonymous_shift() -> void:
	var result := _identity.validate("", "  ", "")
	assert_true(result.ok)
	assert_true(result.identity.is_anonymous())
	assert_eq(result.identity.display_name(), "")


func test_full_identity_is_cleaned() -> void:
	var result := _identity.validate(" Ava@Example.com ", " Ava ", "k")
	assert_true(result.ok, result.message)
	assert_eq(result.identity.email, "ava@example.com")
	assert_eq(result.identity.first_name, "Ava")
	assert_eq(result.identity.last_initial, "K")
	assert_eq(result.identity.display_name(), "Ava K.")


func test_a_name_needs_an_email() -> void:
	var result := _identity.validate("", "Ava", "K")
	assert_false(result.ok)
	assert_eq(result.message, IdentityValidator.NEEDS_EMAIL)
	assert_null(result.identity)
	assert_eq(_identity.validate("", "", "K").message, IdentityValidator.NEEDS_EMAIL)


func test_first_failing_rule_wins() -> void:
	assert_eq(_identity.validate("nope", "Ava", "K").message, "That doesn't look like an email")
	assert_eq(_identity.validate("ava@example.com", "", "K").message, "Enter your first name")
	assert_eq(_identity.validate("ava@example.com", "Ava1", "K").message, "Letters only, A to Z")
	assert_eq(_identity.validate("ava@example.com", "badword", "K").message, "Pick another name")
	assert_eq(_identity.validate("ava@example.com", "Ava", "").message, "Enter your last initial")
	assert_eq(_identity.validate("ava@example.com", "Ava", "KL").message, "Last initial: one letter")


func test_identity_round_trips_through_dict() -> void:
	var named := PlayerIdentity.named("ava@example.com", "Ava", "K")
	var copy := PlayerIdentity.from_dict(named.to_dict())
	assert_eq(copy.display_name(), "Ava K.")
	assert_false(copy.is_anonymous())
	assert_true(PlayerIdentity.from_dict({}).is_anonymous())

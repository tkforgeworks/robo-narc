extends GutTest

const SCENE: PackedScene = preload("res://scenes/game/identity_entry.tscn")

var _entry: IdentityEntry


func before_each() -> void:
	_entry = SCENE.instantiate()
	_entry.validator = IdentityValidator.new(
			NameValidator.new(ProfanityFilter.new(PackedStringArray(["badword"]))))
	add_child_autofree(_entry)
	watch_signals(_entry)


func _chosen() -> PlayerIdentity:
	return get_signal_parameters(_entry, "identity_chosen")[0]


func test_blank_form_submits_anonymous_once() -> void:
	assert_false((_entry.get_node("%SubmitButton") as Button).disabled)
	_entry.submit()
	assert_signal_emitted(_entry, "identity_chosen")
	assert_true(_chosen().is_anonymous())
	_entry.submit()
	assert_signal_emit_count(_entry, "identity_chosen", 1, "only once")


func test_full_identity_is_cleaned() -> void:
	_entry.set_fields(" Ava@Example.com ", " Ava ", "k")
	assert_eq(_entry.message_text(), "")
	_entry.submit()
	var identity := _chosen()
	assert_eq(identity.email, "ava@example.com")
	assert_eq(identity.first_name, "Ava")
	assert_eq(identity.last_initial, "K")


func test_name_without_email_is_refused_live() -> void:
	_entry.set_fields("", "Ava", "K")
	assert_eq(_entry.message_text(), IdentityValidator.NEEDS_EMAIL)
	assert_true((_entry.get_node("%SubmitButton") as Button).disabled)
	_entry.submit()
	assert_signal_not_emitted(_entry, "identity_chosen")


func test_field_problems_show_messages() -> void:
	_entry.set_fields("nope", "Ava", "K")
	_entry.submit()
	assert_eq(_entry.message_text(), "That doesn't look like an email")
	assert_signal_not_emitted(_entry, "identity_chosen")
	_entry.set_fields("ava@example.com", "Ava1", "K")
	assert_eq(_entry.message_text(), "Letters only, A to Z")
	_entry.set_fields("ava@example.com", "badword", "K")
	assert_eq(_entry.message_text(), "Pick another name")
	_entry.set_fields("ava@example.com", "Ava", "")
	assert_eq(_entry.message_text(), "Enter your last initial")
	_entry.set_fields("", "", "")
	assert_eq(_entry.message_text(), "", "blank form shows no complaint")


func test_email_complaint_waits_until_the_field_is_left() -> void:
	var email: LineEdit = _entry.get_node("%EmailEdit")
	email.grab_focus()
	_entry.set_fields("ava@exam", "Ava", "K")
	assert_eq(_entry.message_text(), "", "still typing the email")
	(_entry.get_node("%FirstNameEdit") as LineEdit).grab_focus()
	assert_eq(_entry.message_text(), "That doesn't look like an email")


func test_play_anonymously_ignores_the_fields() -> void:
	_entry.set_fields("junk", "!!", "")
	_entry.skip()
	assert_true(_chosen().is_anonymous())


func test_field_limits() -> void:
	assert_eq((_entry.get_node("%EmailEdit") as LineEdit).max_length, EmailValidator.MAX_LENGTH)
	assert_eq((_entry.get_node("%FirstNameEdit") as LineEdit).max_length, NameValidator.MAX_LENGTH)
	assert_eq((_entry.get_node("%InitialEdit") as LineEdit).max_length, 1)

class_name IdentityEntry
extends Control
## End-of-shift identity prompt (spec FR-043): email, first name, and last
## initial with inline validation, Submit, and Play anonymously. Keyboard for
## now: touch gets the OS keyboard the fields open; there is no gamepad grid.
## Nothing is prefilled, because the booth is shared.

signal identity_chosen(identity: PlayerIdentity)

## Injectable; defaults to the shipped profanity list.
var validator: IdentityValidator

var _chosen: bool = false

@onready var _email: LineEdit = %EmailEdit
@onready var _first_name: LineEdit = %FirstNameEdit
@onready var _initial: LineEdit = %InitialEdit
@onready var _message: Label = %Message
@onready var _submit_button: Button = %SubmitButton
@onready var _skip_button: Button = %SkipButton


func _ready() -> void:
	if validator == null:
		validator = IdentityValidator.new()
	_email.max_length = EmailValidator.MAX_LENGTH
	_first_name.max_length = NameValidator.MAX_LENGTH
	_initial.max_length = 1
	for edit: LineEdit in [_email, _first_name, _initial]:
		edit.text_changed.connect(func(_text: String) -> void: _refresh())
		edit.text_submitted.connect(func(_text: String) -> void: submit())
		edit.focus_exited.connect(_refresh)
	_submit_button.pressed.connect(submit)
	_skip_button.pressed.connect(skip)
	_refresh()
	_email.grab_focus()


func set_fields(email: String, first_name: String, last_initial: String) -> void:
	_email.text = email
	_first_name.text = first_name
	_initial.text = last_initial
	_refresh()


func message_text() -> String:
	return _message.text


func submit() -> void:
	if _chosen:
		return
	var result := validator.validate(_email.text, _first_name.text, _initial.text)
	if not result.ok:
		_message.text = result.message
		return
	_choose(result.identity)


func skip() -> void:
	if not _chosen:
		_choose(PlayerIdentity.anonymous())


func _choose(identity: PlayerIdentity) -> void:
	_chosen = true
	identity_chosen.emit(identity)


## Submit follows validity; the message waits until the fields have something
## in them, and an email complaint waits until the email field is left.
func _refresh() -> void:
	var result := validator.validate(_email.text, _first_name.text, _initial.text)
	_submit_button.disabled = not result.ok
	var untouched := _email.text.strip_edges().is_empty() \
			and _first_name.text.strip_edges().is_empty() \
			and _initial.text.strip_edges().is_empty()
	var typing_email := _email.has_focus() \
			and result.message == EmailValidator.MESSAGES[EmailValidator.Reason.INVALID]
	_message.text = "" if result.ok or untouched or typing_email else result.message

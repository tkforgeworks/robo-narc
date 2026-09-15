class_name IdentityValidator
extends RefCounted
## The entry form's rules as a whole (spec FR-043): nothing entered is an
## anonymous shift; an email unlocks a name and then requires a first name
## (letter rules plus the profanity filter) and a last initial.

const NEEDS_EMAIL := "Enter an email to use your name"


class Result:
	extends RefCounted
	var ok: bool
	var message: String
	## Null unless ok.
	var identity: PlayerIdentity

	func _init(p_message: String, p_identity: PlayerIdentity) -> void:
		ok = p_identity != null
		message = p_message
		identity = p_identity

	static func accepted(p_identity: PlayerIdentity) -> Result:
		return Result.new("", p_identity)

	static func refused(p_message: String) -> Result:
		return Result.new(p_message, null)


var _names: NameValidator


func _init(names: NameValidator = null) -> void:
	_names = names if names != null else NameValidator.new()


func validate(email: String, first_name: String, last_initial: String) -> Result:
	var clean_email := EmailValidator.clean(email)
	var clean_name := NameValidator.clean(first_name)
	var clean_initial := NameValidator.clean_initial(last_initial)
	if clean_email.is_empty():
		if clean_name.is_empty() and clean_initial.is_empty():
			return Result.accepted(PlayerIdentity.anonymous())
		return Result.refused(NEEDS_EMAIL)
	var email_check := EmailValidator.validate(clean_email)
	if not email_check.ok:
		return Result.refused(email_check.message)
	var name_check := _names.validate(clean_name)
	if not name_check.ok:
		return Result.refused(name_check.message)
	var initial_check := NameValidator.validate_initial(clean_initial)
	if not initial_check.ok:
		return Result.refused(initial_check.message)
	return Result.accepted(PlayerIdentity.named(clean_email, clean_name, clean_initial))

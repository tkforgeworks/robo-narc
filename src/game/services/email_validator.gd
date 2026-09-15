class_name EmailValidator
extends RefCounted
## Basic shape check for a leaderboard email: something before one `@`, a
## domain with a dot and at least two letters after the last dot, no spaces,
## at most 254 characters. Mirrors the CHECK constraint in contracts/supabase.sql.

const MAX_LENGTH := 254

enum Reason { OK, EMPTY, TOO_LONG, INVALID }

const MESSAGES: Dictionary = {
	Reason.OK: "",
	Reason.EMPTY: "Enter an email",
	Reason.TOO_LONG: "Email too long",
	Reason.INVALID: "That doesn't look like an email",
}


class Result:
	extends RefCounted
	var ok: bool
	var reason: EmailValidator.Reason
	var message: String

	func _init(p_reason: EmailValidator.Reason) -> void:
		reason = p_reason
		ok = p_reason == EmailValidator.Reason.OK
		message = EmailValidator.MESSAGES[p_reason]


static var _shape := RegEx.create_from_string("^[^\\s@]+@[^\\s@]+\\.[A-Za-z]{2,}$")


## Surrounding whitespace and case are ignored; use `clean()` for the stored form.
static func validate(email: String) -> Result:
	var text := clean(email)
	if text.is_empty():
		return Result.new(Reason.EMPTY)
	if text.length() > MAX_LENGTH:
		return Result.new(Reason.TOO_LONG)
	if _shape.search(text) == null:
		return Result.new(Reason.INVALID)
	return Result.new(Reason.OK)


static func clean(email: String) -> String:
	return email.strip_edges().to_lower()

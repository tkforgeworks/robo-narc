class_name NameValidator
extends RefCounted
## Leaderboard name rules (spec FR-043): a first name of 1 to 12 letters A-Z in
## either case, nothing else, then the profanity filter; a last initial of
## exactly one letter. Stateless apart from the filter.

const MAX_LENGTH := 12

enum Reason { OK, EMPTY, TOO_LONG, INVALID_CHARS, PROFANE, INITIAL_EMPTY, INITIAL_INVALID }

const MESSAGES: Dictionary = {
	Reason.OK: "",
	Reason.EMPTY: "Enter your first name",
	Reason.TOO_LONG: "12 letters max",
	Reason.INVALID_CHARS: "Letters only, A to Z",
	Reason.PROFANE: "Pick another name",
	Reason.INITIAL_EMPTY: "Enter your last initial",
	Reason.INITIAL_INVALID: "Last initial: one letter",
}


class Result:
	extends RefCounted
	var ok: bool
	var reason: NameValidator.Reason
	var message: String

	func _init(p_reason: NameValidator.Reason) -> void:
		reason = p_reason
		ok = p_reason == NameValidator.Reason.OK
		message = NameValidator.MESSAGES[p_reason]


static var _letters := RegEx.create_from_string("^[A-Za-z]+$")

var _filter: ProfanityFilter


func _init(filter: ProfanityFilter = null) -> void:
	_filter = filter if filter != null else ProfanityFilter.load_default()


## Surrounding whitespace is ignored; use `clean()` to get the accepted form.
func validate(name: String) -> Result:
	var text := clean(name)
	if text.is_empty():
		return Result.new(Reason.EMPTY)
	if text.length() > MAX_LENGTH:
		return Result.new(Reason.TOO_LONG)
	if _letters.search(text) == null:
		return Result.new(Reason.INVALID_CHARS)
	if _filter.contains(text):
		return Result.new(Reason.PROFANE)
	return Result.new(Reason.OK)


## Use `clean_initial()` to get the accepted (upper-case) form.
static func validate_initial(initial: String) -> Result:
	var text := clean_initial(initial)
	if text.is_empty():
		return Result.new(Reason.INITIAL_EMPTY)
	if text.length() != 1 or _letters.search(text) == null:
		return Result.new(Reason.INITIAL_INVALID)
	return Result.new(Reason.OK)


static func clean(name: String) -> String:
	return name.strip_edges()


static func clean_initial(initial: String) -> String:
	return initial.strip_edges().to_upper()

class_name PlayerIdentity
extends RefCounted
## Who a shift belongs to on the shared board: an email (the board's unique
## key, never displayed) with a first name and last initial, or nothing at all
## for an anonymous shift, which the server names "anonymous NN".

var email: String = ""
var first_name: String = ""
var last_initial: String = ""


static func anonymous() -> PlayerIdentity:
	return PlayerIdentity.new()


static func named(p_email: String, p_first_name: String, p_last_initial: String) -> PlayerIdentity:
	var identity := PlayerIdentity.new()
	identity.email = p_email
	identity.first_name = p_first_name
	identity.last_initial = p_last_initial
	return identity


func is_anonymous() -> bool:
	return email.is_empty()


## "Ava K." for a named player; empty for anonymous (the server picks the number).
func display_name() -> String:
	if is_anonymous():
		return ""
	return "%s %s." % [first_name, last_initial]


func to_dict() -> Dictionary:
	return {"email": email, "first_name": first_name, "last_initial": last_initial}


static func from_dict(data: Dictionary) -> PlayerIdentity:
	return named(str(data.get("email", "")), str(data.get("first_name", "")),
			str(data.get("last_initial", "")))

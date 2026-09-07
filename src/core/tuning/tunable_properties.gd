class_name TunableProperties
extends RefCounted
## Enumerates the exported script variables of any object. This is how the debug
## menu, the override store, and the tests discover tunables without a hand-kept
## list (constitution IV).


## Property dictionaries (name, type, hint, hint_string, usage) for every
## `@export` variable declared by the object's script.
static func list(object: Object) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for property in object.get_property_list():
		var usage: int = property["usage"]
		var is_script_var := (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0
		var is_exported := (usage & PROPERTY_USAGE_EDITOR) != 0
		if is_script_var and is_exported:
			result.append(property)
	return result


static func names(object: Object) -> PackedStringArray:
	var result := PackedStringArray()
	for property in list(object):
		result.append(property["name"])
	return result


static func has(object: Object, property_name: String) -> bool:
	return names(object).has(property_name)

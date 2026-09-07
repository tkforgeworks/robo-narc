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


## Same properties, grouped by `@export_group` in declaration order. Each entry
## is `{"name": String, "properties": Array[Dictionary]}`; ungrouped properties
## fall under "General".
static func grouped(object: Object) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var current: Dictionary = {}
	for property in object.get_property_list():
		var usage: int = property["usage"]
		if usage & PROPERTY_USAGE_GROUP:
			current = {"name": property["name"], "properties": [] as Array[Dictionary]}
			groups.append(current)
			continue
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0 or (usage & PROPERTY_USAGE_EDITOR) == 0:
			continue
		if current.is_empty():
			current = {"name": "General", "properties": [] as Array[Dictionary]}
			groups.append(current)
		(current["properties"] as Array[Dictionary]).append(property)
	return groups.filter(func(g: Dictionary) -> bool:
		return not (g["properties"] as Array).is_empty())


## Copies every exported value from `source` onto `target` in place, so nodes
## holding a reference to `target` see the new values.
static func copy_values(source: Object, target: Object) -> void:
	for property_name in names(source):
		if has(target, property_name):
			target.set(property_name, source.get(property_name))


static func names(object: Object) -> PackedStringArray:
	var result := PackedStringArray()
	for property in list(object):
		result.append(property["name"])
	return result


static func has(object: Object, property_name: String) -> bool:
	return names(object).has(property_name)

class_name DebugLog
extends RefCounted
## Tagged, timestamped logging. Static only; never instantiated.
##
## Format: `YYYY-MM-DDTHH:MM:SS [LEVEL] [Tag] message`. `warn` and `error` also
## raise the engine's push_warning / push_error so they show in the editor and
## in exported builds' consoles.

enum Level { INFO, WARN, ERROR }

const LEVEL_NAMES: Dictionary = {
	Level.INFO: "INFO",
	Level.WARN: "WARN",
	Level.ERROR: "ERROR",
}


static func info(tag: String, message: String) -> void:
	print(format(Level.INFO, tag, message))


static func warn(tag: String, message: String) -> void:
	var line := format(Level.WARN, tag, message)
	print(line)
	push_warning(line)


static func error(tag: String, message: String) -> void:
	var line := format(Level.ERROR, tag, message)
	printerr(line)
	push_error(line)


static func format(level: Level, tag: String, message: String) -> String:
	return "%s [%s] [%s] %s" % [timestamp(), LEVEL_NAMES[level], tag, message]


static func timestamp() -> String:
	return Time.get_datetime_string_from_system(false, false)

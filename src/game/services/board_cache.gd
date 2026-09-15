class_name BoardCache
extends RefCounted
## The last top-N the board answered with, in user://board_cache.json, so the
## title and results screens have rows to show while offline.

const TAG := "BoardCache"
const DEFAULT_PATH := "user://board_cache.json"

var path: String
var entries: Array[LeaderboardEntry] = []
## Unix seconds of the answer the entries came from; 0 when never fetched.
var fetched_at: int = 0


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path
	read()


func store(p_entries: Array[LeaderboardEntry], now: int = int(Time.get_unix_time_from_system())) -> void:
	entries = p_entries.duplicate()
	fetched_at = now
	save()


func has_entries() -> bool:
	return not entries.is_empty()


func clear() -> void:
	entries.clear()
	fetched_at = 0
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func read() -> bool:
	entries.clear()
	fetched_at = 0
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		DebugLog.warn(TAG, "%s is not a JSON object; ignoring" % path)
		return false
	var data: Dictionary = json.data
	fetched_at = int(data.get("fetched_at", 0))
	for item: Variant in data.get("entries", []):
		if item is Dictionary:
			entries.append(LeaderboardEntry.from_dict(item))
	return true


func save() -> Error:
	var rows: Array = []
	for entry in entries:
		rows.append(entry.to_dict())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		DebugLog.error(TAG, "cannot write %s (error %d)" % [path, err])
		return err
	file.store_string(JSON.stringify({"fetched_at": fetched_at, "entries": rows}))
	return OK

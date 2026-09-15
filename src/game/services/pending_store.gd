class_name PendingStore
extends RefCounted
## Shifts waiting to reach the board, in user://pending_shifts.json, oldest
## first. Kept across restarts so an offline booth catches up later; rows leave
## only when the board has acknowledged them (spec FR-042).

const TAG := "Pending"
const DEFAULT_PATH := "user://pending_shifts.json"
const MAX_RECORDS := 500

var path: String
var results: Array[ShiftResult] = []


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path
	read()


func append(result: ShiftResult) -> void:
	results.append(result)
	while results.size() > MAX_RECORDS:
		results.pop_front()
	save()


## Drops every shift whose submission id is listed.
func remove(ids: PackedStringArray) -> void:
	if ids.is_empty():
		return
	results = results.filter(func(r: ShiftResult) -> bool: return not ids.has(r.submission_id))
	save()


func has(submission_id: String) -> bool:
	for result in results:
		if result.submission_id == submission_id:
			return true
	return false


func size() -> int:
	return results.size()


func is_empty() -> bool:
	return results.is_empty()


## The oldest `count` shifts, for one batch.
func first(count: int) -> Array[ShiftResult]:
	var batch: Array[ShiftResult] = []
	batch.assign(results.slice(0, count))
	return batch


func clear() -> void:
	results.clear()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func read() -> bool:
	results.clear()
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Array:
		DebugLog.warn(TAG, "%s is not a JSON array; ignoring" % path)
		return false
	for entry: Variant in json.data:
		if entry is Dictionary:
			results.append(ShiftResult.from_dict(entry))
	return true


func save() -> Error:
	var data: Array = []
	for result in results:
		data.append(result.to_dict())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		DebugLog.error(TAG, "cannot write %s (error %d)" % [path, err])
		return err
	file.store_string(JSON.stringify(data))
	return OK

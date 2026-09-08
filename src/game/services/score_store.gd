class_name ScoreStore
extends RefCounted
## Local score history in user://scores.json: newest first, capped, always kept
## regardless of the network (spec FR-042).

const TAG := "Scores"
const DEFAULT_PATH := "user://scores.json"
const MAX_RECORDS := 200

var path: String
var records: Array[ScoreRecord] = []


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path
	read()


func append(result: ShiftResult) -> ScoreRecord:
	var record := ScoreRecord.new(result)
	records.push_front(record)
	if records.size() > MAX_RECORDS:
		records.resize(MAX_RECORDS)
	save()
	return record


## Best scores first; ties keep the newer record first.
func top(count: int) -> Array[ScoreRecord]:
	var sorted := records.duplicate()
	sorted.sort_custom(func(a: ScoreRecord, b: ScoreRecord) -> bool:
		return a.result.score > b.result.score)
	if sorted.size() > count:
		sorted.resize(count)
	return sorted


func scores() -> PackedInt32Array:
	var values := PackedInt32Array()
	for record in records:
		values.append(record.result.score)
	return values


func clear() -> void:
	records.clear()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func read() -> bool:
	records.clear()
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
			records.append(ScoreRecord.from_dict(entry))
	return true


func save() -> Error:
	var data: Array = []
	for record in records:
		data.append(record.to_dict())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		DebugLog.error(TAG, "cannot write %s (error %d)" % [path, err])
		return err
	file.store_string(JSON.stringify(data))
	return OK

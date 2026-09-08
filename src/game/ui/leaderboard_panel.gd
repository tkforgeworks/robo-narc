class_name LeaderboardPanel
extends Control
## Top-N list for the title and results screens. Shows remote entries when the
## shared board answers, the local history otherwise, and never blocks: callers
## show local rows first and swap in remote rows when they arrive (spec FR-040a,
## FR-041).

const UNAVAILABLE_NOTE := "leaderboard unavailable"
const LOCAL_NAME := "---"
const HEADING_REMOTE := "TOP SHIFTS"
const HEADING_LOCAL := "TOP SHIFTS (this machine)"
const HIGHLIGHT := Color(1.0, 0.85, 0.3)

var _highlight_name: String = ""
var _highlight_score: int = 0
var _has_highlight: bool = false

@onready var _heading: Label = %Heading
@onready var _note: Label = %Note
@onready var _rows: VBoxContainer = %Rows


func _ready() -> void:
	_note.visible = false


func show_entries(entries: Array[LeaderboardEntry], note: String = "") -> void:
	_heading.text = HEADING_REMOTE
	_fill(entries, note)


## Local history as rows; records without a name show as `---`.
func show_local(records: Array[ScoreRecord], note: String = "") -> void:
	_heading.text = HEADING_LOCAL
	var entries: Array[LeaderboardEntry] = []
	for i in records.size():
		var result := records[i].result
		var name := result.player_name if not result.player_name.is_empty() else LOCAL_NAME
		entries.append(LeaderboardEntry.new(i + 1, name, result.score))
	_fill(entries, note)


## Marks the first row matching `name` and `score`, now or when rows arrive.
func highlight(name: String, score: int) -> void:
	_highlight_name = name
	_highlight_score = score
	_has_highlight = true
	_apply_highlight()


func row_count() -> int:
	return _rows.get_child_count()


func row_text(index: int) -> String:
	return (_rows.get_child(index) as Label).text


func note_text() -> String:
	return _note.text if _note.visible else ""


func _fill(entries: Array[LeaderboardEntry], note: String) -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_note.text = note
	_note.visible = not note.is_empty()
	if entries.is_empty():
		_add_row("No shifts played yet")
		return
	for entry in entries:
		var row := _add_row("%2d.  %-12s %6d" % [entry.rank, entry.name, entry.score])
		row.set_meta("entry_name", entry.name)
		row.set_meta("entry_score", entry.score)
	_apply_highlight()


func _add_row(text: String) -> Label:
	var row := Label.new()
	row.text = text
	_rows.add_child(row)
	return row


func _apply_highlight() -> void:
	if not _has_highlight:
		return
	for child in _rows.get_children():
		var row := child as Label
		if row.has_meta("entry_name") and row.get_meta("entry_name") == _highlight_name \
				and row.get_meta("entry_score") == _highlight_score:
			row.modulate = HIGHLIGHT
			return

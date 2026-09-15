class_name LeaderboardPanel
extends Control
## Top-N list for the title and results screens with the sync indicator under
## its heading. Callers show the cached board first and swap in fresh rows when
## they arrive, so nothing waits on the network (spec FR-040a, FR-041). Each
## row is rank / name / score in three columns; the top three wear the medal
## variations from the theme.

const UNAVAILABLE_NOTE := "leaderboard unavailable"
const CACHED_NOTE := "showing the last synced board"
const HEADING := "TOP SHIFTS"
const HIGHLIGHT := Color(1.0, 0.85, 0.3)
const MEDALS: Array[StringName] = [&"BoardGold", &"BoardSilver", &"BoardBronze"]
const RANK_WIDTH := 48.0
const SCORE_WIDTH := 96.0

var _highlight_name: String = ""
var _highlight_score: int = 0
var _has_highlight: bool = false

@onready var _heading: Label = %Heading
@onready var _sync: SyncIndicator = %Sync
@onready var _note: Label = %Note
@onready var _rows: VBoxContainer = %Rows


func _ready() -> void:
	_heading.text = HEADING
	_note.visible = false


func show_entries(entries: Array[LeaderboardEntry], note: String = "") -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_note.text = note
	_note.visible = not note.is_empty()
	if entries.is_empty():
		_add_message("No shifts played yet")
		return
	for entry in entries:
		var row := _add_entry(entry)
		row.set_meta("entry_name", entry.name)
		row.set_meta("entry_score", entry.score)
	_apply_highlight()


func show_sync(status: int, pending: int = 0) -> void:
	_sync.show_status(status, pending)


## Marks the first row matching `name` and `score`, now or when rows arrive.
func highlight(name: String, score: int) -> void:
	_highlight_name = name
	_highlight_score = score
	_has_highlight = true
	_apply_highlight()


func row_count() -> int:
	return _rows.get_child_count()


## The row's visible text, columns joined by spaces.
func row_text(index: int) -> String:
	var row := _rows.get_child(index)
	if row is Label:
		return (row as Label).text
	var parts: PackedStringArray = []
	for child in row.get_children():
		parts.append((child as Label).text)
	return " ".join(parts)


## Theme variation the row's labels wear (empty for an ordinary row).
func row_variation(index: int) -> StringName:
	var row := _rows.get_child(index)
	if row is Label:
		return (row as Label).theme_type_variation
	return (row.get_child(0) as Label).theme_type_variation


func note_text() -> String:
	return _note.text if _note.visible else ""


func sync_text() -> String:
	return _sync.status_text()


func _add_message(text: String) -> Label:
	var row := Label.new()
	row.text = text
	_rows.add_child(row)
	return row


func _add_entry(entry: LeaderboardEntry) -> HBoxContainer:
	var row := HBoxContainer.new()
	var variation: StringName = MEDALS[entry.rank - 1] if entry.rank >= 1 and entry.rank <= MEDALS.size() else &""
	var rank := _cell("%d." % entry.rank, variation, HORIZONTAL_ALIGNMENT_RIGHT)
	rank.custom_minimum_size.x = RANK_WIDTH
	row.add_child(rank)
	var name := _cell(entry.name, variation, HORIZONTAL_ALIGNMENT_LEFT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var score := _cell(str(entry.score), variation, HORIZONTAL_ALIGNMENT_RIGHT)
	score.custom_minimum_size.x = SCORE_WIDTH
	row.add_child(score)
	_rows.add_child(row)
	return row


func _cell(text: String, variation: StringName, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	if not variation.is_empty():
		label.theme_type_variation = variation
	return label


func _apply_highlight() -> void:
	if not _has_highlight:
		return
	for child in _rows.get_children():
		var row := child as Control
		if row.has_meta("entry_name") and row.get_meta("entry_name") == _highlight_name \
				and row.get_meta("entry_score") == _highlight_score:
			row.modulate = HIGHLIGHT
			return

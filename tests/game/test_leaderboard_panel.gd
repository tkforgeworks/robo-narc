extends GutTest

const SCENE: PackedScene = preload("res://scenes/game/leaderboard_panel.tscn")

var _panel: LeaderboardPanel


func before_each() -> void:
	_panel = SCENE.instantiate()
	add_child_autofree(_panel)


func _entries() -> Array[LeaderboardEntry]:
	return [LeaderboardEntry.new(1, "Ava", 2450), LeaderboardEntry.new(2, "???", 10)]


func test_shows_remote_entries_with_heading_and_no_note() -> void:
	_panel.show_entries(_entries())
	assert_eq(_panel.row_count(), 2)
	assert_string_contains(_panel.row_text(0), "Ava")
	assert_string_contains(_panel.row_text(0), "2450")
	assert_string_contains(_panel.row_text(1), "???")
	assert_eq(_panel.note_text(), "")
	assert_eq((_panel.get_node("%Heading") as Label).text, LeaderboardPanel.HEADING_REMOTE)


func test_local_fallback_uses_dashes_and_note() -> void:
	var records: Array[ScoreRecord] = []
	var r := ShiftResult.new()
	r.score = 99
	records.append(ScoreRecord.new(r))
	_panel.show_local(records, LeaderboardPanel.UNAVAILABLE_NOTE)
	assert_eq(_panel.row_count(), 1)
	assert_string_contains(_panel.row_text(0), "---")
	assert_eq(_panel.note_text(), LeaderboardPanel.UNAVAILABLE_NOTE)
	assert_eq((_panel.get_node("%Heading") as Label).text, LeaderboardPanel.HEADING_LOCAL)


func test_empty_state() -> void:
	_panel.show_entries([])
	assert_eq(_panel.row_count(), 1)
	assert_string_contains(_panel.row_text(0), "No shifts")


func test_highlight_applies_now_and_to_later_rows() -> void:
	_panel.highlight("Ava", 2450)
	_panel.show_entries(_entries())
	var rows: VBoxContainer = _panel.get_node("%Rows")
	assert_eq((rows.get_child(0) as Label).modulate, LeaderboardPanel.HIGHLIGHT)
	assert_eq((rows.get_child(1) as Label).modulate, Color.WHITE)

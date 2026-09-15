extends GutTest

const SCENE: PackedScene = preload("res://scenes/game/leaderboard_panel.tscn")

var _panel: LeaderboardPanel


func before_each() -> void:
	_panel = SCENE.instantiate()
	add_child_autofree(_panel)


func _entries() -> Array[LeaderboardEntry]:
	return [LeaderboardEntry.new(1, "Ava", 2450, 0.87), LeaderboardEntry.new(2, "???", 10)]


func test_shows_remote_entries_with_heading_and_no_note() -> void:
	_panel.show_entries(_entries())
	assert_eq(_panel.row_count(), 2)
	assert_string_contains(_panel.row_text(0), "Ava")
	assert_string_contains(_panel.row_text(0), "2450")
	assert_string_contains(_panel.row_text(0), "0.87", "F1 column")
	assert_string_contains(_panel.row_text(1), "???")
	assert_true(_panel.row_text(1).ends_with("-"), "unknown F1 shows a dash")
	assert_eq(_panel.header_text(), "NAME POINTS F1")
	assert_eq(_panel.note_text(), "")
	assert_eq((_panel.get_node("%Heading") as Label).text, LeaderboardPanel.HEADING)


func test_note_and_sync_indicator() -> void:
	_panel.show_entries(_entries(), LeaderboardPanel.CACHED_NOTE)
	assert_eq(_panel.note_text(), LeaderboardPanel.CACHED_NOTE)
	_panel.show_sync(LeaderboardService.Status.OFFLINE, 2)
	assert_eq(_panel.sync_text(), "offline, 2 waiting to post")
	var sync: SyncIndicator = _panel.get_node("%Sync")
	assert_eq(sync.dot_color(), SyncIndicator.RED)
	_panel.show_sync(LeaderboardService.Status.SYNCING)
	assert_eq(sync.dot_color(), SyncIndicator.YELLOW)
	_panel.show_sync(LeaderboardService.Status.SYNCED)
	assert_eq(sync.dot_color(), SyncIndicator.GREEN)
	assert_eq(_panel.sync_text(), "board in sync")
	_panel.show_sync(LeaderboardService.Status.DISABLED)
	assert_eq(sync.dot_color(), SyncIndicator.GREY)
	_panel.show_entries(_entries())
	assert_eq(_panel.note_text(), "", "note cleared with the next fill")
	await get_tree().process_frame  # let the replaced rows free


func test_empty_state() -> void:
	_panel.show_entries([])
	assert_eq(_panel.row_count(), 1)
	assert_string_contains(_panel.row_text(0), "No shifts")


func test_highlight_applies_now_and_to_later_rows() -> void:
	_panel.highlight("Ava", 2450)
	_panel.show_entries(_entries())
	var rows: VBoxContainer = _panel.get_node("%Rows")
	assert_eq((rows.get_child(0) as Control).modulate, LeaderboardPanel.HIGHLIGHT)
	assert_eq((rows.get_child(1) as Control).modulate, Color.WHITE)


func test_top_three_wear_medals_and_the_rest_do_not() -> void:
	var entries: Array[LeaderboardEntry] = []
	for i in 4:
		entries.append(LeaderboardEntry.new(i + 1, "P%d" % i, 1000 - i * 10))
	_panel.show_entries(entries)
	assert_eq(_panel.row_variation(0), &"BoardGold")
	assert_eq(_panel.row_variation(1), &"BoardSilver")
	assert_eq(_panel.row_variation(2), &"BoardBronze")
	assert_eq(_panel.row_variation(3), &"")
	assert_string_contains(_panel.row_text(3), "P3")

extends GutTest
## Results screen against a stubbed leaderboard: submit, rank, board, and
## the never-block rule.

const RESULTS_SCENE: PackedScene = preload("res://scenes/screens/results_screen.tscn")
const TEST_SCORES := "user://test_results_lb_scores.json"
const TEST_SETTINGS := "user://test_results_lb_settings.cfg"

var _results: ResultsScreen
var _stubs: Array[LeaderboardTransport] = []


class StubTransport:
	extends LeaderboardTransport
	var calls: int = 0

	func post(_url: String, _headers: PackedStringArray, _body: String, _timeout: float) -> Error:
		busy = true
		calls += 1
		return OK

	func respond(code: int, body: String) -> void:
		busy = false
		completed.emit(HTTPRequest.RESULT_SUCCESS, code, body)


func before_each() -> void:
	_stubs = []
	var config := LeaderboardConfig.new()
	config.base_url = "https://x.supabase.co"
	config.anon_key = "k"
	config.enabled = true
	config.submit_from_editor = true
	_results = RESULTS_SCENE.instantiate()
	_results.config = TuningConfig.new()
	_results.score_store = ScoreStore.new(TEST_SCORES)
	_results.leaderboard_config = config
	var client: LeaderboardClient = _results.get_node("LeaderboardClient")
	client.transport_factory = func() -> LeaderboardTransport:
		var stub := StubTransport.new()
		_stubs.append(stub)
		return stub
	add_child_autofree(_results)
	watch_signals(_results)


func after_each() -> void:
	ScoreStore.new(TEST_SCORES).clear()
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _result(score: int) -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.duration_sec = 90.0
	return r


func _choose(name: String) -> void:
	var entry: NameEntry = _results.get_node("%NameEntry")
	entry.prefill(name)
	entry.submit()


func test_results_show_before_the_network_answers_then_update() -> void:
	_results.enter(_result(2450))
	_choose("Ava")
	var rank: Label = _results.get_node("%RankLabel")
	var note: Label = _results.get_node("%NoteLabel")
	assert_string_contains(rank.text, "Local rank: 1 of 1")
	assert_string_contains(note.text, "submitting")
	var submit: StubTransport = _stubs[1]
	submit.respond(201, "")
	submit.respond(200, "57")
	assert_eq(rank.text, "Global rank: #57")
	assert_eq(note.text, "")
	var record := _results.score_store.records[0]
	assert_true(record.submitted)
	assert_eq(record.remote_rank, 57)
	var fetch: StubTransport = _stubs[0]
	assert_eq(fetch.calls, 1, "board refreshed after the submit")
	fetch.respond(200, '[{"rank":1,"name":"Bo","score":9000},{"rank":57,"name":"Ava","score":2450}]')
	var board: LeaderboardPanel = _results.get_node("%Board")
	assert_eq(board.row_count(), 2)
	assert_eq((board.get_node("%Rows").get_child(1) as Label).modulate, LeaderboardPanel.HIGHLIGHT)


func test_failed_submit_keeps_local_record_and_says_so() -> void:
	_results.enter(_result(10))
	_choose("Ava")
	(_stubs[1] as StubTransport).respond(500, "")
	assert_string_contains((_results.get_node("%NoteLabel") as Label).text, "unavailable")
	assert_string_contains((_results.get_node("%RankLabel") as Label).text, "Local rank")
	assert_eq(_results.score_store.records.size(), 1)
	assert_false(_results.score_store.records[0].submitted)
	(_stubs[0] as StubTransport).respond(503, "")
	var board: LeaderboardPanel = _results.get_node("%Board")
	assert_eq(board.note_text(), LeaderboardPanel.UNAVAILABLE_NOTE)


func test_accepted_name_is_remembered_but_skip_is_not() -> void:
	var settings := SettingsStore.new(TEST_SETTINGS)
	_results.bind_settings(settings)
	_results.enter(_result(5))
	_choose("Ava")
	assert_eq(SettingsStore.new(TEST_SETTINGS).last_name, "Ava")
	(_stubs[1] as StubTransport).respond(201, "")
	(_stubs[1] as StubTransport).respond(200, "1")
	var again: ResultsScreen = RESULTS_SCENE.instantiate()
	again.config = TuningConfig.new()
	again.score_store = ScoreStore.new(TEST_SCORES)
	again.leaderboard_config = LeaderboardConfig.new()
	add_child_autofree(again)
	again.bind_settings(SettingsStore.new(TEST_SETTINGS))
	var entry: NameEntry = again.get_node("%NameEntry")
	assert_eq(entry.current_text(), "Ava", "prefilled from last accepted name")
	again.enter(_result(6))
	entry.skip()
	assert_eq(again.score_store.records[0].result.player_name, "Rookie")
	assert_eq(SettingsStore.new(TEST_SETTINGS).last_name, "Ava", "skip does not overwrite")


func test_leaving_mid_submit_hands_the_client_to_the_root() -> void:
	_results.enter(_result(1))
	_choose("Ava")
	var client: LeaderboardClient = _results.get_node("LeaderboardClient")
	_results.get_node("%TitleButton").pressed.emit()
	assert_signal_emitted(_results, "navigation_requested")
	assert_eq(client.get_parent(), get_tree().root)
	(_stubs[1] as StubTransport).respond(201, "")
	(_stubs[1] as StubTransport).respond(200, "4")
	assert_true(client.is_queued_for_deletion())

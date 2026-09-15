extends GutTest
## Results screen against a stubbed leaderboard service: identity entry,
## posting, receipts, the offline path, and the never-block rule.

const StubTransport := preload("res://tests/game/helpers/stub_transport.gd")
const RESULTS_SCENE: PackedScene = preload("res://scenes/screens/results_screen.tscn")
const PENDING := "user://test_results_pending.json"
const CACHE := "user://test_results_cache.json"
const BOARD := '[{"rank":1,"name":"Bo M.","score":9000},{"rank":2,"name":"Ava K.","score":2450},{"rank":3,"name":"anonymous 07","score":-15}]'

var _results: ResultsScreen
var _service: LeaderboardService
var _stubs: Array = []


func before_each() -> void:
	_stubs = []
	_clear_files()
	_service = _make_service(true)
	_results = RESULTS_SCENE.instantiate()
	_results.config = TuningConfig.new()
	_results.leaderboard = _service
	add_child_autofree(_results)
	watch_signals(_results)


func after_each() -> void:
	_clear_files()


func _clear_files() -> void:
	PendingStore.new(PENDING).clear()
	BoardCache.new(CACHE).clear()


func _make_service(submit_from_editor: bool) -> LeaderboardService:
	var config := LeaderboardConfig.new()
	config.base_url = "https://x.supabase.co"
	config.anon_key = "sb_publishable_k"
	config.enabled = true
	config.submit_from_editor = submit_from_editor
	var client := LeaderboardClient.new()
	client.config = config
	client.transport_factory = func() -> LeaderboardTransport:
		var stub := StubTransport.new()
		_stubs.append(stub)
		return stub
	var service := LeaderboardService.new()
	service.client = client
	service.pending_path = PENDING
	service.cache_path = CACHE
	service.config = TuningConfig.new()
	add_child_autofree(service)
	return service


func _fetch() -> StubTransport:
	return _stubs[_stubs.size() - 2]


func _submit() -> StubTransport:
	return _stubs[_stubs.size() - 1]


func _result(score: int) -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.duration_sec = 90.0
	return r


func _entry() -> IdentityEntry:
	return _results.get_node("%IdentityEntry")


func _choose_named() -> void:
	_entry().set_fields("ava@example.com", "Ava", "K")
	_entry().submit()


func _rank() -> String:
	return (_results.get_node("%RankLabel") as Label).text


func _note() -> String:
	return (_results.get_node("%NoteLabel") as Label).text


func _board() -> LeaderboardPanel:
	return _results.get_node("%Board")


func _receipt(rank: int, name: String, best: int) -> String:
	var r: ShiftResult = _service.pending.results[0]
	return '[{"submission_id":"%s","rank":%d,"name":"%s","best_score":%d}]' % [
			r.submission_id, rank, name, best]


func test_results_show_before_the_network_answers_then_update() -> void:
	_results.enter(_result(2450))
	assert_eq(_fetch().calls.size(), 1, "board refreshed on entry")
	_fetch().respond(200, "[]")
	assert_eq(_board().row_count(), 1, "empty board row until the shift is posted")
	assert_true(_entry().visible, "identity entry comes first")
	_choose_named()
	assert_false(_entry().visible)
	assert_true(_results.get_node("%Details").visible)
	assert_eq(_rank(), ResultsScreen.POSTING_TEXT)
	assert_string_contains(_board().sync_text(), "syncing")
	var submitted: ShiftResult = _service.pending.results[0]
	assert_eq(submitted.identity.display_name(), "Ava K.")
	_submit().respond(200, _receipt(57, "Ava K.", 2450))
	assert_eq(_rank(), "Global rank: #57")
	assert_eq(_note(), "")
	assert_eq(_service.pending_count(), 0)
	assert_eq(_fetch().calls.size(), 2, "board refreshed after the receipt")
	_fetch().respond(200, BOARD)
	assert_eq(_board().row_count(), 3)
	assert_eq((_board().get_node("%Rows").get_child(1) as Control).modulate, LeaderboardPanel.HIGHLIGHT)
	assert_string_contains(_board().sync_text(), "in sync")


func test_returning_player_sees_their_best() -> void:
	_results.enter(_result(100))
	_choose_named()
	_submit().respond(200, _receipt(2, "Ava K.", 2450))
	assert_eq(_rank(), "Global rank: #2 (your best: 2450)")
	_fetch().respond(200, BOARD)
	assert_eq((_board().get_node("%Rows").get_child(1) as Control).modulate, LeaderboardPanel.HIGHLIGHT,
			"the best row is theirs")


func test_anonymous_shift_is_named_by_the_board() -> void:
	_results.enter(_result(-15))
	assert_eq(_results.get_node("%ScoreLabel").text, "-15")
	_entry().skip()
	var shifts: Array = _submit().last_json()["p_shifts"]
	assert_null(shifts[0]["email"])
	_submit().respond(200, _receipt(3, "anonymous 07", -15))
	assert_eq(_rank(), "Global rank: #3")
	_fetch().respond(200, BOARD)
	assert_eq((_board().get_node("%Rows").get_child(2) as Control).modulate, LeaderboardPanel.HIGHLIGHT)


func test_offline_submit_waits_on_disk_and_says_so() -> void:
	_results.enter(_result(10))
	_fetch().respond(200, BOARD)
	_choose_named()
	_submit().fail()
	assert_eq(_rank(), ResultsScreen.WAITING_TEXT)
	assert_eq(_note(), LeaderboardPanel.UNAVAILABLE_NOTE)
	assert_eq(_board().note_text(), LeaderboardPanel.CACHED_NOTE)
	assert_eq(_board().row_count(), 3, "cached rows stay up")
	assert_string_contains(_board().sync_text(), "offline, 1 waiting")
	assert_eq(PendingStore.new(PENDING).size(), 1)
	_service.flush()
	assert_eq(_rank(), ResultsScreen.POSTING_TEXT)
	_submit().respond(200, _receipt(4, "Ava K.", 10))
	assert_eq(_rank(), "Global rank: #4")
	assert_eq(_board().note_text(), "")


func test_editor_run_without_opt_in_is_not_posted() -> void:
	if not OS.has_feature("editor"):
		pass_test("only meaningful under the editor binary")
		return
	_stubs = []
	var read_only := _make_service(false)
	var screen: ResultsScreen = RESULTS_SCENE.instantiate()
	screen.config = TuningConfig.new()
	screen.leaderboard = read_only
	add_child_autofree(screen)
	screen.enter(_result(5))
	(screen.get_node("%IdentityEntry") as IdentityEntry).skip()
	assert_eq((screen.get_node("%RankLabel") as Label).text, ResultsScreen.EDITOR_TEXT)
	assert_eq(read_only.pending_count(), 0)


func test_leaving_mid_post_does_not_lose_the_shift() -> void:
	_results.enter(_result(1))
	_choose_named()
	_results.get_node("%TitleButton").pressed.emit()
	assert_signal_emitted(_results, "navigation_requested")
	assert_true(_service.client.submit_pending(), "request still out")
	_submit().respond(200, _receipt(1, "Ava K.", 1))
	assert_eq(_service.pending_count(), 0, "the service outlives the screen")

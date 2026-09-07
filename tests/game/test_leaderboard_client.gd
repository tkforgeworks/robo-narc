extends GutTest

const KEY := "test-anon-key"
const URL := "https://example.supabase.co/"

var _client: LeaderboardClient
var _stubs: Array[StubTransport] = []


## Records the request and completes when the test says so.
class StubTransport:
	extends LeaderboardTransport
	var calls: Array[Dictionary] = []

	func post(url: String, headers: PackedStringArray, body: String, timeout_sec: float) -> Error:
		if busy:
			return ERR_BUSY
		busy = true
		calls.append({"url": url, "headers": headers, "body": body, "timeout": timeout_sec})
		return OK

	func respond(result: int, code: int, body: String) -> void:
		busy = false
		completed.emit(result, code, body)

	func last() -> Dictionary:
		return calls.back()


func _config(enabled: bool = true) -> LeaderboardConfig:
	var config := LeaderboardConfig.new()
	config.base_url = URL
	config.anon_key = KEY
	config.enabled = enabled
	return config


func before_each() -> void:
	_stubs = []
	_client = LeaderboardClient.new()
	_client.config = _config()
	_client.client_tag = "test"
	_client.transport_factory = func() -> LeaderboardTransport:
		var stub := StubTransport.new()
		_stubs.append(stub)
		return stub
	add_child_autofree(_client)
	watch_signals(_client)


func _fetch_stub() -> StubTransport:
	return _stubs[0]


func _submit_stub() -> StubTransport:
	return _stubs[1]


func _result(score: int, name: String = "Ava") -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.player_name = name
	r.correct = 3
	r.duration_sec = 90.0
	return r


func test_fetch_sends_contract_request_and_parses_entries() -> void:
	_client.fetch_top(20)
	var call := _fetch_stub().last()
	assert_eq(call["url"], "https://example.supabase.co/rest/v1/rpc/top_scores")
	assert_true(call["headers"].has("apikey: %s" % KEY))
	assert_true(call["headers"].has("Authorization: Bearer %s" % KEY))
	assert_true(call["headers"].has("Content-Type: application/json"))
	assert_eq(call["body"], '{"p_limit":20}')
	assert_eq(call["timeout"], _client.timeout_sec)
	_fetch_stub().respond(HTTPRequest.RESULT_SUCCESS, 200,
			'[{"rank":1,"name":"Ava","score":2450},{"rank":2,"name":"x y","score":10},{"rank":3,"name":"Abcdefghijklmnop","score":5}]')
	assert_signal_emitted(_client, "top_scores_received")
	var entries: Array = get_signal_parameters(_client, "top_scores_received")[0]
	assert_eq(entries.size(), 3)
	assert_eq(entries[0].name, "Ava")
	assert_eq(entries[0].score, 2450)
	assert_eq(entries[1].name, "???", "invalid name shown as placeholder")
	assert_eq(entries[2].name, "Abcdefghijkl", "long name truncated")


func test_fetch_failures_map_to_reasons() -> void:
	var cases := [
		[HTTPRequest.RESULT_TIMEOUT, 0, "", "TIMEOUT"],
		[HTTPRequest.RESULT_CANT_CONNECT, 0, "", "NETWORK"],
		[HTTPRequest.RESULT_SUCCESS, 401, "{}", "HTTP_401"],
		[HTTPRequest.RESULT_SUCCESS, 200, "not json", "BAD_JSON"],
		[HTTPRequest.RESULT_SUCCESS, 200, '{"rank":1}', "BAD_JSON"],
	]
	for c: Array in cases:
		_client.fetch_top()
		_fetch_stub().respond(c[0], c[1], c[2])
		assert_signal_emitted_with_parameters(_client, "failed", ["fetch", c[3]])
	assert_signal_not_emitted(_client, "top_scores_received")


func test_disabled_config_fails_immediately_without_requests() -> void:
	_client.config = _config(false)
	_client.fetch_top()
	_client.submit(_result(10))
	assert_signal_emitted_with_parameters(_client, "failed", ["fetch", "DISABLED"], 0)
	assert_signal_emitted_with_parameters(_client, "failed", ["submit", "DISABLED"], 1)
	assert_eq(_fetch_stub().calls.size(), 0)
	assert_eq(_submit_stub().calls.size(), 0)


func test_second_fetch_while_pending_is_ignored() -> void:
	_client.fetch_top()
	_client.fetch_top()
	assert_eq(_fetch_stub().calls.size(), 1)
	assert_true(_client.fetch_pending())


func test_submit_inserts_then_asks_for_rank() -> void:
	_client.submit(_result(2450))
	var insert := _submit_stub().last()
	assert_eq(insert["url"], "https://example.supabase.co/rest/v1/scores")
	assert_true(insert["headers"].has("Prefer: return=minimal"))
	var payload: Dictionary = JSON.parse_string(insert["body"])
	assert_eq(payload["name"], "Ava")
	assert_eq(int(payload["score"]), 2450)
	assert_eq(int(payload["duration_sec"]), 90)
	assert_eq(payload["client"], "test")
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 201, "")
	var rank_call := _submit_stub().last()
	assert_eq(rank_call["url"], "https://example.supabase.co/rest/v1/rpc/rank_for_score")
	assert_eq(rank_call["body"], '{"p_score":2450}')
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 200, "57")
	assert_signal_emitted_with_parameters(_client, "submitted", [57])
	assert_false(_client.submit_pending())


func test_submit_failure_at_either_step_reports_and_moves_on() -> void:
	_client.submit(_result(1))
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 400, '{"message":"bad"}')
	assert_signal_emitted_with_parameters(_client, "failed", ["submit", "HTTP_400"], 0)
	_client.submit(_result(2))
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 201, "")
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 200, "oops")
	assert_signal_emitted_with_parameters(_client, "failed", ["submit", "BAD_JSON"], 1)
	assert_false(_client.submit_pending())


func test_submits_queue_in_order() -> void:
	_client.submit(_result(1))
	_client.submit(_result(2))
	assert_eq(_submit_stub().calls.size(), 1, "second waits")
	assert_true(_client.submit_pending())
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 201, "")
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 200, "3")
	assert_eq(_submit_stub().calls.size(), 3, "second insert started")
	assert_string_contains(_submit_stub().last()["body"], '"score":2')


func test_release_when_idle_frees_after_the_submit_finishes() -> void:
	_client.submit(_result(1))
	_client.release_when_idle()
	assert_false(_client.is_queued_for_deletion(), "still busy")
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 201, "")
	_submit_stub().respond(HTTPRequest.RESULT_SUCCESS, 200, "1")
	assert_true(_client.is_queued_for_deletion())


func test_publishable_keys_skip_the_bearer_header() -> void:
	var legacy := LeaderboardClient.headers_for("eyJhbGciOi.legacy.jwt", false)
	assert_true(legacy.has("Authorization: Bearer eyJhbGciOi.legacy.jwt"))
	var publishable := LeaderboardClient.headers_for(" sb_publishable_abc ", true)
	assert_true(publishable.has("apikey: sb_publishable_abc"))
	assert_true(publishable.has("Prefer: return=minimal"))
	for header in publishable:
		assert_false(header.begins_with("Authorization"), header)


func test_entry_display_name_rules() -> void:
	assert_eq(LeaderboardEntry.display_name(" Ava "), "Ava")
	assert_eq(LeaderboardEntry.display_name(""), "???")
	assert_eq(LeaderboardEntry.display_name("A1"), "???")
	assert_eq(LeaderboardEntry.display_name("abcdefghijklmnop"), "abcdefghijkl")


func test_config_precedence_and_usability() -> void:
	var config := LeaderboardConfig.new()
	assert_false(config.is_usable())
	config.enabled = true
	assert_false(config.is_usable(), "needs url and key")
	config.base_url = URL
	config.anon_key = KEY
	assert_true(config.is_usable())
	var active := LeaderboardConfig.load_active()
	assert_not_null(active, "always returns a config")

extends GutTest

const StubTransport := preload("res://tests/game/helpers/stub_transport.gd")
const KEY := "test-anon-key"
const URL := "https://example.supabase.co/"

var _client: LeaderboardClient
var _stubs: Array = []


func _config(enabled: bool = true) -> LeaderboardConfig:
	var config := LeaderboardConfig.new()
	config.base_url = URL
	config.anon_key = KEY
	config.enabled = enabled
	config.submit_from_editor = true  # tests run under the editor binary
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


func _result(score: int, named: bool = true) -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.correct = 3
	r.duration_sec = 90.0
	r.submission_id = Uuid.v4()
	if named:
		r.identity = PlayerIdentity.named("ava@example.com", "Ava", "K")
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
	_fetch_stub().respond(200,
			'[{"rank":1,"name":"Ava K.","score":2450},{"rank":2,"name":"anonymous 07","score":10},'
			+ '{"rank":3,"name":"x_y!","score":5},{"rank":4,"name":"Abcdefghijklmnopqrs T.","score":1}]')
	assert_signal_emitted(_client, "top_scores_received")
	var entries: Array = get_signal_parameters(_client, "top_scores_received")[0]
	assert_eq(entries.size(), 4)
	assert_eq(entries[0].name, "Ava K.")
	assert_eq(entries[0].score, 2450)
	assert_eq(entries[1].name, "anonymous 07")
	assert_eq(entries[2].name, "???", "invalid name shown as placeholder")
	assert_eq(entries[3].name, "Abcdefghijklmnop", "long name truncated")


func test_fetch_failures_map_to_reasons() -> void:
	var cases := [
		[HTTPRequest.RESULT_TIMEOUT, 0, "", "TIMEOUT"],
		[HTTPRequest.RESULT_CANT_CONNECT, 0, "", "NETWORK"],
		[HTTPRequest.RESULT_SUCCESS, 401, "{}", "HTTP_401"],
		[HTTPRequest.RESULT_CONNECTION_ERROR, 400, "{}", "HTTP_400"],
		[HTTPRequest.RESULT_SUCCESS, 200, "not json", "BAD_JSON"],
		[HTTPRequest.RESULT_SUCCESS, 200, '{"rank":1}', "BAD_JSON"],
	]
	for c: Array in cases:
		_client.fetch_top()
		_fetch_stub().respond(c[1], c[2], c[0])
		assert_signal_emitted_with_parameters(_client, "failed", ["fetch", c[3]])
	assert_signal_not_emitted(_client, "top_scores_received")


func test_disabled_config_fails_immediately_without_requests() -> void:
	_client.config = _config(false)
	_client.fetch_top()
	_client.submit_batch([_result(10)])
	assert_signal_emitted_with_parameters(_client, "failed", ["fetch", "DISABLED"], 0)
	assert_signal_emitted_with_parameters(_client, "failed", ["submit", "DISABLED"], 1)
	assert_eq(_fetch_stub().calls.size(), 0)
	assert_eq(_submit_stub().calls.size(), 0)


func test_editor_runs_fetch_but_do_not_submit_unless_opted_in() -> void:
	if not OS.has_feature("editor"):
		pass_test("only meaningful under the editor binary")
		return
	_client.config.submit_from_editor = false
	assert_true(_client.is_enabled())
	assert_false(_client.submit_enabled())
	_client.submit_batch([_result(10)])
	assert_signal_emitted_with_parameters(_client, "failed", ["submit", "DISABLED"])
	assert_eq(_submit_stub().calls.size(), 0, "nothing sent")
	_client.fetch_top()
	assert_eq(_fetch_stub().calls.size(), 1, "reads still work")
	assert_eq(LeaderboardRequests.platform_tag(), "editor")


func test_second_fetch_while_pending_is_ignored() -> void:
	_client.fetch_top()
	_client.fetch_top()
	assert_eq(_fetch_stub().calls.size(), 1)
	assert_true(_client.fetch_pending())


func test_submit_batch_sends_one_rpc_and_parses_receipts() -> void:
	var named := _result(2450)
	var anon := _result(-15, false)
	_client.submit_batch([named, anon])
	var call := _submit_stub().last()
	assert_eq(call["url"], "https://example.supabase.co/rest/v1/rpc/submit_shifts")
	assert_true(_client.submit_pending())
	var shifts: Array = _submit_stub().last_json()["p_shifts"]
	assert_eq(shifts.size(), 2)
	assert_eq(shifts[0]["submission_id"], named.submission_id)
	assert_eq(shifts[0]["email"], "ava@example.com")
	assert_eq(shifts[0]["first_name"], "Ava")
	assert_eq(shifts[0]["last_initial"], "K")
	assert_eq(int(shifts[0]["score"]), 2450)
	assert_eq(int(shifts[0]["correct"]), 3)
	assert_eq(int(shifts[0]["duration_sec"]), 90)
	assert_eq(shifts[0]["client"], "test")
	assert_null(shifts[1]["email"], "anonymous shifts send null identity")
	assert_null(shifts[1]["first_name"])
	assert_null(shifts[1]["last_initial"])
	assert_eq(int(shifts[1]["score"]), -15)
	_submit_stub().respond(200,
			'[{"submission_id":"%s","rank":57,"name":"Ava K.","best_score":2450},' % named.submission_id
			+ '{"submission_id":"%s","rank":900,"name":"anonymous 07","best_score":-15}]' % anon.submission_id)
	assert_signal_emitted(_client, "batch_submitted")
	var receipts: Array = get_signal_parameters(_client, "batch_submitted")[0]
	assert_eq(receipts.size(), 2)
	assert_eq(receipts[0].submission_id, named.submission_id)
	assert_eq(receipts[0].rank, 57)
	assert_eq(receipts[0].best_score, 2450)
	assert_eq(receipts[1].name, "anonymous 07")
	assert_eq(receipts[1].rank, 900)
	assert_false(_client.submit_pending())


func test_submit_failures_report_a_reason() -> void:
	_client.submit_batch([_result(1)])
	_submit_stub().respond(400, '{"message":"bad"}')
	assert_signal_emitted_with_parameters(_client, "failed", ["submit", "HTTP_400"], 0)
	_client.submit_batch([_result(2)])
	_submit_stub().respond(200, "oops")
	assert_signal_emitted_with_parameters(_client, "failed", ["submit", "BAD_JSON"], 1)
	_client.submit_batch([_result(3)])
	_submit_stub().fail(HTTPRequest.RESULT_TIMEOUT)
	assert_signal_emitted_with_parameters(_client, "failed", ["submit", "TIMEOUT"], 2)
	assert_false(_client.submit_pending())


func test_second_batch_while_one_is_out_is_ignored() -> void:
	_client.submit_batch([_result(1)])
	_client.submit_batch([_result(2)])
	assert_eq(_submit_stub().calls.size(), 1)
	_client.submit_batch([])
	assert_eq(_submit_stub().calls.size(), 1, "empty batch never sent")


func test_rejections_are_the_two_payload_errors() -> void:
	assert_true(LeaderboardRequests.is_rejection("HTTP_400"))
	assert_true(LeaderboardRequests.is_rejection("HTTP_422"))
	for reason: String in ["HTTP_401", "HTTP_404", "HTTP_500", "TIMEOUT", "NETWORK", "BAD_JSON"]:
		assert_false(LeaderboardRequests.is_rejection(reason), reason)


func test_publishable_keys_skip_the_bearer_header() -> void:
	var legacy := LeaderboardRequests.headers_for("eyJhbGciOi.legacy.jwt")
	assert_true(legacy.has("Authorization: Bearer eyJhbGciOi.legacy.jwt"))
	var publishable := LeaderboardRequests.headers_for(" sb_publishable_abc ")
	assert_true(publishable.has("apikey: sb_publishable_abc"))
	for header in publishable:
		assert_false(header.begins_with("Authorization"), header)


func test_entry_display_name_rules() -> void:
	assert_eq(LeaderboardEntry.display_name(" Ava K. "), "Ava K.")
	assert_eq(LeaderboardEntry.display_name("anonymous 07"), "anonymous 07")
	assert_eq(LeaderboardEntry.display_name(""), "???")
	assert_eq(LeaderboardEntry.display_name("A<b>"), "???")
	assert_eq(LeaderboardEntry.display_name("abcdefghijklmnopq"), "abcdefghijklmnop")


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

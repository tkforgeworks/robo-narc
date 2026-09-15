extends GutTest
## LeaderboardService against stub transports: the offline queue, batching,
## receipts, retry, and the sync status the screens colour by.

const StubTransport := preload("res://tests/game/helpers/stub_transport.gd")
const PENDING := "user://test_service_pending.json"
const CACHE := "user://test_service_cache.json"
const RECEIPT := '[{"submission_id":"%s","rank":%d,"name":"%s","best_score":%d}]'

var _service: LeaderboardService
var _stubs: Array = []


func before_each() -> void:
	_stubs = []
	_clear_files()
	_service = _make_service()


func after_each() -> void:
	_clear_files()


func _clear_files() -> void:
	PendingStore.new(PENDING).clear()
	BoardCache.new(CACHE).clear()


func _config(enabled: bool = true, submit_from_editor: bool = true) -> LeaderboardConfig:
	var config := LeaderboardConfig.new()
	config.base_url = "https://example.supabase.co"
	config.anon_key = "sb_publishable_test"
	config.enabled = enabled
	config.submit_from_editor = submit_from_editor
	return config


func _make_service(enabled: bool = true, submit_from_editor: bool = true) -> LeaderboardService:
	var client := LeaderboardClient.new()
	client.config = _config(enabled, submit_from_editor)
	client.client_tag = "test"
	client.transport_factory = func() -> LeaderboardTransport:
		var stub := StubTransport.new()
		_stubs.append(stub)
		return stub
	var service := LeaderboardService.new()
	service.client = client
	service.pending_path = PENDING
	service.cache_path = CACHE
	var config := TuningConfig.new()
	config.sync_retry_sec = 5.0
	config.top_count = 15
	service.config = config
	add_child_autofree(service)
	watch_signals(service)
	return service


func _fetch() -> StubTransport:
	return _stubs[_stubs.size() - 2]


func _submit() -> StubTransport:
	return _stubs[_stubs.size() - 1]


func _result(score: int) -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.duration_sec = 90.0
	r.identity = PlayerIdentity.named("ava@example.com", "Ava", "K")
	return r


func _receipt(id: String, rank: int, name: String = "Ava K.", best: int = 0) -> String:
	return RECEIPT % [id, rank, name, best]


func test_starts_syncing_when_enabled_and_disabled_without_config() -> void:
	assert_eq(_service.status, LeaderboardService.Status.SYNCING)
	var off := _make_service(false)
	assert_eq(off.status, LeaderboardService.Status.DISABLED)
	off.refresh_board()
	assert_false(off.submit(_result(1)))
	assert_eq(off.pending_count(), 0, "nothing queued when submits are off")


func test_refresh_caches_the_board_and_settles_synced() -> void:
	_service.refresh_board()
	assert_eq(_fetch().last()["body"], '{"p_limit":15}')
	_fetch().respond(200, '[{"rank":1,"name":"Ava K.","score":2450}]')
	assert_signal_emitted(_service, "board_updated")
	assert_eq(_service.cached_entries().size(), 1)
	assert_eq(BoardCache.new(CACHE).entries[0].name, "Ava K.", "cached on disk")
	assert_eq(_service.status, LeaderboardService.Status.SYNCED)
	assert_signal_emitted_with_parameters(_service, "status_changed", [LeaderboardService.Status.SYNCED])


func test_failed_fetch_goes_offline_and_keeps_the_cache() -> void:
	_service.refresh_board()
	_fetch().respond(200, '[{"rank":1,"name":"Ava K.","score":2450}]')
	_service.refresh_board()
	_fetch().fail()
	assert_eq(_service.status, LeaderboardService.Status.OFFLINE)
	assert_eq(_service.last_failure, "NETWORK")
	assert_eq(_service.cached_entries().size(), 1)


func test_submit_queues_sends_a_batch_and_clears_on_receipt() -> void:
	var r := _result(2450)
	assert_true(_service.submit(r))
	assert_true(Uuid.is_valid(r.submission_id), "id assigned")
	assert_true(_service.is_pending(r.submission_id))
	assert_eq(PendingStore.new(PENDING).size(), 1, "queued on disk before sending")
	assert_eq(_service.status, LeaderboardService.Status.SYNCING)
	var call := _submit().last()
	assert_eq(call["url"], "https://example.supabase.co/rest/v1/rpc/submit_shifts")
	var shifts: Array = _submit().last_json()["p_shifts"]
	assert_eq(shifts.size(), 1)
	assert_eq(shifts[0]["submission_id"], r.submission_id)
	assert_eq(shifts[0]["email"], "ava@example.com")
	_submit().respond(200, _receipt(r.submission_id, 3, "Ava K.", 2450))
	assert_signal_emitted(_service, "receipt_received")
	var receipt: SubmitReceipt = get_signal_parameters(_service, "receipt_received")[0]
	assert_eq(receipt.rank, 3)
	assert_eq(receipt.best_score, 2450)
	assert_false(_service.is_pending(r.submission_id))
	assert_eq(PendingStore.new(PENDING).size(), 0, "acknowledged shift left the disk")
	assert_eq(_service.status, LeaderboardService.Status.SYNCED)


func test_failed_submit_keeps_the_shift_and_retries() -> void:
	var r := _result(10)
	_service.submit(r)
	_submit().fail()
	assert_eq(_service.status, LeaderboardService.Status.OFFLINE)
	assert_eq(_service.pending_count(), 1)
	var retry: Timer = _service.get_node("Retry")
	assert_false(retry.is_stopped(), "retry scheduled")
	assert_almost_eq(retry.wait_time, 5.0, 0.01)
	_service.flush()
	assert_true(retry.is_stopped())
	assert_eq(_submit().calls.size(), 2, "resent")
	assert_eq(_submit().last_json()["p_shifts"][0]["submission_id"], r.submission_id, "same id: no duplicate row")
	_submit().respond(200, _receipt(r.submission_id, 1))
	assert_eq(_service.pending_count(), 0)
	assert_eq(_service.status, LeaderboardService.Status.SYNCED)


func test_a_fetch_answer_flushes_waiting_shifts() -> void:
	_service.submit(_result(10))
	_submit().fail()
	_service.refresh_board()
	_fetch().respond(200, "[]")
	assert_eq(_submit().calls.size(), 2, "the board is reachable again, so resend now")
	assert_eq(_service.status, LeaderboardService.Status.SYNCING)


func test_rejected_batch_is_dropped_rather_than_retried_forever() -> void:
	_service.submit(_result(10))
	_submit().respond(400, '{"message":"violates check constraint"}')
	assert_eq(_service.pending_count(), 0)
	assert_true((_service.get_node("Retry") as Timer).is_stopped())


func test_server_errors_are_retried() -> void:
	_service.submit(_result(10))
	_submit().respond(503, "")
	assert_eq(_service.pending_count(), 1)
	assert_false((_service.get_node("Retry") as Timer).is_stopped())


func test_shifts_waiting_on_disk_are_sent_at_startup() -> void:
	var store := PendingStore.new(PENDING)
	var r := _result(5)
	r.submission_id = Uuid.v4()
	store.append(r)
	_stubs = []
	var restarted := _make_service()
	assert_eq(_submit().calls.size(), 1, "flushed in _ready")
	assert_eq(restarted.status, LeaderboardService.Status.SYNCING)
	_submit().respond(200, _receipt(r.submission_id, 2))
	assert_eq(restarted.pending_count(), 0)


func test_batches_are_capped_and_the_rest_follow() -> void:
	var store := PendingStore.new(PENDING)
	for i in LeaderboardService.MAX_BATCH + 1:
		var r := _result(i)
		r.submission_id = Uuid.v4()
		store.append(r)
	_stubs = []
	var restarted := _make_service()
	var shifts: Array = _submit().last_json()["p_shifts"]
	assert_eq(shifts.size(), LeaderboardService.MAX_BATCH)
	var receipts: Array = []
	for shift: Dictionary in shifts:
		receipts.append({"submission_id": shift["submission_id"], "rank": 1, "name": "Ava K.", "best_score": 1})
	_submit().respond(200, JSON.stringify(receipts))
	assert_eq(restarted.pending_count(), 1)
	assert_eq(_submit().calls.size(), 2, "the leftover went out at once")


func test_editor_runs_do_not_queue_unless_opted_in() -> void:
	if not OS.has_feature("editor"):
		pass_test("only meaningful under the editor binary")
		return
	var read_only := _make_service(true, false)
	assert_true(read_only.is_enabled())
	assert_false(read_only.can_submit())
	assert_false(read_only.submit(_result(1)))
	assert_eq(read_only.pending_count(), 0)
	read_only.refresh_board()
	_fetch().respond(200, "[]")
	assert_eq(read_only.status, LeaderboardService.Status.SYNCED, "reads alone keep it green")


func test_clear_local_forgets_cache_and_queue() -> void:
	_service.refresh_board()
	_fetch().respond(200, '[{"rank":1,"name":"Ava K.","score":1}]')
	_service.submit(_result(10))
	_submit().fail()
	_service.clear_local()
	assert_eq(_service.pending_count(), 0)
	assert_eq(_service.cached_entries().size(), 0)
	var emitted: Array = get_signal_parameters(_service, "board_updated")[0]
	assert_eq(emitted.size(), 0, "screens are told to show the empty board")

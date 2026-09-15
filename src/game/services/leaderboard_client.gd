class_name LeaderboardClient
extends Node
## Talks to the Supabase leaderboard per contracts/leaderboard-api.md: a top-N
## fetch and a batch submit that answers with one receipt per shift. Every
## failure is a signal, never a block; a disabled config fails immediately with
## DISABLED. One fetch and one submit in flight at a time; extra calls are
## ignored (the pending answer is used). LeaderboardService owns the queue.

signal top_scores_received(entries: Array[LeaderboardEntry])
signal batch_submitted(receipts: Array[SubmitReceipt])
signal failed(operation: String, reason: String)

const TAG := "Leaderboard"
const OP_FETCH := "fetch"
const OP_SUBMIT := "submit"
const REASON_DISABLED := "DISABLED"

var config: LeaderboardConfig  # null -> LeaderboardConfig.load_active()
var timeout_sec: float = 5.0
var transport_factory: Callable = func() -> LeaderboardTransport: return HttpTransport.new()
var client_tag: String = LeaderboardRequests.platform_tag()

var _fetch: LeaderboardTransport
var _submit: LeaderboardTransport


func _ready() -> void:
	if config == null:
		config = LeaderboardConfig.load_active()
	timeout_sec = Tuning.config.request_timeout_sec
	_fetch = _make_transport("FetchTransport", _on_fetch_completed)
	_submit = _make_transport("SubmitTransport", _on_submit_completed)


func is_enabled() -> bool:
	return config != null and config.is_usable()


func submit_enabled() -> bool:
	return config != null and config.allows_submit()


func fetch_pending() -> bool:
	return _fetch.busy


func submit_pending() -> bool:
	return _submit.busy


func fetch_top(limit: int = 20) -> void:
	if not is_enabled():
		failed.emit(OP_FETCH, REASON_DISABLED)
		return
	if _fetch.busy:
		return
	if not _post(_fetch, LeaderboardRequests.PATH_TOP, {"p_limit": limit}):
		failed.emit(OP_FETCH, LeaderboardRequests.REASON_NETWORK)


## Sends every shift in one request. Ignored while a batch is already out.
func submit_batch(results: Array[ShiftResult]) -> void:
	if not submit_enabled():
		failed.emit(OP_SUBMIT, REASON_DISABLED)
		return
	if _submit.busy or results.is_empty():
		return
	var payload := LeaderboardRequests.payload_for(results, client_tag)
	if not _post(_submit, LeaderboardRequests.PATH_SUBMIT, payload):
		failed.emit(OP_SUBMIT, LeaderboardRequests.REASON_NETWORK)


func _make_transport(node_name: String, on_completed: Callable) -> LeaderboardTransport:
	var transport: LeaderboardTransport = transport_factory.call()
	transport.name = node_name
	transport.completed.connect(on_completed)
	add_child(transport)
	return transport


func _post(transport: LeaderboardTransport, path: String, payload: Dictionary) -> bool:
	var headers := LeaderboardRequests.headers_for(config.anon_key)
	var url := LeaderboardRequests.url(config.base_url, path)
	var err := transport.post(url, headers, JSON.stringify(payload), timeout_sec)
	if err != OK:
		DebugLog.warn(TAG, "request to %s not sent (error %d)" % [path, err])
	return err == OK


func _on_fetch_completed(result: int, code: int, body: String) -> void:
	var reason := LeaderboardRequests.failure_reason(result, code)
	if not reason.is_empty():
		DebugLog.warn(TAG, "fetch failed: %s (result %d, code %d)" % [reason, result, code])
		failed.emit(OP_FETCH, reason)
		return
	var entries: Variant = LeaderboardRequests.parse_top_scores(body)
	if entries == null:
		DebugLog.warn(TAG, "fetch returned unexpected JSON: %s" % body.left(120))
		failed.emit(OP_FETCH, LeaderboardRequests.REASON_BAD_JSON)
		return
	top_scores_received.emit(entries)


func _on_submit_completed(result: int, code: int, body: String) -> void:
	var reason := LeaderboardRequests.failure_reason(result, code)
	if not reason.is_empty():
		DebugLog.warn(TAG, "submit failed: %s (result %d, code %d) %s" % [
				reason, result, code, body.left(200)])
		failed.emit(OP_SUBMIT, reason)
		return
	var receipts: Variant = LeaderboardRequests.parse_receipts(body)
	if receipts == null:
		DebugLog.warn(TAG, "submit returned unexpected JSON: %s" % body.left(120))
		failed.emit(OP_SUBMIT, LeaderboardRequests.REASON_BAD_JSON)
		return
	batch_submitted.emit(receipts)

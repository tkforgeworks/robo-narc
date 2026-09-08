class_name LeaderboardClient
extends Node
## Talks to the Supabase leaderboard per contracts/leaderboard-api.md: a top-N
## fetch and a submit (insert, then rank lookup). Every failure is a signal,
## never a block; a disabled config fails immediately with DISABLED. One fetch
## in flight at a time (extra requests ignored); submits queue in order.

signal top_scores_received(entries: Array[LeaderboardEntry])
signal submitted(rank: int)
signal failed(operation: String, reason: String)

const TAG := "Leaderboard"
const OP_FETCH := "fetch"
const OP_SUBMIT := "submit"
const REASON_DISABLED := "DISABLED"

enum SubmitStage { INSERT, RANK }

var config: LeaderboardConfig  # null -> LeaderboardConfig.load_active()
var timeout_sec: float = 5.0
var transport_factory: Callable = func() -> LeaderboardTransport: return HttpTransport.new()
var client_tag: String = LeaderboardRequests.platform_tag()

var _fetch: LeaderboardTransport
var _submit: LeaderboardTransport
var _submit_queue: Array[ShiftResult] = []
var _submitting: ShiftResult = null
var _submit_stage: SubmitStage = SubmitStage.INSERT
var _release_when_idle: bool = false


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
	return _submitting != null or not _submit_queue.is_empty()


func fetch_top(limit: int = 20) -> void:
	if not is_enabled():
		failed.emit(OP_FETCH, REASON_DISABLED)
		return
	if _fetch.busy:
		return
	if not _post(_fetch, LeaderboardRequests.PATH_TOP, {"p_limit": limit}, false):
		failed.emit(OP_FETCH, LeaderboardRequests.REASON_NETWORK)


func submit(result: ShiftResult) -> void:
	if not submit_enabled():
		failed.emit(OP_SUBMIT, REASON_DISABLED)
		return
	_submit_queue.append(result)
	_next_submit()


## A screen leaving mid-submit reparents this node to the root and calls this.
func release_when_idle() -> void:
	_release_when_idle = true
	_maybe_release()


func _make_transport(node_name: String, on_completed: Callable) -> LeaderboardTransport:
	var transport: LeaderboardTransport = transport_factory.call()
	transport.name = node_name
	transport.completed.connect(on_completed)
	add_child(transport)
	return transport


func _next_submit() -> void:
	if _submitting != null or _submit_queue.is_empty():
		return
	_submitting = _submit_queue.pop_front()
	_submit_stage = SubmitStage.INSERT
	var payload := LeaderboardRequests.payload_for(_submitting, client_tag)
	if not _post(_submit, LeaderboardRequests.PATH_SCORES, payload, true):
		_finish_submit(LeaderboardRequests.REASON_NETWORK)


func _post(transport: LeaderboardTransport, path: String, payload: Dictionary,
		return_minimal: bool) -> bool:
	var headers := LeaderboardRequests.headers_for(config.anon_key, return_minimal)
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
		_finish_submit(reason)
		return
	if _submit_stage == SubmitStage.INSERT:
		_submit_stage = SubmitStage.RANK
		var payload := {"p_score": _submitting.score}
		if not _post(_submit, LeaderboardRequests.PATH_RANK, payload, false):
			_finish_submit(LeaderboardRequests.REASON_NETWORK)
		return
	var rank := LeaderboardRequests.parse_rank(body)
	if rank == LeaderboardRequests.NO_RANK:
		_finish_submit(LeaderboardRequests.REASON_BAD_JSON)
		return
	_submitting = null
	submitted.emit(rank)
	_next_submit()
	_maybe_release()


func _finish_submit(reason: String) -> void:
	DebugLog.warn(TAG, "submit failed: %s" % reason)
	_submitting = null
	failed.emit(OP_SUBMIT, reason)
	_next_submit()
	_maybe_release()


func _maybe_release() -> void:
	if _release_when_idle and not submit_pending():
		queue_free()

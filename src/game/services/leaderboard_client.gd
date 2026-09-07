class_name LeaderboardClient
extends Node
## Talks to the Supabase leaderboard exactly per contracts/leaderboard-api.md:
## a top-N fetch and a submit (insert, then rank lookup). Every failure is a
## signal, never a block; a disabled config fails immediately with DISABLED.
## One fetch in flight at a time (extra requests ignored); submits queue.

signal top_scores_received(entries: Array[LeaderboardEntry])
signal submitted(rank: int)
signal failed(operation: String, reason: String)

const TAG := "Leaderboard"
const OP_FETCH := "fetch"
const OP_SUBMIT := "submit"
const REASON_DISABLED := "DISABLED"
const REASON_TIMEOUT := "TIMEOUT"
const REASON_NETWORK := "NETWORK"
const REASON_BAD_JSON := "BAD_JSON"
const PATH_TOP := "/rest/v1/rpc/top_scores"
const PATH_SCORES := "/rest/v1/scores"
const PATH_RANK := "/rest/v1/rpc/rank_for_score"

enum SubmitStage { INSERT, RANK }

## Injectable; defaults to LeaderboardConfig.load_active().
var config: LeaderboardConfig
var timeout_sec: float = 5.0
## Builds the two transports; tests swap in a stub.
var transport_factory: Callable = func() -> LeaderboardTransport: return HttpTransport.new()
var client_tag: String = platform_tag()

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
	_fetch = transport_factory.call()
	_fetch.name = "FetchTransport"
	_fetch.completed.connect(_on_fetch_completed)
	add_child(_fetch)
	_submit = transport_factory.call()
	_submit.name = "SubmitTransport"
	_submit.completed.connect(_on_submit_completed)
	add_child(_submit)


func is_enabled() -> bool:
	return config != null and config.is_usable()


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
	if not _post(_fetch, PATH_TOP, {"p_limit": limit}, false):
		failed.emit(OP_FETCH, REASON_NETWORK)


func submit(result: ShiftResult) -> void:
	if not is_enabled():
		failed.emit(OP_SUBMIT, REASON_DISABLED)
		return
	_submit_queue.append(result)
	_next_submit()


## Lets a screen hand the node to the tree root on exit so an in-flight submit
## finishes; the node frees itself once idle.
func release_when_idle() -> void:
	_release_when_idle = true
	_maybe_release()


static func platform_tag() -> String:
	for feature in ["web", "windows", "android", "linux", "macos", "ios"]:
		if OS.has_feature(feature):
			return feature
	return "unknown"


static func payload_for(result: ShiftResult, tag: String) -> Dictionary:
	return {
		"name": result.player_name,
		"score": result.score,
		"correct": result.correct,
		"wrong": result.wrong,
		"missed": result.missed,
		"empty": result.empty,
		"duration_sec": roundi(result.duration_sec),
		"client": tag,
	}


func _next_submit() -> void:
	if _submitting != null or _submit_queue.is_empty():
		return
	_submitting = _submit_queue.pop_front()
	_submit_stage = SubmitStage.INSERT
	if not _post(_submit, PATH_SCORES, payload_for(_submitting, client_tag), true):
		_finish_submit(REASON_NETWORK)


func _post(transport: LeaderboardTransport, path: String, payload: Dictionary,
		return_minimal: bool) -> bool:
	var key := config.anon_key.strip_edges()
	var headers := PackedStringArray([
		"apikey: %s" % key,
		"Authorization: Bearer %s" % key,
		"Content-Type: application/json",
	])
	if return_minimal:
		headers.append("Prefer: return=minimal")
	var url := config.base_url.strip_edges().trim_suffix("/") + path
	var err := transport.post(url, headers, JSON.stringify(payload), timeout_sec)
	if err != OK:
		DebugLog.warn(TAG, "request to %s not sent (error %d)" % [path, err])
	return err == OK


func _on_fetch_completed(result: int, code: int, body: String) -> void:
	var reason := failure_reason(result, code)
	if not reason.is_empty():
		failed.emit(OP_FETCH, reason)
		return
	var json := JSON.new()
	if json.parse(body) != OK or not json.data is Array:
		failed.emit(OP_FETCH, REASON_BAD_JSON)
		return
	var entries: Array[LeaderboardEntry] = []
	for item: Variant in json.data:
		if item is Dictionary:
			entries.append(LeaderboardEntry.from_dict(item))
	top_scores_received.emit(entries)


func _on_submit_completed(result: int, code: int, body: String) -> void:
	var reason := failure_reason(result, code)
	if not reason.is_empty():
		_finish_submit(reason)
		return
	if _submit_stage == SubmitStage.INSERT:
		_submit_stage = SubmitStage.RANK
		if not _post(_submit, PATH_RANK, {"p_score": _submitting.score}, false):
			_finish_submit(REASON_NETWORK)
		return
	var json := JSON.new()
	if json.parse(body) != OK or not (json.data is float or json.data is int):
		_finish_submit(REASON_BAD_JSON)
		return
	var rank := int(json.data)
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


static func failure_reason(result: int, code: int) -> String:
	if result == HTTPRequest.RESULT_TIMEOUT:
		return REASON_TIMEOUT
	if result != HTTPRequest.RESULT_SUCCESS:
		return REASON_NETWORK
	if code < 200 or code >= 300:
		return "HTTP_%d" % code
	return ""

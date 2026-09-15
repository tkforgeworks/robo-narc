class_name LeaderboardService
extends Node
## The game's one door to the shared board, registered as the `Leaderboard`
## autoload. Owns the client, the queue of shifts not yet acknowledged by the
## board, the cached copy of the board, and the retry timer, and reports one
## sync status the screens colour their indicator with. Nothing here blocks a
## screen (spec FR-041); a shift that cannot be sent waits on disk (FR-042).

signal board_updated(entries: Array[LeaderboardEntry])
signal receipt_received(receipt: SubmitReceipt)
signal status_changed(status: int)

enum Status { DISABLED, SYNCED, SYNCING, OFFLINE }

const TAG := "Leaderboard"
const MAX_BATCH := 50

## All injectable before the node enters the tree; the defaults are the real game.
var client: LeaderboardClient
var pending_path: String = PendingStore.DEFAULT_PATH
var cache_path: String = BoardCache.DEFAULT_PATH
var config: TuningConfig  # null -> Tuning.config

var status: Status = Status.DISABLED
var pending: PendingStore
var cache: BoardCache
var last_failure: String = ""

var _retry: Timer
var _in_flight: PackedStringArray = []


func _ready() -> void:
	if config == null:
		config = Tuning.config
	pending = PendingStore.new(pending_path)
	cache = BoardCache.new(cache_path)
	if client == null:
		client = LeaderboardClient.new()
	if client.get_parent() == null:
		client.name = "Client"
		add_child(client)
	client.top_scores_received.connect(_on_top_scores)
	client.batch_submitted.connect(_on_batch_submitted)
	client.failed.connect(_on_failed)
	_retry = Timer.new()
	_retry.name = "Retry"
	_retry.one_shot = true
	_retry.timeout.connect(flush)
	add_child(_retry)
	status = Status.SYNCING if client.is_enabled() else Status.DISABLED
	if not pending.is_empty():
		DebugLog.info(TAG, "%d shift(s) waiting from an earlier run" % pending.size())
	flush()


func is_enabled() -> bool:
	return client.is_enabled()


func can_submit() -> bool:
	return client.submit_enabled()


func cached_entries() -> Array[LeaderboardEntry]:
	return cache.entries


func pending_count() -> int:
	return pending.size()


## True until the board has acknowledged the shift.
func is_pending(submission_id: String) -> bool:
	return pending.has(submission_id)


func refresh_board() -> void:
	if not client.is_enabled() or client.fetch_pending():
		return
	_set_status(Status.SYNCING)
	client.fetch_top(config.top_count)


## Queues the shift and tries to send at once. False when submits are off (no
## config, or an editor run that has not opted in): nothing is queued then.
func submit(result: ShiftResult) -> bool:
	if not client.submit_enabled():
		return false
	if result.submission_id.is_empty():
		result.submission_id = Uuid.v4()
	pending.append(result)
	flush()
	return true


## Sends the oldest waiting shifts as one batch, unless one is already out.
func flush() -> void:
	_retry.stop()
	if pending.is_empty() or not client.submit_enabled() or client.submit_pending():
		return
	var batch := pending.first(MAX_BATCH)
	_in_flight = PackedStringArray()
	for result in batch:
		_in_flight.append(result.submission_id)
	_set_status(Status.SYNCING)
	client.submit_batch(batch)


## Debug: forget the cached board and every unsent shift.
func clear_local() -> void:
	pending.clear()
	cache.clear()
	board_updated.emit(cache.entries)
	_settle()


func _on_top_scores(entries: Array[LeaderboardEntry]) -> void:
	cache.store(entries)
	board_updated.emit(entries)
	# The board answered, so a batch that failed earlier has a chance now.
	if not pending.is_empty() and not client.submit_pending():
		flush()
	_settle()


func _on_batch_submitted(receipts: Array[SubmitReceipt]) -> void:
	var ids := PackedStringArray()
	for receipt in receipts:
		ids.append(receipt.submission_id)
	pending.remove(ids)
	_in_flight = PackedStringArray()
	DebugLog.info(TAG, "%d shift(s) posted; %d waiting" % [receipts.size(), pending.size()])
	for receipt in receipts:
		receipt_received.emit(receipt)
	if not pending.is_empty():
		flush()
	_settle()


func _on_failed(operation: String, reason: String) -> void:
	if reason == LeaderboardClient.REASON_DISABLED:
		_set_status(Status.DISABLED)
		return
	last_failure = reason
	if operation == LeaderboardClient.OP_SUBMIT:
		if LeaderboardRequests.is_rejection(reason):
			DebugLog.warn(TAG, "board refused %d shift(s) (%s); dropping them" % [
					_in_flight.size(), reason])
			pending.remove(_in_flight)
		_in_flight = PackedStringArray()
	_set_status(Status.OFFLINE)
	if not pending.is_empty() and client.submit_enabled():
		_retry.start(config.sync_retry_sec)


## Status once a request has come back: still busy, all caught up, or waiting.
func _settle() -> void:
	if client.fetch_pending() or client.submit_pending():
		_set_status(Status.SYNCING)
	elif pending.is_empty() or not client.submit_enabled():
		_set_status(Status.SYNCED)
	else:
		_set_status(Status.OFFLINE)


func _set_status(value: Status) -> void:
	if value == status:
		return
	status = value
	status_changed.emit(status)

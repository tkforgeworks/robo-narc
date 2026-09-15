extends GutTest
## The two on-disk halves of the leaderboard service: the queue of unsent
## shifts and the cached copy of the board.

const PENDING := "user://test_pending_store.json"
const CACHE := "user://test_board_cache.json"


func after_each() -> void:
	PendingStore.new(PENDING).clear()
	BoardCache.new(CACHE).clear()


func _result(score: int, id: String) -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.submission_id = id
	r.identity = PlayerIdentity.named("ava@example.com", "Ava", "K")
	return r


func test_pending_persists_in_order_and_drops_acknowledged_ids() -> void:
	var store := PendingStore.new(PENDING)
	store.append(_result(1, "a"))
	store.append(_result(2, "b"))
	store.append(_result(3, "c"))
	var reloaded := PendingStore.new(PENDING)
	assert_eq(reloaded.size(), 3)
	assert_eq(reloaded.results[0].submission_id, "a", "oldest first")
	assert_eq(reloaded.results[0].identity.display_name(), "Ava K.")
	assert_true(reloaded.has("b"))
	assert_eq(reloaded.first(2).size(), 2)
	assert_eq(reloaded.first(2)[1].submission_id, "b")
	reloaded.remove(PackedStringArray(["a", "c", "unknown"]))
	assert_eq(reloaded.size(), 1)
	assert_eq(PendingStore.new(PENDING).results[0].submission_id, "b", "removal saved")
	reloaded.remove(PackedStringArray())
	assert_eq(reloaded.size(), 1, "empty id list is a no-op")


func test_pending_is_capped_and_clear_removes_the_file() -> void:
	var store := PendingStore.new(PENDING)
	for i in PendingStore.MAX_RECORDS + 2:
		store.results.append(_result(i, str(i)))
	store.append(_result(-1, "last"))
	assert_eq(store.size(), PendingStore.MAX_RECORDS)
	assert_eq(store.results.back().submission_id, "last", "newest kept")
	assert_false(store.has("0"), "oldest dropped")
	store.clear()
	assert_true(store.is_empty())
	assert_false(FileAccess.file_exists(PENDING))


func test_pending_ignores_a_corrupt_file() -> void:
	var file := FileAccess.open(PENDING, FileAccess.WRITE)
	file.store_string("{not an array")
	file.close()
	assert_true(PendingStore.new(PENDING).is_empty())


func test_board_cache_round_trips_entries_and_time() -> void:
	var cache := BoardCache.new(CACHE)
	assert_false(cache.has_entries())
	var entries: Array[LeaderboardEntry] = [
		LeaderboardEntry.new(1, "Ava K.", 2450), LeaderboardEntry.new(2, "anonymous 07", 10)]
	cache.store(entries, 1700000000)
	var reloaded := BoardCache.new(CACHE)
	assert_true(reloaded.has_entries())
	assert_eq(reloaded.fetched_at, 1700000000)
	assert_eq(reloaded.entries.size(), 2)
	assert_eq(reloaded.entries[1].name, "anonymous 07")
	assert_eq(reloaded.entries[1].rank, 2)
	assert_eq(reloaded.entries[0].score, 2450)
	reloaded.clear()
	assert_false(FileAccess.file_exists(CACHE))
	assert_eq(BoardCache.new(CACHE).fetched_at, 0)


func test_board_cache_stores_a_copy() -> void:
	var cache := BoardCache.new(CACHE)
	var entries: Array[LeaderboardEntry] = [LeaderboardEntry.new(1, "Ava K.", 1)]
	cache.store(entries)
	entries.clear()
	assert_eq(cache.entries.size(), 1)

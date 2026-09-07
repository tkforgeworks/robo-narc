extends GutTest

const TEST_PATH := "user://test_scores.json"


func before_each() -> void:
	ScoreStore.new(TEST_PATH).clear()


func after_each() -> void:
	ScoreStore.new(TEST_PATH).clear()


func _result(score: int, name: String = "") -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.player_name = name
	return r


func test_append_persists_newest_first() -> void:
	var store := ScoreStore.new(TEST_PATH)
	store.append(_result(100, "A"))
	store.append(_result(50, "B"))
	var reloaded := ScoreStore.new(TEST_PATH)
	assert_eq(reloaded.records.size(), 2)
	assert_eq(reloaded.records[0].result.player_name, "B")
	assert_eq(reloaded.records[1].result.score, 100)


func test_top_sorts_by_score() -> void:
	var store := ScoreStore.new(TEST_PATH)
	store.append(_result(10))
	store.append(_result(300))
	store.append(_result(200))
	var top := store.top(2)
	assert_eq(top.size(), 2)
	assert_eq(top[0].result.score, 300)
	assert_eq(top[1].result.score, 200)
	assert_eq(store.scores(), PackedInt32Array([200, 300, 10]))


func test_cap_at_max_records() -> void:
	var store := ScoreStore.new(TEST_PATH)
	for i in ScoreStore.MAX_RECORDS + 5:
		store.records.push_front(ScoreRecord.new(_result(i)))
	store.append(_result(999))
	assert_eq(store.records.size(), ScoreStore.MAX_RECORDS)
	assert_eq(store.records[0].result.score, 999)


func test_clear_removes_file() -> void:
	var store := ScoreStore.new(TEST_PATH)
	store.append(_result(1))
	store.clear()
	assert_false(FileAccess.file_exists(TEST_PATH))
	assert_eq(ScoreStore.new(TEST_PATH).records.size(), 0)


func test_corrupt_file_is_ignored() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{not an array}")
	file.close()
	var store := ScoreStore.new(TEST_PATH)
	assert_eq(store.records.size(), 0)


func test_record_keeps_remote_rank() -> void:
	var store := ScoreStore.new(TEST_PATH)
	var record := store.append(_result(42))
	record.submitted = true
	record.remote_rank = 7
	store.save()
	var reloaded := ScoreStore.new(TEST_PATH)
	assert_true(reloaded.records[0].submitted)
	assert_eq(reloaded.records[0].remote_rank, 7)

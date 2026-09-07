class_name LeaderboardRequests
extends RefCounted
## Pure request and response shaping for contracts/leaderboard-api.md: URLs,
## headers, payloads, failure reasons, and JSON parsing. No I/O, so it is unit
## tested without a transport; LeaderboardClient does the sending.

const PATH_TOP := "/rest/v1/rpc/top_scores"
const PATH_SCORES := "/rest/v1/scores"
const PATH_RANK := "/rest/v1/rpc/rank_for_score"
const REASON_TIMEOUT := "TIMEOUT"
const REASON_NETWORK := "NETWORK"
const REASON_BAD_JSON := "BAD_JSON"
const NO_RANK := -1


## The `client` column value: which platform submitted. Editor runs are tagged
## `editor` so test rows are easy to delete.
static func platform_tag() -> String:
	for feature in ["editor", "web", "windows", "android", "linux", "macos", "ios"]:
		if OS.has_feature(feature):
			return feature
	return "unknown"


static func url(base_url: String, path: String) -> String:
	return base_url.strip_edges().trim_suffix("/") + path


## Legacy anon keys are JWTs and go in both headers. The newer publishable
## keys (`sb_publishable_...`) are not JWTs and are rejected as a Bearer token,
## so they travel in `apikey` only.
static func headers_for(raw_key: String, return_minimal: bool) -> PackedStringArray:
	var key := raw_key.strip_edges()
	var headers := PackedStringArray(["apikey: %s" % key, "Content-Type: application/json"])
	if not key.begins_with("sb_"):
		headers.append("Authorization: Bearer %s" % key)
	if return_minimal:
		headers.append("Prefer: return=minimal")
	return headers


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


## Empty when the response is a success. A status code, when the server sent
## one, beats the transport result: the web build reports some 4xx answers with
## a non-success result.
static func failure_reason(result: int, code: int) -> String:
	if code >= 400:
		return "HTTP_%d" % code
	if result == HTTPRequest.RESULT_TIMEOUT:
		return REASON_TIMEOUT
	if result != HTTPRequest.RESULT_SUCCESS:
		return REASON_NETWORK
	if code < 200 or code >= 300:
		return "HTTP_%d" % code
	return ""


## The entries in a top_scores body, or null when it is not a JSON array.
static func parse_top_scores(body: String) -> Variant:
	var json := JSON.new()
	if json.parse(body) != OK or not json.data is Array:
		return null
	var entries: Array[LeaderboardEntry] = []
	for item: Variant in json.data:
		if item is Dictionary:
			entries.append(LeaderboardEntry.from_dict(item))
	return entries


## The rank in a rank_for_score body, or NO_RANK when it is not a number.
static func parse_rank(body: String) -> int:
	var json := JSON.new()
	if json.parse(body) != OK or not (json.data is float or json.data is int):
		return NO_RANK
	return int(json.data)

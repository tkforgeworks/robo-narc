class_name LeaderboardRequests
extends RefCounted
## Pure request and response shaping for contracts/leaderboard-api.md: URLs,
## headers, payloads, failure reasons, and JSON parsing. No I/O, so it is unit
## tested without a transport; LeaderboardClient does the sending.

const PATH_TOP := "/rest/v1/rpc/top_scores"
const PATH_SUBMIT := "/rest/v1/rpc/submit_shifts"
const REASON_TIMEOUT := "TIMEOUT"
const REASON_NETWORK := "NETWORK"
const REASON_BAD_JSON := "BAD_JSON"
## Answers that mean the payload itself was refused; resending cannot help.
const REJECTIONS: Array[String] = ["HTTP_400", "HTTP_422"]


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
static func headers_for(raw_key: String) -> PackedStringArray:
	var key := raw_key.strip_edges()
	var headers := PackedStringArray(["apikey: %s" % key, "Content-Type: application/json"])
	if not key.begins_with("sb_"):
		headers.append("Authorization: Bearer %s" % key)
	return headers


## The `submit_shifts` argument: one object per shift. Anonymous shifts send
## null identity fields; the server assigns their number.
static func payload_for(results: Array[ShiftResult], tag: String) -> Dictionary:
	var shifts: Array[Dictionary] = []
	for result in results:
		var anonymous := result.identity.is_anonymous()
		shifts.append({
			"submission_id": result.submission_id,
			"email": null if anonymous else result.identity.email,
			"first_name": null if anonymous else result.identity.first_name,
			"last_initial": null if anonymous else result.identity.last_initial,
			"score": result.score,
			"correct": result.correct,
			"wrong": result.wrong,
			"missed": result.missed,
			"empty": result.empty,
			"duration_sec": roundi(result.duration_sec),
			"f1": snappedf(result.f1(), 0.001),
			"client": tag,
		})
	return {"p_shifts": shifts}


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


static func is_rejection(reason: String) -> bool:
	return REJECTIONS.has(reason)


## The entries in a top_scores body, or null when it is not a JSON array.
static func parse_top_scores(body: String) -> Variant:
	var items: Variant = _parse_array(body)
	if items == null:
		return null
	var entries: Array[LeaderboardEntry] = []
	for item: Dictionary in items:
		entries.append(LeaderboardEntry.from_dict(item))
	return entries


## The receipts in a submit_shifts body, or null when it is not a JSON array.
static func parse_receipts(body: String) -> Variant:
	var items: Variant = _parse_array(body)
	if items == null:
		return null
	var receipts: Array[SubmitReceipt] = []
	for item: Dictionary in items:
		receipts.append(SubmitReceipt.from_dict(item))
	return receipts


## The dictionaries in a JSON array body, or null for anything else.
static func _parse_array(body: String) -> Variant:
	var json := JSON.new()
	if json.parse(body) != OK or not json.data is Array:
		return null
	var items: Array[Dictionary] = []
	for item: Variant in json.data:
		if item is Dictionary:
			items.append(item)
	return items

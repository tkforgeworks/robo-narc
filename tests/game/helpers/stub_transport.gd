extends LeaderboardTransport
## Records each request and completes it when the test says so.

var calls: Array[Dictionary] = []


func post(url: String, headers: PackedStringArray, body: String, timeout_sec: float) -> Error:
	if busy:
		return ERR_BUSY
	busy = true
	calls.append({"url": url, "headers": headers, "body": body, "timeout": timeout_sec})
	return OK


func respond(code: int, body: String, result: int = HTTPRequest.RESULT_SUCCESS) -> void:
	busy = false
	completed.emit(result, code, body)


func fail(result: int = HTTPRequest.RESULT_CANT_CONNECT) -> void:
	respond(0, "", result)


func last() -> Dictionary:
	return calls.back()


func last_json() -> Variant:
	return JSON.parse_string(last()["body"])

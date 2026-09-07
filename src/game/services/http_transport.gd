class_name HttpTransport
extends LeaderboardTransport
## LeaderboardTransport over Godot's HTTPRequest. No threads, so it works on
## the web export; one request in flight per instance.

var _request: HTTPRequest


func _init() -> void:
	_request = HTTPRequest.new()
	_request.use_threads = false
	_request.request_completed.connect(_on_completed)
	add_child(_request)


func post(url: String, headers: PackedStringArray, body: String, timeout_sec: float) -> Error:
	if busy:
		return ERR_BUSY
	_request.timeout = timeout_sec
	var err := _request.request(url, headers, HTTPClient.METHOD_POST, body)
	busy = err == OK
	return err


func _on_completed(result: int, response_code: int, _headers: PackedStringArray,
		body: PackedByteArray) -> void:
	busy = false
	completed.emit(result, response_code, body.get_string_from_utf8())

class_name LeaderboardTransport
extends Node
## One JSON POST at a time, reported back through `completed`. The real one
## (`HttpTransport`) wraps HTTPRequest; tests substitute a stub that records the
## call and completes it on demand.

signal completed(result: int, response_code: int, body: String)

var busy: bool = false


func post(_url: String, _headers: PackedStringArray, _body: String, _timeout_sec: float) -> Error:
	return ERR_UNAVAILABLE

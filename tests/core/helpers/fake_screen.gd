extends Control
## Test double for a screen hosted by ScreenHost.

signal navigation_requested(scene: PackedScene, payload: Variant)

var entered_payload: Variant = null
var enter_count: int = 0


func enter(payload: Variant) -> void:
	entered_payload = payload
	enter_count += 1


func go(scene: PackedScene, payload: Variant = null) -> void:
	navigation_requested.emit(scene, payload)

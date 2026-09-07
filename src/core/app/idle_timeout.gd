class_name IdleTimeout
extends Node
## Emits `timed_out` after `timeout_sec` with no input. Any InputEvent restarts
## the countdown. Runs while the tree is paused so an unattended booth still
## resets itself (spec FR-046).

signal timed_out

@export var timeout_sec: float = 60.0
@export var autostart: bool = true

var time_left: float = 0.0
var running: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if autostart:
		start()


## Starts (or restarts) the countdown; a positive `seconds` overrides `timeout_sec`.
func start(seconds: float = -1.0) -> void:
	if seconds > 0.0:
		timeout_sec = seconds
	time_left = timeout_sec
	running = true


func stop() -> void:
	running = false


func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	if time_left <= 0.0:
		running = false
		timed_out.emit()


func _input(_event: InputEvent) -> void:
	if running:
		time_left = timeout_sec

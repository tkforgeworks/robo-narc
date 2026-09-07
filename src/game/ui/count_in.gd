class_name CountIn
extends Control
## The 3-2-1 overlay before a shift starts or resumes. Restart-safe: calling
## run() again cancels the current countdown instead of stacking.

signal tick_played(number: int)
signal finished

@onready var _label: Label = $Label

var _time_left: float = 0.0
var _running: bool = false
var _last_shown: int = -1


func _ready() -> void:
	visible = false


func run(seconds: float) -> void:
	if seconds <= 0.0:
		_running = false
		visible = false
		finished.emit()
		return
	_time_left = seconds
	_running = true
	_last_shown = -1
	visible = true
	_show(int(ceil(_time_left)))


func cancel() -> void:
	_running = false
	visible = false


func _process(delta: float) -> void:
	if not _running:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_running = false
		visible = false
		finished.emit()
		return
	var number := int(ceil(_time_left))
	if number != _last_shown:
		_show(number)


func _show(number: int) -> void:
	_last_shown = number
	_label.text = str(number)
	tick_played.emit(number)

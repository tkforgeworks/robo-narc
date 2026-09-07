class_name FocusPauser
extends Node
## Pauses the scene tree when the application loses focus (tab hidden, window
## blurred, Android app backgrounded) and hands control back on return.
##
## With `hold_resume` false the tree unpauses as soon as focus returns. With it
## true, `resume_requested` is emitted and the tree stays paused until the owner
## calls `release()` (used by gameplay to run a resume count-in first).

signal paused
signal resume_requested

@export var hold_resume: bool = false

var is_paused_by_focus: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_on_focus_lost()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_on_focus_gained()


## Unpauses the tree after a held resume. Safe to call when nothing is held.
func release() -> void:
	if not is_paused_by_focus:
		return
	is_paused_by_focus = false
	get_tree().paused = false


func _on_focus_lost() -> void:
	if is_paused_by_focus:
		return
	is_paused_by_focus = true
	get_tree().paused = true
	paused.emit()


func _on_focus_gained() -> void:
	if not is_paused_by_focus:
		return
	resume_requested.emit()
	if not hold_resume:
		release()

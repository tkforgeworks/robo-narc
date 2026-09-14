class_name PauseMenu
extends CanvasLayer
## In-shift pause: the `pause` action (Escape) opens it and pauses the tree;
## Escape again or Resume hands control back, Quit leaves the shift. The owner
## gates opening through `can_open` and reacts to the signals; this node only
## owns the panel and the tree's paused flag.

signal opened
signal resume_requested
signal quit_requested

## Whether Escape may open the menu right now (e.g. not once the shift ended).
var can_open: Callable = func() -> bool: return true

@onready var _root: Control = $Root
@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_resume_button.pressed.connect(resume)
	_quit_button.pressed.connect(quit)


func is_open() -> bool:
	return _root.visible


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if is_open():
		resume()
	elif not get_tree().paused and can_open.call():
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func open() -> void:
	if is_open():
		return
	get_tree().paused = true
	_root.visible = true
	_resume_button.grab_focus()
	opened.emit()


func resume() -> void:
	if not is_open():
		return
	_root.visible = false
	get_tree().paused = false
	resume_requested.emit()


func quit() -> void:
	if not is_open():
		return
	_root.visible = false
	get_tree().paused = false
	quit_requested.emit()

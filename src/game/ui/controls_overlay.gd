class_name ControlsOverlay
extends CanvasLayer
## The controls card shown over a screen: at shift start (with a "don't show
## this again" box the owner persists) and on demand from About the Game.
## Dismissed by the button or any accept / capture / cancel press.

signal dismissed(dont_show_again: bool)

@onready var _root: Control = $Root
@onready var _opt_out: CheckBox = %OptOut
@onready var _ok_button: Button = %OkButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_ok_button.pressed.connect(close)


func is_open() -> bool:
	return _root.visible


## `with_opt_out` shows the "don't show this again" box.
func open(with_opt_out: bool) -> void:
	_opt_out.visible = with_opt_out
	_opt_out.button_pressed = false
	_root.visible = true
	_ok_button.grab_focus()


func close() -> void:
	if not is_open():
		return
	_root.visible = false
	dismissed.emit(_opt_out.visible and _opt_out.button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("capture") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()

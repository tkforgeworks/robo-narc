class_name NameEntry
extends Control
## End-of-shift name prompt (spec FR-043, FR-043a): a 12-letter field with
## inline validation, Submit, and Skip (neutral default name). Touch relies on
## the OS keyboard the LineEdit opens on focus; touch and gamepad also get an
## on-screen letter grid navigable by stick or tap.

signal name_chosen(name: String)

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const BACKSPACE_LABEL := "DEL"
const KEY_SIZE := Vector2(40, 40)

var config: TuningConfig
## Injectable; defaults to the shipped profanity list.
var validator: NameValidator

var _chosen: bool = false

@onready var _edit: LineEdit = %NameEdit
@onready var _message: Label = %Message
@onready var _submit_button: Button = %SubmitButton
@onready var _skip_button: Button = %SkipButton
@onready var _grid: GridContainer = %LetterGrid


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if validator == null:
		validator = NameValidator.new()
	_edit.max_length = NameValidator.MAX_LENGTH
	_edit.text_changed.connect(_on_text_changed)
	_edit.text_submitted.connect(func(_text: String) -> void: submit())
	_submit_button.pressed.connect(submit)
	_skip_button.pressed.connect(skip)
	_build_grid()
	_grid.visible = false
	_on_text_changed(_edit.text)
	_edit.grab_focus()


func prefill(name: String) -> void:
	_edit.text = name
	_edit.caret_column = name.length()
	_on_text_changed(name)


## Keyboard players type; touch and gamepad players get the letter grid too.
func set_input_source(source: InputSource.Source) -> void:
	_grid.visible = source != InputSource.Source.KEYBOARD
	if source == InputSource.Source.GAMEPAD and _grid.get_child_count() > 0:
		(_grid.get_child(0) as Control).grab_focus()
	elif not _grid.visible:
		_edit.grab_focus()


func current_text() -> String:
	return _edit.text


func submit() -> void:
	if _chosen:
		return
	var result := validator.validate(_edit.text)
	if not result.ok:
		_message.text = result.message
		return
	_choose(NameValidator.clean(_edit.text))


func skip() -> void:
	if not _chosen:
		_choose(config.default_player_name)


func _choose(name: String) -> void:
	_chosen = true
	name_chosen.emit(name)


func _on_text_changed(text: String) -> void:
	var result := validator.validate(text)
	_submit_button.disabled = not result.ok
	_message.text = "" if result.ok or text.strip_edges().is_empty() else result.message


func _build_grid() -> void:
	for ch in LETTERS:
		_add_key(ch, func() -> void: _append(ch))
	_add_key(BACKSPACE_LABEL, _backspace)


func _add_key(label: String, action: Callable) -> void:
	var key := Button.new()
	key.text = label
	key.custom_minimum_size = KEY_SIZE
	key.focus_mode = Control.FOCUS_ALL
	key.pressed.connect(action)
	_grid.add_child(key)


func _append(ch: String) -> void:
	if _edit.text.length() >= NameValidator.MAX_LENGTH:
		return
	_edit.text += ch
	_edit.caret_column = _edit.text.length()
	_on_text_changed(_edit.text)


func _backspace() -> void:
	_edit.text = _edit.text.left(-1)
	_edit.caret_column = _edit.text.length()
	_on_text_changed(_edit.text)

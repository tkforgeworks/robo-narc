class_name DebugMenu
extends CanvasLayer
## Live tuning menu (debug builds only). Enumerates every TuningConfig property
## and every registered style, pauses the tree while open, and offers reset,
## save-overrides, live volume, and any actions the game layer registers.
## DebugSectionBuilder builds the rows.

signal opened
signal closed
signal volume_changed(bus_name: String, linear: float)

const TAG := "DebugMenu"
const VOLUME_BUSES: PackedStringArray = ["master", "music", "sfx"]

## Injected by Main; falls back to the Tuning autoload.
var tuning: TuningService
## Optional: when set, a "Live volume" section edits it and emits volume_changed.
var settings: SettingsStore

var _paused_by_me: bool = false
var _actions: Dictionary = {}
var _builder: DebugSectionBuilder

@onready var _root: Control = $Root
@onready var _sections: VBoxContainer = %Sections
@onready var _actions_box: HBoxContainer = %Actions
@onready var _reset_button: Button = %ResetButton
@onready var _save_button: Button = %SaveButton
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tuning == null:
		tuning = Tuning
	_builder = DebugSectionBuilder.new(_sections)
	_root.visible = false
	_reset_button.pressed.connect(func() -> void: tuning.reset_to_defaults())
	_save_button.pressed.connect(_on_save_pressed)
	_close_button.pressed.connect(close)
	tuning.reset.connect(func() -> void:
		if is_open():
			_build())


func is_open() -> bool:
	return _root.visible


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func open() -> void:
	_build()
	_root.visible = true
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	DebugLog.info(TAG, "opened")
	opened.emit()


func close() -> void:
	_root.visible = false
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	DebugLog.info(TAG, "closed")
	closed.emit()


## Adds (or replaces, by label) a button in the header row.
func register_action(label: String, action: Callable) -> void:
	if _actions.has(label):
		(_actions[label] as Button).queue_free()
	var button := Button.new()
	button.text = label
	button.pressed.connect(action)
	_actions_box.add_child(button)
	_actions[label] = button


## Number of tunable controls currently built (for tests).
func control_count() -> int:
	return _builder.control_count()


func _build() -> void:
	_builder.clear()
	for group in TunableProperties.grouped(tuning.config):
		_builder.add_tunables(str(group["name"]), tuning.config, group["properties"],
				func(name: String, value: Variant) -> void: tuning.set_value(name, value))
	for style in tuning.get_styles():
		var key := str(style.get("key"))
		var properties: Array[Dictionary] = []
		for property in TunableProperties.list(style):
			if property["name"] != "key":
				properties.append(property)
		_builder.add_tunables("Style: %s" % key, style, properties,
				func(name: String, value: Variant) -> void: tuning.set_style_value(key, name, value))
	if settings != null:
		_builder.add_volume("Live volume", VOLUME_BUSES, settings,
				func(bus: String, value: float) -> void: volume_changed.emit(bus, value))


func _on_save_pressed() -> void:
	var err := tuning.save_overrides()
	DebugLog.info(TAG, "save overrides -> %s" % error_string(err))

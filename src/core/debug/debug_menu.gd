class_name DebugMenu
extends CanvasLayer
## Live tuning menu (debug builds only). Enumerates every TuningConfig property
## and every registered style, pauses the tree while open, and offers reset,
## save-overrides, live volume, and any actions the game layer registers.

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
	_root.visible = false
	_reset_button.pressed.connect(_on_reset_pressed)
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
	var count := 0
	for section in _sections.get_children():
		if section is GridContainer:
			count += section.get_child_count() / 2
	return count


func _build() -> void:
	for child in _sections.get_children():
		child.free()
	for group in TunableProperties.grouped(tuning.config):
		_add_section(str(group["name"]), tuning.config, group["properties"],
				func(name: String, value: Variant) -> void: tuning.set_value(name, value))
	for style in tuning.get_styles():
		var key := str(style.get("key"))
		var properties: Array[Dictionary] = []
		for property in TunableProperties.list(style):
			if property["name"] != "key":
				properties.append(property)
		_add_section("Style: %s" % key, style, properties,
				func(name: String, value: Variant) -> void: tuning.set_style_value(key, name, value))
	if settings != null:
		_add_volume_section()


func _add_section(title: String, object: Object, properties: Array,
		on_commit: Callable) -> void:
	_add_heading(title)
	var grid := GridContainer.new()
	grid.columns = 2
	var factory := TunableControlFactory.new()
	factory.value_committed.connect(on_commit)
	for property: Dictionary in properties:
		var label := Label.new()
		label.text = property["name"]
		grid.add_child(label)
		grid.add_child(factory.build(object, property))
	grid.set_meta("factory", factory)
	_sections.add_child(grid)


func _add_volume_section() -> void:
	_add_heading("Live volume")
	var grid := GridContainer.new()
	grid.columns = 2
	for bus in VOLUME_BUSES:
		var label := Label.new()
		label.text = bus
		grid.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.custom_minimum_size.x = 200.0
		slider.value = settings.get(bus)
		slider.value_changed.connect(func(v: float) -> void:
			settings.set(bus, v)
			settings.save()
			volume_changed.emit(bus, v))
		grid.add_child(slider)
	_sections.add_child(grid)


func _add_heading(text: String) -> void:
	var heading := Label.new()
	heading.text = text
	heading.add_theme_font_size_override("font_size", 20)
	_sections.add_child(heading)


func _on_reset_pressed() -> void:
	tuning.reset_to_defaults()


func _on_save_pressed() -> void:
	var err := tuning.save_overrides()
	DebugLog.info(TAG, "save overrides -> %s" % error_string(err))

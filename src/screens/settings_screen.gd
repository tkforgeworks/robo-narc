class_name SettingsScreen
extends Control
## Master / Music / SFX volume sliders and the "show controls at shift start"
## toggle, persisted across sessions (spec FR-022), plus the way to the
## read-only Controls screen.
## Main injects the settings store and audio mixer via the bind_* methods.

signal navigation_requested(scene: PackedScene, payload: Variant)

const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"
const CONTROLS_SCENE_PATH := "res://scenes/screens/controls_screen.tscn"

var settings: SettingsStore
var audio_mixer: AudioMixer

@onready var _sliders: Dictionary = {
	"master": %MasterSlider,
	"music": %MusicSlider,
	"sfx": %SfxSlider,
}
@onready var _show_controls: CheckButton = %ShowControlsToggle
@onready var _controls_button: Button = %ControlsButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	for key: String in _sliders:
		var slider: HSlider = _sliders[key]
		slider.value_changed.connect(_on_slider_changed.bind(key))
	_show_controls.toggled.connect(_on_show_controls_toggled)
	_controls_button.pressed.connect(func() -> void:
		navigation_requested.emit(load(CONTROLS_SCENE_PATH), null))
	_back_button.pressed.connect(func() -> void: _go_back())
	_refresh()
	(_sliders["master"] as HSlider).grab_focus()


func bind_settings(store: SettingsStore) -> void:
	settings = store
	_refresh()


func bind_audio_mixer(mixer: AudioMixer) -> void:
	audio_mixer = mixer


func _refresh() -> void:
	if settings == null or _sliders.is_empty():
		return
	for key: String in _sliders:
		(_sliders[key] as HSlider).set_value_no_signal(settings.get(key))
	_show_controls.set_pressed_no_signal(settings.show_controls_on_start)


func _on_slider_changed(value: float, key: String) -> void:
	if settings == null:
		return
	settings.set(key, value)
	settings.save()
	if audio_mixer != null:
		audio_mixer.set_volume(key, value)


func _on_show_controls_toggled(on: bool) -> void:
	if settings == null:
		return
	settings.show_controls_on_start = on
	settings.save()


func _go_back() -> void:
	navigation_requested.emit(load(TITLE_SCENE_PATH), null)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

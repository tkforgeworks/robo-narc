class_name SettingsScreen
extends Control
## Master / Music / SFX volume sliders, persisted across sessions (spec FR-022).
## Main injects the settings store and audio mixer via the bind_* methods.

signal navigation_requested(scene: PackedScene, payload: Variant)

const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"

var settings: SettingsStore
var audio_mixer: AudioMixer

@onready var _sliders: Dictionary = {
	"master": %MasterSlider,
	"music": %MusicSlider,
	"sfx": %SfxSlider,
}
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	for key: String in _sliders:
		var slider: HSlider = _sliders[key]
		slider.value_changed.connect(_on_slider_changed.bind(key))
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


func _on_slider_changed(value: float, key: String) -> void:
	if settings == null:
		return
	settings.set(key, value)
	settings.save()
	if audio_mixer != null:
		audio_mixer.set_volume(key, value)


func _go_back() -> void:
	navigation_requested.emit(load(TITLE_SCENE_PATH), null)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

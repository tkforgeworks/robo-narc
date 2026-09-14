class_name ControlsScreen
extends Control
## Read-only view of the current bindings, reached from Settings. Rebinding is
## deliberately not offered (arcade build).

signal navigation_requested(scene: PackedScene, payload: Variant)

const SETTINGS_SCENE_PATH := "res://scenes/screens/settings_screen.tscn"

@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(_go_back)
	_back_button.grab_focus()


func _go_back() -> void:
	navigation_requested.emit(load(SETTINGS_SCENE_PATH), null)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

class_name TitleScreen
extends Control
## Title screen (US1 minimal form): name, Start, Quit. Expanded in US4.

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"

@onready var _start_button: Button = %StartButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_quit_button.visible = not OS.has_feature("web")
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	navigation_requested.emit(load(GAMEPLAY_SCENE_PATH), null)

class_name TitleScreen
extends Control
## Title screen (US1 minimal form): name, Start, Quit, and a DEBUG button in
## debug builds. Expanded in US4.

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"

var _debug_menu: DebugMenu = null

@onready var _start_button: Button = %StartButton
@onready var _quit_button: Button = %QuitButton
@onready var _debug_button: Button = %DebugButton


func _ready() -> void:
	_quit_button.visible = not OS.has_feature("web")
	_debug_button.visible = false
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	_debug_button.pressed.connect(_on_debug_pressed)
	_start_button.grab_focus()


## Called by Main in debug builds.
func bind_debug_menu(menu: DebugMenu) -> void:
	_debug_menu = menu
	_debug_button.visible = true
	menu.register_action("Clear local scores", func() -> void:
		ScoreStore.new().clear()
		DebugLog.info("Title", "local scores cleared"))


func _on_start_pressed() -> void:
	navigation_requested.emit(load(GAMEPLAY_SCENE_PATH), null)


func _on_debug_pressed() -> void:
	if _debug_menu != null:
		_debug_menu.open()

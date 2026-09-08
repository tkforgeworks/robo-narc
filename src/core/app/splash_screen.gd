class_name SplashScreen
extends Control
## Studio logo card shown before the first game screen. Holds for `hold_sec`
## or until any input, then navigates to `next_screen`. The logo comes from
## `logo_path` and falls back to the checkerboard placeholder (logged) so the
## template runs before any branding exists.

signal navigation_requested(scene: PackedScene, payload: Variant)

@export var next_screen: PackedScene
@export var logo_path: String = "res://assets/ui/logo.png"
@export_range(0.5, 10.0, 0.5) var hold_sec: float = 2.0
@export var skippable: bool = true

var _time_left: float = 0.0
var _done: bool = false

@onready var _logo: TextureRect = %Logo


func _ready() -> void:
	if ResourceLoader.exists(logo_path):
		_logo.texture = load(logo_path)
	else:
		_logo.texture = PlaceholderTexture.register_use("studio logo")
	_time_left = hold_sec


func _process(delta: float) -> void:
	if _done:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		finish()


func _unhandled_input(event: InputEvent) -> void:
	if skippable and (event.is_pressed() or event is InputEventScreenTouch):
		finish()


func finish() -> void:
	if _done:
		return
	_done = true
	navigation_requested.emit(next_screen, null)

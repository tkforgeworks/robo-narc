class_name AboutScreen
extends Control
## "About the Game": the elevator pitch of the real-world program the game is
## modeled on (spec FR-021), the WHO TO SNAP cue sheet, and the links block.
## Edit the BBCode `text` of the Links node in the scene
## (`[url=https://...]label[/url]`); LinkText opens them in the browser.

signal navigation_requested(scene: PackedScene, payload: Variant)

const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"
const IMAGE_DIR := "res://assets/ui/about"

const PITCH := """In Traffic Fighter 3 you’re a Hayden AI camera system scanning the road for vehicles illegally parked in bus lanes, bus stops, and bike lanes. Traffic appears at the horizon and will move toward your bus. It’s up to you to determine whether a car gets a ticket.
"""

@onready var _text: Label = %PitchText
@onready var _image: TextureRect = %Image
@onready var _controls_button: Button = %ControlsButton
@onready var _back_button: Button = %BackButton
@onready var _controls: ControlsOverlay = $ControlsOverlay


func _ready() -> void:
	_text.text = PITCH
	var textures := SpriteFolderScanner.list_textures(IMAGE_DIR)
	_image.visible = not textures.is_empty()
	if not textures.is_empty():
		_image.texture = textures[0]
	_controls_button.pressed.connect(func() -> void: _controls.open(false))
	_controls.dismissed.connect(func(_opt_out: bool) -> void: _back_button.grab_focus())
	_back_button.pressed.connect(func() -> void:
		navigation_requested.emit(load(TITLE_SCENE_PATH), null))
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		navigation_requested.emit(load(TITLE_SCENE_PATH), null)

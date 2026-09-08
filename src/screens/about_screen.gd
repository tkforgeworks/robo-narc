class_name AboutScreen
extends Control
## Elevator pitch of the real-world program the game is modeled on (spec FR-021),
## plus the links block: edit the BBCode `text` of the Links node in the scene
## (`[url=https://...]label[/url]`); LinkText opens them in the browser.

signal navigation_requested(scene: PackedScene, payload: Variant)

const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"
const IMAGE_DIR := "res://assets/ui/about"

const PITCH := """RoboNarc is modeled on Automated Camera Enforcement: cameras mounted on city buses, like the ones on New York City's MTA fleet, that photograph the license plates of vehicles blocking bus lanes and bus stops.

Every car parked in a bus lane slows down everyone on the bus behind it. Camera enforcement keeps buses moving, gives riders a reliable trip, and does it without pulling officers off other work. Plates are reviewed by people before any ticket is issued.

In this game you are the camera. Read each car the way a reviewer would: where is it sitting, is it moving, what is next to it? Snap the ones breaking the rules and leave the innocent drivers alone."""

@onready var _text: Label = %PitchText
@onready var _image: TextureRect = %Image
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_text.text = PITCH
	var textures := SpriteFolderScanner.list_textures(IMAGE_DIR)
	_image.visible = not textures.is_empty()
	if not textures.is_empty():
		_image.texture = textures[0]
	_back_button.pressed.connect(func() -> void:
		navigation_requested.emit(load(TITLE_SCENE_PATH), null))
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		navigation_requested.emit(load(TITLE_SCENE_PATH), null)

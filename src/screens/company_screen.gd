class_name CompanyScreen
extends Control
## "About the Company" card: the HaydenAI mark, a blurb, and links. Edit the
## wording in BLURB and the BBCode `text` of the Links node in the scene
## (`[url=https://...]label[/url]`); LinkText opens them in the browser.

signal navigation_requested(scene: PackedScene, payload: Variant)

const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"

const BLURB := """About the company goes here.

Replace this text in src/screens/company_screen.gd (BLURB) and add links in the Links node of scenes/screens/company_screen.tscn."""

@onready var _text: Label = %BlurbText
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_text.text = BLURB
	_back_button.pressed.connect(func() -> void:
		navigation_requested.emit(load(TITLE_SCENE_PATH), null))
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		navigation_requested.emit(load(TITLE_SCENE_PATH), null)

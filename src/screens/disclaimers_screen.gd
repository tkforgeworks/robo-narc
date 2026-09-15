class_name DisclaimersScreen
extends Control
## "Disclaimers and Data Privacy", reached from About the Game and Settings:
## the game is not a product demonstration, AI helped build it, and what
## happens to a leaderboard email. Plain language, not legal text; edit the
## constants below. Back returns to whichever screen opened it (the payload
## is that screen's scene path).

signal navigation_requested(scene: PackedScene, payload: Variant)

const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"

const NOT_A_DEMO := """Traffic Fighter 3 is a game, not a demonstration of Hayden AI's products. Real Hayden AI systems detect and review violations automatically; here a person aims the camera and makes every call, and the traffic, rules, and scoring are simplified for play. Nothing in the game reflects how a deployed system performs."""

const BUILT_WITH_AI := """AI tools helped build this game. Parts of the code, tooling, artwork pipeline, and supporting text were drafted with AI assistance, then reviewed, directed, and tested by the developer. Any mistakes are the developer's."""

const DATA_PRIVACY := """Entering an email for the leaderboard is optional. An email you provide is used only by Hayden AI: it keeps one board entry per player and is never shown on the board. It will not be sold, shared, or otherwise distributed to anyone else. Play anonymously if you would rather not provide one."""

var _return_path: String = TITLE_SCENE_PATH

@onready var _not_a_demo: Label = %NotADemoText
@onready var _built_with_ai: Label = %BuiltWithAiText
@onready var _data_privacy: Label = %DataPrivacyText
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_not_a_demo.text = NOT_A_DEMO
	_built_with_ai.text = BUILT_WITH_AI
	_data_privacy.text = DATA_PRIVACY
	_back_button.pressed.connect(_go_back)
	_back_button.grab_focus()


## The opening screen passes its own scene path so Back lands there.
func enter(payload: Variant) -> void:
	if payload is String and ResourceLoader.exists(payload):
		_return_path = payload


func return_path() -> String:
	return _return_path


func _go_back() -> void:
	navigation_requested.emit(load(_return_path), null)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

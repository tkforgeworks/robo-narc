class_name TitleScreen
extends Control
## Title screen: branding, cue sheet, the shared top-20 board (local history
## until it answers), Start / About / Settings / Quit, and a DEBUG button in
## debug builds.

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"
const ABOUT_SCENE_PATH := "res://scenes/screens/about_screen.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/screens/settings_screen.tscn"

var config: TuningConfig
## Injectable for tests; defaults to the shared local score file.
var score_store: ScoreStore
## Injectable for tests; null lets the client load the active config.
var leaderboard_config: LeaderboardConfig

var _debug_menu: DebugMenu = null

@onready var _start_button: Button = %StartButton
@onready var _about_button: Button = %AboutButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _debug_button: Button = %DebugButton
@onready var _board: LeaderboardPanel = %Leaderboard
@onready var _client: LeaderboardClient = $LeaderboardClient


func _enter_tree() -> void:
	if leaderboard_config != null:
		$LeaderboardClient.config = leaderboard_config


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if score_store == null:
		score_store = ScoreStore.new()
	_quit_button.visible = not OS.has_feature("web")
	_debug_button.visible = false
	_start_button.pressed.connect(func() -> void: _go(GAMEPLAY_SCENE_PATH))
	_about_button.pressed.connect(func() -> void: _go(ABOUT_SCENE_PATH))
	_settings_button.pressed.connect(func() -> void: _go(SETTINGS_SCENE_PATH))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	_debug_button.pressed.connect(_on_debug_pressed)
	_client.top_scores_received.connect(_board.show_entries)
	_client.failed.connect(_on_fetch_failed)
	_show_local()
	_client.fetch_top(config.top_count)
	_start_button.grab_focus()


## Called by Main in debug builds.
func bind_debug_menu(menu: DebugMenu) -> void:
	_debug_menu = menu
	_debug_button.visible = true
	menu.register_action("Clear local scores", func() -> void:
		ScoreStore.new().clear()
		score_store.read()
		_show_local()
		DebugLog.info("Title", "local scores cleared"))


func score_row_count() -> int:
	return _board.row_count()


func _show_local(note: String = "") -> void:
	_board.show_local(score_store.top(config.top_count), note)


func _on_fetch_failed(_operation: String, reason: String) -> void:
	var note := "" if reason == LeaderboardClient.REASON_DISABLED else LeaderboardPanel.UNAVAILABLE_NOTE
	_show_local(note)


func _go(path: String) -> void:
	navigation_requested.emit(load(path), null)


func _on_debug_pressed() -> void:
	if _debug_menu != null:
		_debug_menu.open()

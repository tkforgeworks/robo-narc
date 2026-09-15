class_name TitleScreen
extends Control
## Title screen: branding, the shared top-N board (the cached copy until the
## board answers) with its sync indicator, Start / About the Game / About the
## Company / Settings / Quit, and a DEBUG button in debug builds.

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"
const ABOUT_SCENE_PATH := "res://scenes/screens/about_screen.tscn"
const COMPANY_SCENE_PATH := "res://scenes/screens/company_screen.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/screens/settings_screen.tscn"

var config: TuningConfig
## Injectable for tests; null uses the `Leaderboard` autoload.
var leaderboard: LeaderboardService

var _debug_menu: DebugMenu = null

@onready var _start_button: Button = %StartButton
@onready var _about_button: Button = %AboutButton
@onready var _company_button: Button = %CompanyButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _debug_button: Button = %DebugButton
@onready var _board: LeaderboardPanel = %Leaderboard


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if leaderboard == null:
		leaderboard = get_tree().root.get_node_or_null(^"Leaderboard")
	if leaderboard == null:
		leaderboard = LeaderboardService.new()
		add_child(leaderboard)
	_quit_button.visible = not OS.has_feature("web")
	_debug_button.visible = false
	_start_button.pressed.connect(func() -> void: _go(GAMEPLAY_SCENE_PATH))
	_about_button.pressed.connect(func() -> void: _go(ABOUT_SCENE_PATH))
	_company_button.pressed.connect(func() -> void: _go(COMPANY_SCENE_PATH))
	_settings_button.pressed.connect(func() -> void: _go(SETTINGS_SCENE_PATH))
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	_debug_button.pressed.connect(_on_debug_pressed)
	leaderboard.board_updated.connect(_on_board_updated)
	leaderboard.status_changed.connect(_on_status_changed)
	_on_board_updated(leaderboard.cached_entries())
	_on_status_changed(leaderboard.status)
	leaderboard.refresh_board()
	leaderboard.flush()
	_start_button.grab_focus()


## Called by Main in debug builds.
func bind_debug_menu(menu: DebugMenu) -> void:
	_debug_menu = menu
	_debug_button.visible = true
	menu.register_action("Clear board cache and unsent shifts", func() -> void:
		leaderboard.clear_local()
		DebugLog.info("Title", "board cache and pending shifts cleared"))


func score_row_count() -> int:
	return _board.row_count()


func _on_board_updated(entries: Array[LeaderboardEntry]) -> void:
	_board.show_entries(entries, _board_note())


func _on_status_changed(status: int) -> void:
	_board.show_sync(status, leaderboard.pending_count())
	_board.show_entries(leaderboard.cached_entries(), _board_note())


func _board_note() -> String:
	if leaderboard.status != LeaderboardService.Status.OFFLINE:
		return ""
	return LeaderboardPanel.CACHED_NOTE if leaderboard.cache.has_entries() else LeaderboardPanel.UNAVAILABLE_NOTE


func _go(path: String) -> void:
	navigation_requested.emit(load(path), null)


func _on_debug_pressed() -> void:
	if _debug_menu != null:
		_debug_menu.open()

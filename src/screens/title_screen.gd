class_name TitleScreen
extends Control
## Title screen: branding, cue sheet, local top scores (the shared board
## replaces the panel in US7), Start / About / Settings / Quit, and a DEBUG
## button in debug builds.

signal navigation_requested(scene: PackedScene, payload: Variant)

const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"
const ABOUT_SCENE_PATH := "res://scenes/screens/about_screen.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/screens/settings_screen.tscn"

var config: TuningConfig
## Injectable for tests; defaults to the shared local score file.
var score_store: ScoreStore

var _debug_menu: DebugMenu = null

@onready var _start_button: Button = %StartButton
@onready var _about_button: Button = %AboutButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _debug_button: Button = %DebugButton
@onready var _scores_list: VBoxContainer = %ScoresList


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
	_populate_scores()
	_start_button.grab_focus()


## Called by Main in debug builds.
func bind_debug_menu(menu: DebugMenu) -> void:
	_debug_menu = menu
	_debug_button.visible = true
	menu.register_action("Clear local scores", func() -> void:
		ScoreStore.new().clear()
		_populate_scores()
		DebugLog.info("Title", "local scores cleared"))


func score_row_count() -> int:
	return _scores_list.get_child_count()


func _populate_scores() -> void:
	for child in _scores_list.get_children():
		child.queue_free()
	var records := score_store.top(config.top_count)
	if records.is_empty():
		var empty := Label.new()
		empty.text = "No shifts played yet"
		_scores_list.add_child(empty)
		return
	var rank := 1
	for record in records:
		var row := Label.new()
		var name := record.result.player_name
		row.text = "%2d.  %-12s %6d" % [rank, name if not name.is_empty() else "---", record.result.score]
		_scores_list.add_child(row)
		rank += 1


func _go(path: String) -> void:
	navigation_requested.emit(load(path), null)


func _on_debug_pressed() -> void:
	if _debug_menu != null:
		_debug_menu.open()

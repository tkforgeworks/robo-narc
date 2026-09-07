class_name Main
extends Node
## Persistent root scene. Composes the screen host, input-source tracker, focus
## pauser, and settings store, and wires them to whichever screen is active.
## Game-agnostic: the first screen is an export set in main.tscn.

const TAG := "Main"

@export var initial_screen: PackedScene

var settings: SettingsStore

@onready var screen_host: ScreenHost = $ScreenHost
@onready var input_source: InputSource = $InputSource
@onready var focus_pauser: FocusPauser = $FocusPauser


func _ready() -> void:
	settings = SettingsStore.new(SettingsStore.DEFAULT_PATH, Tuning.config)
	screen_host.screen_changed.connect(_on_screen_changed)
	if initial_screen == null:
		DebugLog.error(TAG, "no initial_screen set on main.tscn")
		return
	screen_host.show_screen(initial_screen)
	PlaceholderTexture.report.call_deferred()


## Connects focus-pause hooks on screens that opt in by defining the methods.
func _on_screen_changed(screen: Node) -> void:
	var handles_resume := screen.has_method("on_focus_resume_requested")
	focus_pauser.hold_resume = handles_resume
	if screen.has_method("on_focus_paused"):
		focus_pauser.paused.connect(screen.on_focus_paused)
	if handles_resume:
		focus_pauser.resume_requested.connect(screen.on_focus_resume_requested)
	if screen.has_method("bind_settings"):
		screen.bind_settings(settings)

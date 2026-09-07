class_name Main
extends Node
## Persistent root scene. Composes the screen host, input-source tracker, focus
## pauser, audio mixer, settings store, and (debug builds) the tuning menu, and
## wires them to whichever screen is active. Game-agnostic: the first screen
## is an export.

const TAG := "Main"
const DEBUG_MENU_SCENE: PackedScene = preload("res://scenes/core/debug_menu.tscn")

@export var initial_screen: PackedScene

var settings: SettingsStore
var debug_menu: DebugMenu = null

@onready var screen_host: ScreenHost = $ScreenHost
@onready var input_source: InputSource = $InputSource
@onready var focus_pauser: FocusPauser = $FocusPauser
@onready var audio_mixer: AudioMixer = $AudioMixer
@onready var letterbox: Letterbox = $Letterbox
@onready var touch_controls: TouchControls = $TouchControls


## The mixer applies settings in its own _ready, which runs before ours.
func _enter_tree() -> void:
	settings = SettingsStore.new(SettingsStore.DEFAULT_PATH, Tuning.config)
	get_node("AudioMixer").settings = settings


func _ready() -> void:
	if OS.is_debug_build():
		_install_debug_tools()
	screen_host.screen_changed.connect(_on_screen_changed)
	touch_controls.bind_input_source(input_source)
	touch_controls.bind_tuning(Tuning)
	if initial_screen == null:
		DebugLog.error(TAG, "no initial_screen set on main.tscn")
		return
	screen_host.show_screen(initial_screen)
	PlaceholderTexture.report.call_deferred()


func _install_debug_tools() -> void:
	debug_menu = DEBUG_MENU_SCENE.instantiate()
	debug_menu.tuning = Tuning
	debug_menu.settings = settings
	add_child(debug_menu)
	debug_menu.volume_changed.connect(audio_mixer.set_volume)
	var trigger := DebugTrigger.new()
	trigger.name = "DebugTrigger"
	add_child(trigger)
	trigger.toggle_requested.connect(debug_menu.toggle)


## Connects core services to screens that opt in by defining the methods:
## `on_focus_paused()`, `on_focus_resume_requested(release: Callable)`,
## `bind_settings(SettingsStore)`, `bind_audio_mixer(AudioMixer)`,
## `bind_input_source(InputSource)`, `bind_tuning(TuningService)`,
## `bind_debug_menu(DebugMenu)`.
func _on_screen_changed(screen: Node) -> void:
	# Control screens are responsive and fill the window. Node2D screens are the
	# fixed 1280 x 720 playfield (see Playfield): letterboxed, with touch controls
	# in the gutters.
	var fixed_playfield := screen is Node2D
	letterbox.visible = fixed_playfield
	touch_controls.set_playfield_active(fixed_playfield)
	var handles_resume := screen.has_method("on_focus_resume_requested")
	focus_pauser.hold_resume = handles_resume
	if screen.has_method("on_focus_paused"):
		focus_pauser.paused.connect(screen.on_focus_paused)
	if handles_resume:
		focus_pauser.resume_requested.connect(
				screen.on_focus_resume_requested.bind(focus_pauser.release))
	if screen.has_method("bind_settings"):
		screen.bind_settings(settings)
	if screen.has_method("bind_audio_mixer"):
		screen.bind_audio_mixer(audio_mixer)
	if screen.has_method("bind_input_source"):
		screen.bind_input_source(input_source)
	if screen.has_method("bind_tuning"):
		screen.bind_tuning(Tuning)
	if debug_menu != null and screen.has_method("bind_debug_menu"):
		screen.bind_debug_menu(debug_menu)

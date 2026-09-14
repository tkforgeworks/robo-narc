class_name GameplayScreen
extends Node2D
## Composes the shift. Wires child nodes by signal and drives the per-step
## order (bus, zones, lanes, vehicles, misses) in the physics step so the
## detection areas are current when a capture lands. No judgment or scoring
## logic here; live tuning, sounds, honks, and playfield centring are siblings.

signal navigation_requested(scene: PackedScene, payload: Variant)

const TAG := "Gameplay"
const RESULTS_SCENE_PATH := "res://scenes/screens/results_screen.tscn"
const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"

var config: TuningConfig
## Injected by Main; null (tests) skips the controls card at shift start.
var settings: SettingsStore

var _ramp: DifficultyRamp
var _capture_judge: CaptureJudge
var _miss_judge: MissJudge
var _registry: VehicleRegistry

@onready var _road_view: RoadView = $RoadView
@onready var _road_areas: RoadAreas = $RoadAreas
@onready var _zones: BusStopZones = $BusStopZones
@onready var _vehicle_layer: VehicleLayer = $VehicleLayer
@onready var _spawner: VehicleSpawner = $VehicleSpawner
@onready var _bus_driver: BusDriver = $BusDriver
@onready var _clock: ShiftClock = $ShiftClock
@onready var _score_keeper: ScoreKeeper = $ScoreKeeper
@onready var _bus_overlay: BusOverlay = $Overlay/Frame/BusOverlay
@onready var _capture_box: CaptureBox = $Overlay/Frame/CaptureBox
@onready var _count_in: CountIn = $Overlay/Frame/CountIn
@onready var _hud: Hud = $Hud
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _controls: ControlsOverlay = $ControlsOverlay
@onready var _cues: AudioCues = $AudioCues
@onready var _honks: HonkScheduler = $HonkScheduler
@onready var _sounds: ShiftSounds = $ShiftSounds
@onready var _tuning_hooks: ShiftTuningHooks = $ShiftTuningHooks
@onready var _debug_view: DebugView = $DebugView


## Children read `config` in their own _ready, which runs before ours, so the
## injection happens on enter_tree. Leaving `config` null uses the autoload.
func _enter_tree() -> void:
	if config == null:
		config = Tuning.config
	for path: String in ["RoadView", "RoadAreas", "BusStopZones", "VehicleLayer", "VehicleSpawner",
			"BusDriver", "ShiftClock", "ScoreKeeper", "HonkScheduler", "ShiftTuningHooks", "DebugView",
			"Overlay/Frame/CaptureBox", "Hud/Frame/FeedbackBanner"]:
		get_node(path).config = config


func _ready() -> void:
	_ramp = DifficultyRamp.new(config)
	_capture_judge = CaptureJudge.new(config)
	_miss_judge = MissJudge.new(config)
	_clock.phase_changed.connect(_on_phase_changed)
	_clock.tick.connect(func(time_left: float, _p: float) -> void: _hud.set_time(time_left))
	_clock.ended.connect(_on_shift_ended)
	_count_in.finished.connect(_on_count_in_finished)
	_capture_box.capture_attempted.connect(_on_capture_attempted)
	_score_keeper.score_changed.connect(_on_score_changed)
	_sounds.bind(_count_in, _capture_box, _score_keeper, _clock, _cues)
	_honks.bind(_bus_driver, _vehicle_layer, _cues)
	_debug_view.bind(_road_view, _vehicle_layer, _zones, _bus_overlay)
	_pause_menu.can_open = func() -> bool:
		return _clock.phase != ShiftClock.Phase.IDLE and _clock.phase != ShiftClock.Phase.ENDED
	_pause_menu.opened.connect(_clock.pause)
	_pause_menu.resume_requested.connect(_resume_after_pause)
	_controls.dismissed.connect(_on_controls_dismissed)
	_pause_menu.quit_requested.connect(func() -> void:
		DebugLog.info(TAG, "shift abandoned from the pause menu")
		navigation_requested.emit(load(TITLE_SCENE_PATH), null))


## Called by ScreenHost after instantiation.
func enter(_payload: Variant) -> void:
	_bus_driver.reset()
	_registry = VehicleRegistry.new()
	_spawner.configure(_vehicle_layer, _zones, _registry)
	_score_keeper.begin(config.shift_length_sec)
	_hud.set_time(config.shift_length_sec)
	if settings != null and settings.show_controls_on_start:
		_controls.open(true)
	else:
		_clock.start()


func bind_settings(store: SettingsStore) -> void:
	settings = store


## The controls card at shift start is gone; honour the opt-out, then count in.
func _on_controls_dismissed(dont_show_again: bool) -> void:
	if dont_show_again and settings != null:
		settings.show_controls_on_start = false
		settings.save()
	if _clock.phase == ShiftClock.Phase.IDLE:
		_clock.start()


func bind_tuning(tuning: TuningService) -> void:
	_tuning_hooks.bind(tuning, _clock, _hud, _capture_box, _vehicle_layer, _registry)


func bind_debug_menu(menu: DebugMenu) -> void:
	menu.register_action("Play every SFX", _cues.preview_all)


func bind_input_source(input_source: InputSource) -> void:
	_capture_box.source = input_source.source
	input_source.source_changed.connect(func(s: InputSource.Source) -> void: _capture_box.source = s)


func on_focus_paused() -> void:
	_clock.pause()


func on_focus_resume_requested(release: Callable) -> void:
	release.call()
	if _pause_menu.is_open():
		# Focus came back while the player had paused: stay paused on the menu.
		get_tree().paused = true
		return
	_resume_after_pause()


## Whatever interrupted the shift is over; run the resume count-in if one is owed.
func _resume_after_pause() -> void:
	if _clock.phase == ShiftClock.Phase.RESUME_COUNT_IN:
		_count_in.run(config.resume_count_in_sec)


func _physics_process(delta: float) -> void:
	if _clock.phase != ShiftClock.Phase.RUNNING:
		return
	var progress := _clock.progress
	_spawner.set_interval(_ramp.spawn_interval(progress))
	_bus_driver.update(delta, _ramp.cruise_speed(progress), _vehicle_layer.vehicles)
	_spawner.set_road_speed(_bus_driver.road_speed)
	_zones.scroll(delta, _bus_driver.road_speed)
	_zones.set_camera_x(_bus_driver.camera_x)
	_road_areas.set_camera_x(_bus_driver.camera_x)
	_road_view.scroll(delta, _bus_driver.road_speed)
	_road_view.set_camera_x(_bus_driver.camera_x)
	var passed := _vehicle_layer.advance_all(delta, _bus_driver.road_speed, _bus_driver.camera_x)
	for verdict in _miss_judge.judge_passed(passed):
		_score_keeper.apply_miss(verdict)
	_vehicle_layer.free_passed(passed)


func _on_phase_changed(phase: ShiftClock.Phase) -> void:
	match phase:
		ShiftClock.Phase.COUNT_IN:
			_count_in.run(config.count_in_sec)
		ShiftClock.Phase.RUNNING:
			_capture_box.enabled = true
			_spawner.start()
		ShiftClock.Phase.RESUME_COUNT_IN, ShiftClock.Phase.ENDED:
			_capture_box.enabled = false
			_spawner.stop()


func _on_count_in_finished() -> void:
	match _clock.phase:
		ShiftClock.Phase.COUNT_IN:
			_clock.begin_running()
		ShiftClock.Phase.RESUME_COUNT_IN:
			_clock.resume_after_count_in()


func _on_capture_attempted(hits: Array[PlateHit]) -> void:
	_score_keeper.apply_capture(_capture_judge.judge(hits))


func _on_score_changed(score: int, delta: int, feedback: String) -> void:
	_hud.set_score(score)
	_hud.banner.show_score_feedback(feedback, delta)


func _on_shift_ended() -> void:
	var result := _score_keeper.finish()
	navigation_requested.emit(load(RESULTS_SCENE_PATH), result)

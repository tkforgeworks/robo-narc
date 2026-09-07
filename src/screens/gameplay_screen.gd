class_name GameplayScreen
extends Node2D
## Composes the shift. Wires child nodes by signal and drives the per-frame
## order (bus, zones, vehicles, misses). No judgment or scoring logic here.

signal navigation_requested(scene: PackedScene, payload: Variant)

const TAG := "Gameplay"
const RESULTS_SCENE_PATH := "res://scenes/screens/results_screen.tscn"
const COLOR_GOOD := Color(0.3, 1.0, 0.4)
const COLOR_BAD := Color(1.0, 0.3, 0.3)
const COLOR_MISS := Color(1.0, 0.55, 0.2)
const COLOR_NEUTRAL := Color(0.75, 0.75, 0.75)

var config: TuningConfig

var _ramp: DifficultyRamp
var _capture_judge: CaptureJudge
var _miss_judge: MissJudge

@onready var _road_view: RoadView = $RoadView
@onready var _zones: BusStopZones = $BusStopZones
@onready var _vehicle_layer: VehicleLayer = $VehicleLayer
@onready var _spawner: VehicleSpawner = $VehicleSpawner
@onready var _bus_driver: BusDriver = $BusDriver
@onready var _clock: ShiftClock = $ShiftClock
@onready var _score_keeper: ScoreKeeper = $ScoreKeeper
@onready var _capture_box: CaptureBox = $Overlay/CaptureBox
@onready var _count_in: CountIn = $Overlay/CountIn
@onready var _hud: Hud = $Hud


## Children read `config` in their own _ready, which runs before ours, so the
## injection happens on enter_tree. Leaving `config` null uses the autoload.
func _enter_tree() -> void:
	if config == null:
		config = Tuning.config
	for path: String in ["RoadView", "BusStopZones", "VehicleSpawner", "BusDriver",
			"ShiftClock", "ScoreKeeper", "Overlay/CaptureBox", "Hud/FeedbackBanner"]:
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


## Called by ScreenHost after instantiation.
func enter(_payload: Variant) -> void:
	_bus_driver.reset()
	_spawner.configure(_vehicle_layer, _zones)
	_score_keeper.begin(config.shift_length_sec)
	_hud.set_time(config.shift_length_sec)
	_clock.start()


func bind_input_source(input_source: InputSource) -> void:
	_capture_box.source = input_source.source
	input_source.source_changed.connect(func(s: InputSource.Source) -> void: _capture_box.source = s)


func on_focus_paused() -> void:
	_clock.pause_for_focus()


func on_focus_resume_requested(release: Callable) -> void:
	release.call()
	if _clock.phase == ShiftClock.Phase.RESUME_COUNT_IN:
		_count_in.run(config.resume_count_in_sec)


func _process(delta: float) -> void:
	if _clock.phase != ShiftClock.Phase.RUNNING:
		return
	var progress := _clock.progress
	_spawner.set_interval(_ramp.spawn_interval(progress))
	_bus_driver.update(delta, _ramp.cruise_speed(progress), _vehicle_layer.vehicles)
	_spawner.set_road_speed(_bus_driver.road_speed)
	_zones.scroll(delta, _bus_driver.road_speed)
	_zones.set_camera_x(_bus_driver.camera_x)
	_road_view.set_camera_x(_bus_driver.camera_x)
	var passed := _vehicle_layer.advance_all(delta, _bus_driver.road_speed, _bus_driver.camera_x)
	for verdict in _miss_judge.judge_passed(passed, _zones.zones, _vehicle_layer.vehicles):
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


func _on_capture_attempted(box: Rect2) -> void:
	var outcome := _capture_judge.judge(box, _vehicle_layer.vehicles, _zones.zones)
	_score_keeper.apply_capture(outcome)


func _on_score_changed(score: int, delta: int, feedback: String) -> void:
	_hud.set_score(score)
	if feedback.is_empty():
		return
	var color := COLOR_NEUTRAL
	if delta > 0:
		color = COLOR_GOOD
	elif feedback.contains("MISSED"):
		color = COLOR_MISS
	elif delta < 0:
		color = COLOR_BAD
	_hud.banner.show_text(feedback, color)


func _on_shift_ended() -> void:
	var result := _score_keeper.finish()
	navigation_requested.emit(load(RESULTS_SCENE_PATH), result)

class_name SimScreen
extends Control
## Debug-only screen (reached from the debug menu on the title): runs the
## perfect-shift simulation on the live tuning so values tweaked in the F1
## menu can be judged without leaving the game. Runs and time scale are
## spinners; each run's line appears as it lands, then the summary.

signal navigation_requested(scene: PackedScene, payload: Variant)

const TITLE_SCENE_PATH := "res://scenes/screens/title_screen.tscn"
const RUN_TEXT := "RUN"
const CANCEL_TEXT := "CANCEL"

@onready var _runs: SpinBox = %RunsSpin
@onready var _time_scale: SpinBox = %TimeScaleSpin
@onready var _run_button: Button = %RunButton
@onready var _progress: Label = %ProgressLabel
@onready var _summary: Label = %SummaryLabel
@onready var _runs_log: Label = %RunsLog
@onready var _back_button: Button = %BackButton
@onready var _simulator: PerfectShiftSimulator = $Simulator


func _ready() -> void:
	_run_button.pressed.connect(_on_run_pressed)
	_back_button.pressed.connect(_go_back)
	_simulator.run_finished.connect(_on_run_finished)
	_simulator.finished.connect(_on_finished)
	_progress.text = "Tweak values in the debug menu, then run. Unsaved tweaks count."
	_summary.text = ""
	_runs_log.text = ""
	_run_button.grab_focus()


func is_running() -> bool:
	return _simulator.running


func _on_run_pressed() -> void:
	if _simulator.running:
		_simulator.cancel()
		_run_button.text = RUN_TEXT
		_progress.text = "Cancelled after %d run(s)." % _simulator.results.size()
		return
	_simulator.config = null  # re-read the live config every time
	_simulator.runs = int(_runs.value)
	_simulator.time_scale = _time_scale.value
	_simulator.first_seed = 1
	_summary.text = ""
	_runs_log.text = ""
	_run_button.text = CANCEL_TEXT
	_progress.text = "Run 1 of %d..." % _simulator.runs
	_simulator.start()


func _on_run_finished(run: Dictionary) -> void:
	var done := _simulator.results.size()
	_runs_log.text += PerfectShiftSimulator.run_line(done, run) + "\n"
	_progress.text = "Run %d of %d..." % [done + 1, _simulator.runs] if done < _simulator.runs \
			else "Done."
	_summary.text = "So far: " + _simulator.summary_text().get_slice("\n", 0)


func _on_finished(_results: Array[Dictionary]) -> void:
	_run_button.text = RUN_TEXT
	_progress.text = "Done. %s" % _simulator.describe_config()
	_summary.text = _simulator.summary_text()


func _go_back() -> void:
	_simulator.cancel()
	navigation_requested.emit(load(TITLE_SCENE_PATH), null)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

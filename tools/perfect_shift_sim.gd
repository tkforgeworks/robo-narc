extends SceneTree
## Command-line front end for PerfectShiftSimulator: the ceiling score for a
## tuning, from headless shifts with no input where every missed violator
## counts as a perfect capture. See src/game/debug/perfect_shift_simulator.gd;
## the in-game Simulation screen (debug menu) runs the same thing interactively.
##
##   godot --headless --path . --script tools/perfect_shift_sim.gd -- [options]
##
## Options (after the `--`):
##   --runs=N          shifts to simulate (default 20)
##   --time-scale=X    game seconds per real second (default 20)
##   --seed=S          seed of the first run; run i uses S + i (default 1)
##   --defaults        ignore saved debug-menu overrides, use shipped defaults
##   --set=key=value   override one tunable (repeatable, e.g. --set=spawn_interval_end=0.7)
##   --out=path        also write the summary to this file (for CI step summaries)
##
## Every line of the report starts with `[sim]` so it greps out of engine chatter.

const SIMULATOR_SCRIPT := "res://src/game/debug/perfect_shift_simulator.gd"
const TUNING_SCRIPT := "res://src/core/tuning/tuning.gd"

var runs: int = 20
var time_scale: float = 20.0
var first_seed: int = 1
var use_defaults: bool = false
var overrides: Dictionary = {}
var out_path: String = ""

var _sim: Node


func _initialize() -> void:
	_parse_args()
	# The Tuning autoload loads its config (and the saved overrides) in _ready,
	# which runs after this callback, so wait one frame.
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var key := arg.get_slice("=", 0)
		var value := arg.substr(key.length() + 1) if arg.contains("=") else ""
		match key:
			"--runs":
				runs = maxi(int(value), 1)
			"--time-scale":
				time_scale = clampf(float(value), 1.0, 200.0)
			"--seed":
				first_seed = int(value)
			"--defaults":
				use_defaults = true
			"--set":
				overrides[value.get_slice("=", 0)] = value.substr(value.get_slice("=", 0).length() + 1)
			"--out":
				out_path = value
			_:
				push_warning("perfect_shift_sim: unknown option %s" % arg)


func _setup() -> void:
	var config: Resource = _load_config()
	if config == null:
		return
	_sim = load(SIMULATOR_SCRIPT).new()
	_sim.config = config
	_sim.runs = runs
	_sim.time_scale = time_scale
	_sim.first_seed = first_seed
	root.add_child(_sim)
	_sim.run_finished.connect(_on_run_finished)
	_sim.finished.connect(_on_finished)
	var budget: float = 60.0 + runs * (float(config.shift_length_sec) + 10.0) / time_scale * 3.0
	create_timer(budget, true, false, true).timeout.connect(
			_abort.bind("deadline of %.0f s reached" % budget))
	_report("perfect-shift simulation: %d run(s), time scale %.0fx, seeds %d..%d" % [
			runs, time_scale, first_seed, first_seed + runs - 1])
	_report("tuning: %s" % _sim.describe_config())
	_sim.start()


## Debug-menu overrides come through the Tuning autoload (debug builds only);
## `--defaults` reads the shipped resource instead. `--set` applies on top.
func _load_config() -> Resource:
	var tuning_script: GDScript = load(TUNING_SCRIPT)
	var config: Resource = tuning_script.load_defaults() if use_defaults \
			else root.get_node("Tuning").config
	if config == null:
		_abort("the Tuning autoload has no config")
		return null
	for key: String in overrides:
		var current: Variant = config.get(key)
		if current == null:
			_abort("no tunable named '%s'" % key)
			return null
		config.set(key, type_convert(overrides[key], typeof(current)))
	return config


func _on_run_finished(run: Dictionary) -> void:
	_report(_sim.run_line(_sim.results.size(), run))


func _on_finished(_results: Array) -> void:
	var lines: PackedStringArray = _sim.summary_lines()
	for line in lines:
		_report(line)
	if not out_path.is_empty():
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		if file == null:
			push_error("perfect_shift_sim: cannot write %s" % out_path)
		else:
			file.store_string("\n".join(lines) + "\n")
			_report("summary written to %s" % out_path)
	quit(0)


func _report(text: String) -> void:
	print("[sim] %s" % text)


func _abort(why: String) -> void:
	push_error("perfect_shift_sim: %s" % why)
	_report("ABORTED: %s" % why)
	quit(2)

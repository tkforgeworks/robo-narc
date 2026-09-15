extends SceneTree
## Estimates the ceiling score for the current tuning by playing shifts with
## no input and counting every violator the miss judge reports: each one is a
## capture a perfect player would have made, worth `points_correct`. Runs the
## real gameplay scene (spawner, column gaps, ramp, rules) headless at a high
## `Engine.time_scale`, so one shift takes a few seconds.
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

const GAMEPLAY_SCENE := "res://scenes/game/gameplay.tscn"
const TUNING_SCRIPT := "res://src/core/tuning/tuning.gd"
const RULES_SCRIPT := "res://src/game/judgment/violation_rules.gd"
const THIRDS := ["early", "mid", "late"]

var runs: int = 20
var time_scale: float = 20.0
var first_seed: int = 1
var use_defaults: bool = false
var overrides: Dictionary = {}
var out_path: String = ""

var _config: Resource
var _rules: GDScript
var _screen: Node
var _run_index: int = 0
var _current: Dictionary = {}
var _results: Array[Dictionary] = []
var _deadline: SceneTreeTimer


func _initialize() -> void:
	_parse_args()
	Engine.time_scale = time_scale
	# A scaled frame must be allowed all the physics ticks it covers, or the
	# vehicles fall behind the shift clock.
	Engine.max_physics_steps_per_frame = 4096
	# The Tuning autoload loads its config (and the saved overrides) in _ready,
	# which runs after this callback, so wait one frame.
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	_config = _load_config()
	if _config == null:
		_abort("the Tuning autoload has no config")
		return
	_rules = load(RULES_SCRIPT)
	var budget: float = 60.0 + runs * (float(_config.shift_length_sec) + 10.0) / time_scale * 3.0
	_deadline = create_timer(budget, true, false, true)
	_deadline.timeout.connect(_abort.bind("deadline of %.0f s reached" % budget))
	_report("perfect-shift simulation: %d run(s), time scale %.0fx, seeds %d..%d" % [
			runs, time_scale, first_seed, first_seed + runs - 1])
	_report("tuning: %s" % _describe_config())
	_start_run()


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


## Debug-menu overrides come through the Tuning autoload (debug builds only);
## `--defaults` reads the shipped resource instead. `--set` applies on top.
func _load_config() -> Resource:
	var tuning_script: GDScript = load(TUNING_SCRIPT)
	var config: Resource = tuning_script.load_defaults() if use_defaults \
			else root.get_node("Tuning").config
	for key: String in overrides:
		var current: Variant = config.get(key)
		if current == null:
			_abort("no tunable named '%s'" % key)
			return config
		config.set(key, type_convert(overrides[key], typeof(current)))
	return config


func _describe_config() -> String:
	var c: Resource = _config
	return "shift %.0fs, spawn %.2f->%.2fs, speed %.0f->%.0f, gaps curb %.0f / bus %.0f, +%d per capture, weights %s" % [
			c.shift_length_sec, c.spawn_interval_start, c.spawn_interval_end,
			c.cruise_speed_start, c.cruise_speed_end, c.spawn_column_gap_curb_z,
			c.spawn_column_gap_bus_z, c.points_correct, str(c.situation_weights())]


func _start_run() -> void:
	if _run_index >= runs:
		_finish()
		return
	var seed_value := first_seed + _run_index
	_current = {"seed": seed_value, "missed": 0, "kinds": {}, "thirds": [0, 0, 0]}
	_screen = load(GAMEPLAY_SCENE).instantiate()
	_screen.config = _config
	_screen.get_node("VehicleSpawner").rng.seed = seed_value
	root.add_child(_screen)
	_screen.get_node("ScoreKeeper").miss_applied.connect(_on_miss)
	_screen.navigation_requested.connect(_on_shift_over)
	_screen.enter(null)
	# Skip the count-in: the shift starts at once.
	_screen.get_node("ShiftClock").begin_running()


func _on_miss(verdict: RefCounted) -> void:
	_current["missed"] += 1
	var kinds: Dictionary = _current["kinds"]
	kinds[verdict.label] = kinds.get(verdict.label, 0) + 1
	var elapsed: float = float(_config.shift_length_sec) - float(_screen.get_node("ShiftClock").time_left)
	var third: int = clampi(int(elapsed / float(_config.shift_length_sec) * 3.0), 0, 2)
	_current["thirds"][third] += 1


func _on_shift_over(_scene: PackedScene, result: RefCounted) -> void:
	# Violators still on the road when the clock ran out: a perfect player may
	# have captured some of them, so they are reported but not scored.
	var in_flight := 0
	for vehicle: Node in _screen.get_node("VehicleLayer").vehicles:
		if _rules.evaluate(vehicle.report(), _config).is_violation:
			in_flight += 1
	_current["in_flight"] = in_flight
	_current["spawned"] = _screen.get_node("VehicleSpawner").spawn_count
	_current["score"] = result.missed * _config.points_correct
	_results.append(_current)
	_report("run %2d seed %-4d perfect %5d  violators %2d (%s)  in flight %d  spawned %2d" % [
			_run_index + 1, _current["seed"], _current["score"], _current["missed"],
			"/".join(_current["thirds"].map(func(n: int) -> String: return str(n))),
			in_flight, _current["spawned"]])
	_screen.queue_free()
	_screen = null
	_run_index += 1
	_start_run.call_deferred()


func _finish() -> void:
	var scores: Array = _results.map(func(r: Dictionary) -> int: return r["score"])
	scores.sort()
	var lines: PackedStringArray = []
	lines.append("| Perfect score | min | p10 | median | p90 | max | mean |")
	lines.append("|---|---|---|---|---|---|---|")
	lines.append("| %d run(s) | %d | %d | %d | %d | %d | %.0f |" % [
			_results.size(), scores[0], _percentile(scores, 0.1), _percentile(scores, 0.5),
			_percentile(scores, 0.9), scores[scores.size() - 1], _mean(scores)])
	lines.append("")
	lines.append("| Violators per shift | early third | mid third | late third | total | still on road at end | spawn ticks |")
	lines.append("|---|---|---|---|---|---|---|")
	lines.append("| mean | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f |" % [
			_mean(_results.map(func(r: Dictionary) -> int: return r["thirds"][0])),
			_mean(_results.map(func(r: Dictionary) -> int: return r["thirds"][1])),
			_mean(_results.map(func(r: Dictionary) -> int: return r["thirds"][2])),
			_mean(_results.map(func(r: Dictionary) -> int: return r["missed"])),
			_mean(_results.map(func(r: Dictionary) -> int: return r["in_flight"])),
			_mean(_results.map(func(r: Dictionary) -> int: return r["spawned"]))])
	lines.append("")
	lines.append("| Violation | mean per shift |")
	lines.append("|---|---|")
	for label: String in _all_kind_labels():
		lines.append("| %s | %.1f |" % [label,
				_mean(_results.map(func(r: Dictionary) -> int: return r["kinds"].get(label, 0)))])
	lines.append("")
	lines.append("Tuning: %s" % _describe_config())
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


func _all_kind_labels() -> Array:
	var labels := {}
	for r in _results:
		for label: String in r["kinds"]:
			labels[label] = true
	var sorted := labels.keys()
	sorted.sort()
	return sorted


func _percentile(sorted_values: Array, fraction: float) -> int:
	var index := clampi(int(round(fraction * (sorted_values.size() - 1))), 0, sorted_values.size() - 1)
	return sorted_values[index]


func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v: Variant in values:
		total += float(v)
	return total / values.size()


func _report(text: String) -> void:
	print("[sim] %s" % text)


func _abort(why: String) -> void:
	push_error("perfect_shift_sim: %s" % why)
	_report("ABORTED: %s (%d run(s) finished)" % [why, _results.size()])
	quit(2)

class_name PerfectShiftSimulator
extends Node
## Estimates the ceiling score for a tuning by playing shifts with no input and
## counting every violator the miss judge reports: each one is a capture a
## perfect player would have made, worth `points_correct`. Runs the real
## gameplay scene (spawner, column gaps, ramp, rules) as hidden, muted
## children at a high `Engine.time_scale`. Used by the debug Simulation screen
## and by tools/perfect_shift_sim.gd.

signal run_finished(run: Dictionary)
signal finished(results: Array[Dictionary])

const TAG := "Sim"
const GAMEPLAY_SCENE_PATH := "res://scenes/game/gameplay.tscn"
const MUTED_BUS := "Master"

## Null uses the Tuning autoload's live config, so debug-menu edits apply
## without saving.
var config: TuningConfig
var runs: int = 20
var time_scale: float = 20.0
var first_seed: int = 1

var running: bool = false
## One dictionary per finished run: seed, score, missed, kinds, thirds,
## in_flight, spawned.
var results: Array[Dictionary] = []

var _screen: GameplayScreen
var _current: Dictionary = {}
var _run_index: int = 0
var _saved_time_scale: float = 1.0
var _saved_max_steps: int = 8
var _saved_mute: bool = false


func start() -> void:
	if running:
		return
	if config == null:
		config = Tuning.config
	results.clear()
	_run_index = 0
	running = true
	_saved_time_scale = Engine.time_scale
	_saved_max_steps = Engine.max_physics_steps_per_frame
	Engine.time_scale = time_scale
	# A scaled frame must be allowed all the physics ticks it covers, or the
	# vehicles fall behind the shift clock.
	Engine.max_physics_steps_per_frame = 4096
	var bus := AudioServer.get_bus_index(MUTED_BUS)
	if bus != -1:
		_saved_mute = AudioServer.is_bus_mute(bus)
		AudioServer.set_bus_mute(bus, true)
	DebugLog.info(TAG, "%d run(s) at %.0fx: %s" % [runs, time_scale, describe_config()])
	_start_run()


func cancel() -> void:
	if not running:
		return
	if _screen != null:
		_screen.queue_free()
		_screen = null
	_restore()
	DebugLog.info(TAG, "cancelled after %d run(s)" % results.size())


func describe_config() -> String:
	return "shift %.0fs, spawn %.2f->%.2fs, speed %.0f->%.0f, gaps curb %.0f / bus %.0f, +%d per capture, weights %s" % [
			config.shift_length_sec, config.spawn_interval_start, config.spawn_interval_end,
			config.cruise_speed_start, config.cruise_speed_end, config.spawn_column_gap_curb_z,
			config.spawn_column_gap_bus_z, config.points_correct, str(config.situation_weights())]


## One line per run, as the tool prints them.
static func run_line(index: int, run: Dictionary) -> String:
	return "run %2d seed %-4d perfect %5d  violators %2d (%s)  in flight %d  spawned %2d" % [
			index, run["seed"], run["score"], run["missed"],
			"/".join(run["thirds"].map(func(n: int) -> String: return str(n))),
			run["in_flight"], run["spawned"]]


## Aggregates over `results`: score percentiles, mean violators per third,
## mean per violation kind.
func stats() -> Dictionary:
	var scores: Array = results.map(func(r: Dictionary) -> int: return r["score"])
	scores.sort()
	var kinds := {}
	for run in results:
		for label: String in run["kinds"]:
			kinds[label] = kinds.get(label, 0.0) + float(run["kinds"][label]) / results.size()
	return {
		"runs": results.size(),
		"min": scores[0] if not scores.is_empty() else 0,
		"p10": _percentile(scores, 0.1),
		"median": _percentile(scores, 0.5),
		"p90": _percentile(scores, 0.9),
		"max": scores[scores.size() - 1] if not scores.is_empty() else 0,
		"mean": _mean(scores),
		"early": _mean(results.map(func(r: Dictionary) -> int: return r["thirds"][0])),
		"mid": _mean(results.map(func(r: Dictionary) -> int: return r["thirds"][1])),
		"late": _mean(results.map(func(r: Dictionary) -> int: return r["thirds"][2])),
		"violators": _mean(results.map(func(r: Dictionary) -> int: return r["missed"])),
		"in_flight": _mean(results.map(func(r: Dictionary) -> int: return r["in_flight"])),
		"spawned": _mean(results.map(func(r: Dictionary) -> int: return r["spawned"])),
		"kinds": kinds,
	}


## Markdown tables, for the console and CI step summaries.
func summary_lines() -> PackedStringArray:
	var s := stats()
	var lines: PackedStringArray = []
	lines.append("| Perfect score | min | p10 | median | p90 | max | mean |")
	lines.append("|---|---|---|---|---|---|---|")
	lines.append("| %d run(s) | %d | %d | %d | %d | %d | %.0f |" % [
			s["runs"], s["min"], s["p10"], s["median"], s["p90"], s["max"], s["mean"]])
	lines.append("")
	lines.append("| Violators per shift | early third | mid third | late third | total | still on road at end | spawn ticks |")
	lines.append("|---|---|---|---|---|---|---|")
	lines.append("| mean | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f |" % [
			s["early"], s["mid"], s["late"], s["violators"], s["in_flight"], s["spawned"]])
	lines.append("")
	lines.append("| Violation | mean per shift |")
	lines.append("|---|---|")
	for label: String in _sorted_kinds(s["kinds"]):
		lines.append("| %s | %.1f |" % [label, s["kinds"][label]])
	lines.append("")
	lines.append("Tuning: %s" % describe_config())
	return lines


## Sentences, for a screen.
func summary_text() -> String:
	var s := stats()
	var by_kind: PackedStringArray = []
	for label: String in _sorted_kinds(s["kinds"]):
		by_kind.append("%s %.1f" % [label, s["kinds"][label]])
	return "\n".join([
		"Perfect score over %d run(s): median %d (p10 %d, p90 %d), min %d, max %d, mean %.0f" % [
				s["runs"], s["median"], s["p10"], s["p90"], s["min"], s["max"], s["mean"]],
		"Violators per shift: %.1f early / %.1f mid / %.1f late = %.1f, plus %.1f still on the road at the end; %.0f spawn ticks" % [
				s["early"], s["mid"], s["late"], s["violators"], s["in_flight"], s["spawned"]],
		"By violation: " + ", ".join(by_kind),
	])


func _start_run() -> void:
	if _run_index >= runs:
		_restore()
		DebugLog.info(TAG, "done: median perfect score %d over %d run(s)" % [
				stats()["median"], results.size()])
		finished.emit(results)
		return
	var seed_value := first_seed + _run_index
	_current = {"seed": seed_value, "missed": 0, "kinds": {}, "thirds": [0, 0, 0]}
	_screen = load(GAMEPLAY_SCENE_PATH).instantiate()
	_screen.config = config
	(_screen.get_node("VehicleSpawner") as VehicleSpawner).rng.seed = seed_value
	_screen.visible = false
	for child in _screen.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	add_child(_screen)
	(_screen.get_node("ScoreKeeper") as ScoreKeeper).miss_applied.connect(_on_miss)
	_screen.navigation_requested.connect(_on_shift_over)
	_screen.enter(null)
	# Skip the count-in: the shift starts at once.
	(_screen.get_node("ShiftClock") as ShiftClock).begin_running()


func _on_miss(verdict: Verdict) -> void:
	_current["missed"] += 1
	var kinds: Dictionary = _current["kinds"]
	kinds[verdict.label] = kinds.get(verdict.label, 0) + 1
	var clock: ShiftClock = _screen.get_node("ShiftClock")
	var elapsed := config.shift_length_sec - clock.time_left
	var third := clampi(int(elapsed / config.shift_length_sec * 3.0), 0, 2)
	_current["thirds"][third] += 1


func _on_shift_over(_scene: PackedScene, result: Variant) -> void:
	# Violators still on the road when the clock ran out: a perfect player may
	# have captured some of them, so they are reported but not scored.
	var in_flight := 0
	for vehicle: Vehicle in (_screen.get_node("VehicleLayer") as VehicleLayer).vehicles:
		if ViolationRules.evaluate(vehicle.report(), config).is_violation:
			in_flight += 1
	_current["in_flight"] = in_flight
	_current["spawned"] = (_screen.get_node("VehicleSpawner") as VehicleSpawner).spawn_count
	_current["score"] = (result as ShiftResult).missed * config.points_correct
	results.append(_current)
	_screen.queue_free()
	_screen = null
	_run_index += 1
	run_finished.emit(_current)
	if running:
		_start_run.call_deferred()


func _restore() -> void:
	running = false
	Engine.time_scale = _saved_time_scale
	Engine.max_physics_steps_per_frame = _saved_max_steps
	var bus := AudioServer.get_bus_index(MUTED_BUS)
	if bus != -1:
		AudioServer.set_bus_mute(bus, _saved_mute)


static func _sorted_kinds(kinds: Dictionary) -> Array:
	var labels := kinds.keys()
	labels.sort_custom(func(a: String, b: String) -> bool: return kinds[a] > kinds[b])
	return labels


static func _percentile(sorted_values: Array, fraction: float) -> int:
	if sorted_values.is_empty():
		return 0
	var index := clampi(int(round(fraction * (sorted_values.size() - 1))), 0, sorted_values.size() - 1)
	return sorted_values[index]


static func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v: Variant in values:
		total += float(v)
	return total / values.size()

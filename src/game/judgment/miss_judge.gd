class_name MissJudge
extends RefCounted
## Judges every vehicle that passed under the bus this step BEFORE any of
## them is freed, so a double-park pair passing together still sees its
## neighbour through the areas. Returns only the violations that went
## uncaptured.

var config: TuningConfig


func _init(p_config: TuningConfig) -> void:
	config = p_config


func judge_passed(passed: Array[Vehicle]) -> Array[Verdict]:
	var missed: Array[Verdict] = []
	for vehicle in passed:
		if vehicle.captured:
			continue
		var verdict := ViolationRules.evaluate(vehicle.report(), config)
		if verdict.is_violation:
			missed.append(verdict)
	return missed

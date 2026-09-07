class_name MissJudge
extends RefCounted
## Judges every vehicle that passed under the bus this frame BEFORE any of
## them is freed, so a double-park pair passing together still sees its
## neighbour. Returns only the violations that went uncaptured.

var config: TuningConfig


func _init(p_config: TuningConfig) -> void:
	config = p_config


func judge_passed(passed: Array[Vehicle], zones: Array[ZoneSpan],
		all_vehicles: Array[Vehicle]) -> Array[Verdict]:
	var missed: Array[Verdict] = []
	if passed.is_empty():
		return missed
	var neighbours: Array[VehicleState] = []
	for vehicle in all_vehicles:
		neighbours.append(vehicle.to_state())
	for vehicle in passed:
		if vehicle.captured:
			continue
		var verdict := ViolationRules.evaluate(vehicle.to_state(), zones, neighbours, config)
		if verdict.is_violation:
			missed.append(verdict)
	return missed

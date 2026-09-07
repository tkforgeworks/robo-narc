class_name CaptureJudge
extends RefCounted
## Resolves a capture press: which plate (if any) is fully framed and
## readable, then what the rulebook says about that vehicle.

var config: TuningConfig


func _init(p_config: TuningConfig) -> void:
	config = p_config


func judge(box: Rect2, vehicles: Array[Vehicle], zones: Array[ZoneSpan]) -> CaptureOutcome:
	var target: Vehicle = null
	var too_far := false
	var already := false
	for vehicle in vehicles:
		if not vehicle.visible or not box.encloses(vehicle.get_plate_rect()):
			continue
		if vehicle.captured:
			already = true
			continue
		if vehicle.z > config.plate_readable_z:
			too_far = true
			continue
		if target == null or vehicle.z < target.z:
			target = vehicle
	if target == null:
		if too_far:
			return CaptureOutcome.new(CaptureOutcome.Kind.TOO_FAR)
		if already:
			return CaptureOutcome.new(CaptureOutcome.Kind.ALREADY_CAPTURED)
		return CaptureOutcome.new(CaptureOutcome.Kind.EMPTY)

	var neighbours: Array[VehicleState] = []
	for vehicle in vehicles:
		neighbours.append(vehicle.to_state())
	var verdict := ViolationRules.evaluate(target.to_state(), zones, neighbours, config)
	target.mark_captured()
	var kind := CaptureOutcome.Kind.CORRECT if verdict.is_violation else CaptureOutcome.Kind.WRONG
	return CaptureOutcome.new(kind, target, verdict)

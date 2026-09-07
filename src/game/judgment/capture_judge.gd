class_name CaptureJudge
extends RefCounted
## Resolves a capture press: which overlapped plate (if any) is covered
## enough and readable, then what the rulebook says about that vehicle.

## Coverage is a float ratio; 0.99999 must still count as fully framed.
const EPSILON := 0.001

var config: TuningConfig


func _init(p_config: TuningConfig) -> void:
	config = p_config


func judge(hits: Array[PlateHit]) -> CaptureOutcome:
	var target: Vehicle = null
	var too_far := false
	var already := false
	for hit in hits:
		if hit.coverage + EPSILON < config.capture_overlap_ratio:
			continue
		var vehicle := hit.vehicle
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
	var verdict := ViolationRules.evaluate(target.report(), config)
	target.mark_captured()
	var kind := CaptureOutcome.Kind.CORRECT if verdict.is_violation else CaptureOutcome.Kind.WRONG
	return CaptureOutcome.new(kind, target, verdict)

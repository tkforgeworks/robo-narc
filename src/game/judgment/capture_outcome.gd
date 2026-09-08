class_name CaptureOutcome
extends RefCounted
## What one capture press produced. CaptureJudge fills kind, vehicle, and
## verdict; ScoreKeeper fills points and feedback when it applies the outcome.

enum Kind { CORRECT, WRONG, TOO_FAR, EMPTY, ALREADY_CAPTURED }

var kind: Kind
var vehicle: Node2D = null
var verdict: Verdict = null
var points: int = 0
var feedback: String = ""


func _init(p_kind: Kind = Kind.EMPTY, p_vehicle: Node2D = null, p_verdict: Verdict = null) -> void:
	kind = p_kind
	vehicle = p_vehicle
	verdict = p_verdict


var is_scored: bool:
	get:
		return kind == Kind.CORRECT or kind == Kind.WRONG

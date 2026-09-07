class_name Verdict
extends RefCounted
## The rulebook's answer for one vehicle at one moment.

enum Kind { INNOCENT, BUS_LANE, DOUBLE_PARKING, BIKE_LANE, BUS_STOP }

const LABELS: Dictionary = {
	Kind.INNOCENT: "INNOCENT",
	Kind.BUS_LANE: "BUS LANE",
	Kind.DOUBLE_PARKING: "DOUBLE PARKING",
	Kind.BIKE_LANE: "BIKE LANE",
	Kind.BUS_STOP: "BUS STOP",
}

var kind: Kind


func _init(p_kind: Kind = Kind.INNOCENT) -> void:
	kind = p_kind


static func innocent() -> Verdict:
	return Verdict.new(Kind.INNOCENT)


static func of(p_kind: Kind) -> Verdict:
	return Verdict.new(p_kind)


var label: String:
	get:
		return LABELS[kind]

var is_violation: bool:
	get:
		return kind != Kind.INNOCENT

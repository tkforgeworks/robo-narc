class_name SituationTable
extends RefCounted
## Weighted choice of the next traffic situation. Weights are the
## `situation_weight_*` tunables on TuningConfig (single source of truth) and
## are re-read on every pick so debug-menu changes apply immediately.

enum Kind {
	MOVING_TRAFFIC,
	LEGAL_CURB,
	SLOPPY_PARKER,
	BIKE_LANE_VIOLATOR,
	BUS_LANE_BLOCKER,
	DOUBLE_PARK_PAIR,
	BUS_STOP_ZONE,
}

## Kind -> key in TuningConfig.situation_weights().
const WEIGHT_KEYS: Dictionary = {
	Kind.MOVING_TRAFFIC: "moving_traffic",
	Kind.LEGAL_CURB: "legal_curb",
	Kind.SLOPPY_PARKER: "sloppy_parker",
	Kind.BIKE_LANE_VIOLATOR: "bike_lane_violator",
	Kind.BUS_LANE_BLOCKER: "bus_lane_blocker",
	Kind.DOUBLE_PARK_PAIR: "double_park_pair",
	Kind.BUS_STOP_ZONE: "bus_stop_zone",
}

const TAG := "Situations"

var config: TuningConfig


func _init(p_config: TuningConfig) -> void:
	config = p_config


func weight_of(kind: Kind) -> float:
	return float(config.situation_weights()[WEIGHT_KEYS[kind]])


func total_weight() -> float:
	var total := 0.0
	for kind: Kind in Kind.values():
		total += weight_of(kind)
	return total


func pick(rng: RandomNumberGenerator) -> Kind:
	var total := total_weight()
	if total <= 0.0:
		DebugLog.warn(TAG, "all situation weights are zero; spawning moving traffic")
		return Kind.MOVING_TRAFFIC
	var roll := rng.randf() * total
	for kind: Kind in Kind.values():
		roll -= weight_of(kind)
		if roll <= 0.0:
			return kind
	return Kind.MOVING_TRAFFIC

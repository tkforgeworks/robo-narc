class_name SituationTable
extends RefCounted
## Weighted choice of the next traffic situation, drawn from a shuffled bag so
## every stretch of `situation_bag_size` spawns carries each situation in
## proportion to its `situation_weight_*` tunable (0 rolls independently every
## tick instead). Weights are re-read when the bag refills, so debug-menu
## changes apply within one bag.

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

var _bag: Array[Kind] = []


func _init(p_config: TuningConfig) -> void:
	config = p_config


func weight_of(kind: Kind) -> float:
	return float(config.situation_weights()[WEIGHT_KEYS[kind]])


func total_weight() -> float:
	var total := 0.0
	for kind: Kind in Kind.values():
		total += weight_of(kind)
	return total


func bag_count() -> int:
	return _bag.size()


## What a fresh bag holds: each positive weight rounds to its share of
## `situation_bag_size`, never below one.
func bag_composition() -> Dictionary:
	var total := total_weight()
	var composition := {}
	for kind: Kind in Kind.values():
		var weight := weight_of(kind)
		if weight <= 0.0 or total <= 0.0:
			continue
		composition[kind] = maxi(int(round(weight / total * config.situation_bag_size)), 1)
	return composition


func pick(rng: RandomNumberGenerator) -> Kind:
	var total := total_weight()
	if total <= 0.0:
		DebugLog.warn(TAG, "all situation weights are zero; spawning moving traffic")
		return Kind.MOVING_TRAFFIC
	if config.situation_bag_size <= 0:
		return _roll(rng, total)
	if _bag.is_empty():
		_refill(rng)
	return _bag.pop_back()


## A situation the spawner could not place goes back at a random spot, so a
## column-gap rejection does not cost the bag its mix.
func put_back(kind: Kind, rng: RandomNumberGenerator) -> void:
	if config.situation_bag_size <= 0:
		return
	_bag.insert(rng.randi_range(0, _bag.size()), kind)


func _refill(rng: RandomNumberGenerator) -> void:
	_bag.clear()
	var composition := bag_composition()
	for kind: Kind in composition:
		for i in composition[kind]:
			_bag.append(kind)
	# Fisher-Yates with the spawner's rng, so a seeded run stays reproducible.
	for i in range(_bag.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := _bag[i]
		_bag[i] = _bag[j]
		_bag[j] = swap


func _roll(rng: RandomNumberGenerator, total: float) -> Kind:
	var roll := rng.randf() * total
	for kind: Kind in Kind.values():
		roll -= weight_of(kind)
		if roll <= 0.0:
			return kind
	return Kind.MOVING_TRAFFIC

class_name VehicleReport
extends RefCounted
## What the sensors say about one vehicle at one moment: its motion, how much
## of its body sits in each lane, whether it is inside a bus stop zone, and
## whether a stationary curb-parked neighbour sits beside it. ViolationRules
## judges only this, never the scene, so the rulebook stays a pure function.

var id: int = 0
var z: float = 0.0
var stationary: bool = true
var captured: bool = false
## RoadGeometry.Lane -> 0..1 share of the body's width inside that lane.
var lane_ratios: Dictionary = {}
var in_zone: bool = false
var curb_neighbour: bool = false


func ratio(lane: RoadGeometry.Lane) -> float:
	return float(lane_ratios.get(lane, 0.0))


func in_lane(lane: RoadGeometry.Lane, config: TuningConfig) -> bool:
	return ratio(lane) >= config.lane_membership_ratio


func at_curb(config: TuningConfig) -> bool:
	return in_lane(RoadGeometry.Lane.PARKING, config)

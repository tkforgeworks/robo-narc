class_name ZoneSpan
extends RefCounted
## A bus stop zone as a span along the road: starts at `z` and extends
## `length` units further from the bus. Scrolls toward the bus with the road.

var z: float
var length: float


func _init(p_z: float = 0.0, p_length: float = 0.0) -> void:
	z = p_z
	length = p_length


func end_z() -> float:
	return z + length


func contains(query_z: float) -> bool:
	return query_z >= z and query_z <= end_z()


func scroll(delta: float, road_speed: float) -> void:
	z -= road_speed * delta

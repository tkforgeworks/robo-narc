class_name VehicleState
extends RefCounted
## The scene-free snapshot of a vehicle that the rulebook judges. Built by the
## Vehicle node each time judgment is needed, so ViolationRules never touches
## the scene tree.

var id: int
var road_x: float
var z: float
var stationary: bool
var half_width: float
var captured: bool


func _init(p_id: int = 0, p_road_x: float = 0.0, p_z: float = 0.0,
		p_stationary: bool = true, p_half_width: float = 45.0,
		p_captured: bool = false) -> void:
	id = p_id
	road_x = p_road_x
	z = p_z
	stationary = p_stationary
	half_width = p_half_width
	captured = p_captured

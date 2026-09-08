class_name PlateHit
extends RefCounted
## One plate the capture area overlaps, with how much of it is inside the box.

var vehicle: Vehicle
var coverage: float


func _init(p_vehicle: Vehicle = null, p_coverage: float = 0.0) -> void:
	vehicle = p_vehicle
	coverage = p_coverage

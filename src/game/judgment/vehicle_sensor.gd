class_name VehicleSensor
extends Node
## Reads the parent vehicle's areas and produces a VehicleReport. Which areas
## overlap comes from the physics server (last physics step); the lane share is
## then computed exactly from the body rect against the lane's span at that
## height, so the ratios are stable and testable.

var config: TuningConfig

@onready var _vehicle: Vehicle = get_parent()


func _ready() -> void:
	if config == null:
		config = Tuning.config


## RoadGeometry.Lane -> share of the body width inside that lane.
func lane_ratios() -> Dictionary:
	var ratios := {}
	var rect := AreaRects.global_rect(_vehicle.body_area)
	if rect.size.x <= 0.0:
		return ratios
	for area in _vehicle.body_area.get_overlapping_areas():
		if area is LaneArea:
			var lane := area as LaneArea
			var span := lane.span_at_global_y(rect.get_center().y)
			var overlap := minf(rect.end.x, span.y) - maxf(rect.position.x, span.x)
			ratios[lane.lane] = clampf(overlap / rect.size.x, 0.0, 1.0)
	return ratios


func at_curb() -> bool:
	return float(lane_ratios().get(RoadGeometry.Lane.PARKING, 0.0)) >= config.lane_membership_ratio


func report() -> VehicleReport:
	var r := VehicleReport.new()
	r.id = _vehicle.id
	r.z = _vehicle.z
	r.stationary = _vehicle.is_stationary()
	r.captured = _vehicle.captured
	r.lane_ratios = lane_ratios()
	for area in _vehicle.body_area.get_overlapping_areas():
		if area is ZoneArea:
			r.in_zone = true
	for area in _vehicle.curb_probe.get_overlapping_areas():
		var other := area.get_parent() as Vehicle
		if other != null and other != _vehicle and other.is_stationary() and other.sensor.at_curb():
			r.curb_neighbour = true
	return r

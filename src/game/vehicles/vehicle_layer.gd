class_name VehicleLayer
extends Node2D
## Holds the live vehicles, advances them, and reports which ones have passed
## under the bus. Freeing is a separate step so judgment can run first. In
## debug builds it can outline every plate rect (show_plate_rects tunable).

var config: TuningConfig
var vehicles: Array[Vehicle] = []


func _ready() -> void:
	if config == null:
		config = Tuning.config


func add(vehicle: Vehicle) -> void:
	add_child(vehicle)
	vehicles.append(vehicle)


## Moves every vehicle and returns those that passed the bus this frame.
func advance_all(delta: float, road_speed: float, camera_x: float) -> Array[Vehicle]:
	var passed: Array[Vehicle] = []
	for vehicle in vehicles:
		if vehicle.advance(delta, road_speed, camera_x):
			passed.append(vehicle)
	if config.show_plate_rects:
		queue_redraw()
	return passed


func free_passed(passed: Array[Vehicle]) -> void:
	for vehicle in passed:
		vehicles.erase(vehicle)
		vehicle.queue_free()


## Re-applies body styles, e.g. after a plate or light rect was retuned.
func restyle_all() -> void:
	for vehicle in vehicles:
		vehicle.apply_style()


func states() -> Array[VehicleState]:
	var result: Array[VehicleState] = []
	for vehicle in vehicles:
		result.append(vehicle.to_state())
	return result


func clear() -> void:
	for vehicle in vehicles:
		vehicle.queue_free()
	vehicles.clear()


func _draw() -> void:
	if not config.show_plate_rects:
		return
	for vehicle in vehicles:
		if vehicle.visible:
			draw_rect(vehicle.get_plate_rect(), Color.YELLOW, false, 1.0)

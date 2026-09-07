class_name VehicleLayer
extends Node2D
## Holds the live vehicles, advances them, and reports which ones have passed
## under the bus. Freeing is a separate step so judgment can run first.

var vehicles: Array[Vehicle] = []


func add(vehicle: Vehicle) -> void:
	add_child(vehicle)
	vehicles.append(vehicle)


## Moves every vehicle and returns those that passed the bus this frame.
func advance_all(delta: float, road_speed: float, camera_x: float) -> Array[Vehicle]:
	var passed: Array[Vehicle] = []
	for vehicle in vehicles:
		if vehicle.advance(delta, road_speed, camera_x):
			passed.append(vehicle)
	return passed


func free_passed(passed: Array[Vehicle]) -> void:
	for vehicle in passed:
		vehicles.erase(vehicle)
		vehicle.queue_free()


func states() -> Array[VehicleState]:
	var result: Array[VehicleState] = []
	for vehicle in vehicles:
		result.append(vehicle.to_state())
	return result


func clear() -> void:
	for vehicle in vehicles:
		vehicle.queue_free()
	vehicles.clear()

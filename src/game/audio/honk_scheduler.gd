class_name HonkScheduler
extends Node
## Rolls `honk_probability` whenever traffic interacts with the bus: the bus
## swerves out, a moving car merges out of its way, or a moving car is passed.
## A hit plays the honk cue.

signal honked

var config: TuningConfig
var rng := RandomNumberGenerator.new()

var _cues: AudioCues = null


func _ready() -> void:
	if config == null:
		config = Tuning.config


func bind(bus_driver: BusDriver, vehicle_layer: VehicleLayer, cues: AudioCues) -> void:
	_cues = cues
	bus_driver.swerve_started.connect(roll)
	bus_driver.vehicle_merging.connect(func(_vehicle: Vehicle) -> void: roll())
	vehicle_layer.vehicles_passed.connect(on_vehicles_passed)


## Parked cars do not honk; each moving car that goes by gets one roll.
func on_vehicles_passed(passed: Array[Vehicle]) -> void:
	for vehicle in passed:
		if not vehicle.is_stationary():
			roll()


func roll() -> void:
	var chance := config.honk_probability
	if chance <= 0.0 or rng.randf() > chance:
		return
	honked.emit()
	if _cues != null:
		_cues.play("honk")

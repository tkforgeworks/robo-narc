extends GutTest

const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")

var _config: TuningConfig
var _honks: HonkScheduler
var _driver: BusDriver
var _layer: VehicleLayer
var _cues: AudioCues


func before_each() -> void:
	_config = TuningConfig.new()
	_honks = HonkScheduler.new()
	_honks.config = _config
	_driver = BusDriver.new()
	_driver.config = _config
	_layer = VehicleLayer.new()
	_layer.config = _config
	_cues = AudioCues.new()
	for node: Node in [_driver, _layer, _cues, _honks]:
		add_child_autofree(node)
	_honks.bind(_driver, _layer, _cues)
	watch_signals(_honks)
	watch_signals(_cues)


func _vehicle(moving: bool) -> Vehicle:
	var vehicle: Vehicle = VEHICLE_SCENE.instantiate()
	vehicle.config = _config
	var motion := Vehicle.Motion.MOVING if moving else Vehicle.Motion.CURB_PARKED
	vehicle.setup(0.0, 50.0, motion, 10.0, VehicleStyle.make_default("t"), 0)
	add_child_autofree(vehicle)
	return vehicle


func test_certain_probability_honks_on_swerve_merge_and_pass() -> void:
	_config.honk_probability = 1.0
	_driver.swerve_started.emit()
	_driver.vehicle_merging.emit(_vehicle(true))
	var passed: Array[Vehicle] = [_vehicle(true), _vehicle(true)]
	_layer.vehicles_passed.emit(passed)
	assert_signal_emit_count(_honks, "honked", 4)
	assert_signal_emit_count(_cues, "played", 4)


func test_parked_cars_do_not_honk() -> void:
	_config.honk_probability = 1.0
	var passed: Array[Vehicle] = [_vehicle(false)]
	_layer.vehicles_passed.emit(passed)
	assert_signal_not_emitted(_honks, "honked")


func test_zero_probability_never_honks() -> void:
	_config.honk_probability = 0.0
	for i in 20:
		_driver.swerve_started.emit()
	assert_signal_not_emitted(_honks, "honked")


func test_probability_is_roughly_honoured() -> void:
	_config.honk_probability = 0.5
	_honks.rng.seed = 42
	for i in 400:
		_honks.roll()
	var count: int = get_signal_emit_count(_honks, "honked")
	assert_between(count, 150, 250)

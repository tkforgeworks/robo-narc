extends GutTest

const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")

var _config: TuningConfig
var _layer: VehicleLayer
var _judge: CaptureJudge
var _no_zones: Array[ZoneSpan] = []


func before_each() -> void:
	_config = TuningConfig.new()
	_layer = VehicleLayer.new()
	add_child_autofree(_layer)
	_judge = CaptureJudge.new(_config)


func _vehicle(road_x: float, z: float, motion: Vehicle.Motion) -> Vehicle:
	var v: Vehicle = VEHICLE_SCENE.instantiate()
	v.config = _config
	v.setup(road_x, z, motion, 0.0, VehicleStyle.make_default("t"), 0)
	_layer.add(v)
	v.refresh(_config.lane_bus_center())
	return v


func _box_around(v: Vehicle) -> Rect2:
	return v.get_plate_rect().grow(10.0)


func test_correct_capture_of_bus_lane_blocker() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.STOPPED_IN_ROAD)
	var outcome := _judge.judge(_box_around(v), _layer.vehicles, _no_zones)
	assert_eq(outcome.kind, CaptureOutcome.Kind.CORRECT)
	assert_eq(outcome.verdict.kind, Verdict.Kind.BUS_LANE)
	assert_eq(outcome.vehicle, v)
	assert_true(v.captured)


func test_wrong_capture_of_moving_car() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.MOVING)
	var outcome := _judge.judge(_box_around(v), _layer.vehicles, _no_zones)
	assert_eq(outcome.kind, CaptureOutcome.Kind.WRONG)
	assert_true(v.captured, "innocent vehicles are marked captured too")


func test_too_far_when_beyond_readable_distance() -> void:
	var v := _vehicle(_config.lane_bus_center(), _config.plate_readable_z + 5.0,
			Vehicle.Motion.STOPPED_IN_ROAD)
	var outcome := _judge.judge(_box_around(v), _layer.vehicles, _no_zones)
	assert_eq(outcome.kind, CaptureOutcome.Kind.TOO_FAR)
	assert_false(v.captured)


func test_empty_when_plate_not_fully_inside() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.STOPPED_IN_ROAD)
	var plate := v.get_plate_rect()
	var half_box := Rect2(plate.position, plate.size * 0.5)
	assert_eq(_judge.judge(half_box, _layer.vehicles, _no_zones).kind, CaptureOutcome.Kind.EMPTY)


func test_closest_of_two_framed_plates_wins() -> void:
	var near := _vehicle(_config.lane_bus_center(), 8.0, Vehicle.Motion.STOPPED_IN_ROAD)
	var far := _vehicle(_config.lane_bus_center(), 20.0, Vehicle.Motion.STOPPED_IN_ROAD)
	var box := _box_around(near).merge(_box_around(far))
	var outcome := _judge.judge(box, _layer.vehicles, _no_zones)
	assert_eq(outcome.vehicle, near)
	assert_false(far.captured)


func test_second_capture_of_same_vehicle_is_already_captured() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.STOPPED_IN_ROAD)
	_judge.judge(_box_around(v), _layer.vehicles, _no_zones)
	var again := _judge.judge(_box_around(v), _layer.vehicles, _no_zones)
	assert_eq(again.kind, CaptureOutcome.Kind.ALREADY_CAPTURED)

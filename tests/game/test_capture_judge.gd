extends GutTest
## Captures resolve through the areas, so each test lets the physics server
## settle before reading overlaps.

const VEHICLE_SCENE: PackedScene = preload("res://scenes/game/vehicle.tscn")
const ROAD_AREAS_SCENE: PackedScene = preload("res://scenes/game/road_areas.tscn")
const CAPTURE_BOX_SCENE: PackedScene = preload("res://scenes/game/capture_box.tscn")
const MARGIN := 10.0

var _config: TuningConfig
var _layer: VehicleLayer
var _box: CaptureBox
var _judge: CaptureJudge


func before_each() -> void:
	_config = TuningConfig.new()
	var areas: RoadAreas = ROAD_AREAS_SCENE.instantiate()
	areas.config = _config
	add_child_autofree(areas)
	_layer = VehicleLayer.new()
	_layer.config = _config
	add_child_autofree(_layer)
	_box = CAPTURE_BOX_SCENE.instantiate()
	_box.config = _config
	add_child_autofree(_box)
	_judge = CaptureJudge.new(_config)


func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func _vehicle(road_x: float, z: float, motion: Vehicle.Motion) -> Vehicle:
	var v: Vehicle = VEHICLE_SCENE.instantiate()
	v.config = _config
	v.setup(road_x, z, motion, 0.0, VehicleStyle.make_default("t"), 0)
	_layer.add(v)
	v.refresh(_config.lane_bus_center())
	return v


## Sizes and places the box over `rect` (via the tunable size, which the box follows).
func _frame(rect: Rect2) -> void:
	_config.box_size = rect.size + Vector2.ONE * MARGIN * 2.0
	_box.position = rect.position - Vector2.ONE * MARGIN
	await _settle()


func test_correct_capture_of_bus_lane_blocker() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.STOPPED_IN_ROAD)
	await _frame(v.get_plate_rect())
	var hits := _box.plate_hits()
	assert_eq(hits.size(), 1)
	assert_almost_eq(hits[0].coverage, 1.0, 0.001)
	var outcome := _judge.judge(hits)
	assert_eq(outcome.kind, CaptureOutcome.Kind.CORRECT)
	assert_eq(outcome.verdict.kind, Verdict.Kind.BUS_LANE)
	assert_eq(outcome.vehicle, v)
	assert_true(v.captured)


func test_wrong_capture_of_moving_car() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.MOVING)
	await _frame(v.get_plate_rect())
	var outcome := _judge.judge(_box.plate_hits())
	assert_eq(outcome.kind, CaptureOutcome.Kind.WRONG)
	assert_true(v.captured, "innocent vehicles are marked captured too")


func test_too_far_when_beyond_readable_distance() -> void:
	var v := _vehicle(_config.lane_bus_center(), _config.plate_readable_z + 5.0,
			Vehicle.Motion.STOPPED_IN_ROAD)
	await _frame(v.get_plate_rect())
	var outcome := _judge.judge(_box.plate_hits())
	assert_eq(outcome.kind, CaptureOutcome.Kind.TOO_FAR)
	assert_false(v.captured)


func test_partly_framed_plate_is_empty_at_full_overlap_ratio() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.STOPPED_IN_ROAD)
	var plate := v.get_plate_rect()
	var half := Rect2(plate.position, plate.size * 0.5)
	_config.box_size = half.size
	_box.position = half.position
	await _settle()
	assert_almost_eq(_box.size.x, half.size.x, 0.01, "box follows the tunable size")
	var hits := _box.plate_hits()
	assert_eq(hits.size(), 1, "the area still overlaps")
	assert_almost_eq(hits[0].coverage, 0.25, 0.02)
	assert_eq(_judge.judge(hits).kind, CaptureOutcome.Kind.EMPTY)
	_config.capture_overlap_ratio = 0.2
	assert_eq(_judge.judge(hits).kind, CaptureOutcome.Kind.CORRECT, "a looser ratio accepts it")


func test_closest_of_two_framed_plates_wins() -> void:
	var near := _vehicle(_config.lane_bus_center(), 8.0, Vehicle.Motion.STOPPED_IN_ROAD)
	var far := _vehicle(_config.lane_bus_center(), 20.0, Vehicle.Motion.STOPPED_IN_ROAD)
	await _frame(near.get_plate_rect().merge(far.get_plate_rect()))
	var outcome := _judge.judge(_box.plate_hits())
	assert_eq(outcome.vehicle, near)
	assert_false(far.captured)


func test_second_capture_of_same_vehicle_is_already_captured() -> void:
	var v := _vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.STOPPED_IN_ROAD)
	await _frame(v.get_plate_rect())
	_judge.judge(_box.plate_hits())
	assert_eq(_judge.judge(_box.plate_hits()).kind, CaptureOutcome.Kind.ALREADY_CAPTURED)


func test_nothing_under_the_box_is_empty() -> void:
	_vehicle(_config.lane_bus_center(), 10.0, Vehicle.Motion.STOPPED_IN_ROAD)
	_config.box_size = Vector2(40, 40)
	_box.position = Vector2.ZERO
	await _settle()
	assert_eq(_box.plate_hits().size(), 0)
	assert_eq(_judge.judge(_box.plate_hits()).kind, CaptureOutcome.Kind.EMPTY)

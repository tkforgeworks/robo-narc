extends GutTest
## End-to-end smoke test of the composed gameplay scene with a very short shift.

const GAMEPLAY_SCENE: PackedScene = preload("res://scenes/game/gameplay.tscn")

var _config: TuningConfig
var _screen: GameplayScreen


func before_each() -> void:
	_config = TuningConfig.new()
	_config.shift_length_sec = 10.0
	_config.count_in_sec = 1.0
	_config.spawn_interval_start = 0.3
	_config.spawn_interval_end = 0.3
	_screen = GAMEPLAY_SCENE.instantiate()
	_screen.config = _config
	add_child_autofree(_screen)
	watch_signals(_screen)


func test_enter_runs_count_in_then_shift_and_navigates_with_result() -> void:
	_screen.enter(null)
	var clock: ShiftClock = _screen.get_node("ShiftClock")
	assert_eq(clock.phase, ShiftClock.Phase.COUNT_IN)
	await wait_seconds(1.3)
	assert_eq(clock.phase, ShiftClock.Phase.RUNNING, "count-in hands over to play")
	var box: CaptureBox = _screen.get_node("Overlay/Frame/CaptureBox")
	assert_true(box.enabled)
	await wait_seconds(1.5)
	var layer: VehicleLayer = _screen.get_node("VehicleLayer")
	assert_gt(layer.vehicles.size(), 0, "spawner is running")
	var spawner: VehicleSpawner = _screen.get_node("VehicleSpawner")
	assert_gt(spawner.spawn_count, 0)
	# Fast-forward the clock instead of waiting the whole shift.
	clock.time_left = 0.05
	await wait_seconds(0.3)
	assert_eq(clock.phase, ShiftClock.Phase.ENDED)
	assert_signal_emitted(_screen, "navigation_requested")
	var params: Array = get_signal_parameters(_screen, "navigation_requested")
	assert_true(params[1] is ShiftResult)
	assert_eq((params[1] as ShiftResult).duration_sec, 10.0)
	assert_false(box.enabled)


func test_capture_press_during_shift_is_scored_or_empty() -> void:
	_screen.enter(null)
	var clock: ShiftClock = _screen.get_node("ShiftClock")
	clock.begin_running()
	var box: CaptureBox = _screen.get_node("Overlay/Frame/CaptureBox")
	var keeper: ScoreKeeper = _screen.get_node("ScoreKeeper")
	watch_signals(keeper)
	assert_true(box.try_capture())
	assert_signal_emitted(keeper, "score_changed")
	assert_false(box.try_capture(), "cooldown blocks an immediate second capture")


func test_focus_loss_owes_resume_count_in_and_releases() -> void:
	_screen.enter(null)
	var clock: ShiftClock = _screen.get_node("ShiftClock")
	clock.begin_running()
	_screen.on_focus_paused()
	assert_eq(clock.phase, ShiftClock.Phase.RESUME_COUNT_IN)
	var released := [false]
	_screen.on_focus_resume_requested(func() -> void: released[0] = true)
	assert_true(released[0], "tree is released immediately; the count-in runs unpaused")
	var count_in: CountIn = _screen.get_node("Overlay/Frame/CountIn")
	assert_true(count_in.visible)
	await wait_seconds(_config.resume_count_in_sec + 0.3)
	assert_eq(clock.phase, ShiftClock.Phase.RUNNING)

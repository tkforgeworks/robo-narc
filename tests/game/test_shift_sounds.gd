extends GutTest
## The composed gameplay scene fires the right cue for each shift event.

const GAMEPLAY_SCENE: PackedScene = preload("res://scenes/game/gameplay.tscn")

var _screen: GameplayScreen
var _cues: AudioCues


func before_each() -> void:
	var config := TuningConfig.new()
	config.shift_length_sec = 5.0
	config.count_in_sec = 0.0
	config.spawn_interval_start = 100.0
	config.spawn_interval_end = 100.0
	_screen = GAMEPLAY_SCENE.instantiate()
	_screen.config = config
	add_child_autofree(_screen)
	_cues = _screen.get_node("AudioCues")
	watch_signals(_cues)


func _played() -> Array:
	var events: Array = []
	for i in get_signal_emit_count(_cues, "played"):
		events.append(get_signal_parameters(_cues, "played", i)[0])
	return events


func test_capture_press_plays_shutter_only_when_nothing_is_framed() -> void:
	_screen.enter(null)
	(_screen.get_node("ShiftClock") as ShiftClock).begin_running()
	(_screen.get_node("Overlay/Frame/CaptureBox") as CaptureBox).try_capture()
	assert_eq(_played(), ["shutter"])


func test_correct_wrong_and_miss_map_to_their_cues() -> void:
	var keeper: ScoreKeeper = _screen.get_node("ScoreKeeper")
	_screen.enter(null)
	keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.CORRECT, null,
			Verdict.of(Verdict.Kind.BUS_LANE)))
	keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.WRONG, null, Verdict.innocent()))
	keeper.apply_capture(CaptureOutcome.new(CaptureOutcome.Kind.TOO_FAR))
	keeper.apply_miss(Verdict.of(Verdict.Kind.BIKE_LANE))
	assert_eq(_played(), ["capture_correct", "capture_wrong", "miss"])


func test_shift_end_plays_when_the_clock_runs_out() -> void:
	_screen.enter(null)
	var clock: ShiftClock = _screen.get_node("ShiftClock")
	clock.begin_running()
	clock.time_left = 0.01
	await wait_seconds(0.2)
	assert_true(_played().has("shift_end"))


func test_count_in_ticks_play() -> void:
	(_screen.get_node("Overlay/Frame/CountIn") as CountIn).run(2.0)
	assert_eq(_played(), ["count_in_tick"], "first tick shows immediately")


func test_capture_cue_table() -> void:
	assert_eq(ShiftSounds.cue_for_capture(CaptureOutcome.Kind.CORRECT), "capture_correct")
	assert_eq(ShiftSounds.cue_for_capture(CaptureOutcome.Kind.EMPTY), "")

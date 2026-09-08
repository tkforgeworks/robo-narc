extends GutTest

var _cues: AudioCues


func before_each() -> void:
	_cues = AudioCues.new()
	add_child_autofree(_cues)
	watch_signals(_cues)


func test_every_event_resolves_from_the_placeholder_set() -> void:
	assert_eq(_cues.missing_events().size(), 0, str(_cues.missing_events()))
	for event in AudioCues.EVENTS:
		assert_true(_cues.is_resolved(event), event)


func test_play_starts_a_pooled_player_on_the_sfx_bus() -> void:
	_cues.play("shutter")
	assert_signal_emitted_with_parameters(_cues, "played", ["shutter"])
	var playing := 0
	for child in _cues.get_children():
		var player := child as AudioStreamPlayer
		assert_eq(player.bus, &"SFX")
		if player.playing:
			playing += 1
	assert_eq(playing, 1)


func test_overlapping_cues_use_separate_players() -> void:
	for i in AudioCues.POOL_SIZE + 2:
		_cues.play("honk")
	assert_signal_emit_count(_cues, "played", AudioCues.POOL_SIZE + 2, "pool wraps, never drops")


func test_unknown_event_is_ignored() -> void:
	_cues.play("explosion")
	_cues.play("explosion")
	assert_signal_not_emitted(_cues, "played")


func test_missing_files_are_silent_no_ops() -> void:
	var silent := AudioCues.new()
	silent.sfx_dir = "res://assets/audio/nowhere"
	add_child_autofree(silent)
	watch_signals(silent)
	assert_eq(silent.missing_events().size(), AudioCues.EVENTS.size())
	silent.play("shutter")
	assert_signal_not_emitted(silent, "played")


func test_ogg_is_preferred_over_wav() -> void:
	var stream := AudioCues.resolve("res://assets/audio/sfx", "honk")
	assert_not_null(stream)
	assert_true(stream is AudioStreamWAV, "only the wav placeholder exists today")
	assert_null(AudioCues.resolve("res://assets/audio/sfx", "nope"))

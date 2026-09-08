extends GutTest
## Scene tests for the title, about, settings, and results screens.

const TITLE_SCENE: PackedScene = preload("res://scenes/screens/title_screen.tscn")
const ABOUT_SCENE: PackedScene = preload("res://scenes/screens/about_screen.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/screens/settings_screen.tscn")
const RESULTS_SCENE: PackedScene = preload("res://scenes/screens/results_screen.tscn")
const TEST_SCORES := "user://test_screens_scores.json"
const TEST_SETTINGS := "user://test_screens_settings.cfg"


func after_each() -> void:
	ScoreStore.new(TEST_SCORES).clear()
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _result(score: int, name: String = "Ava") -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.player_name = name
	r.correct = 3
	r.missed = 1
	return r


func test_title_lists_local_top_scores_and_navigates() -> void:
	var store := ScoreStore.new(TEST_SCORES)
	store.append(_result(100, "Ava"))
	store.append(_result(300, "Bo"))
	var title: TitleScreen = TITLE_SCENE.instantiate()
	title.config = TuningConfig.new()
	title.score_store = store
	title.leaderboard_config = LeaderboardConfig.new()
	add_child_autofree(title)
	watch_signals(title)
	assert_eq(title.score_row_count(), 2)
	assert_string_contains((title.get_node("%Leaderboard") as LeaderboardPanel).row_text(0), "Bo")
	title.get_node("%AboutButton").pressed.emit()
	assert_signal_emitted(title, "navigation_requested")
	var params: Array = get_signal_parameters(title, "navigation_requested")
	assert_string_contains((params[0] as PackedScene).resource_path, "about_screen")


func test_title_shows_empty_state_and_cue_sheet() -> void:
	var title: TitleScreen = TITLE_SCENE.instantiate()
	title.config = TuningConfig.new()
	title.score_store = ScoreStore.new(TEST_SCORES)
	title.leaderboard_config = LeaderboardConfig.new()
	add_child_autofree(title)
	assert_eq(title.score_row_count(), 1, "one 'no shifts' row")
	var cue: CueSheet = title.get_node("Layout/Right/CueSheet")
	assert_eq(cue.get_child_count(), cue.row_count() + 2, "heading, rows, light cue")


func test_about_has_pitch_and_back() -> void:
	var about: AboutScreen = ABOUT_SCENE.instantiate()
	add_child_autofree(about)
	watch_signals(about)
	assert_string_contains(about.get_node("%PitchText").text, "bus")
	about.get_node("%BackButton").pressed.emit()
	assert_signal_emitted(about, "navigation_requested")


func test_settings_sliders_persist_and_drive_mixer() -> void:
	var settings := SettingsStore.new(TEST_SETTINGS)
	var mixer := AudioMixer.new()
	mixer.settings = settings
	add_child_autofree(mixer)
	var screen: SettingsScreen = SETTINGS_SCENE.instantiate()
	add_child_autofree(screen)
	screen.bind_settings(settings)
	screen.bind_audio_mixer(mixer)
	var music: HSlider = screen.get_node("%MusicSlider")
	assert_almost_eq(music.value, 0.7, 0.001, "prefilled from settings")
	music.value = 0.2
	assert_almost_eq(settings.music, 0.2, 0.001)
	assert_almost_eq(SettingsStore.new(TEST_SETTINGS).music, 0.2, 0.001, "saved to disk")
	assert_almost_eq(mixer.get_volume("Music"), 0.2, 0.01)
	mixer.set_volume("Music", 1.0)


func test_results_shows_breakdown_rank_and_countdown() -> void:
	var config := TuningConfig.new()
	config.results_idle_timeout_sec = 12.0
	var results: ResultsScreen = RESULTS_SCENE.instantiate()
	results.config = config
	results.score_store = ScoreStore.new(TEST_SCORES)
	results.leaderboard_config = LeaderboardConfig.new()
	add_child_autofree(results)
	watch_signals(results)
	results.enter(_result(-15))
	assert_eq(results.get_node("%ScoreLabel").text, "-15")
	var entry: NameEntry = results.get_node("%NameEntry")
	assert_true(entry.visible, "name entry comes first")
	assert_false(results.get_node("%Details").visible)
	entry.prefill("Ava")
	entry.submit()
	assert_false(entry.visible)
	assert_eq(results.score_store.records[0].result.player_name, "Ava")
	assert_eq(results.get_node("%Breakdown").get_child_count(), 8)
	assert_string_contains(results.get_node("%RankLabel").text, "Local rank: 1 of 1")
	var idle: IdleTimeout = results.get_node("IdleTimeout")
	assert_true(idle.running)
	var countdown: Label = results.get_node("%CountdownLabel")
	results._process(0.0)
	assert_false(countdown.visible, "hidden with 12 s left")
	idle.time_left = 4.2
	results._process(0.0)
	assert_true(countdown.visible)
	assert_eq(countdown.text, "Back to title in 5")
	idle._input(InputEventKey.new())
	assert_false(idle.running, "any input cancels the auto-return")


func test_results_auto_returns_to_title() -> void:
	var config := TuningConfig.new()
	config.results_idle_timeout_sec = 0.05
	var results: ResultsScreen = RESULTS_SCENE.instantiate()
	results.config = config
	results.score_store = ScoreStore.new(TEST_SCORES)
	results.leaderboard_config = LeaderboardConfig.new()
	add_child_autofree(results)
	watch_signals(results)
	results.enter(_result(10))
	await wait_seconds(0.2)
	assert_signal_emitted(results, "navigation_requested")
	var params: Array = get_signal_parameters(results, "navigation_requested")
	assert_string_contains((params[0] as PackedScene).resource_path, "title_screen")

extends GutTest
## Scene tests for the title, about, settings, and results screens.

const TITLE_SCENE: PackedScene = preload("res://scenes/screens/title_screen.tscn")
const ABOUT_SCENE: PackedScene = preload("res://scenes/screens/about_screen.tscn")
const COMPANY_SCENE: PackedScene = preload("res://scenes/screens/company_screen.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/screens/settings_screen.tscn")
const RESULTS_SCENE: PackedScene = preload("res://scenes/screens/results_screen.tscn")
const PENDING := "user://test_screens_pending.json"
const CACHE := "user://test_screens_cache.json"
const TEST_SETTINGS := "user://test_screens_settings.cfg"


func before_each() -> void:
	_clear_files()


func after_each() -> void:
	_clear_files()
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _clear_files() -> void:
	PendingStore.new(PENDING).clear()
	BoardCache.new(CACHE).clear()


## A service with no board configured, reading the test cache and queue.
func _offline_service() -> LeaderboardService:
	var client := LeaderboardClient.new()
	client.config = LeaderboardConfig.new()
	var service := LeaderboardService.new()
	service.client = client
	service.pending_path = PENDING
	service.cache_path = CACHE
	service.config = TuningConfig.new()
	add_child_autofree(service)
	return service


func _result(score: int) -> ShiftResult:
	var r := ShiftResult.new()
	r.score = score
	r.correct = 3
	r.missed = 1
	return r


func test_title_lists_the_cached_board_and_navigates() -> void:
	var entries: Array[LeaderboardEntry] = [
		LeaderboardEntry.new(1, "Bo M.", 300), LeaderboardEntry.new(2, "Ava K.", 100)]
	BoardCache.new(CACHE).store(entries)
	var title: TitleScreen = TITLE_SCENE.instantiate()
	title.config = TuningConfig.new()
	title.leaderboard = _offline_service()
	add_child_autofree(title)
	watch_signals(title)
	assert_eq(title.score_row_count(), 2)
	var board: LeaderboardPanel = title.get_node("%Leaderboard")
	assert_string_contains(board.row_text(0), "Bo M.")
	assert_string_contains(board.sync_text(), "no board")
	title.get_node("%AboutButton").pressed.emit()
	assert_signal_emitted(title, "navigation_requested")
	var params: Array = get_signal_parameters(title, "navigation_requested")
	assert_string_contains((params[0] as PackedScene).resource_path, "about_screen")


func test_title_shows_empty_state_and_reaches_the_company_screen() -> void:
	var title: TitleScreen = TITLE_SCENE.instantiate()
	title.config = TuningConfig.new()
	title.leaderboard = _offline_service()
	add_child_autofree(title)
	watch_signals(title)
	assert_eq(title.score_row_count(), 1, "one 'no shifts' row")
	title.get_node("%CompanyButton").pressed.emit()
	var params: Array = get_signal_parameters(title, "navigation_requested")
	assert_string_contains((params[0] as PackedScene).resource_path, "company_screen")


func test_about_has_pitch_cue_sheet_and_back() -> void:
	var about: AboutScreen = ABOUT_SCENE.instantiate()
	add_child_autofree(about)
	watch_signals(about)
	assert_string_contains(about.get_node("%PitchText").text, "bus")
	var cue: CueSheet = about.get_node("Column/CueSheet")
	assert_gt(cue.get_child_count(), 0, "authored cue sheet is present")
	var overlay: ControlsOverlay = about.get_node("ControlsOverlay")
	assert_false(overlay.is_open())
	about.get_node("%ControlsButton").pressed.emit()
	assert_true(overlay.is_open(), "Controls button opens the card")
	overlay.close()
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
	var toggle: CheckButton = screen.get_node("%ShowControlsToggle")
	assert_true(toggle.button_pressed, "prefilled: controls shown by default")
	toggle.button_pressed = false
	assert_false(settings.show_controls_on_start)
	assert_false(SettingsStore.new(TEST_SETTINGS).show_controls_on_start, "persisted")
	watch_signals(screen)
	screen.get_node("%ControlsButton").pressed.emit()
	var params: Array = get_signal_parameters(screen, "navigation_requested")
	assert_string_contains((params[0] as PackedScene).resource_path, "controls_screen")
	assert_almost_eq(SettingsStore.new(TEST_SETTINGS).music, 0.2, 0.001, "saved to disk")
	assert_almost_eq(mixer.get_volume("Music"), 0.2, 0.01)
	mixer.set_volume("Music", 1.0)


func test_results_shows_breakdown_and_countdown_without_a_board() -> void:
	var config := TuningConfig.new()
	config.results_idle_timeout_sec = 12.0
	var results: ResultsScreen = RESULTS_SCENE.instantiate()
	results.config = config
	results.leaderboard = _offline_service()
	add_child_autofree(results)
	watch_signals(results)
	results.enter(_result(-15))
	assert_eq(results.get_node("%ScoreLabel").text, "-15")
	var entry: IdentityEntry = results.get_node("%IdentityEntry")
	assert_true(entry.visible, "identity entry comes first")
	assert_false(results.get_node("%Details").visible)
	entry.set_fields("ava@example.com", "Ava", "K")
	entry.submit()
	assert_false(entry.visible)
	assert_eq(results.get_node("%Breakdown").get_child_count(), 8)
	var metrics: GridContainer = results.get_node("%Metrics")
	assert_eq(metrics.get_child_count(), 6, "precision, recall, F1")
	assert_eq((metrics.get_child(4) as Label).text, "F1")
	assert_eq((metrics.get_child(5) as Label).text, "0.86", "3 correct, 1 missed")
	assert_eq(results.get_node("%RankLabel").text, ResultsScreen.NOT_POSTED_TEXT)
	assert_eq(PendingStore.new(PENDING).size(), 0, "nothing queued without a board")
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
	results.leaderboard = _offline_service()
	add_child_autofree(results)
	watch_signals(results)
	results.enter(_result(10))
	await wait_seconds(0.2)
	assert_signal_emitted(results, "navigation_requested")
	var params: Array = get_signal_parameters(results, "navigation_requested")
	assert_string_contains((params[0] as PackedScene).resource_path, "title_screen")


func test_company_screen_has_blurb_and_back() -> void:
	var company: CompanyScreen = COMPANY_SCENE.instantiate()
	add_child_autofree(company)
	watch_signals(company)
	assert_false((company.get_node("%BlurbText") as Label).text.is_empty())
	company.get_node("%BackButton").pressed.emit()
	assert_signal_emitted(company, "navigation_requested")

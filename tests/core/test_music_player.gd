extends GutTest


func test_plays_the_placeholder_track_on_the_music_bus() -> void:
	var music := MusicPlayer.new()
	add_child_autofree(music)
	assert_not_null(music.stream)
	assert_eq(music.bus, &"Music")
	assert_true(music.playing)
	assert_true(music.finished.is_connected(music.play), "restarts on finish")


func test_missing_track_is_silent_without_errors() -> void:
	var music := MusicPlayer.new()
	music.track = "res://assets/audio/music/nothing_here"
	add_child_autofree(music)
	assert_null(music.stream)
	assert_false(music.playing)

extends GutTest


func test_format_has_iso_timestamp_level_and_tag() -> void:
	var line := DebugLog.format(DebugLog.Level.INFO, "Tag", "hello world")
	var pattern := RegEx.create_from_string(
			"^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2} \\[INFO\\] \\[Tag\\] hello world$")
	assert_not_null(pattern.search(line), "unexpected format: %s" % line)


func test_levels_are_named() -> void:
	assert_string_contains(DebugLog.format(DebugLog.Level.WARN, "T", "m"), "[WARN]")
	assert_string_contains(DebugLog.format(DebugLog.Level.ERROR, "T", "m"), "[ERROR]")


func test_info_does_not_error() -> void:
	DebugLog.info("Test", "info is safe to call")
	pass_test("no exception")

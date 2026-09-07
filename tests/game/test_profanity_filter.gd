extends GutTest

var _filter: ProfanityFilter


func before_each() -> void:
	_filter = ProfanityFilter.new(PackedStringArray(["fuck", "shit", "twat"]))


func test_plain_and_case_insensitive_matches() -> void:
	assert_true(_filter.contains("fuck"))
	assert_true(_filter.contains("FUCK"))
	assert_true(_filter.contains("ShIt"))
	assert_false(_filter.contains("Ava"))
	assert_false(_filter.contains(""))


func test_substring_matches_inside_a_name() -> void:
	assert_true(_filter.contains("xxFuckxx"))
	assert_true(_filter.contains("BigTwatt"))


func test_repeated_letters_and_leet_are_caught() -> void:
	assert_true(_filter.contains("fuuuuck"))
	assert_true(_filter.contains("sh1t"))
	assert_true(_filter.contains("$hit"))
	assert_true(_filter.contains("f.u.c.k"))


func test_normalize() -> void:
	assert_eq(ProfanityFilter.normalize("Sh1T-4b@"), "shitaba")
	assert_eq(ProfanityFilter.normalize("123"), "ie")


func test_list_parsing_ignores_comments_blanks_and_duplicates() -> void:
	var filter := ProfanityFilter.new(PackedStringArray(["# comment", "", "damn # trailing", "DAMN", "  "]))
	assert_eq(filter.word_count(), 1)
	assert_true(filter.contains("Damn"))


func test_shipped_list_loads_and_spares_common_names() -> void:
	var shipped := ProfanityFilter.load_default()
	assert_gt(shipped.word_count(), 40)
	for name: String in ["Ava", "Cassidy", "Bassam", "Michelle", "Rookie", "Nora"]:
		assert_false(shipped.contains(name), name)
	assert_true(shipped.contains("Fuckface"))
	assert_true(shipped.contains("Scunthorpe"), "substring rule; accepted trade-off (R-13)")


func test_missing_list_is_permissive() -> void:
	var none := ProfanityFilter.load_from("res://data/game/does_not_exist.txt")
	assert_eq(none.word_count(), 0)
	assert_false(none.contains("anything"))

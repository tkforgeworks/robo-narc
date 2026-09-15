extends GutTest


func test_v4_has_the_shape_and_version_bits() -> void:
	var id := Uuid.v4()
	assert_true(Uuid.is_valid(id), id)
	assert_eq(id[14], "4", "version nibble")
	assert_true("89ab".contains(id[19]), "variant nibble: %s" % id)


func test_ids_do_not_repeat() -> void:
	var seen := {}
	for i in 200:
		seen[Uuid.v4()] = true
	assert_eq(seen.size(), 200)


func test_is_valid_rejects_other_strings() -> void:
	assert_false(Uuid.is_valid(""))
	assert_false(Uuid.is_valid("not-a-uuid"))
	assert_false(Uuid.is_valid("12345678-1234-1234-1234-12345678901G"))

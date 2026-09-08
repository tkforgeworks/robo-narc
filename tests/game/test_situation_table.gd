extends GutTest


func test_distribution_matches_weights() -> void:
	var config := TuningConfig.new()
	var table := SituationTable.new(config)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var counts := {}
	var samples := 20000
	for i in samples:
		var kind := table.pick(rng)
		counts[kind] = counts.get(kind, 0) + 1
	var total := table.total_weight()
	for kind: SituationTable.Kind in SituationTable.Kind.values():
		var expected := table.weight_of(kind) / total
		var observed := float(counts.get(kind, 0)) / samples
		assert_almost_eq(observed, expected, 0.02, SituationTable.Kind.keys()[kind])


func test_zero_weight_kind_never_picked() -> void:
	var config := TuningConfig.new()
	config.situation_weight_double_park_pair = 0.0
	var table := SituationTable.new(config)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 2000:
		assert_ne(table.pick(rng), SituationTable.Kind.DOUBLE_PARK_PAIR)
		if is_failing():
			break


func test_all_zero_weights_fall_back_to_moving_traffic() -> void:
	var config := TuningConfig.new()
	for key in TunableProperties.names(config):
		if key.begins_with("situation_weight_"):
			config.set(key, 0.0)
	var table := SituationTable.new(config)
	assert_eq(table.pick(RandomNumberGenerator.new()), SituationTable.Kind.MOVING_TRAFFIC)


func test_weights_are_read_live() -> void:
	var config := TuningConfig.new()
	var table := SituationTable.new(config)
	config.situation_weight_bus_stop_zone = 5.0
	assert_eq(table.weight_of(SituationTable.Kind.BUS_STOP_ZONE), 5.0)

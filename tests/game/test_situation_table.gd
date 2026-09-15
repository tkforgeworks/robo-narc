extends GutTest


func _table(bag_size: int = 20) -> SituationTable:
	var config := TuningConfig.new()
	config.situation_bag_size = bag_size
	return SituationTable.new(config)


func _rng(seed_value: int = 12345) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_distribution_matches_weights() -> void:
	for bag_size in [0, 20]:
		var table := _table(bag_size)
		var rng := _rng()
		var counts := {}
		var samples := 20000
		for i in samples:
			var kind := table.pick(rng)
			counts[kind] = counts.get(kind, 0) + 1
		var total := table.total_weight()
		for kind: SituationTable.Kind in SituationTable.Kind.values():
			var expected := table.weight_of(kind) / total
			var observed := float(counts.get(kind, 0)) / samples
			assert_almost_eq(observed, expected, 0.03, "%s bag %d" % [SituationTable.Kind.keys()[kind], bag_size])


func test_bag_pins_the_mix_within_each_bag() -> void:
	var table := _table(20)
	table.config.situation_weight_moving_traffic = 0.01
	var composition := table.bag_composition()
	var bag_total := 0
	for kind: SituationTable.Kind in composition:
		bag_total += composition[kind]
	assert_between(bag_total, 18, 23, "rounding keeps the bag near its size")
	assert_eq(composition[SituationTable.Kind.MOVING_TRAFFIC], 1, "a tiny weight still gets one slot, never zero")
	var rng := _rng(3)
	var counts := {}
	for i in bag_total:
		var kind := table.pick(rng)
		counts[kind] = counts.get(kind, 0) + 1
	assert_eq(counts, composition, "one full bag draws exactly its composition")
	assert_eq(table.bag_count(), 0, "empty after one bag")
	table.pick(rng)
	assert_eq(table.bag_count(), bag_total - 1, "refilled on the next pick")


func test_put_back_keeps_the_kind_in_the_bag() -> void:
	var table := _table(20)
	var rng := _rng(9)
	var kind := table.pick(rng)
	var before := table.bag_count()
	table.put_back(kind, rng)
	assert_eq(table.bag_count(), before + 1)
	var seen := 0
	while table.bag_count() > 0:
		if table.pick(rng) == kind:
			seen += 1
	assert_eq(seen, table.bag_composition()[kind], "the returned one is drawn again in this bag")


func test_bag_size_zero_rolls_every_tick() -> void:
	var table := _table(0)
	var rng := _rng()
	for i in 50:
		table.pick(rng)
	assert_eq(table.bag_count(), 0)
	table.put_back(SituationTable.Kind.BUS_STOP_ZONE, rng)
	assert_eq(table.bag_count(), 0, "nothing to put back into")


func test_zero_weight_kind_never_picked() -> void:
	for bag_size in [0, 20]:
		var config := TuningConfig.new()
		config.situation_bag_size = bag_size
		config.situation_weight_double_park_pair = 0.0
		var table := SituationTable.new(config)
		var rng := _rng(7)
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


func test_weights_are_read_live_at_the_next_refill() -> void:
	var config := TuningConfig.new()
	var table := SituationTable.new(config)
	config.situation_weight_bus_stop_zone = 5.0
	assert_eq(table.weight_of(SituationTable.Kind.BUS_STOP_ZONE), 5.0)
	assert_gt(table.bag_composition()[SituationTable.Kind.BUS_STOP_ZONE], 15, "dominates the next bag")

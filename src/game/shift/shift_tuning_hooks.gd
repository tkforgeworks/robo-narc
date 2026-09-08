class_name ShiftTuningHooks
extends Node
## Re-applies the few tunables a running shift latches at start (shift length,
## box size, vehicle style rects) when the debug menu changes them, so live
## tuning is visible without restarting the shift (spec FR-021).

var config: TuningConfig


func _ready() -> void:
	if config == null:
		config = Tuning.config


func bind(tuning: TuningService, clock: ShiftClock, hud: Hud, capture_box: CaptureBox,
		vehicle_layer: VehicleLayer, registry: VehicleRegistry) -> void:
	if registry != null:
		tuning.register_style_provider(registry)
	tuning.style_changed.connect(func(_key: String, _prop: String) -> void:
		vehicle_layer.restyle_all())
	tuning.changed.connect(func(property_name: String) -> void:
		if property_name == "shift_length_sec":
			_apply_length(clock, hud)
		elif property_name == "box_size":
			capture_box.center_in_playfield())
	tuning.reset.connect(func() -> void: _apply_length(clock, hud))


func _apply_length(clock: ShiftClock, hud: Hud) -> void:
	clock.set_duration(config.shift_length_sec)
	hud.set_time(clock.time_left)

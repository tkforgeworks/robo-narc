class_name DifficultyRamp
extends RefCounted
## Maps shift progress (0 at the start, 1 at the end) to the cruise speed and
## spawn interval. Reads the live config every call so debug-menu changes
## take effect immediately.

var config: TuningConfig


func _init(p_config: TuningConfig) -> void:
	config = p_config


func cruise_speed(progress: float) -> float:
	return lerpf(config.cruise_speed_start, config.cruise_speed_end, clampf(progress, 0.0, 1.0))


func spawn_interval(progress: float) -> float:
	return lerpf(config.spawn_interval_start, config.spawn_interval_end, clampf(progress, 0.0, 1.0))

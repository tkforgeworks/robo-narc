class_name TuningConfig
extends Resource
## Every gameplay feel value in one typed, enumerable resource (constitution IV).
## Adding an `@export` here is the whole change: the debug menu, reset, and
## overrides pick it up. Defaults match specs/001-robonarc-game/contracts/tunables.md.

@export_group("Shift")
@export_range(10.0, 600.0, 5.0) var shift_length_sec: float = 90.0
@export_range(1.0, 5.0, 1.0) var count_in_sec: float = 3.0
@export_range(0.0, 5.0, 1.0) var resume_count_in_sec: float = 3.0
@export_range(5.0, 600.0, 5.0) var results_idle_timeout_sec: float = 60.0
@export_range(0.3, 4.0, 0.1) var feedback_time_sec: float = 1.4

@export_group("Road")
@export_range(-300.0, 300.0, 1.0) var horizon_y: float = -5.0
@export_range(600.0, 900.0, 1.0) var bus_screen_y: float = 760.0
@export_range(300.0, 900.0, 1.0) var vanishing_point_x: float = 553.0
@export_range(5.0, 40.0, 0.5) var perspective_c: float = 15.0
@export_range(50.0, 200.0, 5.0) var z_max: float = 100.0
@export_range(0.0, 5.0, 0.5) var pass_z: float = 1.0
@export_range(0.0, 1.5, 0.05) var backdrop_shear_factor: float = 1.0
@export_range(-1500.0, 0.0, 5.0) var road_edge_left_x: float = -538.0
@export_range(-800.0, 0.0, 1.0) var lane_road_left: float = -245.0
@export_range(0.0, 600.0, 1.0) var lane_bus_left: float = 148.0
@export_range(0.0, 800.0, 1.0) var lane_bus_right: float = 542.0
@export_range(0.0, 900.0, 1.0) var lane_bike_right: float = 700.0
@export_range(0.0, 1200.0, 1.0) var lane_curb_x: float = 961.0
@export_range(800.0, 3000.0, 5.0) var road_edge_right_x: float = 1576.0
@export_range(0.0, 1200.0, 1.0) var curb_threshold_x: float = 720.0
@export_range(5.0, 60.0, 1.0) var bus_stop_zone_length: float = 20.0
@export_range(10.0, 200.0, 1.0) var stencil_period_z: float = 45.0
@export_range(0.1, 1.0, 0.05) var stencil_flatten: float = 0.45
@export_range(100.0, 1200.0, 10.0) var building_height_px: float = 420.0
@export_range(2.0, 60.0, 1.0) var building_gap_z: float = 14.0
@export_range(0.0, 600.0, 10.0) var building_offset_px: float = 120.0
@export_range(0.0, 400.0, 5.0) var bus_overlay_height_px: float = 180.0

@export_group("Bus")
@export_range(5.0, 60.0, 0.5) var cruise_speed_start: float = 14.0
@export_range(5.0, 80.0, 0.5) var cruise_speed_end: float = 26.0
@export_range(1.0, 60.0, 1.0) var brake_decel: float = 16.0
@export_range(1.0, 40.0, 1.0) var accel: float = 6.0
@export_range(100.0, 2000.0, 10.0) var lane_change_speed: float = 520.0
@export_range(10.0, 90.0, 1.0) var swerve_trigger_z: float = 38.0
@export_range(5.0, 80.0, 1.0) var follow_trigger_z: float = 32.0
@export_range(2.0, 60.0, 1.0) var merge_trigger_z: float = 24.0

@export_group("Traffic")
@export_range(0.3, 5.0, 0.1) var spawn_interval_start: float = 1.5
@export_range(0.2, 5.0, 0.1) var spawn_interval_end: float = 0.9
@export_range(0.1, 1.0, 0.05) var moving_speed_min_ratio: float = 0.45
@export_range(0.1, 1.0, 0.05) var moving_speed_max_ratio: float = 0.65
@export_range(20.0, 600.0, 10.0) var merge_lateral_speed: float = 140.0
@export_range(1.0, 30.0, 0.5) var double_park_adjacent_z: float = 9.0
@export_range(20.0, 400.0, 5.0) var double_park_min_x_gap: float = 100.0
@export_range(0.0, 200.0, 5.0) var bike_intrusion_min_px: float = 60.0
@export_range(2.0, 60.0, 1.0) var spawn_column_gap_curb_z: float = 14.0
@export_range(2.0, 80.0, 1.0) var spawn_column_gap_bus_z: float = 30.0
@export_range(0.0, 1.0, 0.05) var honk_probability: float = 0.3
@export_range(0.0, 10.0, 0.01) var situation_weight_moving_traffic: float = 0.18
@export_range(0.0, 10.0, 0.01) var situation_weight_legal_curb: float = 0.20
@export_range(0.0, 10.0, 0.01) var situation_weight_sloppy_parker: float = 0.10
@export_range(0.0, 10.0, 0.01) var situation_weight_bike_lane_violator: float = 0.14
@export_range(0.0, 10.0, 0.01) var situation_weight_bus_lane_blocker: float = 0.10
@export_range(0.0, 10.0, 0.01) var situation_weight_double_park_pair: float = 0.13
@export_range(0.0, 10.0, 0.01) var situation_weight_bus_stop_zone: float = 0.15

@export_group("Capture")
@export_range(5.0, 100.0, 1.0) var plate_readable_z: float = 30.0
@export_range(0.0, 2.0, 0.05) var capture_cooldown_sec: float = 0.35
@export var box_size: Vector2 = Vector2(140.0, 90.0)
@export_range(100.0, 1500.0, 10.0) var box_speed_keyboard: float = 420.0
@export_range(100.0, 1500.0, 10.0) var box_speed_touch: float = 420.0
@export_range(100.0, 1500.0, 10.0) var box_speed_gamepad: float = 420.0

@export_group("Scoring")
@export_range(0, 1000, 5) var points_correct: int = 100
@export_range(-500, 0, 5) var points_wrong: int = -25
@export_range(-500, 0, 5) var points_missed: int = -10

@export_group("Vehicles")
@export_range(0.0, 1.0, 0.05) var light_intensity_bright: float = 1.0
@export_range(0.0, 1.0, 0.05) var light_intensity_dim: float = 0.35
@export_range(0.0, 1.0, 0.05) var light_intensity_off: float = 0.0
@export var light_glow_color: Color = Color(1.0, 0.15, 0.1)
@export_range(40.0, 300.0, 1.0) var rear_width_px: float = 140.0

@export_group("Leaderboard")
@export_range(5, 100, 5) var top_count: int = 20
@export_range(1.0, 15.0, 0.5) var request_timeout_sec: float = 5.0
@export var default_player_name: String = "Rookie"

@export_group("Audio")
@export_range(0.0, 1.0, 0.05) var volume_master_default: float = 1.0
@export_range(0.0, 1.0, 0.05) var volume_music_default: float = 0.7
@export_range(0.0, 1.0, 0.05) var volume_sfx_default: float = 1.0

@export_group("Debug")
@export_range(0.0, 400.0, 10.0) var touch_gutter_min_px: float = 120.0
@export var show_lane_overlay: bool = false
@export var show_plate_rects: bool = false


## Centre of the bus/travel lane in road space.
func lane_bus_center() -> float:
	return (lane_bus_left + lane_bus_right) * 0.5


## Centre of the passing lane in road space.
func lane_passing_center() -> float:
	return (lane_road_left + lane_bus_left) * 0.5


func lane_bike_center() -> float:
	return (lane_bus_right + lane_bike_right) * 0.5


func situation_weights() -> Dictionary:
	return {
		"moving_traffic": situation_weight_moving_traffic,
		"legal_curb": situation_weight_legal_curb,
		"sloppy_parker": situation_weight_sloppy_parker,
		"bike_lane_violator": situation_weight_bike_lane_violator,
		"bus_lane_blocker": situation_weight_bus_lane_blocker,
		"double_park_pair": situation_weight_double_park_pair,
		"bus_stop_zone": situation_weight_bus_stop_zone,
	}


## Returns a list of human-readable problems; empty when the config is consistent.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if cruise_speed_start > cruise_speed_end:
		problems.append("cruise_speed_start (%.1f) must be <= cruise_speed_end (%.1f)"
				% [cruise_speed_start, cruise_speed_end])
	if spawn_interval_end > spawn_interval_start:
		problems.append("spawn_interval_end (%.2f) must be <= spawn_interval_start (%.2f)"
				% [spawn_interval_end, spawn_interval_start])
	if not (swerve_trigger_z > follow_trigger_z and follow_trigger_z > merge_trigger_z):
		problems.append("bus triggers must satisfy swerve (%.0f) > follow (%.0f) > merge (%.0f)"
				% [swerve_trigger_z, follow_trigger_z, merge_trigger_z])
	if not (lane_road_left < lane_bus_left and lane_bus_left < lane_bus_right
			and lane_bus_right < lane_bike_right and lane_bike_right < lane_curb_x):
		problems.append("lane edges must increase left to right")
	if not (road_edge_left_x < lane_road_left and lane_curb_x < road_edge_right_x):
		problems.append("road edges must lie outside the lanes")
	if moving_speed_min_ratio > moving_speed_max_ratio:
		problems.append("moving_speed_min_ratio must be <= moving_speed_max_ratio")
	var total := 0.0
	for weight: float in situation_weights().values():
		total += weight
	if total <= 0.0:
		problems.append("situation weights must sum to more than zero")
	var name_pattern := RegEx.create_from_string("^[A-Za-z]{1,12}$")
	if name_pattern.search(default_player_name) == null:
		problems.append("default_player_name must be 1-12 letters")
	return problems

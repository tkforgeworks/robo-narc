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
@export_range(-300.0, 300.0, 1.0) var horizon_y: float = 0.0
@export_range(600.0, 900.0, 1.0) var bus_screen_y: float = 760.0
@export_range(300.0, 900.0, 1.0) var vanishing_point_x: float = 553.0
@export_range(5.0, 40.0, 0.5) var perspective_c: float = 15.0
@export_range(50.0, 200.0, 5.0) var z_max: float = 100.0
@export_range(0.0, 5.0, 0.5) var pass_z: float = 1.0
## Lane changes: 0 shifts near things more than far ones (true perspective, the
## vanishing point stays put); 1 pans the whole view by the same amount so flat
## roadside art never distorts against the road.
@export_range(0.0, 1.0, 0.05) var lane_change_pan: float = 0.0
@export_range(-1500.0, 0.0, 5.0) var road_edge_left_x: float = -538.0
@export_range(-800.0, 0.0, 1.0) var lane_road_left: float = -245.0
@export_range(0.0, 600.0, 1.0) var lane_bus_left: float = 148.0
@export_range(0.0, 800.0, 1.0) var lane_bus_right: float = 542.0
@export_range(0.0, 900.0, 1.0) var lane_bike_right: float = 700.0
@export_range(0.0, 1200.0, 1.0) var lane_curb_x: float = 961.0
@export_range(800.0, 3000.0, 5.0) var road_edge_right_x: float = 1576.0
@export_range(5.0, 60.0, 1.0) var bus_stop_zone_length: float = 20.0
## Shelter sprite height at z = 0 (scaled down with distance like buildings).
@export_range(50.0, 800.0, 10.0) var bus_stop_height_px: float = 240.0
## Shelter anchor offset from the curb line in road px (positive = onto the sidewalk).
@export_range(-200.0, 400.0, 5.0) var bus_stop_offset_px: float = 70.0
## Extra lean of the shelter's ground line, on top of the automatic aim at the vanishing point.
@export_range(-30.0, 30.0, 0.5) var bus_stop_lean_deg: float = 0.0
## Yellow hazard stripes over the zone's curb-lane rectangle (0 hides them).
@export_range(0.0, 1.0, 0.05) var bus_stop_marking_opacity: float = 0.75
## Road-tile rows per z unit: how long one repeat of road-tile.png is on the road.
@export_range(5.0, 200.0, 1.0) var road_tile_px_per_z: float = 35.0
@export_range(100.0, 1200.0, 10.0) var building_height_px: float = 700.0
@export_range(0.0, 60.0, 1.0) var building_gap_z: float = 2.0
@export_range(20.0, 600.0, 10.0) var building_footprint_px_per_z: float = 100.0
@export_range(0.0, 60.0, 1.0) var building_reveal_z: float = 15.0
@export_range(-300.0, 600.0, 10.0) var building_offset_px: float = 0.0

@export_group("Bus")
@export_range(5.0, 60.0, 0.5) var cruise_speed_start: float = 11.0
@export_range(5.0, 80.0, 0.5) var cruise_speed_end: float = 32.0
@export_range(1.0, 60.0, 1.0) var brake_decel: float = 6.0
@export_range(1.0, 40.0, 1.0) var accel: float = 4.0
@export_range(100.0, 2000.0, 10.0) var lane_change_speed: float = 320.0
@export_range(10.0, 90.0, 1.0) var swerve_trigger_z: float = 36.0
@export_range(5.0, 80.0, 1.0) var follow_trigger_z: float = 28.0
@export_range(2.0, 60.0, 1.0) var merge_trigger_z: float = 26.0

@export_group("Traffic")
@export_range(0.3, 5.0, 0.1) var spawn_interval_start: float = 1.5
@export_range(0.2, 5.0, 0.1) var spawn_interval_end: float = 0.9
@export_range(0.1, 1.0, 0.05) var moving_speed_min_ratio: float = 0.3
@export_range(0.1, 1.0, 0.05) var moving_speed_max_ratio: float = 0.7
@export_range(20.0, 600.0, 10.0) var merge_lateral_speed: float = 120.0
## Share of a body's width inside a lane for it to count as "in" that lane.
@export_range(0.1, 1.0, 0.05) var lane_membership_ratio: float = 0.85
## Share of a body's width over the bike lane that makes a parker a violator.
@export_range(0.05, 1.0, 0.05) var bike_intrusion_ratio: float = 0.2
@export_range(2.0, 60.0, 1.0) var spawn_column_gap_curb_z: float = 16.0
@export_range(2.0, 80.0, 1.0) var spawn_column_gap_bus_z: float = 32.0
@export_range(0.0, 1.0, 0.05) var honk_probability: float = 0.4
@export_range(0.0, 10.0, 0.01) var situation_weight_moving_traffic: float = 0.06
@export_range(0.0, 10.0, 0.01) var situation_weight_legal_curb: float = 0.14
@export_range(0.0, 10.0, 0.01) var situation_weight_sloppy_parker: float = 0.07
@export_range(0.0, 10.0, 0.01) var situation_weight_bike_lane_violator: float = 0.19
@export_range(0.0, 10.0, 0.01) var situation_weight_bus_lane_blocker: float = 0.11
@export_range(0.0, 10.0, 0.01) var situation_weight_double_park_pair: float = 0.17
@export_range(0.0, 10.0, 0.01) var situation_weight_bus_stop_zone: float = 0.16

@export_group("Capture")
@export_range(5.0, 100.0, 1.0) var plate_readable_z: float = 38.0
@export_range(0.0, 2.0, 0.05) var capture_cooldown_sec: float = 0.15
## Share of the plate that must be inside the box (1.0 = fully framed).
@export_range(0.5, 1.0, 0.05) var capture_overlap_ratio: float = 1.0
@export var box_size: Vector2 = Vector2(150.0, 110.0)
@export_range(100.0, 1500.0, 10.0) var box_speed_keyboard: float = 520.0
@export_range(100.0, 1500.0, 10.0) var box_speed_touch: float = 440.0
@export_range(100.0, 1500.0, 10.0) var box_speed_gamepad: float = 440.0

@export_group("Scoring")
@export_range(0, 1000, 5) var points_correct: int = 150
@export_range(-500, 0, 5) var points_wrong: int = -50
@export_range(-500, 0, 5) var points_missed: int = -10

@export_group("Vehicles")
@export_range(0.0, 2.0, 0.05) var light_intensity_bright: float = 1.25
@export_range(0.0, 1.0, 0.05) var light_intensity_dim: float = 0.55
@export_range(0.0, 1.0, 0.05) var light_intensity_off: float = 0.0
@export var light_glow_color: Color = Color(1.0, 0.15, 0.1)

@export_group("Leaderboard")
@export_range(5, 100, 5) var top_count: int = 15
@export_range(1.0, 15.0, 0.5) var request_timeout_sec: float = 5.0
@export_range(5.0, 300.0, 5.0) var sync_retry_sec: float = 30.0

@export_group("Audio")
@export_range(0.0, 1.0, 0.05) var volume_master_default: float = 1.0
@export_range(0.0, 1.0, 0.05) var volume_music_default: float = 0.7
@export_range(0.0, 1.0, 0.05) var volume_sfx_default: float = 1.0

@export_group("Debug")
@export_range(0.0, 400.0, 10.0) var touch_gutter_min_px: float = 120.0
@export var show_lane_overlay: bool = false
## Outline every detection area (lanes, zones, bodies, plates, probes, capture box).
@export var show_collision_shapes: bool = false
## Hide the art so only the areas and HUD remain.
@export var hide_sprites: bool = false

## One line per tunable for the debug menu. Keep them short; a missing key
## just shows no description.
const DESCRIPTIONS: Dictionary = {
	# Shift
	"shift_length_sec": "How long one shift lasts.",
	"count_in_sec": "3-2-1 before the first shift starts.",
	"resume_count_in_sec": "Count-in after a pause or focus loss (0 = none).",
	"results_idle_timeout_sec": "Results screen returns to the title after this long untouched.",
	"feedback_time_sec": "How long a score banner stays up.",
	# Road
	"horizon_y": "Screen y of the vanishing point (road converges here).",
	"bus_screen_y": "Screen y where z = 0 sits; below 720 puts the bus's own row off-screen.",
	"vanishing_point_x": "Screen x of the vanishing point.",
	"perspective_c": "Foreshortening strength: scale = C / (z + C). Lower = steeper perspective.",
	"z_max": "Distance vehicles and buildings spawn at (the far end of play).",
	"pass_z": "A vehicle is judged missed once it is this far behind the bus line.",
	"lane_change_pan": "0 = far things barely move on a swerve (true perspective); 1 = the whole view pans.",
	"road_edge_left_x": "Road x of the left road edge (median side).",
	"lane_road_left": "Road x of the passing lane's left edge.",
	"lane_bus_left": "Road x of the bus lane's left edge (the dashed line).",
	"lane_bus_right": "Road x of the bus lane's right edge = bike lane's left edge.",
	"lane_bike_right": "Road x of the bike lane's right edge = parking lane's left edge.",
	"lane_curb_x": "Road x of the curb line (parking lane's right edge).",
	"road_edge_right_x": "Road x where the sidewalk ends and buildings stand.",
	"bus_stop_zone_length": "Length of a bus stop zone along the road (z units).",
	"bus_stop_height_px": "Shelter sprite height at z = 0; scales down with distance.",
	"bus_stop_offset_px": "Shelter anchor offset from the curb line (positive = onto the sidewalk).",
	"bus_stop_lean_deg": "Extra lean of the shelter's ground line beyond the automatic aim.",
	"bus_stop_marking_opacity": "Yellow hazard stripes over the zone (0 hides them).",
	"road_tile_px_per_z": "Road-tile rows per z unit: stretches dash and stencil spacing together.",
	"building_height_px": "Height at z = 0 of the tallest (1000 px) building art; every building shares the scale.",
	"building_gap_z": "Empty road between one building's footprint and the next (z units).",
	"building_footprint_px_per_z": "Building width (px at z = 0) per z unit of road it takes up; higher packs the skyline tighter.",
	"building_reveal_z": "Distance over which a new building grows out of the horizon to full size (0 = pop in).",
	"building_offset_px": "Distance of the road-facing corner beyond the road edge (negative = onto it).",
	# Bus
	"cruise_speed_start": "Road speed at the start of the shift (z units per second).",
	"cruise_speed_end": "Road speed at the end of the shift; ramps between the two.",
	"brake_decel": "How hard the bus brakes for a blocker (z units per second squared).",
	"accel": "How fast the bus gets back up to cruise.",
	"lane_change_speed": "Sideways speed of a swerve (road px per second).",
	"swerve_trigger_z": "A stopped car in the bus lane closer than this triggers a swerve.",
	"follow_trigger_z": "A moving car closer than this makes the bus match its speed.",
	"merge_trigger_z": "With the lane clear beyond this distance the bus merges back.",
	# Traffic
	"spawn_interval_start": "Seconds between spawns at the start of the shift.",
	"spawn_interval_end": "Seconds between spawns at the end of the shift.",
	"moving_speed_min_ratio": "Slowest moving traffic, as a share of the bus's speed.",
	"moving_speed_max_ratio": "Fastest moving traffic, as a share of the bus's speed.",
	"merge_lateral_speed": "Sideways speed of a merging car (road px per second).",
	"lane_membership_ratio": "Share of a car's width inside a lane to count as IN it. Also decides 'at the curb' (parking lane), which blocks the bike-lane rule.",
	"bike_intrusion_ratio": "Share of a stopped car's width over the bike lane that makes it a BIKE LANE violator (only if not at the curb).",
	"spawn_column_gap_curb_z": "Minimum spacing between curb-side spawns (z units).",
	"spawn_column_gap_bus_z": "Minimum spacing between bus-lane spawns (z units).",
	"honk_probability": "Chance a blocked situation plays a honk.",
	"situation_weight_moving_traffic": "Relative odds of spawning plain moving traffic.",
	"situation_weight_legal_curb": "Relative odds of a legally parked car.",
	"situation_weight_sloppy_parker": "Relative odds of a car parked partly over the bike lane.",
	"situation_weight_bike_lane_violator": "Relative odds of a car stopped in the bike lane.",
	"situation_weight_bus_lane_blocker": "Relative odds of a car stopped in the bus lane.",
	"situation_weight_double_park_pair": "Relative odds of a double-parked pair.",
	"situation_weight_bus_stop_zone": "Relative odds of a bus stop zone with a car in it.",
	# Capture
	"plate_readable_z": "Plates farther than this are TOO FAR to capture.",
	"capture_cooldown_sec": "Minimum time between two capture presses.",
	"capture_overlap_ratio": "Share of the plate that must be inside the box (1 = fully framed).",
	"box_size": "Capture box size in screen px.",
	"box_speed_keyboard": "Box speed with keys (px per second).",
	"box_speed_touch": "Box speed with the touch stick (px per second).",
	"box_speed_gamepad": "Box speed with a gamepad (px per second).",
	# Scoring
	"points_correct": "Points for capturing a violator.",
	"points_wrong": "Points for capturing an innocent driver.",
	"points_missed": "Points when a violator passes uncaptured.",
	# Vehicles
	"light_intensity_bright": "Brake-light brightness while stopped in the road.",
	"light_intensity_dim": "Light brightness while moving.",
	"light_intensity_off": "Light brightness while parked.",
	"light_glow_color": "Tint of the brake-light glow.",
	# Leaderboard
	"top_count": "Rows on the leaderboard (title and results).",
	"request_timeout_sec": "Give up on the shared board after this long.",
	"sync_retry_sec": "Wait this long before resending shifts the board did not take.",
	# Audio
	"volume_master_default": "Master volume for a fresh install.",
	"volume_music_default": "Music volume for a fresh install.",
	"volume_sfx_default": "SFX volume for a fresh install.",
	# Debug
	"touch_gutter_min_px": "Narrowest side gutter that still shows touch controls.",
	"show_lane_overlay": "Draw the lane edges and horizon over the road.",
	"show_collision_shapes": "Outline every detection area (lanes, zones, bodies, plates, probes, box).",
	"hide_sprites": "Hide the art so only the areas and HUD remain.",
}


## Short description for the debug menu, or empty when none is written.
static func describe(property_name: String) -> String:
	return str(DESCRIPTIONS.get(property_name, ""))


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
	return problems

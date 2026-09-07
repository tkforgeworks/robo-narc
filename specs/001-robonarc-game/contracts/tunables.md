# Contract: Tunables (`TuningConfig`)

Every field is an `@export` on `TuningConfig` (`src/core/tuning/tuning_config.gd`),
lives in `data/core/tuning_defaults.tres`, and appears in the debug menu
automatically. Adding a field here is the whole change; the menu, reset, and
overrides pick it up. Defaults come from the GDD baseline table with the
clarified scoring changes.

| Group | Property | Type | Default | Range / step | Used by |
|-------|----------|------|---------|--------------|---------|
| Shift | shift_length_sec | float | 90 | 10..600 / 5 | ShiftClock |
| Shift | count_in_sec | float | 3 | 1..5 / 1 | CountIn |
| Shift | resume_count_in_sec | float | 3 | 0..5 / 1 | CountIn |
| Shift | results_idle_timeout_sec | float | 60 | 5..600 / 5 | IdleTimeout |
| Shift | feedback_time_sec | float | 1.4 | 0.3..4 / 0.1 | FeedbackBanner |
| Road | horizon_y | float | -5 | -300..300 / 1 | Perspective (calibrated to backdrop) |
| Road | bus_screen_y | float | 760 | 600..900 / 1 | Perspective |
| Road | vanishing_point_x | float | 553 | 300..900 / 1 | Perspective (calibrated) |
| Road | perspective_c | float | 15 | 5..40 / 0.5 | Perspective |
| Road | z_max | float | 100 | 50..200 / 5 | Perspective, Spawner |
| Road | pass_z | float | 1 | 0..5 / 0.5 | MissJudge |
| Road | backdrop_shear_factor | float | 1.0 | 0..1.5 / 0.05 | RoadView (1.0 = exact perspective shear on swerve) |
| Road | road_edge_left_x | float | -538 | -1500..0 / 5 | RoadView, BuildingStrip |
| Road | lane_road_left | float | -245 | -800..0 / 1 | RoadGeometry |
| Road | lane_bus_left | float | 148 | 0..600 / 1 | RoadGeometry |
| Road | lane_bus_right | float | 542 | 0..800 / 1 | RoadGeometry |
| Road | lane_bike_right | float | 700 | 0..900 / 1 | RoadGeometry |
| Road | lane_curb_x | float | 961 | 0..1200 / 1 | RoadGeometry |
| Road | road_edge_right_x | float | 1576 | 800..3000 / 5 | BuildingStrip |
| Road | curb_threshold_x | float | 720 | 0..1200 / 1 | ViolationRules |
| Road | bus_stop_zone_length | float | 20 | 5..60 / 1 | Spawner |
| Road | stencil_period_z | float | 45 | 10..200 / 1 | RoadStencil |
| Road | stencil_flatten | float | 0.45 | 0.1..1 / 0.05 | RoadStencil |
| Road | building_height_px | float | 420 | 100..1200 / 10 | BuildingStrip |
| Road | building_gap_z | float | 14 | 2..60 / 1 | BuildingStrip |
| Road | building_offset_px | float | 120 | 0..600 / 10 | BuildingStrip |
| Road | bus_overlay_height_px | float | 180 | 0..400 / 5 | BusOverlay |
| Bus | cruise_speed_start | float | 14 | 5..60 / 0.5 | DifficultyRamp |
| Bus | cruise_speed_end | float | 26 | 5..80 / 0.5 | DifficultyRamp |
| Bus | brake_decel | float | 16 | 1..60 / 1 | BusDriver |
| Bus | accel | float | 6 | 1..40 / 1 | BusDriver |
| Bus | lane_change_speed | float | 520 | 100..2000 / 10 | BusDriver |
| Bus | swerve_trigger_z | float | 38 | 10..90 / 1 | BusDriver |
| Bus | follow_trigger_z | float | 32 | 5..80 / 1 | BusDriver |
| Bus | merge_trigger_z | float | 24 | 2..60 / 1 | BusDriver |
| Traffic | spawn_interval_start | float | 1.5 | 0.3..5 / 0.1 | DifficultyRamp |
| Traffic | spawn_interval_end | float | 0.9 | 0.2..5 / 0.1 | DifficultyRamp |
| Traffic | moving_speed_min_ratio | float | 0.45 | 0.1..1 / 0.05 | Spawner |
| Traffic | moving_speed_max_ratio | float | 0.65 | 0.1..1 / 0.05 | Spawner |
| Traffic | merge_lateral_speed | float | 140 | 20..600 / 10 | Vehicle |
| Traffic | double_park_adjacent_z | float | 9 | 1..30 / 0.5 | ViolationRules |
| Traffic | double_park_min_x_gap | float | 100 | 20..400 / 5 | ViolationRules |
| Traffic | bike_intrusion_min_px | float | 60 | 0..200 / 5 | ViolationRules |
| Traffic | spawn_column_gap_curb_z | float | 14 | 2..60 / 1 | Spawner |
| Traffic | spawn_column_gap_bus_z | float | 30 | 2..80 / 1 | Spawner |
| Traffic | honk_probability | float | 0.3 | 0..1 / 0.05 | HonkScheduler |
| Traffic | situation_weight_* (7) | float | GDD §14 values | 0..10 / 0.01 | SituationTable |
| Capture | plate_readable_z | float | 30 | 5..100 / 1 | CaptureJudge |
| Capture | capture_cooldown_sec | float | 0.35 | 0..2 / 0.05 | CaptureBox |
| Capture | box_size | Vector2 | (140, 90) | 40..400 each | CaptureBox |
| Capture | box_speed_keyboard | float | 420 | 100..1500 / 10 | CaptureBox |
| Capture | box_speed_touch | float | 420 | 100..1500 / 10 | CaptureBox |
| Capture | box_speed_gamepad | float | 420 | 100..1500 / 10 | CaptureBox |
| Scoring | points_correct | int | 100 | 0..1000 / 5 | ScoreKeeper |
| Scoring | points_wrong | int | -25 | -500..0 / 5 | ScoreKeeper |
| Scoring | points_missed | int | -10 | -500..0 / 5 | ScoreKeeper |
| Vehicles | light_intensity_bright | float | 1.0 | 0..1 / 0.05 | VehicleLights |
| Vehicles | light_intensity_dim | float | 0.35 | 0..1 / 0.05 | VehicleLights |
| Vehicles | light_intensity_off | float | 0.0 | 0..1 / 0.05 | VehicleLights |
| Vehicles | light_glow_color | Color | (1, 0.15, 0.1) | color | VehicleLights |
| Vehicles | rear_width_px | float | 140 | 40..300 / 1 | Vehicle (default; per-style value wins) |
| Leaderboard | top_count | int | 20 | 5..100 / 5 | LeaderboardPanel |
| Leaderboard | request_timeout_sec | float | 5 | 1..15 / 0.5 | LeaderboardClient |
| Leaderboard | default_player_name | String | "Rookie" | letters, <= 12 | NameEntry |
| Audio | volume_master_default | float | 1.0 | 0..1 | AudioMixer |
| Audio | volume_music_default | float | 0.7 | 0..1 | AudioMixer |
| Audio | volume_sfx_default | float | 1.0 | 0..1 | AudioMixer |
| Debug | touch_gutter_min_px | float | 120 | 0..400 / 10 | TouchControls |
| Debug | show_lane_overlay | bool | false | | RoadView (debug builds) |
| Debug | show_plate_rects | bool | false | | VehicleLayer (debug builds) |

Per-body-style tunables (`VehicleStyle`, enumerated under a "Style: <key>" section):
`plate_rect`, `left_light_rect`, `right_light_rect` as normalized `Rect2`, each
component 0..1 / 0.005, and `rear_width_px`. Saved overrides for styles are applied
when the registry registers as the style provider (shift start).

Lane values were calibrated 2026-09-07 against `assets/road/backdrop.png` (vanishing
point at image x 1217, y 0; edges measured at three rows and projected to the bus
line). Tests that need the prototype geometry set it explicitly.

## Debug menu behavior

- Control mapping by type: `float`/`int` with range hint → `SpinBox` (or `HSlider`
  when the hint has `slider`); `bool` → `CheckBox`; `Vector2`/`Rect2` → grouped
  spin boxes per component; `Color` → `ColorPickerButton`; `String` → `LineEdit`.
- Every change calls `Tuning.set_value(name, value)` which emits `changed(name)`;
  nodes that cache a value re-read on `changed`.
- Buttons: **Reset to defaults**, **Save as overrides** (debug builds; writes
  `user://tuning_overrides.cfg`), **Clear local scores**, **Close**.
- Opening sets `get_tree().paused = true`; the menu runs in `PROCESS_MODE_ALWAYS`.
- Triggers: `debug_menu` action (F1) on desktop; three-finger tap on touch; a
  `DEBUG` button on the title screen. All exist only when `OS.is_debug_build()`.
- The Audio group holds **defaults** only; live volume is owned by `SettingsStore`
  and the Settings screen. The debug menu shows a separate "Live volume" section with
  three sliders bound to `AudioMixer` and `SettingsStore` so an operator can adjust
  volume mid-play (spec FR-047).
- Debug builds show a frame-time readout on the HUD so SC-006 can be checked live.

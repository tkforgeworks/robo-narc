# Data Model: RoboNarc Convention Game

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

Types are GDScript classes. `Resource` types are editor-editable data; value objects
are `RefCounted`; nodes hold runtime state. Field names are the intended property
names. Ranges in brackets are validation rules enforced by `@export_range` or by
the class's `validate()`.

## Resources (editor data)

### TuningConfig (`src/core/tuning/tuning_config.gd`, extends Resource)

Every feel value in the game. Full field list with defaults and ranges is the
contract in [contracts/tunables.md](contracts/tunables.md). Groups: Shift, Road,
Bus, Traffic, Capture, Scoring, Vehicles, Leaderboard, Audio, Debug. Invariants:
`cruise_speed_start <= cruise_speed_end`, `spawn_interval_end <= spawn_interval_start`,
`swerve_trigger_z > follow_trigger_z > merge_trigger_z`.

### VehicleStyle (`src/game/vehicles/vehicle_style.gd`, extends Resource)

| Field | Type | Rule |
|-------|------|------|
| key | String | folder name, `^[a-z0-9_]+$`, unique |
| plate_rect | Rect2 | normalized to sprite (0..1), tunable |
| left_light_rect | Rect2 | normalized, tunable |
| right_light_rect | Rect2 | normalized, tunable |
| rear_width_px | float | width at full scale, default 90 |
| textures | Array[Texture2D] | filled at runtime by VehicleRegistry, one per color |

### SituationTable (`src/game/traffic/situation_table.gd`, extends RefCounted)

Not a resource: weights are the seven `situation_weight_*` tunables on
`TuningConfig` (single source of truth), read on every `pick(rng)`. The class holds
only the `Situation.Kind` enum and per-kind `min_z_gap` constants. Kinds:
MOVING_TRAFFIC, LEGAL_CURB, SLOPPY_PARKER, BIKE_LANE_VIOLATOR, BUS_LANE_BLOCKER,
DOUBLE_PARK_PAIR, BUS_STOP_ZONE. Rule: weights sum > 0, else `pick` returns
MOVING_TRAFFIC and logs a warning.

## Value objects (RefCounted, immutable after construction)

### Verdict (`src/game/judgment/verdict.gd`)

| Field | Type |
|-------|------|
| kind | enum Kind { INNOCENT, BUS_LANE, DOUBLE_PARKING, BIKE_LANE, BUS_STOP } |
| label | String, display text ("BUS LANE") |
| is_violation | bool (kind != INNOCENT) |

### CaptureOutcome (`src/game/judgment/capture_judge.gd`, inner or sibling class)

| Field | Type |
|-------|------|
| kind | enum { CORRECT, WRONG, TOO_FAR, EMPTY, ALREADY_CAPTURED } |
| vehicle | Vehicle or null |
| verdict | Verdict or null |
| points | int |
| feedback | String |

### ShiftResult (`src/game/shift/shift_result.gd`)

| Field | Type | Rule |
|-------|------|------|
| score | int | may be negative |
| correct | int | >= 0 |
| wrong | int | >= 0 |
| missed | int | >= 0 |
| empty | int | >= 0 |
| duration_sec | float | tuned shift length at start |
| played_at | int | unix seconds |
| player_name | String | set by NameEntry, "" until then |

### ScoreRecord (`src/game/services/score_store.gd`)

`ShiftResult` plus `submitted: bool` and `remote_rank: int` (-1 unknown). Stored as
JSON lines in `user://scores.json`; newest first; capped at 200 records.

### LeaderboardEntry (`src/game/services/leaderboard_client.gd`)

| Field | Type |
|-------|------|
| rank | int (1-based) |
| name | String (display; empty or overlong values replaced by placeholder) |
| score | int |

### NameValidator.Result

`ok: bool`, `reason: enum { OK, EMPTY, TOO_LONG, INVALID_CHARS, PROFANE }`,
`message: String`.

## Runtime node state (selected)

### Vehicle (`src/game/vehicles/vehicle.gd`, Node2D)

| Field | Type | Notes |
|-------|------|-------|
| road_x | float | lateral, road space px at full scale |
| z | float | distance ahead; spawn at Z_MAX, passes at <= pass_z |
| motion | enum Motion { MOVING, STOPPED_IN_ROAD, CURB_PARKED } | drives lights and rules |
| own_speed | float | 0 when not MOVING |
| style | VehicleStyle | |
| color_index | int | |
| plate_text | String | 6 chars, decorative |
| captured | bool | |
| target_road_x | float | merge destination |

Motion state machine:

```text
MOVING ──(merge_to)──> MOVING (lateral drift)      # never becomes parked
STOPPED_IN_ROAD / CURB_PARKED: fixed for the vehicle's lifetime
```

Lifecycle: `spawned → active → passed (judged for miss) → freed`. `MissJudge`
evaluates every passed vehicle before `VehicleLayer` frees any of them (two-phase).

### ShiftClock (`src/game/shift/shift_clock.gd`, Node)

| Field | Type |
|-------|------|
| phase | enum Phase { IDLE, COUNT_IN, RUNNING, RESUME_COUNT_IN, ENDED } |
| time_left | float |
| progress | float 0..1 (elapsed / duration) |

Transitions:

```text
IDLE ──start()──> COUNT_IN ──(count done)──> RUNNING ──(time_left<=0)──> ENDED
RUNNING ──focus lost──> (tree paused) ──focus back──> RESUME_COUNT_IN ──> RUNNING
COUNT_IN ──focus lost/back──> COUNT_IN (restarts)
```

Signals: `phase_changed(phase)`, `tick(time_left, progress)`, `ended`.

### BusDriver (`src/game/traffic/bus_driver.gd`, Node)

| Field | Type |
|-------|------|
| camera_x | float (road space) |
| road_speed | float (actual, after braking) |
| lane_target | enum { BUS_LANE, PASSING_LANE } |

Signals: `swerve_started`, `swerve_ended`, `speed_changed(road_speed)`. Inputs each
frame: cruise speed from `DifficultyRamp`, vehicle list from `VehicleLayer`.

### ScoreKeeper (`src/game/shift/score_keeper.gd`, Node)

Holds a mutable `ShiftResult` under construction; `apply(outcome: CaptureOutcome)`
and `apply_miss(verdict)`; emits `score_changed(score, delta, feedback)`;
`finish() -> ShiftResult`.

### InputSource (`src/core/input/input_source.gd`, Node)

`source: enum Source { KEYBOARD, TOUCH, GAMEPAD }`, signal `source_changed(source)`.

### Tuning (autoload, `src/core/tuning/tuning.gd`)

`config: TuningConfig`, signals `changed(property_name)`, `reset`, and
`style_changed(style_key, property_name)`. Methods: `load_config(cfg)`,
`set_value(name, value)`, `reset_to_defaults()`, `save_overrides()` (debug builds
only), `register_style_provider(provider)` where the provider exposes
`get_styles() -> Array[Resource]`, and `set_style_value(style_key, property_name,
value)` which writes to the matching `VehicleStyle` and emits `style_changed`.

## Persistence formats

| File | Format | Contents |
|------|--------|----------|
| `user://settings.cfg` | ConfigFile | `[audio] master, music, sfx` (0..1 linear); `[player] last_name` |
| `user://tuning_overrides.cfg` | ConfigFile | `[tuning] <property>=<value>`, `[style.<key>] plate_rect, left_light_rect, right_light_rect`; debug builds only |
| `user://scores.json` | JSON array | ScoreRecord objects, newest first, max 200 |

## Remote schema

See [contracts/leaderboard-api.md](contracts/leaderboard-api.md) for the `scores`
table and RPC definitions.

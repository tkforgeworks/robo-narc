# Tasks: RoboNarc Convention Game

**Input**: Design documents from `/specs/001-robonarc-game/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: The constitution requires unit tests for pure-logic classes and live
tunables for every feature. Test tasks are therefore bundled into the implementation
task of each pure-logic class (same task, `tests/` path named) rather than listed
separately, to keep tasks few and shippable.

**Organization**: Tasks are grouped by user story. Each story phase ends in a
playable, web-exportable state. Task sizes are deliberately coarse: one task is one
cohesive class or scene with its test, not a single function.

**Revision**: 2026-09-07 after `/speckit-analyze`: `VehicleStyle`, `ScoreStore`, and
`RankCalculator` moved into US1; screen navigation by signal; `Main.initial_screen`;
situation weights single-sourced on `TuningConfig`; bundle-size CI check; debug menu
live volumes and frame-time readout; placeholders allowed in release with a startup
log.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1..US7)
- File paths are repository-relative; `[core]` in a path comment means template layer

## Path Conventions

Single Godot project at the repository root. Layout per plan.md: `src/core/` (template
layer), `src/game/` (RoboNarc), `src/screens/`, `scenes/{core,game,screens}/`,
`data/{core,game}/`, `assets/`, `tests/{core,game}/`, `addons/gut/`,
`.github/workflows/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: A Godot 4.6.2 project that opens cleanly, exports to web, runs an empty
test suite in CI, and holds the premade art under the agreed folder layout.

- [ ] T001 Create `project.godot` at repo root: name RoboNarc, `config/features=("4.6","GL Compatibility")`, `renderer/rendering_method=gl_compatibility` (+ `.mobile`), viewport 1280×720, `stretch/mode=canvas_items`, `stretch/aspect=expand`, `handheld/orientation=sensor_landscape`, `emulate_mouse_from_touch=false`, `emulate_touch_from_mouse=false`, main scene `res://scenes/core/main.tscn`; no Jolt or D3D12 settings (research R-01, R-08)
- [ ] T002 Add the input map to `project.godot` per `contracts/input-actions.md`: `move_up/down/left/right` (WASD + arrows + left stick + d-pad), `capture` (Space + joypad button 0), `debug_menu` (F1), deadzone 0.2
- [ ] T003 Create `export_presets.cfg` with presets `Web` (`variant/thread_support=false`, `extensions_support=false`, VRAM compression off, export path `build/web/index.html`, exclude filter `addons/*,tests/*`), `Windows Desktop`, and `Android` (`screen/orientation=sensor_landscape`, gamepad enabled); same exclude filter on all
- [ ] T004 [P] Create `.gitignore` for Godot (`.godot/`, `build/`, `*.import` kept, `export_credentials.cfg`, `*.tmp`) and `README` pointer note in `assets/audio/README.md` describing the SFX event file names from `contracts/asset-conventions.md`
- [ ] T005 [P] Move premade art from `Assets/` to `assets/` per the migration table in `contracts/asset-conventions.md` (`assets/vehicles/car1..car4/carN-<color>.png` + `.svg`, `assets/roadside/buildings/{left,right}/`, `assets/road/backdrop.png`, `sky.png`, `road.png`, `stencil-bus-lane.png`, `stencil-bike-lane.png`); use `git mv`; delete the empty `Assets/` tree
- [ ] T006 [P] Vendor GUT 9.x into `addons/gut/`, enable it in `project.godot` `[editor_plugins]`, and add `.gutconfig.json` at root (`dirs: ["res://tests"]`, `include_subdirs: true`, `should_exit: true`); create `tests/core/.gdkeep` and `tests/game/.gdkeep`
- [ ] T007 [P] Add `.github/workflows/ci.yml` (research R-14): jobs `test` (checkout, Godot 4.6.2 headless image, `--import`, GUT headless command from quickstart.md, fail on non-zero) and `export-web` (needs test, `--export-release "Web" build/web/index.html`, a bundle-size step that fails when `build/web` exceeds `WEB_BUNDLE_LIMIT_MB` (workflow env var, default 40, expected to be revised for the itch.io upload), then `actions/upload-artifact` of `build/web`); triggers push to `main` and `pull_request`
- [ ] T008 [P] Implement `PlaceholderTexture` in `src/core/app/placeholder_texture.gd` (`class_name PlaceholderTexture`, static `get_texture() -> Texture2D` returning `assets/ui/placeholder.png` if present else a generated 64×64 pink/black checkerboard `ImageTexture`, cached; static `register_use(element_name)` collects element names and `report()` logs the list via `DebugLog.warn` once at startup in every build, including release, per spec FR-030b) and commit a generated `assets/ui/placeholder.png`
- [ ] T009 Update `CLAUDE.md`: replace "no CI/CD" with a note that `.github/workflows/ci.yml` runs tests, the web export, and the bundle-size check per constitution Principle V; add the test command and the `assets/` layout pointer

**Checkpoint**: `godot --headless --import` succeeds, `--export-release Web` produces `build/web/index.html`, CI is green with zero tests.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The template-layer core every story composes on: tuning, logging, the
persistent Main root, input source tracking, focus pausing, settings persistence.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T010 Implement `DebugLog` in `src/core/debug/debug_log.gd` (`class_name DebugLog`, static `info/warn/error(tag, msg)` with ISO timestamp + tag prefix, `error` also calls `push_error`); unit test in `tests/core/test_debug_log.gd` asserting format
- [ ] T011 Implement `TuningConfig` resource in `src/core/tuning/tuning_config.gd` with every `@export` property, group, default, and range from `contracts/tunables.md` (Shift, Road, Bus, Traffic incl. seven `situation_weight_*`, Capture, Scoring, Vehicles, Leaderboard, Audio, Debug) plus `validate() -> PackedStringArray` enforcing the invariants in data-model.md; create `data/core/tuning_defaults.tres`; unit test `tests/core/test_tuning_config.gd` (defaults match contract, invariants flagged)
- [ ] T012 Implement `TuningStore` in `src/core/tuning/tuning_store.gd` (`class_name TuningStore`: load/save `user://tuning_overrides.cfg` sections `[tuning]` and `[style.<key>]` via ConfigFile, apply overrides onto a `TuningConfig`, `clear()`); unit test `tests/core/test_tuning_store.gd` using a temp `user://` path
- [ ] T013 Implement the `Tuning` autoload in `src/core/tuning/tuning.gd` (`class_name TuningService` registered as autoload `Tuning`: `config`, `load_config(cfg)`, `set_value(name, value)` emitting `changed(name)`, `reset_to_defaults()` emitting `reset`, `save_overrides()` debug-only, `register_style_provider(provider)`, `set_style_value(key, prop, value)` emitting `style_changed(key, prop)`, applies `TuningStore` overrides on `_ready` when `OS.is_debug_build()`); register in `project.godot [autoload]`; unit test `tests/core/test_tuning_service.gd`
- [ ] T014 [P] Implement `InputSource` in `src/core/input/input_source.gd` (`class_name InputSource`, enum `Source {KEYBOARD, TOUCH, GAMEPAD}`, classifies events per `contracts/input-actions.md`, emits `source_changed` only on change); test `tests/core/test_input_source.gd` feeding synthetic `InputEvent`s
- [ ] T015 [P] Implement `FocusPauser` in `src/core/app/focus_pauser.gd` (`class_name FocusPauser`, `PROCESS_MODE_ALWAYS`, handles `NOTIFICATION_APPLICATION_FOCUS_OUT/IN` and `PAUSED/RESUMED`, sets `get_tree().paused`, emits `paused` and `resume_requested`; `hold_resume: bool` lets the owner keep the tree paused until it calls `release()`); test `tests/core/test_focus_pauser.gd` via `notification()` calls
- [ ] T016 [P] Implement `SettingsStore` in `src/core/app/settings_store.gd` (`class_name SettingsStore`: `user://settings.cfg`, `[audio] master/music/sfx`, `[player] last_name`, typed getters/setters with defaults from `Tuning.config.volume_*_default`, `save()`); test `tests/core/test_settings_store.gd`
- [ ] T017 [P] Implement `IdleTimeout` in `src/core/app/idle_timeout.gd` (`class_name IdleTimeout`, `PROCESS_MODE_ALWAYS`, `@export timeout_sec`, restarts on any `InputEvent`, emits `timed_out`); test `tests/core/test_idle_timeout.gd`
- [ ] T018 Implement `ScreenHost` in `src/core/app/screen_host.gd` (`class_name ScreenHost`: `show_screen(scene: PackedScene, payload: Variant = null)` frees current child, instantiates next, calls `enter(payload)` if present, connects the screen's `navigation_requested(scene: PackedScene, payload)` signal to itself so screens never look up the host, ignores `show_screen` while a transition is in progress (double-Start debounce), emits `screen_changed(name)`) and `Main` in `src/core/app/main.gd` (`class_name Main`: `@export var initial_screen: PackedScene` so the core layer has no game scene path, owns `ScreenHost`, `InputSource`, `FocusPauser`, `SettingsStore`; on `screen_changed` connects `FocusPauser.paused/resume_requested` to the new screen's `on_focus_paused/on_focus_resume_requested` methods if present); build `scenes/core/main.tscn` with those children and `initial_screen` set to the title scene; scene test `tests/core/test_screen_host.gd` (navigation by signal, debounce)

**Checkpoint**: Main boots to an empty title placeholder, `Tuning.config` is loaded, all core tests pass headless, CI green.

---

## Phase 3: User Story 1 - Play a Complete Shift (Priority: P1) 🎯 MVP

**Goal**: Title → count-in → 90-second shift with keyboard, context-judged captures, misses, scoring, results with Play Again / Title, scores kept locally. Vehicles use the placeholder checkerboard texture with a plate overlay; the road backdrop is the premade image.

**Independent Test**: Quickstart US1 scenarios 1–6 pass on desktop and on the web export; `user://scores.json` holds the shift afterwards.

### Pure logic (parallel, each with its GUT test)

- [ ] T019 [P] [US1] Implement `Perspective` in `src/game/road/perspective.gd` (`class_name Perspective`, static `factor(z, c)`, `project(road_x, z, camera_x, cfg: TuningConfig) -> Vector2` reading horizon/bus_screen_y/vanishing_point/perspective_c/lane_bus_center from config; camera offset passed in, no static state); test `tests/game/test_perspective.gd` (z=0 hits bus_screen_y, z=z_max near horizon, straight lines stay straight)
- [ ] T020 [P] [US1] Implement `RoadGeometry` in `src/game/road/road_geometry.gd` (`class_name RoadGeometry`, static lane queries `is_in_bus_lane`, `is_at_curb`, `bike_lane_intrusion(road_x, half_w)`, lane centres, all reading `TuningConfig` lane_* values); test `tests/game/test_road_geometry.gd`
- [ ] T021 [P] [US1] Implement `Verdict` in `src/game/judgment/verdict.gd` (`class_name Verdict`, enum `Kind`, `label`, `is_violation`, static constructors) and `ViolationRules` in `src/game/judgment/violation_rules.gd` (`class_name ViolationRules`, static `evaluate(vehicle_state, zones, neighbours, cfg) -> Verdict` implementing the six ordered rules from spec FR-008 over a plain `VehicleState` struct-like RefCounted so it needs no scene); test `tests/game/test_violation_rules.gd` covering each rule, sloppy parker, double-park pair, bus stop edge
- [ ] T022 [P] [US1] Implement `DifficultyRamp` in `src/game/shift/difficulty_ramp.gd` (`class_name DifficultyRamp`, `cruise_speed(progress)`, `spawn_interval(progress)` lerping the four tunables); test `tests/game/test_difficulty_ramp.gd`
- [ ] T023 [P] [US1] Implement `ShiftResult` in `src/game/shift/shift_result.gd` (`class_name ShiftResult` per data-model.md, `to_dict()/from_dict()`) and `ScoreKeeper` in `src/game/shift/score_keeper.gd` (`class_name ScoreKeeper` Node: `apply_capture(outcome)`, `apply_miss(verdict)`, emits `score_changed(score, delta, feedback)`, `finish() -> ShiftResult`, points from `Tuning.config`); test `tests/game/test_score_keeper.gd` (+100/−25/−10, negative allowed, counts)
- [ ] T024 [P] [US1] Implement `SituationTable` in `src/game/traffic/situation_table.gd` (`class_name SituationTable` RefCounted, `Situation.Kind` enum, per-kind `min_z_gap` constants, `pick(rng) -> Kind` reading weights only from `Tuning.config.situation_weight_*` so there is a single source of truth and no separate weights resource); test `tests/game/test_situation_table.gd` (weighted distribution over 10k picks within tolerance, re-reads after `Tuning.changed`)
- [ ] T025 [P] [US1] Implement `VehicleStyle` resource in `src/game/vehicles/vehicle_style.gd` (`class_name VehicleStyle` per data-model.md: `key`, `plate_rect`, `left_light_rect`, `right_light_rect`, `rear_width_px`, `textures`, with `@export_range` on rect components, static `make_default(key) -> VehicleStyle` using the centred fallback rects from `contracts/asset-conventions.md`); test `tests/game/test_vehicle_style.gd`
- [ ] T026 [P] [US1] Implement `ScoreStore` in `src/game/services/score_store.gd` (`class_name ScoreStore`: `ScoreRecord`, `user://scores.json`, newest first, cap 200, `append(result)`, `top(n)`, `clear()`); test `tests/game/test_score_store.gd`
- [ ] T027 [P] [US1] Implement `RankCalculator` in `src/game/services/rank_calculator.gd` (`class_name RankCalculator`, static `rank(score, scores) -> int` = 1 + count higher, ties share); test `tests/game/test_rank_calculator.gd`

### Scenes and nodes

- [ ] T028 [US1] Implement `Vehicle` scene: `src/game/vehicles/vehicle.gd` (`class_name Vehicle` Node2D: fields per data-model.md, `setup(road_x, z, motion, own_speed, style: VehicleStyle, color_index)`, `advance(delta, road_speed) -> bool passed`, `merge_to(x)`, `to_state() -> VehicleState`, `get_plate_rect() -> Rect2` from the `PlateOverlay` child, `mark_captured()`), `src/game/vehicles/plate_overlay.gd` (`class_name PlateOverlay` Sprite2D using `PlaceholderTexture` until `assets/overlays/plate.png` exists, positioned by `style.plate_rect`), and `scenes/game/vehicle.tscn` (Body Sprite2D using `PlaceholderTexture` when the style has no textures, PlateOverlay, CapturedMark Label hidden until captured)
- [ ] T029 [US1] Implement `VehicleLayer` in `src/game/vehicles/vehicle_layer.gd` (`class_name VehicleLayer` Node2D: `add(vehicle)`, `vehicles: Array[Vehicle]`, `advance_all(delta, road_speed) -> Array[Vehicle] passed`, z-sorted drawing order, `free_passed(list)`), and `BusStopZones` in `src/game/road/bus_stop_zone.gd` (`class_name BusStopZones` Node2D: `zones` array of `{z, length}`, `spawn_zone(z)`, `scroll(delta, speed)`, draws each zone as a placeholder-textured quad along the curb)
- [ ] T030 [US1] Implement `VehicleSpawner` in `src/game/traffic/vehicle_spawner.gd` (`class_name VehicleSpawner` Node with child `Timer`: `configure(layer, zones, style_source)` where `style_source` has `random_style_and_color(rng)` and defaults to a single `VehicleStyle.make_default("placeholder")`, `start()/stop()`, `set_interval(sec)`, ports the seven situation spawners and column-gap rules from the prototype, no violation labels, emits `vehicle_spawned`); scene test `tests/game/test_vehicle_spawner.gd` (every kind spawns without error, double-park pair z proximity, zone clearance)
- [ ] T031 [US1] Implement `BusDriver` in `src/game/traffic/bus_driver.gd` (`class_name BusDriver` Node: `camera_x`, `road_speed`, `update(delta, cruise_speed, vehicles)`; swerve around parked bus-lane blockers, follow/merge moving lead; emits `swerve_started/ended`, `speed_changed`); test `tests/game/test_bus_driver.gd` with scripted vehicle states
- [ ] T032 [US1] Implement `ShiftClock` in `src/game/shift/shift_clock.gd` (`class_name ShiftClock` Node: `Phase` enum and transitions per data-model.md, `start()`, `pause_for_focus()`, `resume_after_count_in()`, emits `phase_changed`, `tick`, `ended`) and `CountIn` in `src/game/ui/count_in.gd` + `scenes/game/count_in.tscn` (`class_name CountIn` Control, `PROCESS_MODE_ALWAYS`, `run(seconds)` shows 3-2-1, emits `finished`, restart-safe); test `tests/game/test_shift_clock.gd`
- [ ] T033 [US1] Implement `CaptureBox` in `src/game/capture/capture_box.gd` + `scenes/game/capture_box.tscn` (`class_name CaptureBox` Control: `_draw()` reticle, movement via `Input.get_vector` × `box_speed_<source>`, clamped to playfield, cooldown from tuning, emits `capture_attempted(rect)`), and `CaptureJudge` in `src/game/judgment/capture_judge.gd` (`class_name CaptureJudge` + `CaptureOutcome`: closest enclosed plate, readable distance, already-captured, TOO_FAR/EMPTY rules from spec FR-010/011, returns `CaptureOutcome`); test `tests/game/test_capture_judge.gd`
- [ ] T034 [US1] Implement `MissJudge` in `src/game/judgment/miss_judge.gd` (`class_name MissJudge`: `judge_passed(passed, zones, all_vehicles) -> Array[Verdict]` evaluating every passed vehicle before any is freed, skipping captured ones); test `tests/game/test_miss_judge.gd` (double-park pair passing same frame both judged)
- [ ] T035 [US1] Implement `RoadView` in `src/game/road/road_view.gd` + `scenes/game/road_view.tscn` (`class_name RoadView` Node2D: `assets/road/backdrop.png` Sprite2D scaled to 720 px tall and centred, `set_camera_x(x)` slides by `backdrop_slide_factor` clamped to image slack, a placeholder-textured median strip left of the road registered with `PlaceholderTexture.register_use("median")`, debug lane overlay when `show_lane_overlay`)
- [ ] T036 [US1] Implement `Hud` in `src/game/ui/hud.gd` + `scenes/game/hud.tscn` (`class_name Hud` CanvasLayer: score label with sign, `TIME mm:ss.s`, frame-time readout visible only in debug builds) and `FeedbackBanner` in `src/game/ui/feedback_banner.gd` (`class_name FeedbackBanner` Label: `show_text(text, color)` fading over `feedback_time_sec`)
- [ ] T037 [US1] Compose `GameplayScreen` in `src/screens/gameplay_screen.gd` + `scenes/game/gameplay.tscn` (`class_name GameplayScreen`: children RoadView, BusStopZones, VehicleLayer, VehicleSpawner, BusDriver, ShiftClock, DifficultyRamp, CaptureBox, CaptureJudge, MissJudge, ScoreKeeper, Hud, FeedbackBanner, CountIn; wires signals only, no game logic; `enter(payload)` starts the count-in; on `ShiftClock.ended` calls `ScoreKeeper.finish()` and emits `navigation_requested(results_scene, result)`; implements `on_focus_paused()` / `on_focus_resume_requested()` to run the resume count-in per research R-10 and release `FocusPauser`)
- [ ] T038 [P] [US1] Implement minimal `TitleScreen` in `src/screens/title_screen.gd` + `scenes/screens/title_screen.tscn` (`class_name TitleScreen`: game name, Start button focused on entry, Quit hidden on `OS.has_feature("web")`; Start emits `navigation_requested(gameplay_scene, null)`)
- [ ] T039 [P] [US1] Implement minimal `ResultsScreen` in `src/screens/results_screen.gd` + `scenes/screens/results_screen.tscn` (`class_name ResultsScreen`: `enter(result: ShiftResult)` appends to `ScoreStore`, shows score with sign, four counts, and a local rank line from `RankCalculator`; Play Again → gameplay, Title → title via `navigation_requested`; `IdleTimeout` child with `results_idle_timeout_sec` → title)
- [ ] T040 [US1] Set `main.tscn` `initial_screen` to the title scene and export the web build; play a full shift on desktop and in the browser; fix any web-only issue (research R-07 and R-10 verify items apply here for backdrop loading and focus pause); confirm the startup placeholder log lists vehicle body, plate, bus stop zone, and median

**Checkpoint**: MVP. A full shift is playable on web with correct scoring, results, and a local score file. Every tunable used so far is already on `TuningConfig`.

---

## Phase 4: User Story 2 - Tune the Game Live (Priority: P1)

**Goal**: A debug-build-only menu that enumerates every `TuningConfig` property and every `VehicleStyle`, pauses the game, applies changes live, resets to defaults, saves overrides, clears local scores, and exposes the live volume sliders.

**Independent Test**: Quickstart US2 scenarios 1–5, including adding a throwaway `@export` and seeing it appear with no menu edit.

- [ ] T041 [P] [US2] Implement `TunableControlFactory` in `src/core/debug/tunable_control_factory.gd` (`class_name TunableControlFactory`: `build(object, property_info) -> Control` mapping float/int (range hint → SpinBox or HSlider), bool → CheckBox, Vector2/Rect2 → component SpinBoxes, Color → ColorPickerButton, String → LineEdit; each control emits `value_committed(name, value)`); test `tests/core/test_tunable_control_factory.gd` (one control per SCRIPT_VARIABLE property of `TuningConfig`, none for non-exported)
- [ ] T042 [US2] Implement `DebugMenu` in `src/core/debug/debug_menu.gd` + `scenes/core/debug_menu.tscn` (`class_name DebugMenu` CanvasLayer, `PROCESS_MODE_ALWAYS`: builds grouped sections from `Tuning.config.get_property_list()` via the factory, a "Vehicle styles" section from `Tuning`'s registered style provider (interface: `get_styles() -> Array[Resource]`), a "Live volume" section with three sliders bound to an injected `SettingsStore` and `AudioMixer` when present, buttons Reset to defaults / Save overrides / Clear local scores (injected `ScoreStore`) / Close, `open()` pauses tree, `close()` unpauses only if it paused); scene test `tests/core/test_debug_menu_enumeration.gd`
- [ ] T043 [US2] Implement `DebugTrigger` in `src/core/debug/debug_trigger.gd` (`class_name DebugTrigger` Node: `debug_menu` action, three-finger `InputEventScreenTouch` tap, emits `toggle_requested`) and instance `DebugTrigger` + `DebugMenu` under `Main` only when `OS.is_debug_build()`, injecting `SettingsStore` and `ScoreStore` from `Main`; add a `DEBUG` button to `TitleScreen` visible only in debug builds
- [ ] T044 [US2] Make consumers live: audit every node that caches a tunable (`CaptureBox`, `DifficultyRamp`, `SituationTable`, `VehicleSpawner`, `BusDriver`, `ShiftClock`, `RoadView`, `ScoreKeeper`) to re-read on `Tuning.changed`; verify on the web debug export that the three-finger tap opens the menu

**Checkpoint**: Every value in `contracts/tunables.md` is adjustable live; a new `@export` shows up with zero menu edits.

---

## Phase 5: User Story 3 - See a Polished, Readable Scene (Priority: P2)

**Goal**: Real vehicle sprites discovered from `assets/vehicles/`, shader taillight states, tunable plate/light regions per style, scrolling stencils and buildings, bus stop landmark, bus cab overlay, shared theme.

**Independent Test**: Quickstart US3 scenarios 1–4, including dropping in a new `car9` folder.

- [ ] T045 [P] [US3] Implement `SpriteFolderScanner` in `src/core/assets/sprite_folder_scanner.gd` (`class_name SpriteFolderScanner`, static `list_textures(dir) -> Array[Texture2D]` and `list_subdirs(dir)`, normalizing `.png.import` entries per research R-07); test `tests/core/test_sprite_folder_scanner.gd` against `assets/vehicles/car1`
- [ ] T046 [P] [US3] Author `data/game/vehicle_styles/car1.tres` … `car4.tres` (`VehicleStyle` from T025) with eyeballed initial plate and light rects for each premade body style
- [ ] T047 [US3] Implement `VehicleRegistry` in `src/game/vehicles/vehicle_registry.gd` (`class_name VehicleRegistry`: scans `assets/vehicles/*/`, pairs each folder with its `.tres` or `VehicleStyle.make_default(key)` + `DebugLog.warn`, `random_style_and_color(rng)`, implements the style provider interface and registers itself with `Tuning`); test `tests/game/test_vehicle_registry.gd`; pass it to `VehicleSpawner.configure` in `GameplayScreen`, replacing the placeholder style source
- [ ] T048 [US3] Implement taillights: `src/game/vehicles/taillights.gdshader` (canvas_item, uniforms `left_rect`, `right_rect`, `glow_color`, `intensity`, per research R-04) and `VehicleLights` in `src/game/vehicles/vehicle_lights.gd` (`class_name VehicleLights` Node: sets shader params from `VehicleStyle` and `Tuning.config.light_intensity_*` based on `Vehicle.motion`; re-applies on `Tuning.changed` and `Tuning.style_changed`); wire into `scenes/game/vehicle.tscn`; verify the shader compiles in the web export (fallback in R-04 if not)
- [ ] T049 [US3] Wire per-style tuning end to end: `DebugMenu` "Vehicle styles" section edits `plate_rect`, `left_light_rect`, `right_light_rect` live via `Tuning.set_style_value`; `TuningStore` persists them under `[style.<key>]`; `PlateOverlay` and `VehicleLights` re-read on `style_changed`; `show_plate_rects` debug overlay in `VehicleLayer`; extend `test_tuning_store.gd`
- [ ] T050 [P] [US3] Implement `RoadStencil` in `src/game/road/road_stencil.gd` (`class_name RoadStencil` Sprite2D placed in road space at a fixed lane x, scrolls with `z`, projected each frame, respawns at `z_max` on a tunable period) and add BUS ONLY + bike-lane stencil instances to `scenes/game/road_view.tscn`
- [ ] T051 [P] [US3] Implement `BuildingStrip` in `src/game/road/building_strip.gd` (`class_name BuildingStrip` Node2D: `side` export, scans `assets/roadside/buildings/<side>/`, keeps a shuffled queue of building sprites placed at sidewalk x beyond the curb, scrolls and re-projects them, spawns the next when the last clears a tunable gap); add Left and Right instances to `road_view.tscn`
- [ ] T052 [P] [US3] Replace the `BusStopZones` placeholder quad with `assets/road/bus-stop-stripe.png` when present (still `PlaceholderTexture` otherwise, registered) and add `BusOverlay` in `src/game/ui/bus_overlay.gd` + `scenes/game/bus_overlay.tscn` (`class_name BusOverlay` TextureRect anchored bottom, `assets/overlays/bus-cab.png` or registered placeholder); add to `gameplay.tscn` above vehicles
- [ ] T053 [US3] Create `assets/ui/theme.tres` (fallback font, sizes, button styles) and apply it on `Main`'s root so every screen inherits it; set the `CapturedMark` style in `vehicle.tscn` to read over sprite art (outline + green tint)
- [ ] T054 [US3] Calibrate `lane_*` and `vanishing_point_x` tunables against `assets/road/backdrop.png` using the `show_lane_overlay` debug view, then write the calibrated values into `data/core/tuning_defaults.tres`

**Checkpoint**: Scene reads correctly from two metres; adding `assets/vehicles/car9/` needs no code edit.

---

## Phase 6: User Story 4 - Navigate Title, About, Settings, and Results (Priority: P2)

**Goal**: Full title screen (branding, cue sheet, top scores panel, Start / About / Settings / Quit / debug-only DEBUG), About screen, Settings with persisted volume sliders, results with auto-return.

**Independent Test**: Quickstart US4 scenarios 1–3.

- [ ] T055 [P] [US4] Implement `AudioMixer` in `src/core/app/audio_mixer.gd` (`class_name AudioMixer` Node: ensures buses `Master`, `Music`, `SFX` exist (creates via `AudioServer` if the default bus layout lacks them), `set_volume(bus, linear)`, loads from `SettingsStore` on ready); create `default_bus_layout.tres` with the three buses; add under `Main` and inject into `DebugMenu`'s live volume section
- [ ] T056 [P] [US4] Implement `CueSheet` in `src/game/ui/cue_sheet.gd` + `scenes/game/cue_sheet.tscn` (`class_name CueSheet` Control: four violation rows with one-line cue text each and the parked/moving light cue)
- [ ] T057 [P] [US4] Implement `AboutScreen` in `src/screens/about_screen.gd` + `scenes/screens/about_screen.tscn` (`class_name AboutScreen`: elevator pitch text of the bus-mounted camera enforcement program from spec FR-021, optional image from `assets/ui/about/` else none, Back → title via `navigation_requested`, first button focused)
- [ ] T058 [P] [US4] Implement `SettingsScreen` in `src/screens/settings_screen.gd` + `scenes/screens/settings_screen.tscn` (`class_name SettingsScreen`: Master / Music / SFX `HSlider`s bound to `AudioMixer` and `SettingsStore.save()` on change, Back → title, gamepad-navigable)
- [ ] T059 [US4] Expand `TitleScreen` (`src/screens/title_screen.gd`, `title_screen.tscn`): branding, `CueSheet`, a top-scores region fed from `ScoreStore.top(20)` (replaced by `LeaderboardPanel` in US7), About and Settings buttons, focus neighbours for gamepad, Quit hidden on web
- [ ] T060 [US4] Expand `ResultsScreen`: per-category breakdown layout, "Your rank" line from `RankCalculator` over `ScoreStore`, visible idle countdown in the last 10 s, any input cancels; confirm `IdleTimeout` keeps running while focus is lost

**Checkpoint**: Every screen reachable and back; volumes persist across relaunch on web.

---

## Phase 7: User Story 5 - Play with Touch or a Gamepad (Priority: P3)

**Goal**: Virtual joystick and capture button in the side gutters when touch is active; gamepad plays identically to keyboard; Android landscape lock.

**Independent Test**: Quickstart US5 scenarios 1–2.

- [ ] T061 [P] [US5] Implement `VirtualJoystick` in `src/core/input/virtual_joystick.gd` + `scenes/core/virtual_joystick.tscn` (`class_name VirtualJoystick` Control: base + thumb textures (registered placeholder until `assets/ui/joystick-*.png`), tracks one touch index, emits direction vector, calls `Input.action_press/release` for the four move actions with strength)
- [ ] T062 [P] [US5] Implement `VirtualButton` in `src/core/input/virtual_button.gd` + `scenes/core/virtual_button.tscn` (`class_name VirtualButton` Control: `@export action`, presses/releases the action on touch, registered placeholder texture until `assets/ui/capture-button.png`)
- [ ] T063 [US5] Implement `TouchControls` in `src/core/input/touch_controls.gd` + `scenes/core/touch_controls.tscn` (`class_name TouchControls` CanvasLayer: joystick left gutter, button right gutter, computes gutter width from viewport vs 1280 playfield each resize, falls back to edge overlay at reduced opacity when below `touch_gutter_min_px`, `visible = InputSource.source == TOUCH`); add under `Main`
- [ ] T064 [US5] Gamepad pass: verify `Input.get_vector` analog movement and `capture` on joypad button 0 in `CaptureBox`, `ui_accept/ui_cancel` navigation on all screens, and per-source `box_speed_*` switching on `InputSource.source_changed`; confirm Android preset orientation lock and test on device or emulator

**Checkpoint**: A full shift is playable with touch only and with gamepad only.

---

## Phase 8: User Story 6 - Hear the Game (Priority: P3)

**Goal**: Every event has a hook routed through SFX or Music; missing files are silent no-ops.

**Independent Test**: Quickstart US6 scenarios 1–2.

- [ ] T065 [P] [US6] Implement `AudioCues` in `src/game/audio/audio_cues.gd` + node in `gameplay.tscn` (`class_name AudioCues` Node: resolves `assets/audio/sfx/<event>.ogg` for the seven event names at ready, pool of `AudioStreamPlayer`s on bus `SFX`, `play(event)` no-op when unresolved, logs once per missing file); test `tests/game/test_audio_cues.gd` (missing files produce no errors)
- [ ] T066 [P] [US6] Implement `HonkScheduler` in `src/game/audio/honk_scheduler.gd` (`class_name HonkScheduler` Node: on `BusDriver.swerve_started` and on each moving vehicle merge/pass, rolls `honk_probability` and calls `AudioCues.play("honk")`)
- [ ] T067 [US6] Wire hooks: `CountIn` ticks → `count_in_tick`; `CaptureBox.capture_attempted` → `shutter`; `ScoreKeeper.score_changed` → `capture_correct`/`capture_wrong`/`miss` by outcome; `ShiftClock.ended` → `shift_end`; add `MusicPlayer` (`AudioStreamPlayer`, bus `Music`, loop) under `AudioMixer` playing `assets/audio/music/background.ogg` when present

**Checkpoint**: With placeholder `.ogg` files every event sounds once; without them, silence and zero errors.

---

## Phase 9: User Story 7 - Compete on a Shared Leaderboard (Priority: P4)

**Goal**: Name entry with validation and profanity filter, Supabase submit and top-20 fetch, graceful offline behavior on top of the local score history from US1.

**Independent Test**: Quickstart US7 scenarios 1–4.

- [ ] T068 [P] [US7] Implement `ProfanityFilter` in `src/game/services/profanity_filter.gd` (`class_name ProfanityFilter`: loads `data/game/profanity.txt`, normalization and substring rules per research R-13, `contains(text) -> bool`) and create `data/game/profanity.txt` with a common-English list; test `tests/game/test_profanity_filter.gd` with a fixture list
- [ ] T069 [P] [US7] Implement `NameValidator` in `src/game/services/name_validator.gd` (`class_name NameValidator` + `Result`: length 1–12, `^[A-Za-z]+$`, then profanity; messages per spec FR-043); test `tests/game/test_name_validator.gd`
- [ ] T070 [P] [US7] Implement `LeaderboardConfig` resource (`src/game/services/leaderboard_config.gd`, `data/game/leaderboard_config.tres` with `base_url`, `anon_key`, `enabled=false` by default) and `LeaderboardClient` in `src/game/services/leaderboard_client.gd` (`class_name LeaderboardClient` Node with two `HTTPRequest` children, headers/timeouts/payloads/RPCs/failure reasons exactly per `contracts/leaderboard-api.md`, signals `top_scores_received`, `submitted`, `failed`); test `tests/game/test_leaderboard_client.gd` with an injectable request stub (success, timeout, HTTP error, bad JSON, disabled)
- [ ] T071 [P] [US7] Write `specs/001-robonarc-game/contracts/supabase.sql` implementing the `scores` table, constraints, index, RLS policies, `rank_for_score`, and `top_scores` from the contract; document applying it in `quickstart.md` prerequisites
- [ ] T072 [US7] Implement `NameEntry` in `src/game/ui/name_entry.gd` + `scenes/game/name_entry.tscn` (`class_name NameEntry` Control: `LineEdit` max 12 with `SettingsStore.last_name` prefilled, inline `NameValidator` message, Submit and Skip (uses `default_player_name`), OS virtual keyboard on touch, gamepad letter grid, emits `name_chosen(name)`)
- [ ] T073 [US7] Implement `LeaderboardPanel` in `src/game/ui/leaderboard_panel.gd` + `scenes/game/leaderboard_panel.tscn` (`class_name LeaderboardPanel` Control: `show_entries(entries)` top-N rows with placeholder `???` for bad names, `highlight(name, score)`, "leaderboard unavailable" note state, `show_local(scores)` fallback); replace the local top-scores region on `TitleScreen`
- [ ] T074 [US7] Integrate on `ResultsScreen`: show `NameEntry` first, then `ScoreStore.append` with the name, `LeaderboardClient.submit`, rank line from `submitted(rank)` or `RankCalculator` fallback on `failed`, `LeaderboardPanel` with highlight; `TitleScreen` fetches top 20 on enter and falls back to local; never block transitions (results appear before any network result)

**Checkpoint**: Online and offline paths both leave the game responsive; names are validated and filtered.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [ ] T075 [P] Split any script over 150 lines found by `Get-ChildItem -Recurse src -Filter *.gd | ForEach { (Get-Content $_).Count }`; document any over 300 in plan.md Complexity Tracking
- [ ] T076 [P] Add `docs/template-extraction.md` listing the `[core]` files, their dependencies, and the steps to lift them into the org Godot starter template (constitution Principle V)
- [ ] T077 [P] Update `specs/001-robonarc-game/spec.md` asset inventory to match the startup placeholder log, and add `specs/001-robonarc-game/checklists/missing-art.md` listing each placeholder element with where it appears in the release build, for testers producing the art
- [ ] T078 Run every quickstart.md scenario on the web export, on Windows, and on Android or an emulator; record results in `specs/001-robonarc-game/checklists/validation.md`; confirm the release web build ships with placeholders visible and logged (allowed by FR-030b)
- [ ] T079 Tune for convention feel with the debug menu (ramp, spawn, readable distance, penalties) targeting SC-003; save the result into `data/core/tuning_defaults.tres` and note the values in `contracts/tunables.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies; T004–T008 parallel after T001–T003
- **Foundational (Phase 2)**: depends on Phase 1; blocks all stories. T010 → T011 → T012 → T013; T014–T017 parallel after T010; T018 after T013–T017
- **US1 (Phase 3)**: depends on Phase 2. Pure logic T019–T027 parallel; scenes T028–T037 mostly sequential (T028 → T029 → T030; T031, T032, T033/T034, T035, T036 parallel after T029; T037 after all); T038–T039 parallel with scene work; T040 last
- **US2 (Phase 4)**: depends on Phase 2 and on T037 for the live-consumer audit (T044); live volume section is inert until T055
- **US3 (Phase 5)**: depends on US1 (vehicle scene, road view, `VehicleStyle`) and on US2 for T049
- **US4 (Phase 6)**: depends on US1 screens and `ScoreStore`; T055–T058 parallel; T059–T060 after
- **US5 (Phase 7)**: depends on Phase 2 (`InputSource`) and US1 (`CaptureBox`)
- **US6 (Phase 8)**: depends on US1 signals and T055 (`AudioMixer`)
- **US7 (Phase 9)**: depends on US1 (`ShiftResult`, `ScoreStore`, `RankCalculator`) and US4 (results/title layouts); T068–T071 parallel first
- **Polish (Phase 10)**: after all desired stories

### User Story Dependencies

- **US1**: none beyond Foundational (MVP)
- **US2**: Foundational only; T044 touches US1 nodes
- **US3**: US1 (+ US2 for per-style tuning)
- **US4**: US1
- **US5**: US1
- **US6**: US1 + T055
- **US7**: US1 + US4

### Parallel Opportunities

- Phase 1: T004, T005, T006, T007, T008 together
- Phase 2: T014, T015, T016, T017 together
- US1: T019–T027 together; then T031, T032, T033, T034, T035, T036 together; T038, T039 alongside
- US3: T045, T046 together; T050, T051, T052 together
- US4: T055–T058 together
- US5: T061, T062 together
- US6: T065, T066 together
- US7: T068–T071 together
- Polish: T075–T077 together

---

## Parallel Example: User Story 1

```text
# Pure logic with tests, all independent files:
Task: "Perspective in src/game/road/perspective.gd + tests/game/test_perspective.gd"
Task: "RoadGeometry in src/game/road/road_geometry.gd + tests/game/test_road_geometry.gd"
Task: "Verdict + ViolationRules in src/game/judgment/ + tests/game/test_violation_rules.gd"
Task: "DifficultyRamp in src/game/shift/difficulty_ramp.gd + tests/game/test_difficulty_ramp.gd"
Task: "ShiftResult + ScoreKeeper in src/game/shift/ + tests/game/test_score_keeper.gd"
Task: "SituationTable in src/game/traffic/situation_table.gd + tests/game/test_situation_table.gd"
Task: "VehicleStyle in src/game/vehicles/vehicle_style.gd + tests/game/test_vehicle_style.gd"
Task: "ScoreStore in src/game/services/score_store.gd + tests/game/test_score_store.gd"
Task: "RankCalculator in src/game/services/rank_calculator.gd + tests/game/test_rank_calculator.gd"

# After VehicleLayer (T029) lands:
Task: "BusDriver", "ShiftClock + CountIn", "CaptureBox + CaptureJudge", "MissJudge", "RoadView", "Hud + FeedbackBanner"
```

---

## Implementation Strategy

### MVP First (User Stories 1 and 2)

1. Phase 1 Setup, Phase 2 Foundational
2. Phase 3 US1: play a full shift on the web export with placeholder vehicles
3. Phase 4 US2: the debug menu, because the constitution treats tunability as part of done and every later story tunes through it
4. **STOP and VALIDATE**: quickstart US1 and US2 on web

### Incremental Delivery

1. US3 art and light cues → the scene becomes convention-worthy
2. US4 screens → the booth is self-explanatory
3. US5 touch/gamepad, US6 audio → wider venues, more attention
4. US7 leaderboard → bragging rights; last because it is the only external dependency
5. Polish: template extraction notes, missing-art checklist, convention tuning

### Solo Cadence

Each phase is one shippable commit series. Within a phase, land the `[P]` group first,
run the headless tests, then the sequential tasks. Export web at every checkpoint.

---

## Notes

- Every new class declares `class_name`, uses static typing on all declarations, parameters, and return types, and stays under ~150 lines (constitution II)
- Every new feel value goes on `TuningConfig` first, never as a literal (constitution IV)
- Screens never look up `Main` or `ScreenHost`; they emit `navigation_requested` and expose `on_focus_*` methods for `Main` to connect (constitution I)
- Any element without an asset uses `PlaceholderTexture.register_use(name)` so it appears in the startup log and in spec.md (FR-030b); placeholders are allowed in release builds
- Commit `.specify/` and `specs/` doc changes with brief `docs:` messages; game code commits only at working checkpoints

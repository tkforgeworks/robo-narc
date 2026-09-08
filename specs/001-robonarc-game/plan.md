# Implementation Plan: Traffic Fighter 3: Next Generation (TF3) Convention Game

**Branch**: `001-robonarc-game` | **Date**: 2026-09-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-robonarc-game/spec.md`

## Summary

Rebuild the TF3 prototype as a composition-first Godot 4.6 project: a 90-second
bus-camera judgment game with premade art, three input schemes, audio piping, a shared
Supabase leaderboard, and a self-enumerating debug tuning menu. The prototype's pure
logic (perspective projection, violation rulebook, situation spawner, bus driving
behavior) carries over as stateless classes; everything else is re-expressed as
composed scenes under a persistent `Main` root. The reusable skeleton (tuning system,
debug menu, logging, input source detection, focus pausing, settings persistence,
asset discovery, CI, tests) lives in `src/core/` and `scenes/core/` so it can be lifted
into the org template; TF3-specific content lives in `src/game/` and
`scenes/game/`.

## Technical Context

**Language/Version**: GDScript on Godot 4.6.2 stable (GL Compatibility renderer).
Static typing everywhere; every script declares `class_name`.

**Primary Dependencies**: Godot engine only at runtime. Dev-time: GUT 9.x (unit test
addon, excluded from exports). External service: Supabase (PostgREST over HTTPS via
`HTTPRequest`).

**Storage**: `user://` files only. `settings.cfg` (volumes, last name),
`tuning_overrides.cfg` (debug-menu saved values, debug builds only), `scores.json`
(local score history). Remote: one Supabase table `scores`.

**Testing**: GUT 9.x run headless (`godot --headless -s addons/gut/gut_cmdln.gd`).
Unit tests for all pure-logic classes; scene tests for composed behaviors (spawner,
capture judgment, focus pause, debug menu enumeration). Manual validation via
quickstart scenarios on web export.

**Target Platform**: Web (no-threads, GL Compatibility, static host) as the hard
constraint; Windows desktop; Android (landscape, gamepad).

**Project Type**: Single Godot game project with a template-extractable core.

**Performance Goals**: 60 fps on a mid-range laptop in the web build with up to ~25
vehicles live; compressed web bundle reported per build and under the 1 GB itch.io
upload cap (about 10 MB today, engine wasm dominates); title screen in under 10 s on
convention Wi-Fi.

**Constraints**: No threads, no cross-origin isolation, no GDExtensions, no APIs
absent on web. All feel-values tunable at runtime. Debug menu absent in release
builds. Network never blocks (5 s request timeout, fire-and-forget submit).

**Scale/Scope**: 5 screens, ~60 scripts each under 150 lines target, 24 vehicle
sprites, 30 building sprites, one leaderboard table, one CI workflow.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Composition First | PASS | Persistent `Main` root hosts screens as child scenes; gameplay is composed from `RoadView`, `BusDriver`, `VehicleSpawner`, `VehicleLayer`, `CaptureBox`, `Hud`, `AudioCues`, `TouchControls`, `FocusPauser` nodes wired by signals and exported references; screens emit `navigation_requested` and never look up `Main`. One autoload (`Tuning`) with written rationale below. No static mutable state (prototype's `Road.camera_x` becomes `BusDriver` state passed into projection). |
| II. Small Class-Based Scripts | PASS | Every script has `class_name`; the prototype's 312-line `gameplay.gd` splits into `ShiftClock`, `BusDriver`, `CaptureJudge`, `MissJudge`, `ScoreKeeper`, `Hud`, `FeedbackBanner`. Pure logic (`RoadGeometry`, `Perspective`, `ViolationRules`, `NameValidator`, `RankCalculator`) is stateless and scene-free. |
| III. Web Compatibility | PASS | Web export preset is the first thing built; `thread_support=false`; leaderboard uses `HTTPRequest` with CORS-friendly Supabase; persistence via `user://`; shader is a plain `canvas_item` shader supported by GL Compatibility on WebGL 2. CI exports web on every push. |
| IV. Everything Tunable | PASS | `TuningConfig` resource holds every feel-value with `@export` and ranges; `DebugMenu` enumerates it via `get_property_list()` so new tunables need no menu edits; per-body-style plate and taillight regions are tunables too; reset-to-defaults reloads the shipped `.tres`. |
| V. Organization Template | PASS | `src/core/`, `scenes/core/`, `tests/core/`, `.github/workflows/`, `addons/`, export presets and `project.godot` hygiene form the template layer; `src/game/`, `scenes/game/`, `assets/`, `data/game/` are game-specific. Decisions recorded in research.md with rationale. |

**Autoload justification (Principle I)**: `Tuning` is the single autoload. It is read
every frame by a dozen nodes across every scene, must be reachable by the debug menu
from any screen, and must survive screen swaps. Injecting it into every leaf node
would add a constructor parameter to nearly every script for no isolation gain; unit
tests replace it with a test `TuningConfig` via `Tuning.load_config()`. Everything the
prototype kept in `GameState` (run stats, scene paths) becomes a `ShiftResult` value
object passed explicitly from `GameplayScreen` to `ResultsScreen` through `Main`.

**Post-design re-check**: all five still PASS after Phase 1. One watch item under
Principle II: `DebugMenu` may approach 150 lines because of the generic control
factory; the plan splits it into `DebugMenu` (toggle, pause, layout) and
`TunableControlFactory` (property to control mapping) up front.

## Project Structure

### Documentation (this feature)

```text
specs/001-robonarc-game/
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # Phase 1 entities, resources, state machines
├── quickstart.md        # Phase 1 validation guide
├── contracts/
│   ├── leaderboard-api.md      # Supabase table, endpoints, RLS, payloads
│   ├── tunables.md             # TuningConfig fields, defaults, ranges
│   ├── asset-conventions.md    # Folder layout, naming, discovery rules
│   └── input-actions.md        # Action map and input source rules
└── tasks.md             # Phase 2 output (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
project.godot                 # 4.6, GL Compatibility, canvas_items + expand stretch, no Jolt/D3D12
export_presets.cfg            # Web (no threads), Windows, Android (landscape)
.gitignore
.github/workflows/ci.yml      # [core] headless GUT tests + web export + bundle-size check

addons/gut/                   # [core] test addon, excluded from exports

assets/                       # premade art, moved from Assets/ (see research R-11)
├── vehicles/<style>/<style>-<color>.png   # e.g. vehicles/car1/car1-red.png
├── roadside/buildings/{left,right}/
├── road/                     # backdrop, sky, road, stencils
├── ui/                       # placeholder.png (checkerboard), fonts, theme
└── audio/{music,sfx}/        # empty folders with README; hooks resolve to null

data/
├── core/tuning_defaults.tres # [core] TuningConfig baseline
├── game/vehicle_styles/<style>.tres        # VehicleStyle per body style
├── game/                     # (situation weights live on TuningConfig)
└── game/profanity.txt        # blocklist, one word per line

src/
├── core/                     # [core] template layer, game-agnostic
│   ├── tuning/       tuning.gd (autoload), tuning_config.gd, tuning_store.gd
│   ├── debug/        debug_menu.gd, tunable_control_factory.gd, debug_log.gd,
│   │                 debug_trigger.gd (F1 + three-finger tap, debug builds only)
│   ├── input/        input_source.gd, virtual_joystick.gd, virtual_button.gd,
│   │                 touch_controls.gd
│   ├── app/          main.gd, screen_host.gd, focus_pauser.gd, idle_timeout.gd,
│   │                 settings_store.gd, audio_mixer.gd, placeholder_texture.gd
│   └── assets/       sprite_folder_scanner.gd
├── game/                     # TF3-specific
│   ├── road/         road_geometry.gd, perspective.gd, road_view.gd,
│   │                 road_stencil.gd, bus_stop_zone.gd, building_strip.gd
│   ├── vehicles/     vehicle.gd, vehicle_style.gd, vehicle_registry.gd,
│   │                 vehicle_lights.gd (+ taillights.gdshader), plate_overlay.gd,
│   │                 vehicle_layer.gd
│   ├── traffic/      situation_table.gd, vehicle_spawner.gd, bus_driver.gd
│   ├── judgment/     violation_rules.gd, verdict.gd, capture_judge.gd,
│   │                 miss_judge.gd
│   ├── shift/        shift_clock.gd, score_keeper.gd, shift_result.gd,
│   │                 difficulty_ramp.gd
│   ├── capture/      capture_box.gd
│   ├── ui/           hud.gd, feedback_banner.gd, count_in.gd, cue_sheet.gd,
│   │                 leaderboard_panel.gd, name_entry.gd
│   ├── audio/        audio_cues.gd, honk_scheduler.gd
│   └── services/     leaderboard_client.gd, score_store.gd, name_validator.gd,
│                     profanity_filter.gd, rank_calculator.gd
└── screens/          title_screen.gd, about_screen.gd, settings_screen.gd,
                      gameplay_screen.gd, results_screen.gd

scenes/
├── core/             main.tscn, debug_menu.tscn, touch_controls.tscn,
│                     virtual_joystick.tscn, virtual_button.tscn
├── game/             gameplay.tscn, vehicle.tscn, capture_box.tscn, road_view.tscn,
│                     bus_overlay.tscn, hud.tscn, count_in.tscn, name_entry.tscn,
│                     leaderboard_panel.tscn
└── screens/          title_screen.tscn, about_screen.tscn, settings_screen.tscn,
                      results_screen.tscn

tests/
├── core/             test_tuning_config.gd, test_debug_menu_enumeration.gd,
│                     test_input_source.gd, test_focus_pauser.gd, test_settings_store.gd,
│                     test_sprite_folder_scanner.gd
└── game/             test_perspective.gd, test_road_geometry.gd,
                      test_violation_rules.gd, test_situation_table.gd,
                      test_bus_driver.gd, test_capture_judge.gd, test_miss_judge.gd,
                      test_score_keeper.gd, test_difficulty_ramp.gd,
                      test_name_validator.gd, test_profanity_filter.gd,
                      test_rank_calculator.gd, test_leaderboard_client.gd (stubbed HTTP),
                      test_vehicle_registry.gd
```

**Structure Decision**: single Godot project. The `[core]` marker identifies the
template layer that Principle V will extract; it depends on nothing under `src/game/`.
Game code depends on core, never the reverse. Screens are children of `Main`, swapped
by `ScreenHost`, so music, debug menu, touch controls, and focus pausing persist
without extra autoloads.

## Scene Composition (key scenes)

```text
Main (main.gd)
├── ScreenHost            # swaps screen scenes via navigation_requested, passes ShiftResult forward; Main.initial_screen is an export so core has no game path
├── AudioMixer            # Master/Music/SFX bus wiring + MusicPlayer child
├── TouchControls         # visible only when InputSource.active == TOUCH
├── FocusPauser           # pauses tree on focus-out, requests resume count-in
├── DebugTrigger + DebugMenu (instanced only when OS.is_debug_build())
└── InputSource           # tracks last input device, emits source_changed

GameplayScreen (gameplay_screen.gd) — wires children by signal only
├── RoadView              # backdrop sprite + slide offset from BusDriver
│   ├── StencilLayer      # scrolling BUS ONLY / bike stencils
│   ├── BusStopZones      # zone markers (placeholder art)
│   └── BuildingStrips    # left/right building sprites scrolling
├── VehicleLayer          # container; orders by z
├── VehicleSpawner        # SituationTable + Timer; emits vehicle_spawned
├── BusDriver             # camera_x, road_speed, swerve/follow/merge; emits swerved
├── ShiftClock            # count-in, timer, pause/resume; emits phase_changed, ended
├── DifficultyRamp        # maps clock progress to cruise speed + spawn interval
├── CaptureBox            # reticle, movement from actions, emits capture_attempted
├── CaptureJudge          # box + VehicleLayer + ViolationRules -> Verdict
├── MissJudge             # passes + ViolationRules -> Verdict
├── ScoreKeeper           # verdicts -> score, counts; emits score_changed
├── Hud + FeedbackBanner + CountIn
├── AudioCues + HonkScheduler
└── BusOverlay            # cab/hood frame (placeholder art)
```

## Phase 0 and Phase 1 outputs

- [research.md](research.md): 14 decisions (R-01 to R-14) covering engine pin, test
  framework, tuning and debug menu pattern, taillight shader, plate overlay, road
  backdrop and swerve, asset discovery on web, aspect and gutters, input source
  detection, focus pause, leaderboard, profanity filter, CI, asset folder move.
- [data-model.md](data-model.md): resources, value objects, node state, state
  machines for shift phases and vehicle lifecycle.
- [contracts/](contracts/): leaderboard API, tunables, asset conventions, input
  actions.
- [quickstart.md](quickstart.md): setup, test, run, export, and per-story validation.

## Complexity Tracking

No constitution violations to justify. Two design choices worth recording because
they look like extra machinery:

| Choice | Why Needed | Simpler Alternative Rejected Because |
|--------|------------|-------------------------------------|
| Persistent `Main` root with `ScreenHost` instead of `change_scene_to_file` | Music, debug menu, touch controls, focus pausing and input-source tracking must survive screen swaps; passing `ShiftResult` explicitly avoids a results autoload | Scene switching would force three or four autoloads (music, debug, results, input), violating Principle I's minimal-autoload rule |
| Generic `TunableControlFactory` reading `get_property_list()` | Principle IV requires new tunables to appear with zero menu edits | Hand-wired spin boxes (prototype approach) need a menu edit per tunable and already drifted out of sync in the prototype |
| `TuningConfig` stays one 150+ line resource (T075) | It is pure data: one `@export` per tunable, grouped by `@export_group`. Every line is a contract row in `contracts/tunables.md` | Splitting into sub-resources would make the debug menu enumeration, the diff-only override store, and the tunables contract all walk a tree for no behavioural gain |
| Area2D detection (lanes, zones, bodies, plates, probes, capture) with vehicles moved in the physics step and 2D physics interpolation on | The layout is inspectable in the editor and in play (`show_collision_shapes`, `hide_sprites`), rules become tunable overlap shares, and every shape scales with the vehicle node | Screen-rect maths was deterministic and cheap but invisible; it kept plate placement in data instead of the scene and forced every rule into road-space thresholds |

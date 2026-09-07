# Research: RoboNarc Convention Game

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-09-07

All Technical Context unknowns are resolved below. Items marked **verify** are
decisions made from documented engine behavior that must be confirmed on the first
web export; each has a fallback so none blocks planning.

## R-01: Engine version and renderer

- **Decision**: Godot 4.6.2 stable, GL Compatibility renderer, `config/features`
  pinned to `("4.6", "GL Compatibility")`. Drop the prototype's Jolt 3D physics and
  D3D12 driver settings from `project.godot`.
- **Rationale**: Matches the prototype and its verified no-threads web export. GL
  Compatibility is the only renderer that targets WebGL 2 and old Android GPUs. The
  unused 3D physics and D3D12 settings are cruft called out by the GDD.
- **Alternatives considered**: Godot 4.7 (not yet proven with the export pipeline
  here); Forward+ or Mobile renderer (no web support).

## R-02: Test framework

- **Decision**: GUT 9.x (Godot Unit Test) as `addons/gut/`, run headless with
  `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs
  -gexit`. Excluded from all export presets via the export exclude filter
  `addons/*,tests/*`.
- **Rationale**: Pure GDScript, no C# or extensions, explicit assertions, mature
  headless CLI, and one config file to lift into the org template. Its `add_child_autofree`
  and signal watchers cover the scene-level tests this plan needs without a second
  framework.
- **Alternatives considered**: gdUnit4 (richer scene runner and an official GitHub
  Action, but heavier and its editor plugin adds noise; can be swapped later since
  tests are behavior-level); no framework with ad-hoc scripts (rejected by
  Principle V, the template needs a real test story).

## R-03: Tunables and debug menu enumeration

- **Decision**: One `TuningConfig` resource class with `@export` properties grouped
  by `@export_group` and constrained by `@export_range`. A shipped baseline lives at
  `data/core/tuning_defaults.tres`. The `Tuning` autoload loads it, applies any
  `user://tuning_overrides.cfg` in debug builds, and exposes `config`. `DebugMenu`
  builds controls by iterating `config.get_property_list()`, keeping entries with
  `PROPERTY_USAGE_SCRIPT_VARIABLE` and using each property's hint string for range and
  step. `Tuning.reset_to_defaults()` reloads the `.tres` and deletes the override file.
  Per-body-style values (plate rect, taillight rects) live in `VehicleStyle` resources
  and are exposed by the menu through a "Vehicle styles" section that enumerates
  each registered style the same way.
- **Rationale**: Satisfies Principle IV literally: adding an `@export var` to
  `TuningConfig` is the entire change. Resources are inspectable in the editor,
  serializable, and easy to replace in tests. Overrides in `user://` let tuned plate
  anchors persist and be copied back into the `.tres` as new defaults.
- **Alternatives considered**: Dictionary-based config (loses types and editor
  ranges); ProjectSettings custom keys (not live-editable on web); per-node
  `@export` values scattered across scenes (unenumerable).

## R-04: Taillight states via shader

- **Decision**: A `canvas_item` shader on the vehicle `Sprite2D` with uniforms
  `light_rects` (two `vec4` UV rectangles from `VehicleStyle`), `glow_color`, and
  `intensity` (0.0 off, 0.35 dim, 1.0 bright, all three tunables). Inside a rect the
  fragment blends toward `glow_color` by `intensity` and adds a soft falloff outside
  it. `VehicleLights` sets `intensity` from the vehicle's motion state. Uses only
  `TEXTURE`, `UV`, and uniforms, so it runs on WebGL 2 under GL Compatibility.
- **Rationale**: No per-variant art, works on all 24 sprites today, and the regions
  are tunable so each body style is aligned by eye per the clarification. A shader
  handles the "off" state (darkening the drawn lens) which an additive overlay could
  not.
- **Alternatives considered**: Additive glow `Sprite2D` overlay (cannot turn lights
  off, only on); per-state frames (blocked on art).
- **Verify**: shader compiles in the web export; fallback is a `modulate`-tinted
  glow sprite with the same tunable rects.

## R-05: License plate overlay and capture rect

- **Decision**: `PlateOverlay` is a child `Sprite2D` using a shared plate texture
  (placeholder checkerboard until provided), positioned and scaled by
  `VehicleStyle.plate_rect` (normalized to the sprite). `Vehicle.get_plate_rect()`
  returns the overlay's projected screen rect and is the single input to capture
  enclosure testing.
- **Rationale**: Keeps the plate as data, makes the capture target exactly what the
  player sees, and needs one asset for all styles.
- **Alternatives considered**: Baked plates per variant (blocked on art); drawn
  rectangle (contradicts "art assets replace draw calls" except for the reticle).

## R-06: Road backdrop and swerve

- **Decision**: `RoadView` shows the premade `Background+Road` image scaled to 720 px
  tall (about 1593 px wide) centred in the 1280 px playfield, and offsets its
  `position.x` by `-(camera_x - bus_lane_center) * backdrop_slide_factor` (tunable,
  baseline 0.35) during swerves, clamped so the image edges never enter the
  playfield. Road-fixed objects and vehicles use the full perspective shift through
  `Perspective.project(road_x, z, camera_x)`. `RoadGeometry` lane constants are
  recalibrated to the image's lane edges (measured at the bottom edge and horizon of
  the artwork) so projected vehicles sit on the painted lanes.
- **Rationale**: Implements clarification "static backdrop that slides". The image
  has roughly 156 px of slack each side at 720 px height, enough for a visible slide
  without exposing edges. A partial slide factor hides the fact that the vanishing
  point does not move.
- **Alternatives considered**: Rebuilt drawn road (rejected by the clarification);
  no slide (rejected as too static).
- **Verify**: lane edge calibration by overlaying projected lane lines in a debug
  build; the constants are tunables so it can be done live.

## R-07: Asset discovery on exported builds (web)

- **Decision**: `SpriteFolderScanner.list_textures(dir)` opens the folder with
  `DirAccess`, collects entries ending in `.png` or `.png.import`, strips the
  `.import` suffix, de-duplicates, and returns `ResourceLoader.load()` results.
  `VehicleRegistry` scans `assets/vehicles/<style>/` folders, derives the style key
  from the folder name, and pairs it with `data/game/vehicle_styles/<style>.tres`
  (creating a default `VehicleStyle` with centred fallback rects and a logged
  warning when absent).
- **Rationale**: In exported PCKs the source PNG is remapped and the directory
  listing shows the `.import` marker instead; handling both makes discovery work in
  the editor and in web, desktop, and Android exports with no registry file to
  maintain, which is what FR-026 demands.
- **Alternatives considered**: Editor-time generated registry `.tres` (needs a tool
  step, so "drop in a file" is no longer the whole change); hard-coded lists
  (rejected by spec).
- **Verify**: directory listing inside the web PCK; fallback is a tiny editor tool
  script that writes `data/game/vehicle_manifest.tres`, run automatically by CI.

## R-08: Aspect handling and touch gutters

- **Decision**: `display/window/stretch/mode = canvas_items`, `stretch/aspect =
  expand`, base size 1280 × 720. The playfield is a 1280-wide container anchored to
  the centre; on wider displays the viewport grows horizontally and the extra width
  on each side is a real drawable gutter where `TouchControls` places the joystick
  (left) and capture button (right). When the gutter width is below a tunable
  minimum (baseline 120 px), controls overlay the playfield edges at reduced opacity.
- **Rationale**: With `aspect = keep`, letterbox bars are outside the viewport and
  cannot host controls. `expand` keeps the playfield unstretched (FR-030) while
  making gutters drawable. Phones at 19.5:9 get about 140 px per side; 16:9 tablets
  get none, hence the overlay fallback.
- **Alternatives considered**: `aspect = keep` with controls inside the playfield
  (contradicts spec); separate SubViewport (heavier, unnecessary).

## R-09: Input source detection

- **Decision**: `InputSource` node in `Main` inspects every `InputEvent` in
  `_input`: `InputEventScreenTouch`/`InputEventScreenDrag` set TOUCH,
  `InputEventJoypadButton`/`InputEventJoypadMotion` (above deadzone) set GAMEPAD,
  `InputEventKey`/`InputEventMouse*` set KEYBOARD. It emits `source_changed` only on
  change. `TouchControls.visible` binds to `source == TOUCH`. Virtual joystick and
  button inject `Input.action_press/release` for the named actions so gameplay never
  sees device types (FR-031). `emulate_mouse_from_touch` is disabled so touches are
  not double-counted as mouse.
- **Rationale**: "Most recent input wins" (spec edge case) falls out naturally; no
  platform checks in gameplay.
- **Alternatives considered**: `DisplayServer.is_touchscreen_available()` at start
  (wrong for hybrid laptops and for a gamepad plugged into a phone).

## R-10: Focus-loss pause and resume count-in

- **Decision**: `FocusPauser` in `Main` handles `NOTIFICATION_APPLICATION_FOCUS_OUT`
  and `NOTIFICATION_APPLICATION_PAUSED` by setting `get_tree().paused = true` and
  emitting `paused`; on `FOCUS_IN`/`RESUMED` it emits `resume_requested`.
  `GameplayScreen` listens: if `ShiftClock.phase == RUNNING` it keeps the tree paused
  and runs `CountIn` in `PROCESS_MODE_ALWAYS`, then unpauses; in any other phase it
  unpauses immediately. Repeated focus flips while a count-in is pending restart the
  same count-in rather than stacking. `IdleTimeout` (results screen) runs in
  `PROCESS_MODE_ALWAYS` so it keeps counting while paused, per the spec edge case.
- **Rationale**: Uses only engine notifications available on web (window blur),
  desktop, and Android (app lifecycle).
- **Verify**: on web, tab switch triggers FOCUS_OUT (window blur). If a browser only
  fires visibility change, fallback is `JavaScriptBridge` listening for
  `visibilitychange`, which is web-only and non-blocking, so still constitutional.

## R-11: Asset folder move and naming

- **Decision**: Move `Assets/` to lowercase `assets/` with the layout in
  `contracts/asset-conventions.md`: `vehicles/car1/car1-red.png`,
  `roadside/buildings/left/building1-left.png`, `road/backdrop.png`,
  `road/stencil-bus-lane.png`, and so on. Keep the SVG sources next to the PNGs.
  Import presets: lossless PNG, mipmaps off, filter on, no VRAM compression for
  web size predictability.
- **Rationale**: Godot and the GDD both use lowercase `assets/`; folder-name-derived
  style keys need stable, space-free names (`Car 1` becomes `car1`). Doing the move
  once, before any scene references exist, avoids broken paths later.
- **Alternatives considered**: Keep `Assets/` as-is and map names in code (adds a
  mapping table that Principle V would have to carry into the template).

## R-12: Leaderboard service

- **Decision**: Supabase project with one table `scores` and two SQL functions,
  accessed through PostgREST with the anon key in an `apikey` header. `LeaderboardClient`
  wraps two `HTTPRequest` nodes (one fetch, one submit), 5 s timeout, JSON bodies,
  and emits `top_scores_received(entries)`, `submitted(rank)`, `failed(reason)`.
  Rank is returned by an RPC `rank_for_score(p_score)` that counts higher scores
  plus one, so the client never pages the table. RLS: anon may `INSERT` rows that
  pass a CHECK constraint (name pattern, score range) and may `SELECT`; no update or
  delete. Contract in `contracts/leaderboard-api.md`.
- **Rationale**: PostgREST works from browsers with CORS, needs no SDK, and a single
  `HTTPRequest` is available on every target. The anon key in a client is accepted
  by FR-044.
- **Alternatives considered**: Custom Cloudflare Worker (more control, more infra to
  run); Supabase GDScript SDK addons (unnecessary dependency).

## R-13: Profanity filter and name validation

- **Decision**: `NameValidator.validate(name) -> NameValidator.Result` applies, in
  order: length 1 to 12, `^[A-Za-z]+$`, then `ProfanityFilter.contains(name)`.
  `ProfanityFilter` loads `data/game/profanity.txt` once, lowercases, and tests
  substring matches after collapsing repeated letters and mapping common leet
  substitutions (`0→o, 1→i, 3→e, 4→a, 5→s, 7→t, @→a, $→s`). Substring matching is
  accepted despite false positives (the "Scunthorpe problem") because the spec
  prioritises keeping obvious words off a public screen and the player can retry.
- **Rationale**: Data-driven, no rebuild to extend, testable with a fixture list.
- **Alternatives considered**: Word-boundary matching (misses `xxBADWORDxx` style
  entries which are the common case for a 12-letter, no-space field).

## R-14: CI/CD and template layer

- **Decision**: `.github/workflows/ci.yml` (GitHub Actions; the repo is hosted at
  `github.com/tkforgeworks/robo-narc`) with two jobs on `ubuntu-latest` using a Godot
  4.6.2 headless container image (for example `barichello/godot-ci:4.6.2`, which
  ships the editor and export templates): `test` (GUT headless, fails on any failing
  test) and `export-web` (runs `--export-release Web`, zips `build/web` and reports
  raw and gzip-compressed sizes, fails only if the compressed archive exceeds the
  1 GB itch.io upload limit, uploads the zip with `actions/upload-artifact`). The
  compressed size is what itch.io serves, so it is the number tracked; the raw wasm
  alone is about 38 MB while its gzip is about 10 MB. Triggers: push to `main` and
  pull requests. Windows and
  Android exports are documented in quickstart but not run in CI for this feature
  (Android needs a keystore secret; deferred). The workflow, `tests/core`,
  `src/core`, `scenes/core`, `addons/gut`, `project.godot` conventions and
  `export_presets.cfg` are the extractable template.
- **Rationale**: Principle V requires a CI story now; Principle III makes the web
  export the natural smoke test. The project lives on GitHub, so GitHub Actions is
  the zero-setup option and the template's target host.
- **Note**: The repo's CLAUDE.md says "no CI/CD"; the constitution (v1.1.0,
  Principle V) supersedes it. CLAUDE.md should be updated when the workflow lands.
- **Alternatives considered**: No CI (violates Principle V); Gitea Actions (the org
  has a Gitea instance, but this repo is on GitHub and the workflow syntax is
  compatible if it is ever mirrored).

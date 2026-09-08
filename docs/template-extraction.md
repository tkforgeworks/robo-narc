# Template extraction guide

RoboNarc is the first TK ForgeWorks game and doubles as the org's Godot starter
template (constitution Principle V). Everything marked `[core]` below is
game-agnostic and can be lifted into a new project without reading any RoboNarc
gameplay code. Everything else is RoboNarc.

## The boundary

| Layer | Directories | Rule |
|-------|-------------|------|
| `[core]` template | `src/core/`, `scenes/core/`, `tests/core/`, `data/core/`, `addons/gut/`, `.github/workflows/ci.yml`, `.gutconfig.json`, `.gitattributes`, `.specify/`, `.claude/` | Never references `src/game/` or `scenes/game/`. Depends only on Godot, GUT, and the one autoload |
| Game | `src/game/`, `scenes/game/`, `scenes/screens/`, `data/game/`, `assets/`, `specs/` | May depend on core freely |

The only autoload is `Tuning` (`src/core/tuning/tuning.gd`). Core nodes that need
tunables read `Tuning.config`; screens and game nodes receive a `TuningConfig`
by injection first and fall back to the autoload.

## Core inventory

### App shell (`src/core/app/`)

| File | Purpose | Depends on |
|------|---------|------------|
| `main.gd` + `scenes/core/main.tscn` | Persistent root: hosts screens, input source, focus pauser, audio mixer, music, letterbox, touch controls, debug menu. Binds services to screens through opt-in methods (`bind_settings`, `bind_audio_mixer`, `bind_input_source`, `bind_tuning`, `bind_debug_menu`, `on_focus_paused`, `on_focus_resume_requested`) | everything below; `initial_screen` export points at a game scene |
| `screen_host.gd` | Owns the one active screen; screens navigate by emitting `navigation_requested(scene, payload)` | DebugLog |
| `focus_pauser.gd` | Pauses on window/tab focus loss; JavaScriptBridge hooks on web; optional resume count-in hold | DebugLog |
| `idle_timeout.gd` | Auto-return timer that keeps running while paused; restart-or-cancel on input | none |
| `settings_store.gd` | `user://settings.cfg`: volumes and last player name | TuningConfig defaults |
| `audio_mixer.gd` + `default_bus_layout.tres` | Master / Music / SFX buses, linear-to-dB with a hard mute | SettingsStore |
| `music_player.gd` | Loops `assets/audio/music/background.{ogg,wav}` if present | DebugLog |
| `placeholder_texture.gd` + `assets/ui/placeholder.png` | Shared checkerboard for missing art; logs the missing set at startup | DebugLog |
| `playfield.gd` | Fixed 1280 x 720 design area centred in the expand-stretched viewport; gutter maths | none |
| `playfield_anchor.gd` | Composable node that moves its parent and listed frames to the playfield offset on resize | Playfield |
| `letterbox.gd` | Paints the gutters for fixed-playfield screens | Playfield |
| `splash_screen.gd` + `scenes/core/splash_screen.tscn` | Studio logo card before the first game screen; `assets/ui/logo.png`, skippable, `Main.first_game_screen` is its next screen | PlaceholderTexture |
| `src/core/ui/link_text.gd` | RichTextLabel whose `[url]` tags open in the system browser | none |

### Input (`src/core/input/`)

| File | Purpose |
|------|---------|
| `input_source.gd` | Classifies the last input device (keyboard / touch / gamepad); `source_changed` |
| `virtual_joystick.gd` + `.tscn` | Touch stick feeding the four move actions with analog strength |
| `virtual_button.gd` + `.tscn` | Touch button that presses a named action and pushes an `InputEventAction` |
| `touch_controls.gd` + `.tscn` | Places both in the gutters (or faded on the edges) when touch is active on a playfield screen |

Requires these actions in `project.godot`: `move_up`, `move_down`, `move_left`,
`move_right`, `capture` (rename `capture` freely; `VirtualButton.action` is an
export), `debug_menu`.

### Tuning (`src/core/tuning/`)

| File | Purpose |
|------|---------|
| `tuning_config.gd` | The resource holding every tunable as an `@export` in `@export_group`s. Replace its fields for a new game; keep the pattern |
| `tuning.gd` (autoload `Tuning`) | Loads `data/core/tuning_defaults.tres`, applies `user://tuning_overrides.cfg`, emits `changed(property)`, `reset`, `style_changed`; optional style provider for per-asset tunables |
| `tuning_store.gd` | Diff-only override persistence |
| `tunable_properties.gd` | Reflection over `@export` groups for the debug menu |

### Debug (`src/core/debug/`)

| File | Purpose |
|------|---------|
| `debug_log.gd` | Tagged, timestamped `info` / `warn` / `error` |
| `debug_menu.gd` + `scenes/core/debug_menu.tscn` | Debug-build-only live tuning menu: every tunable, styles, live volume, reset, save, registered actions |
| `debug_section_builder.gd` | Builds the menu's grids |
| `tunable_control_factory.gd` | One control per property type |
| `debug_trigger.gd` | F1 or three-finger tap opens the menu |
| `debug_shapes.gd` | Outlines an Area2D's shapes from its `_draw` (used by the game's `OutlinedArea`) |

### Assets (`src/core/assets/`)

`sprite_folder_scanner.gd`: lists textures in a folder, normalising `.import`
stubs in exports. Use it for any drop-in asset variant system.

### Tests (`tests/core/`)

One GUT suite per core script plus `helpers/fake_screen.*`. They run headless
and are the smoke test of the template itself.

### Repo scaffolding

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | `test` job (headless GUT) then `export-web` with a compressed-size gate and an optional secrets step |
| `.gutconfig.json` | GUT dirs, prefix, exit codes |
| `.gitattributes` | LF normalisation so Windows and CI agree |
| `export_presets.cfg` | Web (no threads), Windows Desktop, Android (landscape) presets |
| `project.godot` | GL Compatibility, canvas_items stretch with `expand`, no mouse-from-touch emulation, the input map, the `Tuning` autoload |
| `.specify/`, `.claude/` | spec-kit workflow, constitution, agent guidance |
| `CLAUDE.md` | Build/test commands and layout for agents |

## Lifting it into a new project

1. Copy the `[core]` directories and files from the table above. Keep paths;
   `main.tscn` and the debug menu reference them by `res://` path.
2. Copy `project.godot` and replace `config/name`, `run/main_scene` (keep
   `scenes/core/main.tscn`), and the icon. Keep the `[display]`, `[input_devices]`,
   `[autoload]`, and `[rendering]` blocks.
3. Replace the fields in `tuning_config.gd` with the new game's tunables and
   regenerate `data/core/tuning_defaults.tres` (`TuningConfig.new()` saved as a
   resource). The debug menu picks them up with no edits.
4. Make a first screen under `scenes/screens/` (a `Control` for menus, a `Node2D`
   under a `PlayfieldAnchor` for a fixed-size playfield) and set it as
   `initial_screen` on `Main`. Navigate by emitting `navigation_requested`.
5. Adjust the input map if the game needs different actions; update
   `VirtualButton.action` in `touch_controls.tscn`.
6. Run `godot --headless --path . --import` then the GUT command from `CLAUDE.md`.
   The core suites must pass before any game code exists.
7. Push: CI runs the tests and the web export. Set `WEB_BUNDLE_LIMIT_MB` to the
   target store's limit.

## Things that look core but are not

- `src/game/services/leaderboard_*`: the Supabase client is generic in shape but
  its payload is RoboNarc's `ShiftResult`. Lift it with the `ShiftResult` fields
  swapped for the new game's record.
- `src/game/services/profanity_filter.gd` and `name_validator.gd`: reusable as-is
  for any name entry; kept in the game layer only because the rules come from
  RoboNarc's spec.
- `src/game/ui/leaderboard_panel.gd`, `name_entry.gd`: reusable UI with RoboNarc
  wording.

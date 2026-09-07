# Quickstart: RoboNarc Convention Game

Validation guide for the feature. Implementation details are in
[plan.md](plan.md) and tasks.md; contracts are under [contracts/](contracts/).

## Prerequisites

- Godot 4.6.2 stable editor (`Godot_v4.6.2-stable_win64.exe`) on PATH as `godot`,
  or set `GODOT` to its full path.
- Export templates 4.6.2.stable installed (Editor → Manage Export Templates, or
  the PowerShell route in the prototype's `BUILD_WEB.md`).
- Python 3 (only for the local static server).
- Optional: a Supabase project with the schema from
  [contracts/leaderboard-api.md](contracts/leaderboard-api.md), and its URL and
  anon key entered in `data/game/leaderboard_config.tres`.

## Setup

```powershell
git clone <repo> C:\Code\robo-narc
cd C:\Code\robo-narc
godot --headless --path . --import      # imports assets, builds .godot cache
```

## Run the tests

```powershell
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Expected: all tests pass, exit code 0. Pure-logic suites (`test_perspective`,
`test_violation_rules`, `test_name_validator`, `test_profanity_filter`,
`test_rank_calculator`, `test_difficulty_ramp`) need no scene tree.

## Run the game (desktop)

```powershell
godot --path .
```

Or open the project in the editor and press F5. `Main` is the main scene.

## Export and serve the web build

```powershell
New-Item -ItemType Directory -Force build\web | Out-Null
godot --headless --path . --export-release "Web" build\web\index.html
python -m http.server 8000 -d build\web
```

Open `http://localhost:8000`. No cross-origin headers are needed; if the page
complains about SharedArrayBuffer, thread support was accidentally enabled in the
preset.

## Validation scenarios

Each maps to a user story in [spec.md](spec.md). Run every scenario on the web build
at least once; desktop is fine for iteration.

### US1 Play a complete shift

1. Title → Start. Expect 3-2-1 count-in with no vehicles and no box movement.
2. Move the box with WASD; capture a stopped car in the red bus lane while its plate
   is large. Expect `+100 BUS LANE`, plate marked.
3. Capture a moving car. Expect `-25 INNOCENT DRIVER`.
4. Let a curb car inside the bus stop zone pass. Expect `-10 MISSED BUS STOP`.
5. Press capture on a distant plate. Expect `TOO FAR`, no score change.
6. Wait for 00:00. Expect end cue, results screen with score and four counts.

### US2 Tune the game live

1. During a shift press F1. Expect pause and a menu listing every property in
   [contracts/tunables.md](contracts/tunables.md).
2. Set `shift_length_sec` to 20 and `cruise_speed_end` to 60; close. Expect the timer
   and speed to reflect it immediately.
3. Reset to defaults. Expect baseline values.
4. Add `@export var demo_value: float = 1.0` to `TuningConfig`, rerun. Expect it in
   the menu with no other change. Remove it afterwards.
5. On the web debug export, three-finger tap. Expect the same menu.

### US3 Polished scene

1. Watch several spawns: vehicles are sprites in varied styles and colors; stopped
   cars in the road show bright lights, curb cars off, moving cars dim.
2. Toggle `show_plate_rects` in the debug menu; plate overlays sit on each rear.
3. Copy `car1` to `assets/vehicles/car9/` with renamed files; rerun. Expect `car9`
   in the rotation and a logged warning about default style data.
4. During a swerve the backdrop slides with the cars and no edge appears.

### US4 Screens

1. Title shows name, cue sheet, top 20 (or "leaderboard unavailable"), Start /
   About / Settings; Quit hidden on web.
2. About → back. Settings: lower Music to 0; relaunch; still 0.
3. Results: wait 60 s with no input → title. Press a key at 30 s → stays.

### US5 Touch and gamepad

1. Web build on a phone or Chrome device emulation with touch: joystick left gutter,
   button right gutter, none over the road; play a shift.
2. Plug in a gamepad on desktop: stick moves the box, A captures, virtual controls
   hidden.

### US6 Audio

1. Drop any short `.ogg` files named per
   [contracts/asset-conventions.md](contracts/asset-conventions.md) into
   `assets/audio/sfx/`; each event plays once. Remove them; the game is silent and
   logs no errors.
2. Settings SFX 0, Music 1: music only.

### US7 Leaderboard

1. With a configured Supabase project: finish a shift, enter `Ava`, expect rank shown
   and the name on the title top 20 after return.
2. Enter `Ava1`, `A very long name here`, and a blocklisted word: each refused inline.
3. Skip: submitted as `Rookie`.
4. Disable network (DevTools offline): results appear instantly with
   "leaderboard unavailable"; local score kept.

## CI

`.github/workflows/ci.yml` runs the test command above and the web export on every
push. A red `test` job or a failed export blocks the change.

# Quickstart validation record

**Purpose**: Results of running the [quickstart.md](../quickstart.md) scenarios per
platform (task T078). Re-run and update before each release.
**Last run**: 2026-09-07, commit after the polish split (web release export served
from `build/web` over localhost; Windows release export `build/windows/TF3.exe`;
Supabase project live with the publishable key).

Legend: ✓ passed this run · ◐ passed in an earlier session or by unit test only ·
✗ failed · — not run.

| Scenario | Web | Windows | Android | Notes |
|----------|-----|---------|---------|-------|
| US1.1 Count-in, no vehicles, no box motion | ✓ | — | — | |
| US1.2 Correct bus-lane capture `+100` | ◐ | — | — | Play sessions 1–3; local history holds 2425 / 1915 |
| US1.3 Moving car `-25 INNOCENT DRIVER` | ◐ | — | — | Play sessions |
| US1.4 Curb car in bus stop passes `-10 MISSED BUS STOP` | ✓ | — | — | |
| US1.5 Distant plate `TOO FAR` | ◐ | — | — | `test_capture_judge.gd`; `NO PLATE IN FRAME` seen live |
| US1.6 Timer to 00:00, results with score and four counts | ✓ | — | — | |
| US2.1 F1 pauses and lists every tunable | ✓ | — | — | |
| US2.2 `shift_length_sec` applies live | ✓ | — | — | Set to 5 and 10 mid-session |
| US2.3 Reset to defaults | ◐ | — | — | Session 2; `test_tuning_service.gd` |
| US2.4 New `@export` appears with no menu edit | ◐ | — | — | `test_debug_menu_enumeration.gd` |
| US2.5 Three-finger tap opens the menu on web | ◐ | — | — | `test_debug_trigger.gd`; not tapped on a device |
| US3.1 Varied sprites; light states by motion | ✓ | — | — | |
| US3.2 `show_plate_rects` overlays | ◐ | — | — | Session 3 |
| US3.3 Drop-in `car9` joins the rotation | ◐ | — | — | `test_vehicle_registry.gd` |
| US3.4 Backdrop slides on swerve, no edge | ◐ | — | — | Session 3 (lane alignment pass) |
| US4.1 Title: cue sheet, top 20, buttons, Quit hidden on web | ✓ | ✓ | — | Windows: title reached per log |
| US4.2 About / Settings; Music 0 persists | ✓ | — | — | Session 4; `test_settings_store.gd` |
| US5.1 Touch: joystick left gutter, button right, none over road | ✓ | — | — | Synthetic touch events in Chrome; wide and 16:9 windows |
| US5.2 Gamepad: stick moves box, A captures, no virtual controls | — | — | — | No gamepad on the dev machine |
| US6.1 Each SFX plays once; silent with files removed | ◐ | — | — | Placeholder set confirmed audible by Tim; `test_audio_cues.gd` for the missing case |
| US6.2 SFX 0, Music 1: music only | — | — | — | |
| US7.1 Configured project: rank shown, name on title top 20 | ✓ | — | — | `Global rank: #1`, row highlighted, title lists it |
| US7.2 `Ava1`, overlong, blocklisted refused inline | ✓ / ◐ | — | — | `Ava1` live; others `test_name_validator.gd` |
| US7.3 Skip submits as `Rookie` | ◐ | — | — | `test_results_leaderboard.gd` |
| US7.4 Offline: instant results, "leaderboard unavailable", local kept | ◐ | — | — | Exercised via a rejected insert (HTTP 400): note shown, local kept; true offline not toggled |
| Release web build ships placeholders visible and logged (FR-030b) | ✓ | ✓ | — | Startup log lists the three touch-control elements on both |

## Windows

Release export (`--export-release "Windows Desktop"`, embedded pck, 106 MB) launched
for 12 s: `[Leaderboard] config from leaderboard_config.local.tres (enabled)`,
`[ScreenHost] showing TitleScreen`, placeholder report present. Gameplay not driven
on Windows in this run.

## Android

Not run: no device or emulator on the dev machine. Owner: Tim, first MVP playtest.
Preset is landscape-locked and arm64; the touch scheme is the same code path as
the web build.

## Open items from this run

- US5.2 gamepad and US6.2 mixer isolation need a hands-on pass.
- US7.4 should be re-run with DevTools offline once before a convention.

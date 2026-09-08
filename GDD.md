# Traffic Fighter 3: Next Generation (TF3) — Game Design Document

**Version:** 1.0-draft (rebuild target — evolution of prototype v0.3 at
`C:/code/gamedev/robo_narc`)
**Engine:** Godot 4.x (GL Compatibility renderer)
**Genre:** Forward-scroller / reaction & judgment arcade

Changes from v0.3 in brief: art assets replace `_draw()` rendering (except the
capture box), touch + gamepad input, forced-landscape Android target, audio
piping with a settings/mixer menu, shared online leaderboard, About screen,
and composition-first architecture. The core game design (loop, violations,
scoring, run structure) is carried over intact.

---

## 1. Concept

You are the automated enforcement camera mounted on a city bus driving down its
route. Traffic appears at the **horizon** and rolls toward you as the bus moves
forward. Your job: move a **capture box** over the license plates of vehicles
committing violations and snap them — while leaving innocent drivers alone.

Real-world inspiration: NYC MTA's ACE (Automated Camera Enforcement) program,
where bus-mounted cameras capture plates of vehicles blocking bus lanes, bus
stops, and double parking. The game's **About screen** gives players this
elevator pitch — what the real system is and what it's meant to accomplish.

Design pillars (unchanged from prototype):

1. **Judgment, not labels** — violators are never highlighted. The player reads
   the scene the way a human reviewer would: where is the car, is it moving,
   what landmarks are next to it?
2. **Aim under pressure** — plates start tiny at the horizon and grow as they
   approach; you must judge early and capture in the readable window before the
   vehicle passes under the bus.
3. **Escalation** — the bus drives faster as the shift progresses, shrinking
   every judgment window.

## 2. Core Loop

Shift count-in (3-2-1 with countdown audio) → vehicle crests the horizon →
judge from context (position + motion + landmarks) → track it as it approaches
→ once the plate is close enough to read, frame it in the capture box → press
capture → receive points/penalty + audio feedback → repeat until the shift
timer expires → end-of-shift fanfare → results + leaderboard.

## 3. Platforms & Display

| Target | Notes |
|---|---|
| **Web** | No-threads export, runs on any static host (no cross-origin isolation headers). Web playability is a hard constraint — no feature may break it. |
| **Android** | **Forced landscape.** Includes gamepad support for Android-based handhelds. |
| **Desktop (Windows)** | Primary dev target. |

**Aspect handling:** the game keeps its native aspect ratio — **no stretch**.
On wider screens the letterbox space at the sides stays available and is
deliberately used on touch devices to host the virtual controls, keeping them
off the playfield.

## 4. Controls & Input

All gameplay input goes through Godot input actions (`move_*`, `capture`) —
no device-specific handling in gameplay code. Three input schemes:

| Scheme | Move capture box | Capture |
|---|---|---|
| **Keyboard** | W / A / S / D | Space |
| **Touch** (Android / web-mobile) | Virtual joystick (side gutter) | Single virtual button (opposite gutter) |
| **Gamepad** (Android handhelds, desktop) | Left stick / d-pad | Face button (A / Cross) |

- Virtual controls appear only when touch is the active input; they live in the
  letterbox gutters, not over the playfield.
- Capture has a short cooldown (~0.35 s). Plates farther than the readable
  distance refuse to capture ("TOO FAR — PLATE UNREADABLE") with no penalty —
  prevents sniping vehicles before their context is visible.
- Capture box size/speed may need per-scheme tuning (see §16); treat the
  keyboard values as the baseline.

## 5. Playfield & Perspective

First-person-ish view from the bus's camera. A horizon line sits in the upper
third; the road converges to a vanishing point. Objects live in *road space*
(lateral position + distance `z`) and are projected with true perspective
(`scale = C / (z + C)`), so vehicles start small at the horizon and grow as the
bus approaches. Passing vehicles slide under the bus overlay at the bottom of
the screen.

Road layout, left → right: median (decoration) · passing lane · bus/travel
lane (tinted) · bike lane (tinted, dashed separator) · parking lane/curb ·
sidewalk (landmarks: bus stop stripe, roadside props).

**Motion is information.** Everything fixed to the road (parked cars, paint,
the bus stop stripe, roadside assets) sweeps past at road speed. Vehicles that
are *driving* approach much more slowly. Parked-vs-moving is read from relative
motion, exactly as a human would.

### Bus driving behavior (carried from prototype)

- **Parked car in the bus lane** → the bus swerves into the passing lane (world
  shifts) and returns once past. The blocker is still a Bus Lane violation —
  capture it during the pass.
- **Moving car in the bus lane** → the bus brakes to match its speed; once
  close, the car merges out and the bus accelerates again. Merging cars are
  innocent. Passing/passed cars may **honk** (audio flavor, §11).

## 6. Vehicles & Visual Assets

Rendering moves from `_draw()` primitives to **imported art assets** — with one
deliberate exception: the **capture box remains drawn** (it is a camera reticle,
not a world object).

- **Vehicles:** rear-view sprites with **multiple imported variants** per
  archetype. Body color/variant is random and meaningless — never a violation
  cue.
- **Light states are load-bearing.** Each vehicle variant must support three
  taillight states, because they carry the parked/stopped/moving cue:
  - *Stopped in roadway* → bright brake lights
  - *Curb-parked* → lights off
  - *Moving* → dim taillights
  Implementation may be per-state frames or a light overlay layer, but the
  asset spec must guarantee all three states per variant.
- **No violation markings of any kind** on any vehicle.
- **Capture feedback:** captured vehicle's plate is visibly marked (green tint
  + "CAPTURED" tag or equivalent) — must work over sprite art.
- **Roadside assets:** imported props on the sidewalk/median strip that scroll
  with the road (they are road-fixed, so they also reinforce the motion cue).
  Bus stop stripe remains a distinct, readable landmark.
- **Bus overlay:** enhanced "I'm driving a bus" cab/hood frame replacing the
  drawn hood polygon.
- **UI:** proper fonts and a consistent theme across all screens.

## 7. Violations — Judged from Context

Violation status is **derived at capture time** by a rulebook
(`ViolationRules.evaluate`) from the vehicle's position, motion, and landmarks.
The spawner never labels anything; it only sets up situations. Rules in
evaluation order (first match wins):

| # | Situation | Verdict |
|---|---|---|
| 1 | Vehicle is moving | Innocent — normal traffic |
| 2 | Stationary in the bus/travel lane | **BUS LANE** violation |
| 3 | Stationary beside a curb-parked car (side by side) | **DOUBLE PARKING** |
| 4 | Stationary past the intrusion threshold into the bike lane | **BIKE LANE** violation |
| 5 | Stationary at the curb within a bus stop zone | **BUS STOP** violation |
| 6 | Anything else | Innocent |

Landmarks and tricky cases (carried from prototype): bus stop zone extent,
sloppy parker (under the intrusion threshold — innocent but tempting),
double-parking vs bike-lane distinction, driving-vs-stopped in the bus lane.

## 8. Scoring

| Event | Points | Audio |
|---|---|---|
| Correct capture (violator's plate fully in box) | **+100** | positive tone |
| Wrong capture (innocent vehicle captured) | **−50** | negative tone |
| Missed violation (violator passes uncaptured) | **−25** | sad tone |
| Empty capture / plate not readable yet | 0, cooldown wasted | shutter only |

A capture requires the **entire plate** inside the capture box and the vehicle
within readable distance. Each vehicle can be captured at most once; if several
plates are framed, the closest wins. Feedback text reveals the rulebook's
verdict, teaching the cues over time. Every capture attempt plays the camera
shutter sound.

## 9. Run Structure

- A run is one **timed shift: 90 seconds** (debug-adjustable), preceded by a
  **3-2-1 count-in** with countdown audio before control is handed to the
  player and spawning begins.
- Difficulty ramps during the shift: cruise speed rises (shrinking judgment
  windows) and spawn interval drops. Actual speed also dips when the bus
  brakes behind traffic.
- Misses are evaluated the moment a vehicle passes under the bus.
- Timer hits zero → end-of-shift "yay" sound → Game Finished screen with score
  + stats (correct / wrong / missed / empty), leaderboard standing, and options
  to replay or return to title.

## 10. Leaderboard

Local CSV scoreboard (prototype §8b) is replaced by a **shared online
leaderboard** backed by a hosted **Supabase** project, accessed via its REST
API through `HTTPRequest` (works identically from desktop, Android, and web —
Supabase's CORS headers permit browser calls, so the web build keeps working).

- **Submit** on shift end: score + stat breakdown + player identity.
- **Fetch** latest top scores for display on the title and results screens.
- **Offline / failed submit:** the game never blocks on the network. Scores
  are kept locally regardless; submission failures degrade silently to
  local-only display with a "leaderboard unavailable" note.
- **Integrity:** no anti-cheat. Scores are trivially forgeable and that is an
  accepted trade-off for this project's scope.
- **Player identity:** open question — see §17.

## 11. Audio

This version builds the **audio piping only** — bus layout, event hooks, and
mixing controls. Actual audio tracks are authored/added later; the spec must
not block on assets existing.

**Bus layout:** `Master` → `Music`, `SFX`.

**Event hooks (all routed through SFX unless noted):**

| Event | Sound |
|---|---|
| Shift count-in | countdown ticks (3-2-1) |
| Capture pressed | camera shutter |
| Correct capture | positive tone |
| Wrong capture | negative tone |
| Missed violation | sad tone |
| Passing / being passed by cars | honking |
| Shift end | ending "yay" |
| Background (Music bus) | gentle background music track, looped |

**Settings menu** (accessible from title screen, see §12): sliders for
**Master**, **Music**, and **SFX** volume, persisted across sessions.

## 12. Screens / Scene Flow

```
             ┌──About──┐   ┌─Settings─┐
             ▼         │   ▼          │
TitleScreen ─┴─────────┴───┴──────────┘
     │ Start
     ▼
 Count-in ──▶ Gameplay ──Timer ends──▶ GameOverScreen
     ▲                                      │
     └──────────── Play Again ──────────────┘
                (Title returns to TitleScreen)
```

1. **Title Screen** — game name/branding, cue cheat-sheet, Start, About,
   Settings, Quit; shows current leaderboard top scores.
2. **About** — promotional/informational screen: elevator pitch of the
   real-world ACE-style system this game is modeled on.
3. **Settings** — audio sliders (Master / Music / SFX); room to grow
   (input options later).
4. **Gameplay** — count-in, then horizon road, spawner, capture box, HUD
   (score, time, feedback), virtual controls on touch.
5. **Game Finished** — final score, stat breakdown, leaderboard standing,
   Play Again / Title.

## 13. Debug Menu

Carried from prototype: adjustable bus speeds, shift length, plate readable
distance; scoreboard/leaderboard reset (local); toggled with **F1** on
desktop, pauses gameplay when opened. Access on touch devices is an open
question (§17) — default assumption: available in debug builds only, absent
from release Android/web builds.

## 14. Architecture & Technical Design

**Principles (constitution-level):**

- **Composition first** — scene composition drives behavior wherever possible;
  scripts support, composition extends. Prefer child component nodes and
  signals over static mutable state and cross-scene reach-ins.
- **Small, well-named, single-purpose scripts** — more classes for specific
  tasks over bundled god-scripts.
- **Web compatibility is sacred** — no feature may require threads or
  cross-origin isolation.

**Carried design decisions:**

- **Road space & projection:** lane geometry + `project(road_x, z)` perspective
  mapping. Pure math — a static helper remains appropriate, but the prototype's
  mutable `Road.camera_x` static should become owned state (e.g. on the bus/
  camera node) passed into projection.
- **Judgment:** `ViolationRules` stays a pure, stateless rulebook — single
  source of truth for both capture verdicts and miss detection. The spawner
  assigns **no** violation labels.
- **Spawner:** weighted *situation* table (moving traffic, legal curb, sloppy
  parker, bike violator, bus lane blocker, double-park pair, bus stop zone).
  Landmark ownership/drawing coupling from the prototype should be dissolved
  into composed scene nodes.
- **Singletons:** keep autoloads minimal (prototype used exactly one,
  `GameState`); audio and settings persistence may justify one more, but
  default to scene-local composition.
- **Despawn:** z-based, two-phase (judge miss before free) so double-park
  pairs judge correctly.
- **Logging:** tagged, timestamped debug logging utility.

**Project config hygiene:** do not carry prototype cruft — drop the Jolt 3D
physics and D3D12 rendering-device settings (never used by this 2D game).

## 15. Asset Pipeline

- Assets live under an `assets/` tree (e.g. `assets/vehicles/`,
  `assets/roadside/`, `assets/ui/`, `assets/audio/`, `assets/fonts/`) with
  documented naming conventions so new variants can be dropped in without code
  changes.
- Vehicle variants are discovered/registered, not hard-coded — adding a new
  car sprite (with its three light states) should require no script edits.
- Import settings (filtering, compression) standardized for the GL
  Compatibility renderer and web build size.

## 16. Tuning Values (baseline, carried from prototype)

| Parameter | Value |
|---|---|
| Viewport | 1280 × 720 (native aspect kept, no stretch) |
| Shift length | 90 s (debug-adjustable) |
| Count-in | 3 s |
| Horizon y / bus screen y | 140 / 760 |
| Perspective constant C | 15 (scale = C / (z + C)) |
| Road depth Z_MAX | 100 units |
| Cruise speed | 14 → 26 units/s over the shift |
| Moving traffic speed | 45–65% of road speed at spawn |
| Spawn interval | 1.5 s → 0.9 s |
| Plate readable distance | z ≤ 30 (debug-adjustable) |
| Bike lane intrusion threshold | 60 px (road space) |
| Bus stop zone length | 20 units |
| Swerve / follow / merge triggers | z < 38 / 32 / 24 |
| Bus brake / accel | 16 / 6 units/s² |
| Lane change / merge lateral speed | 520 / 140 px/s (road space) |
| Capture box size / speed | 140 × 90 px / 420 px/s (keyboard baseline; per-scheme tuning expected) |
| Vehicle rear size | 90 × 76 px (at full scale) |

## 17. Open Questions

1. **Leaderboard identity** — arcade-style initials entered once and stored
   locally? Free-text name? Anonymous device ID with optional name?
2. **Debug menu on touch/release builds** — debug-builds-only (current
   assumption), or a hidden gesture?
3. **Honk trigger definition** — on every pass, probabilistic, or only for
   specific situations (e.g. the merging car honks)?
4. **Web-mobile touch** — is the touch scheme expected to work in mobile
   browsers too, or is touch officially Android-app-only?

## 18. Out of Scope / Future Work

- Curved road segments, intersections, richer tricky-innocent cases
- Vehicle animation beyond light states; screen shake on capture
- Object pooling; combo/streak multipliers
- Strike system or hybrid end conditions
- Review-queue mini-mechanic (human review of captures, like the real ACE
  program)
- Difficulty settings tuning readable distance and cue subtlety
- Authoring the actual audio tracks (piping is in scope, content is not)
- Input rebinding UI

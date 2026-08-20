# RoboNarc

An evolution of the RoboNarc prototype (original at `C:/code/gamedev/robo_narc`).

## The Game

You are the automated enforcement camera mounted on a city bus. Traffic crests the
horizon and rolls toward you as the bus drives its route. Your job: move a capture
box over the license plates of vehicles committing violations — blocking the bus
lane, double parking, sitting in the bike lane or a bus stop — and snap them, while
leaving innocent drivers alone.

Inspired by NYC MTA's ACE (Automated Camera Enforcement) program, where bus-mounted
cameras capture plates of vehicles blocking bus lanes and stops.

### Design Pillars (from the prototype)

1. **Judgment, not labels** — violators are never highlighted. The player reads the
   scene like a human reviewer: where is the car, is it moving, what landmarks are
   next to it?
2. **Aim under pressure** — plates start tiny at the horizon and grow as they
   approach; judge early, capture in the readable window.
3. **Escalation** — the bus drives faster as the shift progresses, shrinking every
   judgment window.

## The Prototype (v0.3)

The original is a working Godot 4.6.2 (GL Compatibility) prototype, GDScript, with:

- **Core loop**: pseudo-3D forward-scroller — road space (lateral x + distance z)
  projected with true perspective; WASD-driven capture box, Space to capture, 90 s
  timed shifts with ramping speed and spawn rate
- **Context-derived violations**: a `ViolationRules` rulebook evaluates position,
  motion, and landmarks at capture time — the spawner sets up *situations* (sloppy
  parkers, double-park pairs, bus stop zones) but never labels anything
- **Bus driving behavior**: the bus swerves around parked blockers and brakes/follows
  moving traffic, moving the whole projected world — motion itself is the tell for
  parked vs. driving
- **Scoring & persistence**: +100 correct / −50 wrong / −25 missed, CSV scoreboard
  with high scores and top-5 shifts
- **Supporting kit**: title/game-over screens, F1 debug menu with live tuning,
  tagged debug logging, preconfigured web export (no-threads build for static hosts)
- **Rendering**: all `_draw()` rectangles/polygons — no art assets yet

The prototype's `GDD.md` is the authoritative reference for mechanics, tuning
values, and its future-work list (sprite art, sound, combo multipliers, review-queue
mechanic, richer road furniture).

## Goals for This Version

### Art & Presentation

- **Real art assets instead of `_draw()` calls** — specifically for vehicles, with
  varying versions of each car to be imported. The plate capture box stays as-is
  (not an art asset)
- **Roadside assets** that scroll with the game world
- **Enhanced "I'm driving a bus" overlay** — a more convincing cab/hood frame
- **Fonts, general theming, and other UI polish tweaks**
- **Title screen promotional content** — including an "About" screen giving an
  elevator pitch of the real-world system this game is designed after (bus-mounted
  automated camera enforcement) and what it's meant to accomplish

### Input

- **Varied input support** — beyond the current keyboard-only WASD + Space:
  touch (virtual joystick + single virtual capture button in the letterbox
  gutters) and gamepad (for Android-based handhelds)

### Audio

- **Audio piping** (bus layout, event hooks, settings) — tracks authored later.
  Events: camera shutter, honks from passing cars, gentle background music,
  positive/negative capture tones, sad missed-capture tone, shift count-in
  ticks, end-of-shift "yay"
- **Settings menu** with Master / Music / SFX volume control

### Architecture & Code Style

- **More "Godot-style" composition** — let scene composition drive behavior as much
  as possible rather than pure scripting. Scripts help, but composition makes the
  game easier to extend
- **Better-named scripts, kept small** — favor more classes for specific tasks over
  bundling all functions into a single script

### Platforms & Services

- **Android playable build** alongside the existing desktop and web targets
- **Shared leaderboard** — something simple like a hosted Supabase project to store
  scores against and fetch the latest leaderboard from
- **Web playability preserved** — the Android and leaderboard work should not break
  the ability to play as a web game, if at all possible

## This Repo

Greenfield rebuild of the game, to be planned and built spec-first with
[github/spec-kit](https://github.com/spec-kit). Work is tracked in Jira under the
**ROB** project (RoboNarc).

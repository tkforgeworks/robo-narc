# Audio assets

Placeholder sounds are checked in as generated `.wav` files so every hook can be
heard during play-testing. Replace them by dropping an `.ogg` with the same base
name next to (or instead of) the `.wav`; `.ogg` wins when both exist. The game
resolves these files at startup and stays silent for any that are missing.

## `sfx/` (routed to the SFX bus)

| File | Event | Placeholder |
|------|-------|-------------|
| `count_in_tick` | each 3-2-1 count-in tick | high blip |
| `shutter` | every capture press | click |
| `capture_correct` | correct capture (positive tone) | rising two-note ding |
| `capture_wrong` | innocent vehicle captured (negative tone) | descending buzz |
| `miss` | violator passed uncaptured (sad tone) | slow slide down |
| `honk` | passing / being passed by traffic | two-tone horn |
| `shift_end` | shift timer reaches zero | four-note arpeggio |

## `music/` (routed to the Music bus)

| File | Use | Placeholder |
|------|-----|-------------|
| `background` | looped gameplay music | 8 s I-vi-IV-V loop at 120 bpm |

Volumes are controlled from the Settings screen (Master / Music / SFX). The debug
menu's "Play every SFX" action plays each cue in turn.
See `specs/001-robonarc-game/contracts/asset-conventions.md`.

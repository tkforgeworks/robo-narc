# Audio assets

No audio is authored yet. The game resolves these files at startup and stays silent
for any that are missing (no errors). Drop `.ogg` files in with these exact names.

## `sfx/` (routed to the SFX bus)

| File | Event |
|------|-------|
| `count_in_tick.ogg` | each 3-2-1 count-in tick |
| `shutter.ogg` | every capture press |
| `capture_correct.ogg` | correct capture (positive tone) |
| `capture_wrong.ogg` | innocent vehicle captured (negative tone) |
| `miss.ogg` | violator passed uncaptured (sad tone) |
| `honk.ogg` | passing / being passed by traffic |
| `shift_end.ogg` | shift timer reaches zero |

## `music/` (routed to the Music bus)

| File | Use |
|------|-----|
| `background.ogg` | looped gameplay music |

Volumes are controlled from the Settings screen (Master / Music / SFX).
See `specs/001-robonarc-game/contracts/asset-conventions.md`.

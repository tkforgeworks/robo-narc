# Missing art checklist

**Purpose**: Every element that renders the pink/black checkerboard placeholder
(spec FR-030b), where it appears in the release build, and what to drop in to
replace it. The game logs the same names at startup (`[Placeholder]`) and when
each element first appears, so this list and the log should always agree.
**Feature**: [spec.md](../spec.md) art asset inventory

Tick an item once the file is in place and the startup log no longer lists it.

## Visible in the release build

- [ ] **`touch joystick base`** — left gutter during gameplay when the last input
  was a touch. Drop `assets/ui/joystick-base.png` (square, transparent corners;
  drawn at 96 to 180 px). Logged at startup.
- [ ] **`touch joystick thumb`** — the stick's thumb, 45 % of the base size. Drop
  `assets/ui/joystick-thumb.png`. Logged at startup.
- [ ] **`touch capture button`** — right gutter during gameplay on touch. Drop
  `assets/ui/capture-button.png` (square; 96 to 140 px). Logged at startup.
- [x] **`bus cab overlay`** — the full-frame cab (top bar, transparent windshield,
  dashboard) stretched over the 1280 × 720 playfield during gameplay. Lives at
  `assets/ui/bus-overlay.png`; without it an 80 px placeholder strip is tiled along
  the bottom edge. Logged when the shift starts.
- [ ] **`license plate`** — the small rectangle on every vehicle's rear, placed and
  sized per body style by the `PlateArea` rectangle in `scenes/game/vehicles/<style>.tscn`. Drop
  `assets/vehicles/plate.png` (landscape plate, no text needed; the capture target
  is the rect, not the pixels). Logged at the first vehicle spawn.
- [x] **`bus stop shelter`** — a shelter sprite on the right curb at the far end of
  every bus stop zone, `bus_stop_height_px` tall at z = 0 and scaled with distance.
  Lives at `assets/roadside/bus-stop.png`. The zone's curb-lane rectangle is marked by
  generated yellow hazard stripes (`bus_stop_marking_opacity`); no art slot.
- [x] **`median`** — no longer a slot. The ground beyond the road tile is a flat colour;
  widen the margin in `tools/build_road_tile.gd` to paint more of it.

- [x] **`studio logo`** — the studio splash card, fitted inside 512 by 256 px
  centred on a near-black background. Lives at `assets/ui/logo.png`.

## Not drawn at all yet (no placeholder)

- [ ] Roadside props other than buildings (signs, trees, hydrants). Optional; there
  is no hook drawn for them. A `BuildingStrip`-style scanner over
  `assets/roadside/props/` would be the natural home.
- [ ] Fonts, UI theme, title branding, About screen imagery. Text-only theme in
  `assets/ui/theme.tres` today.

## Placeholder sound

- [ ] All seven SFX and the music loop are generated `.wav` placeholders. Replace by
  dropping an `.ogg` with the same base name (`assets/audio/README.md`); the `.ogg`
  wins when both exist.

## Not art

- `assets/ui/placeholder.png` is the checkerboard itself and stays.
- The capture box is a drawn reticle by design (FR-027).
- Taillight states are a shader over the sprite, not separate art.

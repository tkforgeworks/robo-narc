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
- [ ] **`bus cab overlay`** — the strip across the bottom of the playfield during
  gameplay, `bus_overlay_height_px` tall (tunable) by 1280 wide. Drop
  `assets/overlays/bus-cab.png`; it is stretched to that size. Logged when the
  shift starts.
- [ ] **`license plate`** — the small rectangle on every vehicle's rear, placed and
  sized per body style by the `PlateArea` rectangle in `scenes/game/vehicles/<style>.tscn`. Drop
  `assets/vehicles/plate.png` (landscape plate, no text needed; the capture target
  is the rect, not the pixels). Logged at the first vehicle spawn.
- [ ] **`bus stop stripe`** — the curb-side marker for a bus stop zone, scrolling
  with the road. Drop `assets/road/stencil-bus-stop.png` in the same pre-sheared
  style as the bus-lane and bike-lane stencils. Logged when the shift starts.
- [ ] **`median`** — the decoration strip left of the road, scrolling with it. Drop
  `assets/road/median.png` (tileable vertically). Logged when the shift starts.

- [ ] **`studio logo`** — the splash card before the title, up to 512 by 512 px
  centred on a near-black background. Drop `assets/ui/logo.png`. Logged at startup.

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

# Contract: Asset Conventions

Folder layout under `assets/` and the discovery rules that make "drop in a file" the
whole change (FR-026). Placeholder rule: any element with no asset uses
`assets/ui/placeholder.png` (a 64 × 64 pink/black checkerboard; `PlaceholderTexture`
also generates it at runtime if the file is missing) sized to the element.

## Layout

```text
assets/
├── vehicles/
│   └── <style>/                # style key = folder name, ^[a-z0-9_]+$
│       ├── <style>-<color>.png # one per color; color = ^[a-z]+$
│       └── <style>-<color>.svg # optional source, ignored by discovery
├── roadside/
│   └── buildings/
│       ├── left/building<N>-left.png
│       └── right/building<N>-right.png
├── road/
│   ├── backdrop.png            # sky + road (2732 × 1235), reference only
│   ├── sky.png                 # static sky layer (used by RoadView)
│   ├── road.png                # transparent road layer, sheared on swerves (used by RoadView)
│   ├── stencil-bus-lane.png
│   ├── stencil-bike-lane.png
│   ├── bus-stop-stripe.png     # MISSING → placeholder
│   └── median.png              # MISSING → placeholder
├── overlays/
│   ├── bus-cab.png             # MISSING → placeholder
│   └── plate.png               # MISSING → placeholder
├── ui/
│   ├── placeholder.png
│   ├── fonts/                  # MISSING → engine fallback font
│   ├── theme.tres              # MISSING → default theme
│   ├── joystick-base.png, joystick-thumb.png, capture-button.png  # MISSING → placeholder
│   └── about/                  # MISSING → text only
└── audio/
    ├── music/background.ogg    # placeholder .wav shipped → replace
    └── sfx/<event>.ogg         # placeholder .wav shipped → replace; event names below
```

Migration from the current `Assets/` tree:

| From | To |
|------|----|
| `Assets/Cars/Car N/carN-<color>.png` | `assets/vehicles/carN/carN-<color>.png` |
| `Assets/Buildings/Left/buildingN-left.png` | `assets/roadside/buildings/left/buildingN-left.png` |
| `Assets/Buildings/Right/buildingN-right.png` | `assets/roadside/buildings/right/buildingN-right.png` |
| `Assets/Background and Road/HAI_26_8_Videogame_Background+Road.png` | `assets/road/backdrop.png` |
| `Assets/Background and Road/HAI_26_8_Videogame_Background.png` | `assets/road/sky.png` |
| `Assets/Background and Road/HAI_26_8_Videogame_Road.png` | `assets/road/road.png` |
| `Assets/Background and Road/bus-lane.png` | `assets/road/stencil-bus-lane.png` |
| `Assets/Background and Road/bike-lane.png` | `assets/road/stencil-bike-lane.png` |

## Discovery rules

- `VehicleRegistry` lists `assets/vehicles/*/`; each subfolder is a style. Textures
  are every `<style>-<color>.png` in it (`.png.import` entries in exports are
  normalized). A style with zero textures is skipped with a warning.
- Style data comes from `data/game/vehicle_styles/<style>.tres`; absent → default
  `VehicleStyle` (plate rect centred at 45%–55% width, 78%–86% height; light rects
  at the lower outer corners) plus a logged warning.
- `BuildingStrip` lists `assets/roadside/buildings/<side>/*.png` and cycles them in
  a shuffled order; count is not hard-coded.
- Audio hooks resolve `assets/audio/sfx/<event>.ogg`, then `<event>.wav`, at
  startup; a missing file leaves the hook `null` and `AudioCues.play(event)` is a
  no-op. Generated placeholder `.wav` files ship until real `.ogg` art exists; an
  `.ogg` beside a `.wav` wins.

## SFX event names

`count_in_tick`, `shutter`, `capture_correct`, `capture_wrong`, `miss`, `honk`,
`shift_end`. Music: `assets/audio/music/background.ogg` (looped).

## Import settings

PNG: lossless, mipmaps off, filter on, no VRAM compression (`for_desktop=false`,
`for_mobile=false` in the web preset) so the web bundle size is predictable.
Buildings and vehicles keep their source resolution; scaling happens in perspective.

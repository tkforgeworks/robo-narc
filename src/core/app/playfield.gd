class_name Playfield
extends RefCounted
## The fixed 1280 x 720 design area. The project stretches with aspect "expand",
## so a wider or taller window grows the visible viewport instead of scaling;
## fixed-size screens centre the playfield in it and the remainder forms the
## gutters (spec FR-030) that hold the touch controls.

const BASE := Vector2(1280.0, 720.0)


## Top-left of the centred playfield inside `viewport`, in viewport pixels.
static func offset(viewport: Viewport) -> Vector2:
	return offset_for(viewport.get_visible_rect().size)


static func offset_for(visible_size: Vector2) -> Vector2:
	return ((visible_size - BASE) * 0.5).max(Vector2.ZERO).floor()


static func rect(viewport: Viewport) -> Rect2:
	return Rect2(offset(viewport), BASE)


## Width of one side gutter; zero at 16:9 or narrower.
static func gutter_width_for(visible_size: Vector2) -> float:
	return offset_for(visible_size).x

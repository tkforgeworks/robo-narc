class_name PlateOverlay
extends Sprite2D
## The shared license plate composited onto every vehicle, placed by the
## body style's normalized plate_rect. Its screen rect is the capture target.

const PLATE_PATH := "res://assets/overlays/plate.png"


## Positions and scales this overlay over `body` (a non-centred Sprite2D whose
## offset puts the vehicle origin at the rear bumper).
func apply(style: VehicleStyle, body: Sprite2D) -> void:
	if texture == null:
		texture = load(PLATE_PATH) if ResourceLoader.exists(PLATE_PATH) \
				else PlaceholderTexture.register_use("license plate")
	centered = false
	var body_size := Vector2(body.texture.get_size()) * body.scale
	var body_origin := body.offset * body.scale
	var rect := Rect2(body_origin + style.plate_rect.position * body_size,
			style.plate_rect.size * body_size)
	position = rect.position
	scale = rect.size / Vector2(texture.get_size())


## Axis-aligned screen rect (no rotation in this game).
func screen_rect() -> Rect2:
	return Rect2(global_position, Vector2(texture.get_size()) * get_global_scale())

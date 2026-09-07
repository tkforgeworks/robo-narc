class_name VehicleStyle
extends Resource
## Per-body-style data: where the plate overlay and taillight regions sit on
## the sprite (normalized 0..1 rects, tunable live) and the textures for each
## color variant (filled at runtime by VehicleRegistry).

## Folder name under assets/vehicles/, e.g. "car1".
@export var key: String = ""
@export var plate_rect: Rect2 = Rect2(0.45, 0.78, 0.10, 0.08)
@export var left_light_rect: Rect2 = Rect2(0.06, 0.60, 0.10, 0.10)
@export var right_light_rect: Rect2 = Rect2(0.84, 0.60, 0.10, 0.10)
@export_range(40.0, 200.0, 1.0) var rear_width_px: float = 90.0

## One texture per color variant; not saved with the resource.
var textures: Array[Texture2D] = []


static func make_default(p_key: String) -> VehicleStyle:
	var style := VehicleStyle.new()
	style.key = p_key
	return style


func has_textures() -> bool:
	return not textures.is_empty()


func texture_at(color_index: int) -> Texture2D:
	if textures.is_empty():
		return null
	return textures[posmod(color_index, textures.size())]

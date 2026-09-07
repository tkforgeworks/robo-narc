class_name VehicleStyle
extends Resource
## Per-body-style data: the taillight regions for the lighting shader
## (normalized 0..1 rects, tunable live) plus what the registry discovers at
## runtime: the colour textures and the style's authored scene. Plate placement
## and body size live in that scene (scenes/game/vehicles/<key>.tscn).

## Folder name under assets/vehicles/, e.g. "car1".
@export var key: String = ""
@export var left_light_rect: Rect2 = Rect2(0.06, 0.60, 0.10, 0.10)
@export var right_light_rect: Rect2 = Rect2(0.84, 0.60, 0.10, 0.10)

## One texture per color variant; not saved with the resource.
var textures: Array[Texture2D] = []
## The style's vehicle scene; null falls back to the base vehicle.tscn.
var scene: PackedScene = null


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

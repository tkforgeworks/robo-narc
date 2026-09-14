class_name BusOverlay
extends TextureRect
## The "you are driving a bus" cab frame: a top bar and a dashboard with a
## transparent windshield between them, stretched over the whole playfield.
## Uses assets/ui/bus-overlay.png when it exists, else a placeholder strip
## along the bottom edge.

const ART_PATH := "res://assets/ui/bus-overlay.png"
const PLACEHOLDER_HEIGHT_PX := 80.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(ART_PATH):
		texture = load(ART_PATH)
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_SCALE
		size = Playfield.BASE
		position = Vector2.ZERO
	else:
		texture = PlaceholderTexture.register_use("bus cab overlay")
		stretch_mode = TextureRect.STRETCH_TILE
		size = Vector2(Playfield.BASE.x, PLACEHOLDER_HEIGHT_PX)
		position = Vector2(0.0, Playfield.BASE.y - size.y)

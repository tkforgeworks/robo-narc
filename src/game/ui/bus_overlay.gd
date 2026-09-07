class_name BusOverlay
extends TextureRect
## The "you are driving a bus" cab/hood frame across the bottom of the screen.
## Uses assets/overlays/bus-cab.png when it exists, else the placeholder.

const CAB_PATH := "res://assets/overlays/bus-cab.png"

var config: TuningConfig


func _ready() -> void:
	if config == null:
		config = Tuning.config
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(CAB_PATH):
		texture = load(CAB_PATH)
		stretch_mode = TextureRect.STRETCH_SCALE
	else:
		texture = PlaceholderTexture.register_use("bus cab overlay")
		stretch_mode = TextureRect.STRETCH_TILE
	_layout()


func _process(_delta: float) -> void:
	if not is_equal_approx(size.y, config.bus_overlay_height_px):
		_layout()


func _layout() -> void:
	var viewport := get_viewport_rect().size
	size = Vector2(viewport.x, config.bus_overlay_height_px)
	position = Vector2(0.0, viewport.y - size.y)

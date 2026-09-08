class_name Letterbox
extends CanvasLayer
## Paints the gutters around the centred playfield so fixed-size screens keep
## their frame on wide or tall windows. Main shows it only for such screens;
## menu screens are responsive Controls and fill the window instead.

const COLOR := Color.BLACK
const SIDES := 4

var _bars: Array[ColorRect] = []


func _ready() -> void:
	for i in SIDES:
		var bar := ColorRect.new()
		bar.color = COLOR
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		_bars.append(bar)
	get_viewport().size_changed.connect(_layout)
	_layout()


func bar_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for bar in _bars:
		rects.append(Rect2(bar.position, bar.size) if bar.visible else Rect2())
	return rects


func _layout() -> void:
	layout_for(get_viewport().get_visible_rect().size)


## Sizes the left, right, top, and bottom bars for `visible_size`; public for tests.
func layout_for(visible_size: Vector2) -> void:
	var field := Rect2(Playfield.offset_for(visible_size), Playfield.BASE)
	var rects: Array[Rect2] = [
		Rect2(0.0, 0.0, field.position.x, visible_size.y),
		Rect2(field.end.x, 0.0, visible_size.x - field.end.x, visible_size.y),
		Rect2(field.position.x, 0.0, field.size.x, field.position.y),
		Rect2(field.position.x, field.end.y, field.size.x, visible_size.y - field.end.y),
	]
	for i in SIDES:
		_bars[i].position = rects[i].position
		_bars[i].size = rects[i].size
		_bars[i].visible = rects[i].size.x > 0.0 and rects[i].size.y > 0.0

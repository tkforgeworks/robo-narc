class_name TouchControls
extends CanvasLayer
## Places the virtual joystick in the left gutter and the capture button in the
## right one whenever touch is the active input on a playfield screen (spec
## FR-033). Gutters narrower than `touch_gutter_min_px` (a 16:9 window has none)
## fall back to a faded overlay on the playfield edges.

const MARGIN := 16.0
const JOYSTICK_MAX := 180.0
const BUTTON_MAX := 140.0
const CONTROL_MIN := 96.0
const VERTICAL_ANCHOR := 0.58
const OVERLAY_ALPHA := 0.45

var config: TuningConfig
var source: InputSource.Source = InputSource.Source.KEYBOARD
var playfield_active: bool = false
## True when the last layout put the controls in real gutters.
var in_gutters: bool = false

@onready var joystick: VirtualJoystick = $Joystick
@onready var button: VirtualButton = $Button


func _ready() -> void:
	if config == null:
		config = Tuning.config
	get_viewport().size_changed.connect(_layout)
	_layout()
	_update_visibility()


func bind_input_source(input_source: InputSource) -> void:
	source = input_source.source
	input_source.source_changed.connect(func(s: InputSource.Source) -> void:
		source = s
		_update_visibility())
	_update_visibility()


func bind_tuning(tuning: TuningService) -> void:
	tuning.changed.connect(func(property_name: String) -> void:
		if property_name == "touch_gutter_min_px":
			_layout())
	tuning.reset.connect(_layout)


## Main calls this on every screen change; only fixed-playfield screens show controls.
func set_playfield_active(active: bool) -> void:
	playfield_active = active
	_update_visibility()


func _update_visibility() -> void:
	var show := playfield_active and source == InputSource.Source.TOUCH
	if not show:
		joystick.release()
		button.release()
	visible = show


func _layout() -> void:
	layout_for(get_viewport().get_visible_rect().size)


## Positions both controls for a viewport of `visible_size`; public for tests.
func layout_for(visible_size: Vector2) -> void:
	var gutter := Playfield.gutter_width_for(visible_size)
	in_gutters = gutter >= maxf(config.touch_gutter_min_px, CONTROL_MIN)
	var joy := _fit(JOYSTICK_MAX, gutter)
	var btn := _fit(BUTTON_MAX, gutter)
	joystick.size = Vector2(joy, joy)
	button.size = Vector2(btn, btn)
	var field := Playfield.offset_for(visible_size)
	var y := field.y + Playfield.BASE.y * VERTICAL_ANCHOR
	if in_gutters:
		joystick.position = Vector2((gutter - joy) * 0.5, y - joy * 0.5)
		button.position = Vector2(visible_size.x - gutter + (gutter - btn) * 0.5, y - btn * 0.5)
	else:
		joystick.position = field + Vector2(MARGIN, y - joy * 0.5)
		button.position = field + Vector2(Playfield.BASE.x - btn - MARGIN, y - btn * 0.5)
	var alpha := 1.0 if in_gutters else OVERLAY_ALPHA
	joystick.modulate.a = alpha
	button.modulate.a = alpha


## Control edge that fits the gutter with margins, or the full size in overlay mode.
func _fit(max_size: float, gutter: float) -> float:
	if not in_gutters:
		return max_size
	return clampf(gutter - 2.0 * MARGIN, CONTROL_MIN, max_size)

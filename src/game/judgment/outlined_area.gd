class_name OutlinedArea
extends Area2D
## Base for every detection area in the game: an Area2D that draws its own
## shapes while the `show_collision_shapes` tunable is on, so the whole layout
## can be inspected in play with the art hidden (`hide_sprites`).

@export var outline_color: Color = Color(0.3, 1.0, 0.6)

var config: TuningConfig

var _shown: bool = false


func _ready() -> void:
	if config == null and not Engine.is_editor_hint():
		config = Tuning.config


func _process(_delta: float) -> void:
	if config == null:
		return
	if config.show_collision_shapes != _shown:
		_shown = config.show_collision_shapes
		queue_redraw()


func _draw() -> void:
	if _shown:
		DebugShapes.draw_outline(self, outline_color)

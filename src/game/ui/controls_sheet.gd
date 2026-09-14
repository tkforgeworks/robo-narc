class_name ControlsSheet
extends VBoxContainer
## The controls list: one row per action, binding on the left (read live from
## the InputMap through ControlBindings) and what it does on the right. Used by
## the pause menu, the controls overlay, and the Controls screen.

const ACTIONS: Array[Array] = [
	["move_up", "Move the camera up"],
	["move_down", "Move the camera down"],
	["move_left", "Move the camera left"],
	["move_right", "Move the camera right"],
	["capture", "Take the photo"],
	["pause", "Pause the shift"],
]

var _grid: GridContainer


func _ready() -> void:
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 28)
	_grid.add_theme_constant_override("v_separation", 6)
	add_child(_grid)
	for row in ACTIONS:
		var key := Label.new()
		key.text = ControlBindings.describe(row[0])
		key.theme_type_variation = &"ControlKey"
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(key)
		var what := Label.new()
		what.text = row[1]
		what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(what)


func row_count() -> int:
	return ACTIONS.size()


## Binding text shown on row `index` (for tests).
func binding_text(index: int) -> String:
	return (_grid.get_child(index * 2) as Label).text

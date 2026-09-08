class_name TunableControlFactory
extends RefCounted
## Builds an edit control for one exported property, from its property
## dictionary alone. This is what lets the debug menu show a new tunable with
## zero menu edits (constitution IV).

signal value_committed(property_name: String, value: Variant)

const SPIN_WIDTH := 120.0


func build(object: Object, property: Dictionary) -> Control:
	var property_name: String = property["name"]
	var value: Variant = object.get(property_name)
	match int(property["type"]):
		TYPE_INT, TYPE_FLOAT:
			return _number(property_name, value, property)
		TYPE_BOOL:
			return _toggle(property_name, value)
		TYPE_VECTOR2:
			var v := value as Vector2
			return _composite(property_name, ["x", "y"], [v.x, v.y],
					func(p: Array) -> Variant: return Vector2(p[0], p[1]))
		TYPE_RECT2:
			var r := value as Rect2
			return _composite(property_name, ["x", "y", "w", "h"],
					[r.position.x, r.position.y, r.size.x, r.size.y],
					func(p: Array) -> Variant: return Rect2(p[0], p[1], p[2], p[3]))
		TYPE_COLOR:
			return _color(property_name, value)
		TYPE_STRING:
			return _text(property_name, value)
	var label := Label.new()
	label.text = "(unsupported %s)" % type_string(int(property["type"]))
	return label


## {min, max, step} from an `@export_range` hint, or permissive defaults.
static func parse_range(property: Dictionary) -> Dictionary:
	var is_int := int(property["type"]) == TYPE_INT
	var result := {"min": -1.0e9, "max": 1.0e9, "step": 1.0 if is_int else 0.01}
	if int(property["hint"]) != PROPERTY_HINT_RANGE:
		return result
	var parts: PackedStringArray = str(property["hint_string"]).split(",")
	if parts.size() >= 2:
		result["min"] = float(parts[0])
		result["max"] = float(parts[1])
	if parts.size() >= 3 and parts[2].is_valid_float():
		result["step"] = float(parts[2])
	return result


func _number(property_name: String, value: Variant, property: Dictionary) -> SpinBox:
	var is_int := int(property["type"]) == TYPE_INT
	var range_info := parse_range(property)
	var spin := SpinBox.new()
	spin.min_value = range_info["min"]
	spin.max_value = range_info["max"]
	spin.step = range_info["step"]
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.rounded = is_int
	spin.custom_minimum_size.x = SPIN_WIDTH
	spin.value = value
	spin.value_changed.connect(func(v: float) -> void:
		value_committed.emit(property_name, int(v) if is_int else v))
	return spin


func _toggle(property_name: String, value: Variant) -> CheckBox:
	var box := CheckBox.new()
	box.button_pressed = bool(value)
	box.toggled.connect(func(on: bool) -> void: value_committed.emit(property_name, on))
	return box


func _composite(property_name: String, labels: Array, values: Array,
		assemble: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var spins: Array[SpinBox] = []
	var normalized := values.all(func(v: float) -> bool: return absf(v) <= 1.0)
	for i in labels.size():
		var label := Label.new()
		label.text = labels[i]
		row.add_child(label)
		var spin := SpinBox.new()
		spin.min_value = -1.0e9
		spin.max_value = 1.0e9
		spin.step = 0.005 if normalized else 1.0
		spin.custom_minimum_size.x = SPIN_WIDTH * 0.8
		spin.value = values[i]
		row.add_child(spin)
		spins.append(spin)
	for spin in spins:
		spin.value_changed.connect(func(_v: float) -> void:
			var parts: Array = []
			for s in spins:
				parts.append(s.value)
			value_committed.emit(property_name, assemble.call(parts)))
	return row


func _color(property_name: String, value: Variant) -> ColorPickerButton:
	var button := ColorPickerButton.new()
	button.color = value
	button.custom_minimum_size.x = SPIN_WIDTH
	button.color_changed.connect(func(c: Color) -> void: value_committed.emit(property_name, c))
	return button


func _text(property_name: String, value: Variant) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = str(value)
	edit.custom_minimum_size.x = SPIN_WIDTH * 1.5
	edit.text_submitted.connect(func(t: String) -> void: value_committed.emit(property_name, t))
	edit.focus_exited.connect(func() -> void: value_committed.emit(property_name, edit.text))
	return edit

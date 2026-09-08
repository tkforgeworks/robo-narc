class_name DebugSectionBuilder
extends RefCounted
## Builds the labelled grids the debug menu shows: one per tunable group or
## style (through TunableControlFactory) and the live-volume sliders. Owns no
## state beyond the container it fills.

const HEADING_FONT_SIZE := 20
const SLIDER_WIDTH := 200.0
const TEXT_BOX_HEIGHT := 120.0

var _container: Container


func _init(container: Container) -> void:
	_container = container


func clear() -> void:
	for child in _container.get_children():
		child.free()


## One label + control row per property; `on_commit(name, value)` on change.
func add_tunables(title: String, object: Object, properties: Array, on_commit: Callable) -> void:
	_add_heading(title)
	var grid := _new_grid()
	var factory := TunableControlFactory.new()
	factory.value_committed.connect(on_commit)
	for property: Dictionary in properties:
		grid.add_child(_label(property["name"]))
		grid.add_child(factory.build(object, property))
	grid.set_meta("factory", factory)
	_container.add_child(grid)


## A 0..1 slider per bus that writes through to `settings` and then calls
## `on_change(bus, value)`.
func add_volume(title: String, buses: PackedStringArray, settings: SettingsStore,
		on_change: Callable) -> void:
	_add_heading(title)
	var grid := _new_grid()
	for bus in buses:
		grid.add_child(_label(bus))
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.custom_minimum_size.x = SLIDER_WIDTH
		slider.value = settings.get(bus)
		slider.value_changed.connect(func(v: float) -> void:
			settings.set(bus, v)
			settings.save()
			on_change.call(bus, v))
		grid.add_child(slider)
	_container.add_child(grid)


## A read-only, selectable text block (for exports the operator copies by hand).
func add_text(title: String, text: String) -> void:
	_add_heading(title)
	var box := TextEdit.new()
	box.text = text
	box.editable = false
	box.custom_minimum_size = Vector2(0.0, TEXT_BOX_HEIGHT)
	box.scroll_fit_content_height = true
	_container.add_child(box)


## Number of label/control pairs across every grid built.
func control_count() -> int:
	var count := 0
	for section in _container.get_children():
		if section is GridContainer:
			count += section.get_child_count() / 2
	return count


func _new_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	return grid


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _add_heading(text: String) -> void:
	var heading := Label.new()
	heading.text = text
	heading.add_theme_font_size_override("font_size", HEADING_FONT_SIZE)
	_container.add_child(heading)

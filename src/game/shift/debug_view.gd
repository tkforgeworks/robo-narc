class_name DebugView
extends Node
## Applies the `hide_sprites` debug tunable: art off, detection areas and HUD
## stay, so the layout can be inspected in play. `show_collision_shapes` is
## read by every OutlinedArea itself.

var config: TuningConfig

var _art_nodes: Array = []


func _ready() -> void:
	if config == null:
		config = Tuning.config
	if config == Tuning.config:
		Tuning.changed.connect(func(property_name: String) -> void:
			if property_name == "hide_sprites":
				apply())
		Tuning.reset.connect(apply)


## `road_view` and `bus_overlay` are hidden outright; the layer and zones keep
## their areas and drop only their art.
func bind(road_view: CanvasItem, vehicle_layer: VehicleLayer, zones: BusStopZones,
		bus_overlay: CanvasItem) -> void:
	_art_nodes = [road_view, vehicle_layer, zones, bus_overlay]
	apply()


func apply() -> void:
	if _art_nodes.is_empty():
		return
	var art := not config.hide_sprites
	(_art_nodes[0] as CanvasItem).visible = art
	(_art_nodes[1] as VehicleLayer).art_visible = art
	(_art_nodes[2] as BusStopZones).art_visible = art
	(_art_nodes[3] as CanvasItem).visible = art

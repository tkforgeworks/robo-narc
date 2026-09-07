class_name RoadAreas
extends Node2D
## The lane areas, one LaneArea child per lane authored in road_areas.tscn.
## Follows the bus's lateral position so the trapezoids stay under the art,
## and rebuilds when a lane or perspective tunable changes.

const REBUILD_ON: PackedStringArray = ["horizon_y", "bus_screen_y", "vanishing_point_x",
		"perspective_c", "z_max"]

var config: TuningConfig
var lanes: Array[LaneArea] = []


## Children read `config` in their own _ready, which runs before ours.
func _enter_tree() -> void:
	if config == null:
		config = Tuning.config
	for child in get_children():
		if child is LaneArea:
			(child as LaneArea).config = config
			lanes.append(child)


func _ready() -> void:
	if config == Tuning.config:
		Tuning.changed.connect(func(property_name: String) -> void:
			if property_name.begins_with("lane_") or property_name.begins_with("road_edge") \
					or REBUILD_ON.has(property_name):
				rebuild())
		Tuning.reset.connect(rebuild)


func set_camera_x(camera_x: float) -> void:
	for lane in lanes:
		lane.set_camera_x(camera_x)


func rebuild() -> void:
	for lane in lanes:
		lane.rebuild()


func lane_area(lane: RoadGeometry.Lane) -> LaneArea:
	for area in lanes:
		if area.lane == lane:
			return area
	return null

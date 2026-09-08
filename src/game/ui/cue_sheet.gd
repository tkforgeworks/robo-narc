class_name CueSheet
extends VBoxContainer
## The title-screen cheat sheet: one line per violation plus the taillight
## cue. Rows are data so the wording can be tuned in one place.

const ROWS: Array[Array] = [
	["BUS LANE", "stopped in the red bus lane"],
	["DOUBLE PARKING", "stopped beside a parked car"],
	["BIKE LANE", "parked over the green bike lane"],
	["BUS STOP", "parked on the bus stop stripe"],
]
const LIGHT_CUE := "Bright brake lights = stopped in the road.  Lights off = parked.  Dim = moving (innocent)."
const HEADING := "WHO TO SNAP"


func _ready() -> void:
	if get_child_count() > 0:
		return
	var heading := Label.new()
	heading.text = HEADING
	heading.add_theme_font_size_override("font_size", 22)
	add_child(heading)
	for row in ROWS:
		var line := Label.new()
		line.text = "%s  —  %s" % [row[0], row[1]]
		add_child(line)
	var lights := Label.new()
	lights.text = LIGHT_CUE
	lights.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lights.add_theme_font_size_override("font_size", 15)
	add_child(lights)


func row_count() -> int:
	return ROWS.size()

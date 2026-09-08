class_name FeedbackBanner
extends Label
## One-line verdict feedback that fades out over feedback_time_sec. Colour
## follows the score delta: green for points, red for a wrong capture, orange
## for a miss, grey for a no-score outcome.

const COLOR_GOOD := Color(0.3, 1.0, 0.4)
const COLOR_BAD := Color(1.0, 0.3, 0.3)
const COLOR_MISS := Color(1.0, 0.55, 0.2)
const COLOR_NEUTRAL := Color(0.75, 0.75, 0.75)

var config: TuningConfig

var _time_left: float = 0.0


func _ready() -> void:
	if config == null:
		config = Tuning.config
	text = ""
	modulate.a = 0.0


func show_text(message: String, color: Color) -> void:
	text = message
	add_theme_color_override("font_color", color)
	modulate.a = 1.0
	_time_left = config.feedback_time_sec


## ScoreKeeper feedback, coloured by what happened.
func show_score_feedback(message: String, delta: int) -> void:
	if message.is_empty():
		return
	show_text(message, color_for(message, delta))


static func color_for(message: String, delta: int) -> Color:
	if delta > 0:
		return COLOR_GOOD
	if message.contains("MISSED"):
		return COLOR_MISS
	if delta < 0:
		return COLOR_BAD
	return COLOR_NEUTRAL


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	modulate.a = clampf(_time_left / (config.feedback_time_sec * 0.5), 0.0, 1.0)

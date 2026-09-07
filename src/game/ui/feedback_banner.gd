class_name FeedbackBanner
extends Label
## One-line verdict feedback that fades out over feedback_time_sec.

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


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	modulate.a = clampf(_time_left / (config.feedback_time_sec * 0.5), 0.0, 1.0)

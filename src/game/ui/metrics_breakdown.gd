class_name MetricsBreakdown
extends GridContainer
## Precision / Recall / F1 for the shift, beside the count table on the
## results screen: how the player compares to a detection model.


func show_result(result: ShiftResult) -> void:
	for child in get_children():
		child.queue_free()
	for row: Array in [["Precision", result.precision()], ["Recall", result.recall()], ["F1", result.f1()]]:
		var name := Label.new()
		name.text = str(row[0])
		add_child(name)
		var value := Label.new()
		value.text = F1Score.format(row[1])
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(value)

class_name ScoreBreakdown
extends GridContainer
## The four-row count table on the results screen.

const ROWS: Array[Array] = [["Correct", "correct"], ["Wrong", "wrong"],
		["Missed", "missed"], ["Empty", "empty"]]


func show_result(result: ShiftResult) -> void:
	for child in get_children():
		child.queue_free()
	for row: Array in ROWS:
		var name := Label.new()
		name.text = str(row[0])
		add_child(name)
		var value := Label.new()
		value.text = str(result.get(row[1]))
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(value)

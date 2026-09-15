class_name F1Score
extends RefCounted
## Precision, recall, and F1 for a shift, the way a detection model is graded:
## true positives are correct captures, false positives are wrong and empty
## captures, false negatives are violators that got away (passed uncaptured,
## or still inside capture range when the clock ran out). Undefined ratios
## (nothing captured, nothing to capture) score 0.


static func precision(tp: int, fp: int) -> float:
	return 0.0 if tp + fp == 0 else float(tp) / float(tp + fp)


static func recall(tp: int, fn: int) -> float:
	return 0.0 if tp + fn == 0 else float(tp) / float(tp + fn)


static func f1(tp: int, fp: int, fn: int) -> float:
	var p := precision(tp, fp)
	var r := recall(tp, fn)
	return 0.0 if p + r == 0.0 else 2.0 * (p * r) / (p + r)


## "0.87" style text; negative (unknown) shows as a dash.
static func format(value: float) -> String:
	return "-" if value < 0.0 else "%.2f" % value

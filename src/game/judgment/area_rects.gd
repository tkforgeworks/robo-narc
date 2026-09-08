class_name AreaRects
extends RefCounted
## Rect helpers for axis-aligned Area2D rectangles (nothing rotates here).


## Global rect of the area's first rectangular collision shape.
static func global_rect(area: Node2D) -> Rect2:
	for child in area.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			var node := child as CollisionShape2D
			var size: Vector2 = (node.shape as RectangleShape2D).size * node.global_scale
			return Rect2(node.global_position - size * 0.5, size)
	return Rect2()


## Share of `inner` covered by `outer`, 0..1 (1 = fully inside).
static func coverage(inner: Rect2, outer: Rect2) -> float:
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return 0.0
	return inner.intersection(outer).get_area() / inner.get_area()

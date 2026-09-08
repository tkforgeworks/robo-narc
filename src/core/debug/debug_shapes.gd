class_name DebugShapes
extends RefCounted
## Draws an Area2D's collision shapes as hairline outlines from inside that
## area's `_draw`, so a game can show its detection geometry with the art
## hidden. Rectangles and polygons only; nothing in this template rotates.

const HAIRLINE := -1.0


static func draw_outline(area: Node2D, color: Color) -> void:
	for child in area.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			var node := child as CollisionShape2D
			var size: Vector2 = (node.shape as RectangleShape2D).size * node.scale
			area.draw_rect(Rect2(node.position - size * 0.5, size), color, false, HAIRLINE)
		elif child is CollisionPolygon2D:
			var points: PackedVector2Array = (child as CollisionPolygon2D).polygon
			if points.size() >= 3:
				var closed := PackedVector2Array(points)
				closed.append(points[0])
				area.draw_polyline(closed, color, HAIRLINE)

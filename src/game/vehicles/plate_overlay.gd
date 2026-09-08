class_name PlateOverlay
extends Sprite2D
## The shared license plate composited onto every vehicle, sized to the
## PlateArea authored in the vehicle's scene so the art and the capture target
## are always the same rectangle.

const PLATE_PATH := "res://assets/overlays/plate.png"


func apply(plate_area: Node2D) -> void:
	if texture == null:
		texture = load(PLATE_PATH) if ResourceLoader.exists(PLATE_PATH) \
				else PlaceholderTexture.register_use("license plate")
	centered = false
	var rect := local_rect(plate_area)
	position = rect.position
	scale = rect.size / Vector2(texture.get_size())


## The area's rectangle in the vehicle's local space.
static func local_rect(plate_area: Node2D) -> Rect2:
	for child in plate_area.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			var node := child as CollisionShape2D
			var size: Vector2 = (node.shape as RectangleShape2D).size * node.scale
			return Rect2(plate_area.position + node.position - size * 0.5, size)
	return Rect2(Vector2(-14.0, -50.0), Vector2(28.0, 14.0))

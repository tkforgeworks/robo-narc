class_name PlaceholderTexture
extends RefCounted
## The shared pink/black checkerboard "no texture" sprite for every element that
## has no art yet (spec FR-030b). Elements register their use so the missing set
## is logged at startup in every build, release included.

const TAG := "Placeholder"
const PATH := "res://assets/ui/placeholder.png"
const SIZE := 64
const CELL := 8
const PINK := Color(1.0, 0.0, 1.0)
const BLACK := Color(0.0, 0.0, 0.0)

static var _texture: Texture2D = null
static var _uses: PackedStringArray = PackedStringArray()


## The checkerboard texture, loaded from disk or generated if the file is missing.
static func get_texture() -> Texture2D:
	if _texture == null:
		if ResourceLoader.exists(PATH):
			_texture = load(PATH)
		else:
			_texture = _generate()
	return _texture


## Records that `element_name` is using the placeholder and returns the texture.
## Logs once per distinct name.
static func register_use(element_name: String) -> Texture2D:
	if not _uses.has(element_name):
		_uses.append(element_name)
		DebugLog.warn(TAG, "no art for '%s'; using checkerboard placeholder" % element_name)
	return get_texture()


static func uses() -> PackedStringArray:
	return _uses.duplicate()


## Logs the full list of placeholder users. Call once after the first screen loads.
static func report() -> void:
	if _uses.is_empty():
		DebugLog.info(TAG, "no placeholder art in use")
		return
	DebugLog.warn(TAG, "placeholder art in use for %d element(s): %s" % [
		_uses.size(), ", ".join(_uses)
	])


static func _generate() -> ImageTexture:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var pink := ((x / CELL) + (y / CELL)) % 2 == 0
			image.set_pixel(x, y, PINK if pink else BLACK)
	return ImageTexture.create_from_image(image)

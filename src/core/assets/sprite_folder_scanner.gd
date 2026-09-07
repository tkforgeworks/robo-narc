class_name SpriteFolderScanner
extends RefCounted
## Discovers textures by folder so new art is a drop-in (spec FR-026). Works in
## the editor, in exported PCKs (where listings show `.png.import` markers), and
## on plain user:// folders (loaded as raw images).

const TAG := "Scanner"
const IMAGE_EXTENSIONS: PackedStringArray = ["png", "jpg", "jpeg", "webp"]


static func list_subdirs(dir_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not DirAccess.dir_exists_absolute(dir_path):
		return result
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for name in dir.get_directories():
		if not name.begins_with("."):
			result.append(name)
	result.sort()
	return result


## Full paths of image files in `dir_path`, de-duplicated and sorted.
static func list_texture_paths(dir_path: String) -> PackedStringArray:
	var found := {}
	if not DirAccess.dir_exists_absolute(dir_path):
		return PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return PackedStringArray()
	for file_name in dir.get_files():
		var name := file_name
		if name.ends_with(".import"):
			name = name.trim_suffix(".import")
		if name.get_extension().to_lower() in IMAGE_EXTENSIONS:
			found[name] = true
	var result := PackedStringArray()
	for name: String in found.keys():
		result.append(dir_path.path_join(name))
	result.sort()
	return result


static func list_textures(dir_path: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in list_texture_paths(dir_path):
		var texture := load_texture(path)
		if texture != null:
			textures.append(texture)
	return textures


## Imported resources load through the resource system; anything else (a file
## dropped into user://) is read as a raw image.
static func load_texture(path: String) -> Texture2D:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is Texture2D:
			return resource
	var image := Image.load_from_file(path)
	if image == null:
		DebugLog.warn(TAG, "could not load image %s" % path)
		return null
	return ImageTexture.create_from_image(image)

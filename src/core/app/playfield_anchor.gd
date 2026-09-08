class_name PlayfieldAnchor
extends Node
## Keeps a fixed-size screen centred in the expand-stretched viewport: moves
## its parent to Playfield.offset, and any listed frame Controls (typically the
## 1280 x 720 root inside each CanvasLayer) with it, on ready and on resize.
## Pure composition: drop it under a playfield screen and list the frames.

@export var frames: Array[NodePath] = []


func _ready() -> void:
	get_viewport().size_changed.connect(apply)
	apply()


func apply() -> void:
	var offset := Playfield.offset(get_viewport())
	var parent := get_parent()
	if parent is Node2D or parent is Control:
		parent.position = offset
	for path in frames:
		var frame := get_node_or_null(path) as Control
		if frame != null:
			frame.position = offset

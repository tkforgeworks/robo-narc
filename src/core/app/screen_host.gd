class_name ScreenHost
extends Node
## Owns the one active screen. Screens navigate by emitting
## `navigation_requested(scene: PackedScene, payload: Variant)`; this node
## connects that signal on instantiation so screens never look up their host
## (constitution I). Requests from a screen that is no longer current are
## ignored, which also debounces a double Start press.

signal screen_changed(screen: Node)

const TAG := "ScreenHost"

var current: Node = null

var _transitioning: bool = false


## Replaces the current screen. Returns false if the request was ignored.
func show_screen(scene: PackedScene, payload: Variant = null) -> bool:
	if scene == null:
		DebugLog.warn(TAG, "show_screen called with no scene")
		return false
	if _transitioning:
		DebugLog.info(TAG, "ignored show_screen during transition")
		return false
	_transitioning = true
	_retire(current)
	var next := scene.instantiate()
	add_child(next)
	current = next
	if next.has_signal("navigation_requested"):
		next.navigation_requested.connect(_on_navigation_requested.bind(next))
	# Listeners bind services (settings, mixer, tuning) on screen_changed, so it
	# fires before enter(): a screen's entry logic can rely on what was bound.
	DebugLog.info(TAG, "showing %s" % next.name)
	screen_changed.emit(next)
	if next.has_method("enter"):
		next.enter(payload)
	_transitioning = false
	return true


func _on_navigation_requested(scene: PackedScene, payload: Variant, sender: Node) -> void:
	if sender != current:
		DebugLog.info(TAG, "ignored navigation from retired screen %s" % sender.name)
		return
	show_screen(scene, payload)


func _retire(screen: Node) -> void:
	if screen == null:
		return
	screen.process_mode = Node.PROCESS_MODE_DISABLED
	if screen is CanvasItem:
		(screen as CanvasItem).visible = false
	screen.queue_free()

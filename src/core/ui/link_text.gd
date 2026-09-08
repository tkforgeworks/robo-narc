class_name LinkText
extends RichTextLabel
## A RichTextLabel whose `[url=https://...]label[/url]` tags open in the
## system browser (a new tab on web). Write the links as BBCode in the
## scene's `text` property; nothing else is needed.

signal link_opened(url: String)

## Off in tests so no browser opens.
@export var open_urls: bool = true


func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	meta_underlined = true
	if not meta_clicked.is_connected(_on_meta_clicked):
		meta_clicked.connect(_on_meta_clicked)


func _on_meta_clicked(meta: Variant) -> void:
	var url := str(meta)
	if open_urls:
		OS.shell_open(url)
	link_opened.emit(url)

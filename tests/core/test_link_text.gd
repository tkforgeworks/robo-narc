extends GutTest


func test_url_tags_open_through_meta_clicked() -> void:
	var text := LinkText.new()
	text.open_urls = false
	text.text = "[url=https://example.com/bugs]Report a bug[/url] and [url=https://example.com]home[/url]"
	add_child_autofree(text)
	watch_signals(text)
	assert_true(text.bbcode_enabled)
	assert_eq(text.get_parsed_text(), "Report a bug and home")
	text.meta_clicked.emit("https://example.com/bugs")
	assert_signal_emitted_with_parameters(text, "link_opened", ["https://example.com/bugs"])

class_name ProfanityFilter
extends RefCounted
## Blocks common English profanity in player names (spec FR-043). Data-driven
## from `data/game/profanity.txt`; matching follows research R-13: lowercase,
## map leet substitutions, and accept repeated letters (`fuuuck`), matched as a
## substring so `xxWORDxx` entries are caught. False positives are accepted.

const TAG := "Profanity"
const DEFAULT_PATH := "res://data/game/profanity.txt"
const LEET: Dictionary = {
	"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "@": "a", "$": "s",
}

var _patterns: Array[RegEx] = []
var _words: PackedStringArray = PackedStringArray()


func _init(words: PackedStringArray = PackedStringArray()) -> void:
	for word in words:
		add_word(word)


## Loads the shipped list; an absent file yields an empty (permissive) filter.
static func load_default() -> ProfanityFilter:
	return load_from(DEFAULT_PATH)


static func load_from(path: String) -> ProfanityFilter:
	var filter := ProfanityFilter.new()
	if not FileAccess.file_exists(path):
		DebugLog.warn(TAG, "no word list at %s; names are unfiltered" % path)
		return filter
	var file := FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		filter.add_word(file.get_line())
	return filter


## One word per call; blank lines and `#` comments are ignored.
func add_word(raw: String) -> void:
	var word := normalize(raw.get_slice("#", 0))
	if word.is_empty() or _words.has(word):
		return
	var pattern := ""
	for ch in word:
		pattern += "%s+" % ch  # letters only after normalize, so no escaping
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		DebugLog.warn(TAG, "cannot compile pattern for '%s'" % raw)
		return
	_words.append(word)
	_patterns.append(regex)


func word_count() -> int:
	return _words.size()


func contains(text: String) -> bool:
	var subject := normalize(text)
	for regex in _patterns:
		if regex.search(subject) != null:
			return true
	return false


## Lowercase, leet-mapped, letters only.
static func normalize(text: String) -> String:
	var out := ""
	for ch in text.to_lower():
		var mapped: String = LEET.get(ch, ch)
		if mapped >= "a" and mapped <= "z":
			out += mapped
	return out

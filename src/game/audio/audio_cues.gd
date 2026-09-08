class_name AudioCues
extends Node
## Plays named sound effects on the SFX bus. Resolves one stream per event at
## ready (`.ogg` preferred, `.wav` accepted); events without a file are silent
## no-ops and logged once (spec FR-038, FR-039). Playback rotates through a
## small player pool so overlapping cues do not cut each other off.

signal played(event: String)

const TAG := "Audio"
const EVENTS: PackedStringArray = ["count_in_tick", "shutter", "capture_correct",
		"capture_wrong", "miss", "honk", "shift_end"]
const EXTENSIONS: PackedStringArray = ["ogg", "wav"]
const BUS := "SFX"
const POOL_SIZE := 6
const PREVIEW_GAP_SEC := 0.45

## Folder holding `<event>.ogg` / `<event>.wav`.
@export var sfx_dir: String = "res://assets/audio/sfx"

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _warned_unknown: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for event in EVENTS:
		_streams[event] = resolve(sfx_dir, event)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)
	_report()


## The stream for `event` in `dir`, trying each extension in order, or null.
static func resolve(dir: String, event: String) -> AudioStream:
	for ext in EXTENSIONS:
		var path := dir.path_join("%s.%s" % [event, ext])
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func is_resolved(event: String) -> bool:
	return _streams.get(event) != null


func missing_events() -> PackedStringArray:
	var missing := PackedStringArray()
	for event in EVENTS:
		if not is_resolved(event):
			missing.append(event)
	return missing


## Plays `event` if it has a stream. Unknown names log once and are ignored.
func play(event: String) -> void:
	if not _streams.has(event):
		if not _warned_unknown.has(event):
			_warned_unknown[event] = true
			DebugLog.warn(TAG, "unknown sfx event '%s'" % event)
		return
	var stream: AudioStream = _streams[event]
	if stream == null:
		return
	var player := _free_player()
	player.stream = stream
	player.play()
	played.emit(event)


## Plays every resolved cue in turn; the debug menu offers this so an operator
## can hear each one without waiting for the event.
func preview_all() -> void:
	for event in EVENTS:
		play(event)
		await get_tree().create_timer(PREVIEW_GAP_SEC, true).timeout


func _free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	return player


func _report() -> void:
	var missing := missing_events()
	if missing.is_empty():
		DebugLog.info(TAG, "all %d sfx events resolved from %s" % [EVENTS.size(), sfx_dir])
	else:
		DebugLog.warn(TAG, "no audio for %d event(s): %s" % [missing.size(), ", ".join(missing)])

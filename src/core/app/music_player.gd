class_name MusicPlayer
extends AudioStreamPlayer
## Loops the background track on the Music bus when a file exists (`.ogg`
## preferred, `.wav` accepted). Without one it stays silent and logs once
## (spec FR-039). Keeps playing through pauses so menus are not abrupt.

const TAG := "Music"
const EXTENSIONS: PackedStringArray = ["ogg", "wav"]

## Path without extension.
@export var track: String = "res://assets/audio/music/background"


func _ready() -> void:
	bus = "Music"
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = resolve(track)
	if stream == null:
		DebugLog.info(TAG, "no track at %s.{%s}; music off" % [track, ",".join(EXTENSIONS)])
		return
	if "loop" in stream:
		stream.set("loop", true)
	# Streams without a loop flag (WAV) restart on finish; a small gap is fine
	# for placeholder music.
	finished.connect(play)
	play()


static func resolve(base_path: String) -> AudioStream:
	for ext in EXTENSIONS:
		var path := "%s.%s" % [base_path, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null

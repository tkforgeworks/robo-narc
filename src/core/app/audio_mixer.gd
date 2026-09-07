class_name AudioMixer
extends Node
## Owns the Master / Music / SFX buses. Guarantees the buses exist (creating
## them if the bus layout lacks them), applies persisted volumes on ready, and
## maps linear 0..1 volumes to decibels with a hard mute at zero.

const BUSES: PackedStringArray = ["Master", "Music", "SFX"]
const MUTE_BELOW := 0.001

## Injected by Main before ready; volumes are applied from it.
var settings: SettingsStore


func _ready() -> void:
	ensure_buses()
	if settings != null:
		apply_settings()


## Creates any missing bus, routed to Master.
func ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			var index := AudioServer.bus_count
			AudioServer.add_bus(index)
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")


func apply_settings() -> void:
	set_volume("Master", settings.master)
	set_volume("Music", settings.music)
	set_volume("SFX", settings.sfx)


## `bus_name` is matched case-insensitively ("sfx" and "SFX" both work).
func set_volume(bus_name: String, linear: float) -> void:
	var index := bus_index(bus_name)
	if index == -1:
		return
	var level := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, level < MUTE_BELOW)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, MUTE_BELOW)))


func get_volume(bus_name: String) -> float:
	var index := bus_index(bus_name)
	if index == -1:
		return 0.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


static func bus_index(bus_name: String) -> int:
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i).to_lower() == bus_name.to_lower():
			return i
	return -1

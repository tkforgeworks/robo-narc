class_name LeaderboardConfig
extends Resource
## Where the shared leaderboard lives. The committed `leaderboard_config.tres`
## is disabled and empty; a gitignored `leaderboard_config.local.tres` beside it
## (or one written by CI from secrets) takes precedence, so no key is ever
## committed and the game runs fine with neither (spec FR-041).

const TAG := "Leaderboard"
const DEFAULT_PATH := "res://data/game/leaderboard_config.tres"
const LOCAL_PATH := "res://data/game/leaderboard_config.local.tres"

## Supabase project URL, e.g. https://abcdefgh.supabase.co (no trailing slash needed).
@export var base_url: String = ""
## The project's anon (public) API key.
@export var anon_key: String = ""
@export var enabled: bool = false


func is_usable() -> bool:
	return enabled and not base_url.strip_edges().is_empty() and not anon_key.strip_edges().is_empty()


## Local override first, then the committed default, then an empty config.
static func load_active() -> LeaderboardConfig:
	for path in [LOCAL_PATH, DEFAULT_PATH]:
		if ResourceLoader.exists(path):
			var config := load(path) as LeaderboardConfig
			if config != null:
				DebugLog.info(TAG, "config from %s (%s)" % [
					path.get_file(), "enabled" if config.is_usable() else "disabled"])
				return config
	DebugLog.info(TAG, "no config resource; leaderboard disabled")
	return LeaderboardConfig.new()

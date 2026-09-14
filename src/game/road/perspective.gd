class_name Perspective
extends RefCounted
## Road space to screen space. Pure math, no state.
##
## Road space: `road_x` is lateral position in px at full (nearest) scale,
## `z` is distance ahead of the bus (0 = at the bus, z_max = horizon).
## True perspective: f(z) = C / (z + C). Screen x and y are both linear in f,
## so straight road markings stay straight. The bus's own lateral position
## (`camera_x`) shifts the world the opposite way; the hood stays put. How
## much that shift scales with depth is `lane_change_pan`: 0 is exact
## perspective (far things barely move), 1 pans every depth equally.


static func factor(z: float, perspective_c: float) -> float:
	return perspective_c / (maxf(z, 0.0) + perspective_c)


static func project(road_x: float, z: float, camera_x: float, config: TuningConfig) -> Vector2:
	var f := factor(z, config.perspective_c)
	var shift := camera_shift(camera_x, config) * lerpf(f, 1.0, config.lane_change_pan)
	return Vector2(
		config.vanishing_point_x + (road_x - config.vanishing_point_x) * f - shift,
		config.horizon_y + (config.bus_screen_y - config.horizon_y) * f
	)


## How far the bus sits from its home lane centre, in road px.
static func camera_shift(camera_x: float, config: TuningConfig) -> float:
	return camera_x - config.lane_bus_center()


## Where lines along the road converge on screen for this camera position.
## With lane_change_pan > 0 it slides with the bus.
static func vanishing_point(camera_x: float, config: TuningConfig) -> Vector2:
	return Vector2(
		config.vanishing_point_x - camera_shift(camera_x, config) * config.lane_change_pan,
		config.horizon_y
	)


## Screen-space scale for a sprite drawn at full size when z = 0.
static func scale_at(z: float, config: TuningConfig) -> float:
	return factor(z, config.perspective_c)

class_name Perspective
extends RefCounted
## Road space to screen space. Pure math, no state.
##
## Road space: `road_x` is lateral position in px at full (nearest) scale,
## `z` is distance ahead of the bus (0 = at the bus, z_max = horizon).
## True perspective: f(z) = C / (z + C). Screen x and y are both linear in f,
## so straight road markings stay straight. The bus's own lateral position
## (`camera_x`) shifts the whole world the opposite way; the hood stays put.


static func factor(z: float, perspective_c: float) -> float:
	return perspective_c / (maxf(z, 0.0) + perspective_c)


static func project(road_x: float, z: float, camera_x: float, config: TuningConfig) -> Vector2:
	var f := factor(z, config.perspective_c)
	var x_eff := road_x - (camera_x - config.lane_bus_center())
	return Vector2(
		config.vanishing_point_x + (x_eff - config.vanishing_point_x) * f,
		config.horizon_y + (config.bus_screen_y - config.horizon_y) * f
	)


## Screen-space scale for a sprite drawn at full size when z = 0.
static func scale_at(z: float, config: TuningConfig) -> float:
	return factor(z, config.perspective_c)

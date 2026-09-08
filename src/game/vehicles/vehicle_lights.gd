class_name VehicleLights
extends Node
## Drives the taillight shader on a vehicle's body sprite from its motion
## state and the live tuning values (spec FR-025).

const SHADER: Shader = preload("res://src/game/vehicles/taillights.gdshader")

var config: TuningConfig

var _material: ShaderMaterial
var _intensity: float = -1.0


func attach(body: Sprite2D, style: VehicleStyle, p_config: TuningConfig) -> void:
	config = p_config
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	body.material = _material
	apply_style(style)


func apply_style(style: VehicleStyle) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("left_rect", _to_vec4(style.left_light_rect))
	_material.set_shader_parameter("right_rect", _to_vec4(style.right_light_rect))


## Re-reads the tunable intensities; cheap to call every frame.
func set_motion(motion: Vehicle.Motion) -> void:
	if _material == null:
		return
	var intensity := intensity_for(motion, config)
	if is_equal_approx(intensity, _intensity):
		return
	_intensity = intensity
	_material.set_shader_parameter("intensity", intensity)
	_material.set_shader_parameter("glow_color", config.light_glow_color)


static func intensity_for(motion: Vehicle.Motion, p_config: TuningConfig) -> float:
	match motion:
		Vehicle.Motion.STOPPED_IN_ROAD:
			return p_config.light_intensity_bright
		Vehicle.Motion.MOVING:
			return p_config.light_intensity_dim
	return p_config.light_intensity_off


static func _to_vec4(rect: Rect2) -> Vector4:
	return Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y)

class_name ControlBindings
extends RefCounted
## Human-readable names for whatever the InputMap binds to an action, so the
## controls sheet always shows the real bindings (spec: arcade players need
## to see them; changing them is out of scope).

const JOY_BUTTON_NAMES: Dictionary = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad Up", JOY_BUTTON_DPAD_DOWN: "D-pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left", JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
}


## Key names bound to `action`, e.g. ["W", "Up"].
static func keyboard(action: StringName) -> PackedStringArray:
	var names := PackedStringArray()
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := event as InputEventKey
			var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			names.append(OS.get_keycode_string(code))
	return names


## Gamepad names bound to `action`, e.g. ["A"] or ["Left stick"].
static func gamepad(action: StringName) -> PackedStringArray:
	var names := PackedStringArray()
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			var index := (event as InputEventJoypadButton).button_index
			names.append(JOY_BUTTON_NAMES.get(index, "Button %d" % index))
		elif event is InputEventJoypadMotion:
			var axis := (event as InputEventJoypadMotion).axis
			var stick := "Left stick" if axis <= JOY_AXIS_LEFT_Y else "Right stick"
			if not names.has(stick):
				names.append(stick)
	return names


## One line for a sheet row: keys first, then gamepad, e.g. "W / Up  ·  Left stick".
static func describe(action: StringName) -> String:
	var parts := PackedStringArray()
	var keys := keyboard(action)
	if not keys.is_empty():
		parts.append(" / ".join(keys))
	var pad := gamepad(action)
	if not pad.is_empty():
		parts.append(" / ".join(pad))
	return "  ·  ".join(parts) if not parts.is_empty() else "(unbound)"

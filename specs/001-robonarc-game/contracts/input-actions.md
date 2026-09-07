# Contract: Input Actions and Sources

Gameplay reads only these named actions (FR-031). Device handling lives in
`project.godot` bindings and in `TouchControls`; no gameplay script inspects device
types.

## Actions (`project.godot` `[input]`)

| Action | Keyboard | Gamepad | Touch (virtual) | Deadzone |
|--------|----------|---------|-----------------|----------|
| move_up | W, Up | Left stick -Y, D-pad up | joystick | 0.2 |
| move_down | S, Down | Left stick +Y, D-pad down | joystick | 0.2 |
| move_left | A, Left | Left stick -X, D-pad left | joystick | 0.2 |
| move_right | D, Right | Left stick +X, D-pad right | joystick | 0.2 |
| capture | Space | A / Cross (button 0) | capture button | 0.2 |
| ui_accept (engine) | Enter, Space | A / Cross | tap | |
| ui_cancel (engine) | Escape | B / Circle | back button (Android) | |
| debug_menu | F1 | none | three-finger tap (DebugTrigger) | |

Capture box movement uses `Input.get_vector("move_left", "move_right", "move_up",
"move_down")` so analog sticks give proportional speed and the virtual joystick
supplies the same vector via `Input.action_press(action, strength)`.

## Input source rules (`InputSource`)

| Event type | Source |
|------------|--------|
| InputEventScreenTouch, InputEventScreenDrag | TOUCH |
| InputEventJoypadButton, InputEventJoypadMotion (|axis| > deadzone) | GAMEPAD |
| InputEventKey, InputEventMouseButton, InputEventMouseMotion (non-emulated) | KEYBOARD |

- `source_changed(source)` fires only on change.
- `TouchControls.visible == (source == TOUCH)`.
- `CaptureBox` speed = `box_speed_<source>` from `TuningConfig`.
- Project settings: `input_devices/pointing/emulate_mouse_from_touch = false`,
  `emulate_touch_from_mouse = false`.

## Screen navigation

Menus are `Control` scenes with focus neighbours set so gamepad and keyboard can
navigate; the first button grabs focus on screen entry. Touch taps buttons
directly. `NameEntry` opens the OS virtual keyboard on touch
(`DisplayServer.virtual_keyboard_show`) and accepts gamepad navigation through an
on-screen letter grid when the source is GAMEPAD.

## Playfield and gutters

`Playfield.BASE` is 1280 × 720. Under the `expand` stretch aspect the viewport grows
instead of scaling, so `Playfield.offset(viewport)` centres the design area and the
remainder is gutter. `Main` treats `Node2D` screens as fixed-playfield screens: it
shows `Letterbox` over the gutters and lets `TouchControls` place the joystick in
the left gutter and the capture button in the right one. `Control` screens are
responsive and fill the window. Gutters narrower than `touch_gutter_min_px` (or
than the 96 px control minimum) put both controls on the playfield edges at 45 %
opacity instead.

`VirtualJoystick` feeds move actions with `Input.action_press(action, strength)`;
`VirtualButton` additionally pushes an `InputEventAction` so `_unhandled_input`
handlers (CaptureBox) see the press.

## Platform lock

Android export preset: `screen/orientation = sensor_landscape`;
`project.godot`: `display/window/handheld/orientation = sensor_landscape`.

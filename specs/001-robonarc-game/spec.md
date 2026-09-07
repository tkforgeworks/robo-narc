# Feature Specification: RoboNarc Convention Game

**Feature Branch**: `001-robonarc-game`

**Created**: 2026-09-07

**Status**: Draft

**Input**: User description: "Utilize the README.md and GDD.md to specify the Game that is meant to be built - the GDD is the primary reference point. This is meant to be a short game for use at conventions as an attention grabber and not something ultra competitive or very difficult, higher scoring feels better to most players."

## Overview

RoboNarc is a short, single-session arcade game in which the player is the automated
enforcement camera on a city bus. Traffic appears at the horizon and rolls toward the
player. The player moves a capture box over the license plates of vehicles that are
committing violations (blocking the bus lane, double parking, sitting in the bike lane
or at a bus stop) and snaps them, while leaving innocent drivers alone. It is modeled
on New York City's bus-mounted Automated Camera Enforcement program.

The game is built for **convention play**: a passer-by should be able to walk up, start
a round with one action, understand what to do within seconds, play a complete round in
under two minutes, feel good about their score, and walk away with a clear idea of what
the real-world system does. It is deliberately **not** a hard or highly competitive
game. Difficulty ramps gently, scoring skews positive, and feedback teaches the cues
rather than punishing mistakes.

Three design pillars carry over from the prototype and are non-negotiable:

1. **Judgment, not labels.** Violators are never visually marked. The player reads the
   scene the way a human reviewer would: where the car is, whether it is moving, what
   landmarks are next to it.
2. **Aim under pressure.** Plates start tiny at the horizon and grow as they approach.
   The player judges early and captures inside the readable window.
3. **Escalation.** The bus drives faster as the shift progresses, gently shrinking every
   judgment window.

## Clarifications

### Session 2026-09-07

- Q: Which art assets should the game use, and what happens when a needed asset does
  not exist? → A: The premade assets under `Assets/` are the art and MUST be used.
  Every asset the game needs that is not provided MUST be listed explicitly (see
  Assumptions, "Art asset inventory"), and MUST be represented in development by a
  standard pink/black checkerboard "no texture" placeholder sprite.
- Q: How should the road be rendered, given the premade road is a static pre-rendered
  perspective image? → A: Use it as a static backdrop that slides sideways when the
  bus swerves. Lane dashes do not scroll; the motion cue comes from the road stencils,
  buildings, parked vehicles, and the bus stop landmark sweeping past.
- Q: How should each vehicle get its taillight states and license plate, given the
  premade sprites have unlit taillights and no plate? → A: Taillight states are
  produced by a shader-driven lighting effect applied to the existing sprite (no new
  art). The plate is a shared composite overlay placed on each vehicle, with its
  position and size per body style tuned by the developer at runtime.
- Q: What happens to a running shift when the game loses focus (tab switched away,
  app backgrounded)? → A: The shift pauses. On return, a 3-2-1 resume count-in plays
  before control and spawning continue.
- Q: How many leaderboard entries are shown, and is the board global or per event? →
  A: One global board. Title and results show the top 20; results also shows the
  player's own rank even when outside the top 20.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Play a Complete Shift (Priority: P1)

A convention visitor steps up to the booth, presses Start, gets a 3-2-1 count-in, and
plays one 90-second shift. Vehicles crest the horizon and approach. The visitor moves the
capture box with the keyboard, frames the plate of a vehicle they believe is violating,
and presses capture. They receive immediate points and a short verdict message that
names the violation (or tells them the car was innocent). When the timer runs out, they
see their final score and a breakdown of correct, wrong, missed, and empty captures, and
can play again or return to the title.

**Why this priority**: This is the entire game. Every other story decorates, extends,
or distributes this loop. With only this story done, the game is fully playable with
placeholder visuals on a single machine.

**Independent Test**: Start a shift with keyboard controls, capture at least one
violator and one innocent vehicle, let one violator pass uncaptured, let the timer
expire, and confirm the results screen shows the correct score and per-category counts.

**Acceptance Scenarios**:

1. **Given** the player is on the title screen, **When** they press Start, **Then** a
   3-2-1 count-in plays, control is withheld during the count-in, and gameplay and
   vehicle spawning begin when it ends.
2. **Given** a vehicle is stationary in the bus lane and within readable distance,
   **When** the player frames its entire plate in the capture box and presses capture,
   **Then** the score increases by the correct-capture value, the plate is visibly marked
   as captured, and the feedback text names "BUS LANE".
3. **Given** a vehicle is driving normally (moving), **When** the player captures it,
   **Then** the score changes by the wrong-capture value and the feedback text explains
   the vehicle was innocent.
4. **Given** a violating vehicle passes under the bus without being captured, **When**
   it leaves the playfield, **Then** the score changes by the missed-violation value and
   feedback indicates a miss.
5. **Given** a vehicle is beyond readable distance, **When** the player presses capture
   with its plate framed, **Then** no score change occurs, the message "TOO FAR - PLATE
   UNREADABLE" (or equivalent) appears, and the capture cooldown is consumed.
6. **Given** the player presses capture with no plate fully inside the box, **When**
   the capture fires, **Then** no score change occurs, the shutter feedback plays, and
   the cooldown is consumed.
7. **Given** two plates are fully inside the capture box, **When** the player captures,
   **Then** only the closest vehicle is judged.
8. **Given** a vehicle has already been captured, **When** the player captures it again,
   **Then** nothing is scored and the vehicle remains marked as captured.
9. **Given** the shift has been running, **When** time advances, **Then** the bus cruise
   speed rises and the spawn interval shortens according to the tunable ramp, so the
   final third of a shift is visibly busier than the first third.
9a. **Given** a shift is running, **When** the game loses focus, **Then** the timer and
    all motion stop; **When** focus returns, **Then** a 3-2-1 resume count-in plays and
    the shift continues from where it paused with the same score and timer.
10. **Given** the shift timer reaches zero, **When** the shift ends, **Then** spawning
    and input stop, an end-of-shift cue plays, and the results screen shows the final
    score with counts of correct, wrong, missed, and empty captures plus Play Again and
    Title options.

---

### User Story 2 - Tune the Game Live (Priority: P1)

A developer or booth operator opens the debug menu during play. Gameplay pauses. Every
behavior value that shapes the feel of the game (bus speeds and ramp, shift length,
count-in length, spawn interval and ramp, situation weights, readable distance, capture
box size and speed, cooldown, score and penalty values, lane thresholds, bus driving
triggers, audio volumes) is listed with its current value and can be changed with
immediate effect on resuming. A reset-to-defaults action restores the documented
baseline. Local scores can be cleared from the same menu.

**Why this priority**: The project constitution makes live tunability a completion
requirement for every feature, and the convention-friendly feel (gentle ramp, positive
scoring) can only be found by adjusting values while playing. Building this alongside
the core loop is far cheaper than retrofitting it.

**Independent Test**: Open the debug menu mid-shift, confirm gameplay is paused, change
the shift length and cruise speed, resume, and observe both changes take effect in the
current shift. Reset to defaults and confirm the values return to baseline.

**Acceptance Scenarios**:

1. **Given** gameplay is running on a desktop debug build, **When** the operator presses
   the debug toggle, **Then** the game pauses and the debug menu appears listing every
   tunable with its current value.
2. **Given** the debug menu is open, **When** the operator changes a value and closes
   the menu, **Then** gameplay resumes and the new value is in effect immediately.
3. **Given** values have been changed, **When** the operator chooses reset to defaults,
   **Then** every tunable returns to its documented baseline value.
4. **Given** a new tunable is added to the game, **When** the debug menu is opened,
   **Then** the new tunable appears without any change to the menu itself.
5. **Given** a release build on any platform, **When** the player attempts the debug
   toggle, **Then** nothing happens and no debug menu exists.
6. **Given** a debug build on web or Android, **When** the operator triggers the debug
   toggle, **Then** the debug menu opens and behaves identically to desktop.

---

### User Story 3 - See a Polished, Readable Scene (Priority: P2)

A passer-by looking at the booth screen from a few feet away sees a recognisable city
street from a bus driver's viewpoint: a road converging to a horizon, buildings and
roadside props sweeping past, a bus stop stripe on the curb, and a cab/hood frame that
says "you are driving a bus". Vehicles are real rear-view sprites in varied body styles
and colors. Their taillights carry the crucial cue: bright brake lights for a car
stopped in the roadway, lights off for a curb-parked car, dim taillights for a moving
car. Nothing on any vehicle indicates whether it is a violator. The capture box is a
crisp camera reticle drawn over the scene. Screens share consistent fonts and theming.

**Why this priority**: The game's job at a convention is to be looked at. Placeholder
rectangles will not stop anyone walking past. Light states are also load-bearing for
the judgment pillar, so this story affects playability, not only polish.

**Independent Test**: Run a shift and confirm every vehicle uses a sprite from the
imported variant set with the correct light state for its situation, roadside props and
buildings scroll at road speed, the bus overlay frames the bottom of the screen, and
the capture box remains a drawn reticle. Add a new vehicle variant to the asset folder
and confirm it appears in play with no other changes.

**Acceptance Scenarios**:

1. **Given** the vehicle asset set contains several body styles each in several colors,
   **When** vehicles spawn, **Then** body style and color are chosen at random and never
   correlate with violation status.
2. **Given** a vehicle is stopped in the roadway, **When** it is visible, **Then** its
   brake lights are bright; **Given** it is curb-parked, its lights are off; **Given**
   it is moving, its taillights are dim.
3. **Given** a vehicle has been captured, **When** it is still on screen, **Then** its
   plate area shows a clear capture mark that reads correctly over the sprite art.
4. **Given** the bus is cruising, **When** the scene is viewed, **Then** buildings,
   roadside props, road stencils, and the bus stop stripe all sweep past at the same
   road speed over the static road backdrop, while driving vehicles approach noticeably
   more slowly.
4a. **Given** the bus swerves around a blocker, **When** the view shifts, **Then** the
    road backdrop, stencils, props, and vehicles all move sideways together and no
    backdrop edge becomes visible.
5. **Given** a new vehicle variant is dropped into the asset folder following the
   naming convention, **When** the game runs, **Then** the variant appears in the
   rotation without any other change.
6. **Given** any screen in the game, **When** it is displayed, **Then** it uses the
   shared font set and theme.

---

### User Story 4 - Navigate Title, About, Settings, and Results (Priority: P2)

A visitor at the title screen sees the game name, a short cheat-sheet of the visual
cues, the current top scores, and Start, About, Settings, and Quit options. About gives
a short elevator pitch of the real-world bus camera enforcement program and what it is
for. Settings offers Master, Music, and SFX volume sliders that persist between
sessions. After a shift, the results screen shows the score and breakdown, where the
player stands on the leaderboard, and Play Again or Title. If nobody touches the
results screen for a while, it returns to the title on its own so the booth is ready
for the next visitor.

**Why this priority**: The title and About screens are what make the booth
self-explanatory and deliver the "here is what this is modeled on" message, which the
project owner has called out as a goal. Settings is needed because booth volume must be
adjustable without a debug menu.

**Independent Test**: From launch, visit every screen via its button, return to title
from each, change a volume slider, restart the game, and confirm the slider value was
kept.

**Acceptance Scenarios**:

1. **Given** the game launches, **When** the title screen appears, **Then** it shows
   the game name, the cue cheat-sheet, the current top 20 scores, and Start, About,
   Settings, and Quit.
2. **Given** the title screen, **When** the player chooses About, **Then** an
   informational screen describes the real-world program in plain language and offers a
   way back to the title.
3. **Given** the Settings screen, **When** the player adjusts Master, Music, or SFX and
   later relaunches the game, **Then** the adjusted values are still in effect.
4. **Given** the results screen, **When** the player chooses Play Again, **Then** a new
   shift begins with a fresh count-in; **When** they choose Title, **Then** the title
   screen appears.
5. **Given** the game is running on a platform without a meaningful "quit" (web),
   **When** the title screen is shown, **Then** the Quit option is hidden or inert
   rather than broken.
6. **Given** the results screen is showing, **When** no input arrives for the idle
   timeout (baseline 60 seconds), **Then** the game returns to the title screen;
   **When** any input arrives before then, **Then** the auto-return is cancelled.

---

### User Story 5 - Play with Touch or a Gamepad (Priority: P3)

A visitor on an Android device or handheld, or at a touch-screen booth, plays the same
shift using a virtual joystick and a single capture button placed in the letterbox
gutters beside the playfield, or using a gamepad's left stick or d-pad and face button.
Virtual controls appear only when touch is the active input and never cover the
playfield.

**Why this priority**: The core loop and visuals must exist first. Touch and gamepad
widen where the game can be shown but do not change what it is.

**Independent Test**: Play a full shift on a touch device using only the on-screen
controls, then on a gamepad using only the controller, and confirm both can move the
box across the whole playfield and capture.

**Acceptance Scenarios**:

1. **Given** touch is the active input, **When** gameplay starts, **Then** a virtual
   joystick and capture button are shown in the side gutters, not over the road.
2. **Given** a keyboard or gamepad is used, **When** gameplay starts, **Then** virtual
   controls are not shown.
3. **Given** a gamepad is connected, **When** the player uses the left stick or d-pad
   and the primary face button, **Then** the box moves and captures exactly as with the
   keyboard.
4. **Given** the display is wider than the game's native aspect, **When** the game is
   shown, **Then** the playfield keeps its native aspect without stretching and the
   extra width forms the gutters used for touch controls.
5. **Given** the game runs on Android, **When** the device rotates, **Then** the game
   stays in landscape.

---

### User Story 6 - Hear the Game (Priority: P3)

Every meaningful event has a sound hook: count-in ticks, camera shutter on every
capture press, a positive tone for a correct capture, a negative tone for a wrong one,
a sad tone for a missed violation, honks from passing cars, an end-of-shift "yay", and a
looping background music track. The Settings sliders control Master, Music, and SFX
independently. Actual audio content may be missing; the game runs silently and
correctly without it.

**Why this priority**: Sound is a strong attention grabber at a booth but the game is
complete without it, and the audio assets themselves are explicitly out of scope for
this version.

**Independent Test**: With placeholder sounds assigned, trigger every event and confirm
the corresponding sound plays through the correct channel; remove all sound files and
confirm the game plays with no errors.

**Acceptance Scenarios**:

1. **Given** placeholder sounds are assigned, **When** each listed event occurs,
   **Then** the matching sound plays once per event.
2. **Given** the Music slider is at zero and SFX is at full, **When** a shift plays,
   **Then** no background music is heard but event sounds are.
3. **Given** no audio files are present, **When** a full shift is played, **Then** the
   game behaves identically apart from silence.

---

### User Story 7 - Compete on a Shared Leaderboard (Priority: P4)

At the end of a shift the visitor types a short name (up to 12 letters, checked
against a profanity filter, with a skip option) and their score is submitted to a
shared online leaderboard along with their stat breakdown. The title and results
screens show the current top scores. If the booth has no connectivity or the submission fails,
the game continues without delay, keeps the score locally, and shows a brief
"leaderboard unavailable" note.

**Why this priority**: A shared board adds bragging rights across booths and days, but
convention play works without it, and it is the only feature with an external
dependency.

**Independent Test**: Finish a shift with connectivity and confirm the score appears in
the top list on the title screen; finish another with connectivity disabled and confirm
the game proceeds normally with a local-only note.

**Acceptance Scenarios**:

1. **Given** the shift ends and the network is available, **When** the player enters
   an accepted name (or skips), **Then** the score, breakdown, and name are submitted
   and the player's rank is shown alongside the top 20, highlighted if inside it.
1c. **Given** the player's score ranks 57th, **When** the results screen shows,
    **Then** the top 20 is listed and "Your rank: 57" (or equivalent) is shown below.
1a. **Given** the name entry, **When** the player types a name longer than 12
    characters, containing anything other than letters, or matching the profanity
    filter, **Then** it is refused with a short message and they can try again or skip.
1b. **Given** a name was accepted on this machine previously, **When** the next shift
    ends, **Then** that name is pre-filled and can be accepted with a single action.
2. **Given** the network is unavailable, **When** the shift ends, **Then** the results
   screen appears without waiting on the network, the score is kept locally, and a
   "leaderboard unavailable" note is shown.
3. **Given** the title screen, **When** the leaderboard fetch succeeds, **Then** the
   top scores are displayed; **When** it fails, **Then** locally kept scores are shown
   instead.
4. **Given** a submission fails, **When** the player continues, **Then** no error
   dialog blocks them and no retry is required from them.

---

### Edge Cases

- A double-parked pair: the outer car must be judged as double parking, the curb car as
  innocent, and both must be judged for misses in the right order when they pass.
- A "sloppy parker" just under the bike-lane intrusion threshold is innocent and must
  neither score as a violation nor count as a miss.
- The bus is mid-swerve around a bus lane blocker when the player captures it: the
  capture must still evaluate correctly.
- A moving car in the bus lane that the bus is following, then merging out: it is
  innocent throughout and must not be counted as a miss.
- The shift timer hits zero while the capture cooldown is active or a vehicle is
  mid-judgment: the shift ends cleanly and any in-flight verdict is either applied or
  discarded consistently, never double-counted.
- The score drops below zero: the negative value is shown with its sign on the HUD and
  results screen and submitted as-is; nothing is clamped or hidden.
- Name entry: an empty name, a name over 12 characters, a name containing digits,
  spaces, or symbols, or a name matching the profanity filter (including obvious
  spacing or casing variants) must be refused inline without leaving the entry screen.
  The player can always skip and submit under the neutral default name.
- The results idle timeout expires while the player is mid-way through typing a name:
  any keypress counts as input and cancels the auto-return, so this cannot happen
  unless the player has stopped interacting entirely.
- Debug menu opened during the count-in or on the results screen: it pauses whatever is
  running and resumes without skipping or duplicating the count-in.
- The game loses focus mid-shift: everything pauses, nothing is scored while hidden,
  and a 3-2-1 resume count-in plays on return. Repeated rapid focus loss and gain must
  not stack multiple count-ins.
- Focus is lost while the results idle timeout is counting down: the timeout keeps
  running, since the booth should still reset itself.
- Keyboard, touch, and gamepad inputs arrive simultaneously: the most recent input
  source wins and virtual controls appear or disappear accordingly.
- A new body style is added with no tuned plate or taillight data yet: the game must
  fall back to a sensible default anchor (centred, lower third of the sprite), log a
  clear message, and still render all three light states so the cue is never wrong.
- Two Start presses in quick succession (booth visitors mashing): only one shift
  starts.
- The leaderboard returns an entry with an empty or over-long name (submitted by an
  older or tampered client): the display must show a neutral placeholder or truncate
  without layout breakage.

## Requirements *(mandatory)*

### Functional Requirements

**Core loop and judgment**

- **FR-001**: The game MUST present a first-person view from a bus with a horizon in the
  upper third, a road converging to a vanishing point, and vehicles that grow with
  perspective as they approach and pass beneath the bus overlay.
- **FR-002**: The road MUST contain, left to right: median, passing lane, bus/travel
  lane (tinted), bike lane (tinted, dashed separator), parking lane/curb, and sidewalk
  with landmarks including a distinct bus stop stripe.
- **FR-003**: Everything fixed to the road (parked vehicles, road stencils, bus stop
  stripe, roadside props, buildings) MUST sweep past at road speed, while driving
  vehicles approach at a slower relative speed, so motion alone distinguishes parked
  from moving. The road surface itself is the premade static perspective image and its
  lane dashes do not scroll; the sweeping objects carry the motion cue.
- **FR-003a**: When the bus swerves, the road backdrop MUST slide sideways together
  with all road-fixed objects and vehicles so the whole view shifts, without exposing
  the backdrop's edges at the native aspect ratio.
- **FR-004**: A shift MUST begin with a 3-2-1 count-in during which input is ignored and
  no vehicles spawn, then run for a tunable duration (baseline 90 seconds).
- **FR-005**: During a shift the bus cruise speed MUST rise and the spawn interval MUST
  fall along tunable ramps (baseline 14 to 26 units/s and 1.5 s to 0.9 s).
- **FR-006**: The bus MUST swerve into the passing lane around a parked bus-lane blocker
  and return once past, and MUST brake to follow a moving bus-lane vehicle until that
  vehicle merges out, then accelerate again.
- **FR-007**: Vehicles MUST be spawned from a weighted situation table covering at least:
  moving traffic, legal curb parking, sloppy parker (innocent), bike lane violator, bus
  lane blocker, double-park pair, and bus stop zone violator. Spawning MUST NOT assign
  any violation label to a vehicle.
- **FR-008**: Violation status MUST be derived at judgment time from the vehicle's
  position, motion, and nearby landmarks using this ordered rulebook, first match wins:
  (1) moving, innocent; (2) stationary in the bus/travel lane, BUS LANE; (3) stationary
  beside a curb-parked vehicle, DOUBLE PARKING; (4) stationary past the bike lane
  intrusion threshold, BIKE LANE; (5) stationary at the curb inside a bus stop zone,
  BUS STOP; (6) otherwise innocent.
- **FR-009**: The same rulebook MUST be the single source of truth for both capture
  verdicts and missed-violation detection.
- **FR-010**: A capture MUST succeed only when the entire plate is inside the capture
  box and the vehicle is within the tunable readable distance. If several plates
  qualify, only the closest vehicle is judged. Each vehicle can be captured at most
  once.
- **FR-011**: Capturing a vehicle beyond readable distance MUST produce a "too far"
  message, no score change, and consume the cooldown. Capturing with no qualifying plate
  MUST produce shutter feedback only, no score change, and consume the cooldown.
- **FR-012**: Capture MUST have a short tunable cooldown (baseline 0.35 s).
- **FR-013**: Every capture MUST show feedback text that states the rulebook's verdict
  in plain words so the player learns the cues over time.
- **FR-014**: A captured vehicle's plate MUST be visibly marked for the rest of its time
  on screen, legibly over sprite art.
- **FR-015**: Missed violations MUST be evaluated the moment a vehicle passes under the
  bus, and double-park pairs MUST be judged before either vehicle is removed.
- **FR-015a**: When the game loses focus during a shift (browser tab hidden, app
  backgrounded, window minimised), the shift MUST pause immediately: the timer, bus,
  vehicles, and spawner all stop and no misses are evaluated. On regaining focus a
  3-2-1 resume count-in MUST play before control and spawning continue. Focus loss
  during the count-in or on non-gameplay screens MUST NOT require a resume count-in.

**Scoring**

- **FR-016**: The game MUST award tunable score values per event with these baselines:
  correct capture +100, wrong capture −25, missed violation −10, empty or unreadable
  capture 0. These reduce the prototype's penalties (−50 / −25) so scores climb faster
  and mistakes sting less.
- **FR-017**: Scoring MUST be balanced for convention play so that a typical first-time
  player finishes with a clearly positive score. There is no floor on the score; a
  negative total is possible but is expected to be rare at baseline tuning, and a
  negative value MUST be displayed clearly (with its sign) rather than hidden.
- **FR-018**: The results screen MUST show the final score and counts of correct, wrong,
  missed, and empty captures.

**Screens and flow**

- **FR-019**: The game MUST provide these screens with the flow Title → Count-in →
  Gameplay → Results, with Results offering Play Again (new shift) and Title, and Title
  offering Start, About, Settings, and Quit.
- **FR-020**: The title screen MUST show the game name and branding, a cheat-sheet of
  the visual cues, and the current top scores.
- **FR-021**: The About screen MUST give a plain-language elevator pitch of the
  real-world bus-mounted camera enforcement program and its purpose.
- **FR-022**: The Settings screen MUST provide Master, Music, and SFX volume controls
  whose values persist across sessions on every platform.
- **FR-023**: Quit MUST be hidden or inert on platforms where quitting is not
  meaningful.

**Presentation**

- **FR-024**: Vehicles MUST be rendered from imported rear-view sprite assets with
  multiple body styles and multiple colors per style, chosen at random and never
  correlated with violation status.
- **FR-025**: Every vehicle variant MUST present three taillight states: bright brake
  lights when stopped in the roadway, lights off when curb-parked, dim taillights when
  moving. The states MUST be produced by a lighting effect applied to the existing
  sprite at its taillight regions, so no per-variant light art is required. No vehicle
  may carry any violation marking.
- **FR-025a**: Every vehicle MUST show a license plate rendered as a shared plate
  overlay composited onto the sprite. The plate's position and size per body style
  MUST be tunable at runtime (debug menu) so each style can be aligned by eye, and
  the tuned values MUST be saved as that style's defaults.
- **FR-025b**: The taillight regions per body style MUST likewise be tunable at
  runtime so the lighting effect lands on the drawn lights of each sprite.
- **FR-026**: New vehicle variants and roadside props MUST be addable by placing assets
  in the designated folders under a documented naming convention, with no other change.
- **FR-027**: The capture box MUST remain a drawn reticle rather than an art asset.
- **FR-028**: The scene MUST include imported roadside props and buildings that scroll
  with the road, and an enhanced bus cab/hood overlay framing the bottom of the screen.
- **FR-029**: All screens MUST use a shared font set and visual theme.
- **FR-030**: The game MUST keep its native aspect ratio (baseline 1280 × 720) with no
  stretching; extra width becomes letterbox gutters.
- **FR-030a**: The game MUST use the premade art under `Assets/` (four vehicle body
  styles in six colors, fifteen building sprites per roadside, the sky and road
  backdrop, and the bus-lane and bike-lane road stencils) as the source art for those
  elements.
- **FR-030b**: Every visual element the game needs that has no premade asset MUST be
  rendered in development with one shared pink/black checkerboard "no texture"
  placeholder sprite, sized to the element, and MUST be listed in the spec's art asset
  inventory so the missing set is always visible. No placeholder may remain in a
  release build.

**Input**

- **FR-031**: All gameplay input MUST go through named actions (move up/down/left/right,
  capture) so that keyboard, touch, and gamepad are interchangeable.
- **FR-032**: Keyboard MUST support W/A/S/D for movement and Space for capture.
- **FR-033**: Touch MUST provide a virtual joystick in one gutter and a single capture
  button in the opposite gutter, shown only when touch is the active input and never
  over the playfield.
- **FR-034**: Gamepad MUST support the left stick or d-pad for movement and the primary
  face button for capture.
- **FR-035**: Android builds MUST be locked to landscape.
- **FR-036**: Capture box size and speed MUST be tunable, with keyboard values as the
  baseline (140 × 90 px, 420 px/s) and room for per-scheme adjustment.

**Audio**

- **FR-037**: The game MUST route sound through a Master channel with Music and SFX
  sub-channels, controlled by the Settings sliders.
- **FR-038**: The game MUST provide sound hooks for: count-in ticks, capture shutter,
  correct capture, wrong capture, missed violation, passing-car honks, shift end, and a
  looping background music track.
- **FR-039**: The game MUST run correctly with any or all audio assets absent.

**Leaderboard and persistence**

- **FR-040**: On shift end the game MUST submit score, stat breakdown, and player
  identity to a single shared global leaderboard and MUST fetch the current top scores
  for the title and results screens.
- **FR-040a**: The title and results screens MUST show the top 20 entries (rank, name,
  score). The results screen MUST also show the player's own rank for the shift just
  played, even when that rank is outside the top 20, and MUST highlight the player's
  entry when it is inside the top 20.
- **FR-041**: The game MUST never block or delay gameplay or screen transitions on
  network activity. Failed fetches or submissions MUST degrade to local-only display
  with a brief "leaderboard unavailable" note and no error dialog.
- **FR-042**: Scores MUST always be kept locally regardless of network outcome.
- **FR-043**: Player identity for the leaderboard MUST be a free-text name entered at
  shift end, limited to 1 to 12 characters, letters only (upper and lower case, no
  digits, spaces, or symbols). Names MUST be checked against a profanity filter
  covering common English profanity; a rejected name MUST be refused with a short
  message and the player asked to enter another. The most recently accepted name MUST
  be offered as the default on the next shift on the same machine.
- **FR-043a**: Name entry MUST be completable with keyboard, touch (on-screen
  keyboard), and gamepad, and MUST offer a skip that submits the score under a
  neutral default name so a visitor is never blocked from finishing.
- **FR-044**: No anti-cheat is required; forgeable scores are an accepted trade-off.

**Convention operation**

- **FR-045**: A visitor MUST be able to start a shift from the title screen with a
  single action and no prior setup.
- **FR-046**: The results screen MUST automatically return to the title screen after a
  tunable idle timeout (baseline 60 seconds) with no input, so an unattended booth
  resets itself between visitors. Any input during the countdown MUST cancel the
  auto-return. No attract loop or demo mode is included in this feature.

**Debug and tuning**

- **FR-047**: Every value that shapes gameplay feel (speeds, ramps, durations, intervals,
  weights, distances, thresholds, box size and speed, cooldown, score values, volumes)
  MUST be adjustable at runtime from a debug menu with immediate effect, and the menu
  MUST enumerate tunables automatically so adding one requires no menu change.
- **FR-048**: The debug menu MUST pause gameplay while open, MUST offer reset to
  documented defaults and local score reset, MUST be available in debug builds on every
  platform, and MUST be absent from release builds.
- **FR-049**: The game MUST provide tagged, timestamped debug logging.

**Platform**

- **FR-050**: The game MUST be playable in a web browser from a plain static host
  without special headers, and every feature MUST either work there or degrade with the
  core loop fully intact.
- **FR-051**: The game MUST also run on Windows desktop and Android.

### Key Entities

- **Shift**: One timed play session. Has a duration, elapsed time, current cruise speed,
  current spawn interval, a running score, and per-category counts (correct, wrong,
  missed, empty). Ends when time expires.
- **Vehicle**: A single car on the road. Has a lateral position, a distance from the
  bus, a motion state (moving, stopped in roadway, curb-parked), a body style and color
  variant, a plate, a captured flag, and a light state derived from its motion state.
- **Body Style**: One of the vehicle sprite families. Carries per-style tunable data:
  plate overlay position and size, and taillight regions for the lighting effect.
- **Situation**: A spawn template that places one or more vehicles and any needed
  landmarks (for example a bus stop zone) to create a judgment scenario. Carries a
  spawn weight. Never carries a violation label.
- **Landmark**: A road-fixed feature that affects judgment, such as a bus stop zone
  with an extent along the road, or lane boundaries and the bike lane intrusion
  threshold.
- **Verdict**: The result of evaluating a vehicle against the rulebook at a moment in
  time: one of BUS LANE, DOUBLE PARKING, BIKE LANE, BUS STOP, or INNOCENT.
- **Capture Attempt**: A single capture press. Records whether a plate qualified, which
  vehicle was judged, the verdict, and the resulting score change and feedback text.
- **Score Record**: The outcome of a completed shift: final score, category counts,
  timestamp, and player name (1 to 12 letters, or the neutral default when skipped). Kept locally and, when possible, submitted to the
  shared leaderboard.
- **Leaderboard Entry**: A score record as seen on the single global board, with its
  rank. The board is displayed as its top 20 plus the current player's own rank.
- **Settings**: Persisted player preferences: Master, Music, and SFX volume.
- **Tunable**: A named, typed behavior value with a documented default, current value,
  and allowed range, exposed in the debug menu.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time visitor can go from the title screen to actively playing in
  under 10 seconds with no instruction from staff.
- **SC-002**: A complete play session (start, count-in, shift, results) lasts under two
  and a half minutes at baseline settings.
- **SC-003**: In playtesting, at least 80% of first-time players finish their first shift
  with a positive score, and at least 90% of players correctly identify at least one
  violation type unprompted after one shift.
- **SC-004**: In playtesting, at least 70% of first-time players choose Play Again at
  least once.
- **SC-005**: Parked-versus-moving and each of the four violation situations can be
  distinguished by an observer watching the screen from two metres away without any
  on-vehicle marking.
- **SC-006**: The web build loads and reaches the title screen in under 10 seconds on a
  typical convention Wi-Fi connection and plays without visible stutter on a mid-range
  laptop.
- **SC-007**: The game plays a complete shift on web, Windows desktop, and Android with
  identical rules and scoring.
- **SC-008**: With connectivity removed, shift end to results screen takes no longer
  than with connectivity present, and no error dialog appears.
- **SC-009**: Every tunable listed in the baseline tuning table can be located and
  changed from the debug menu in under 30 seconds, and a newly added tunable appears
  in the menu with zero menu edits.
- **SC-010**: A new vehicle variant or roadside prop added to the asset folders appears
  in play with zero code or scene edits.
- **SC-011**: The game runs a full shift with no audio assets present and produces no
  errors.

## Assumptions

- **Convention tone drives tuning.** The gentle ramp, positive scoring skew, and
  readable cue sizes are design intents to be found through the debug menu rather than
  fixed numbers in this spec. The prototype's baseline tuning table is the starting
  point, not the target. The penalty values were deliberately halved or better from the
  prototype (−50 / −25 to −25 / −10) at spec time to favor higher scores.
- **Profanity filter.** A bundled list of common English profanity, matched
  case-insensitively against the whole name and as a substring, is sufficient. It is
  not expected to catch every variant; the goal is to keep obvious words off a public
  booth screen. The list is data, not code, so it can be extended without a rebuild.
- **Neutral default name.** Skipping name entry submits under a fixed placeholder
  (for example "Rookie"); the exact word is a tunable string.
- **Art asset inventory.** The premade art under `Assets/` is the art. What exists:
  - Vehicles: four rear-view body styles, six colors each (24 sprites). Taillights are
    drawn unlit and there is no license plate on the sprite.
  - Roadside: fifteen building sprites per side (left-facing and right-facing sets).
  - Backdrop: one pre-rendered perspective scene (sky with sun plus a six-lane road
    whose tinted bus and bike lanes match the GDD layout), also split into separate
    sky-only and road-only images.
  - Road stencils: "BUS ONLY" and bike-lane markings pre-sheared for perspective.

  Needed but **not provided** (checkerboard placeholder in development, must be called
  out in every plan and status until supplied):
  - One shared license plate overlay image (positioned per body style by tunable
    data). Taillight states need no art: they are a lighting effect on the sprite.
  - Bus cab/hood overlay framing the bottom of the screen.
  - Bus stop stripe / bus stop zone landmark on the curb.
  - Any roadside props other than buildings (signs, trees, hydrants) if wanted.
  - Median decoration.
  - Touch controls art (virtual joystick, capture button).
  - Fonts, UI theme elements, title branding, and About screen imagery.
  - Placeholder checkerboard sprite itself (a trivial generated texture).
- **Touch in mobile browsers.** The touch scheme is assumed to work in mobile browsers
  as well as the Android app, since web playability is a hard constraint and touch
  detection is platform-neutral.
- **Honk trigger.** Honks are assumed to fire probabilistically when a vehicle passes or
  is passed, with the probability tunable; specific-situation-only honks are a later
  refinement.
- **Debug menu access.** Per the constitution, the debug menu is available in debug
  builds on every platform (desktop toggle key, plus a debug-build-only on-screen or
  gesture trigger on touch) and absent from release builds.
- **Leaderboard hosting.** A hosted service reachable from a browser is assumed to be
  available and CORS-friendly; its cost and administration are outside this spec.
- **Audio content.** No audio tracks are authored in this feature; placeholder or
  missing sounds are acceptable.
- **Single player, single machine.** No simultaneous multi-player or split-screen play.
- **Out of scope** (carried from the GDD): curved roads, intersections, richer
  tricky-innocent cases, vehicle animation beyond light states, screen shake, object
  pooling, combo multipliers, strike systems, review-queue mechanic, difficulty
  settings, authored audio tracks, input rebinding UI.
- **Dependencies.** The prototype at `C:/code/gamedev/robo_narc` is the reference for
  mechanics and tuning; this repository's GDD is authoritative where the two differ.

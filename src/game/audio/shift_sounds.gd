class_name ShiftSounds
extends Node
## Connects shift events to their AudioCues event names (spec FR-038), so the
## mapping lives in one place and GameplayScreen only composes.

const CAPTURE_CUES: Dictionary = {
	CaptureOutcome.Kind.CORRECT: "capture_correct",
	CaptureOutcome.Kind.WRONG: "capture_wrong",
}


func bind(count_in: CountIn, capture_box: CaptureBox, score_keeper: ScoreKeeper,
		clock: ShiftClock, cues: AudioCues) -> void:
	count_in.tick_played.connect(func(_number: int) -> void: cues.play("count_in_tick"))
	capture_box.capture_attempted.connect(func(_rect: Rect2) -> void: cues.play("shutter"))
	score_keeper.capture_applied.connect(func(outcome: CaptureOutcome) -> void:
		var cue := cue_for_capture(outcome.kind)
		if not cue.is_empty():
			cues.play(cue))
	score_keeper.miss_applied.connect(func(_verdict: Verdict) -> void: cues.play("miss"))
	clock.ended.connect(func() -> void: cues.play("shift_end"))


## Empty for outcomes that only get the shutter (too far, empty, already captured).
static func cue_for_capture(kind: CaptureOutcome.Kind) -> String:
	return CAPTURE_CUES.get(kind, "")

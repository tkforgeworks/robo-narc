extends GutTest

var _pauser: FocusPauser


func before_each() -> void:
	_pauser = FocusPauser.new()
	add_child_autofree(_pauser)
	watch_signals(_pauser)


func after_each() -> void:
	get_tree().paused = false


func test_focus_out_pauses_and_focus_in_resumes() -> void:
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(get_tree().paused)
	assert_signal_emitted(_pauser, "paused")
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_false(get_tree().paused)
	assert_signal_emitted(_pauser, "resume_requested")


func test_hold_resume_waits_for_release() -> void:
	_pauser.hold_resume = true
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(get_tree().paused, "still paused until release")
	assert_signal_emitted(_pauser, "resume_requested")
	_pauser.release()
	assert_false(get_tree().paused)


func test_repeated_focus_loss_does_not_stack() -> void:
	_pauser.hold_resume = true
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_signal_emit_count(_pauser, "paused", 1)
	assert_signal_emit_count(_pauser, "resume_requested", 2)
	_pauser.release()
	assert_false(get_tree().paused)


func test_focus_in_without_focus_out_is_ignored() -> void:
	_pauser.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_signal_not_emitted(_pauser, "resume_requested")


func test_android_lifecycle_notifications() -> void:
	_pauser.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(get_tree().paused)
	_pauser.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_false(get_tree().paused)

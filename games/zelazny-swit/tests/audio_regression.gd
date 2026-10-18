extends SceneTree
## Exercise the actual eight-second ambience and deferred replay without native WAV looping.
var audio: Node
var checks: int = 0
var failures: int = 0
var finished_signals: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _run() -> void:
	if not "--test-isolated" in OS.get_cmdline_user_args():
		push_error("Supply --test-isolated for audio regression.")
		quit(2)
		return
	var script: Script = load("res://scripts/audio.gd")
	audio = script.new()
	root.add_child(audio)
	await process_frame
	var stream: AudioStreamWAV = audio.ambience.stream
	var stream_id: int = stream.get_instance_id()
	_check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,"actual ambience WAV uses no native loop mode")
	_check(is_equal_approx(stream.get_length(),8.0),"regression retains the actual original eight-second ambience")
	_check(audio.clips.size() == 7,"all seven original synthesized sound effects remain available")
	audio.ambience.finished.connect(_on_finished)
	# Headless startup intentionally mutes audio; explicitly enable its Dummy driver
	# so this regression tests the real stream rather than merely its metadata.
	audio.set_enabled(true)
	await create_timer(0.5).timeout
	_check(audio.ambience.playing and audio.ambience.get_playback_position() > 0.1,"actual audio playback advances on the audio driver")
	await create_timer(8.2).timeout
	var natural_completions: int = finished_signals
	_check(natural_completions >= 1,"eight-second ambience reaches its natural finished signal")
	_check(audio.ambience.playing and audio.ambience.get_playback_position() < 3.0,"natural completion safely restarts ambience on a later GUI turn")
	_check(audio.ambience.stream.get_instance_id() == stream_id,"ambience restart reuses the same WAV resource")
	var before_children: int = audio.get_child_count()
	audio.play_sfx("forge")
	audio.play_sfx("hit")
	audio.play_sfx("missing_sound")
	_check(audio.get_child_count() == before_children+2,"valid effects create their players and unknown effect creates none")
	await create_timer(1.0).timeout
	_check(audio.get_child_count() == before_children,"finished effects free temporary players")
	# Simulate a stream finishing immediately before the user mutes sound.
	audio.ambience.stop()
	audio.ambience.finished.emit()
	audio.set_enabled(false)
	await _frames(3)
	_check(not audio.ambience.playing and not audio.enabled,"muting before a deferred replay prevents queued ambience restart")
	audio.play_sfx("forge")
	_check(audio.get_child_count() == before_children,"muted effects allocate no players")
	audio.set_enabled(true)
	await _frames(3)
	_check(audio.ambience.playing and audio.ambience.stream.get_instance_id() == stream_id,"unmuting resumes the same valid ambience resource")
	audio.ambience.stop()
	audio.ambience.finished.emit()
	audio.queue_free()
	await _frames(3)
	_check(not is_instance_valid(audio),"leaving the scene safely disposes audio with a replay queued")
	# Let the audio mixer release its final playback reference before process exit.
	await create_timer(0.25).timeout
	print("AUDIO REGRESSION RESULT: %d checks, %d failures; natural_completions=%d" % [checks,failures,natural_completions])
	quit(0 if failures == 0 else 1)

func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame

func _on_finished() -> void:
	finished_signals += 1

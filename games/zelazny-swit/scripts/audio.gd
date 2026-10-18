extends Node
## Tiny original synthesized audio. No third party files or network dependencies.
var enabled: bool = true
var clips: Dictionary = {}
var ambience: AudioStreamPlayer
var _exiting: bool = false

func _ready() -> void:
	# A headless test/server has no audio device and needs no looping playback.
	enabled = enabled and DisplayServer.get_name() != "headless"
	clips.swing = _tone(0.16,180.0,55.0,0.21,0.65)
	clips.hit = _tone(0.16,95.0,37.0,0.3,0.8)
	clips.coin = _tone(0.32,880.0,1400.0,0.16,0.0)
	clips.heal = _tone(0.48,440.0,880.0,0.13,0.0)
	clips.skill = _tone(0.48,130.0,700.0,0.23,0.3)
	clips.level = _tone(0.75,400.0,1000.0,0.18,0.0)
	clips.forge = _tone(0.44,1200.0,280.0,0.2,0.25)
	_build_ambience()

func _tone(duration: float, start: float, finish: float, volume: float, noise: float) -> AudioStreamWAV:
	var rate: int = 22050
	var data: PackedByteArray = PackedByteArray()
	data.resize(int(duration * rate) * 2)
	var phase: float = 0.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8702
	for i: int in range(int(duration * rate)):
		var t: float = float(i) / rate
		var ratio: float = t / duration
		phase += TAU * lerpf(start,finish,ratio) / rate
		var sample: float = (sin(phase) * (1.0-noise) + rng.randf_range(-1,1)*noise) * volume * pow(1.0-ratio,2) * minf(t*90.0,1.0)
		data.encode_s16(i*2,int(clampf(sample,-1,1)*32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream

func _build_ambience() -> void:
	var rate: int = 22050
	var length: float = 8.0
	var data: PackedByteArray = PackedByteArray()
	data.resize(int(rate*length)*2)
	for i: int in range(int(rate*length)):
		var t: float = float(i)/rate
		var fade: float = sin(PI*t/length)*sin(PI*t/length)
		var sample: float = (sin(TAU*146.832*t)+sin(TAU*220.0*t)*0.5+sin(TAU*293.664*t)*0.23)*0.026*fade
		data.encode_s16(i*2,int(sample*32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	# Keep the native PCM decoder on its non-looping path. Some Godot versions
	# mix an inclusive loop_end while wrapping it as exclusive (GH-119778),
	# which reads past the data at a whole-stream forward-loop boundary.
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	ambience = AudioStreamPlayer.new()
	ambience.stream = stream
	ambience.volume_db = -10.0
	add_child(ambience)
	ambience.finished.connect(_on_ambience_finished)
	if enabled:
		ambience.play()

func _on_ambience_finished() -> void:
	if _exiting or not enabled or not is_inside_tree():
		return
	_diagnostic_note("audio_ambience_finished")
	# Reuse the same stream/player after signal dispatch, rather than entering
	# the native WAV-loop path or allocating another player every eight seconds.
	call_deferred("_restart_ambience")

func _restart_ambience() -> void:
	if _exiting or not enabled or not is_inside_tree() or not is_instance_valid(ambience):
		return
	if ambience.stream != null and not ambience.playing:
		ambience.play()

func play_sfx(key: String) -> void:
	if not enabled or not clips.has(key):
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = clips[key]
	player.volume_db = -4.0
	add_child(player)
	player.finished.connect(player.queue_free)
	_diagnostic_note("audio_sfx_play",{"category":key})
	player.play()

func _diagnostic_note(event_name: String, data: Dictionary = {}) -> void:
	var diagnostics: Node = get_node_or_null("/root/Diagnostics")
	if is_instance_valid(diagnostics) and diagnostics.has_method("note"):
		diagnostics.call("note",event_name,data)

func set_enabled(value: bool) -> void:
	enabled = value
	if is_instance_valid(ambience):
		if enabled:
			ambience.play()
		else:
			ambience.stop()

func _exit_tree() -> void:
	# Release the loop before AudioServer shuts down, including headless runs.
	_exiting = true
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
	clips.clear()

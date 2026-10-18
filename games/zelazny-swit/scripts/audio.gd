extends Node
## Tiny original synthesized audio. No third party files or network dependencies.
var enabled: bool = true
var clips: Dictionary = {}
var ambience: AudioStreamPlayer
var _exiting: bool = false
var _combat_swings: Array[AudioStreamWAV] = []
var _combat_hits: Array[AudioStreamWAV] = []
var _stone_hits: Array[AudioStreamWAV] = []
var _fire_impact: AudioStreamWAV
const MAX_SFX_VOICES: int = 12
var _sfx_voices: Array[AudioStreamPlayer] = []

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
	for step: int in range(4):
		_combat_swings.append(_combat_sound(step,false,false))
		_combat_hits.append(_combat_sound(step,true,false))
		_stone_hits.append(_combat_sound(step,true,true))
	_fire_impact = _ground_impact()
	_build_ambience()

func _pcm_stream(data: PackedByteArray,rate: int = 22050) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream

func _combat_sound(step: int,contact: bool,stone: bool) -> AudioStreamWAV:
	# Layered air, a short blade transient and a damped low body. The finisher
	# has more mass; three preceding cuts keep separate pitches/envelopes.
	var rate: int = 22050
	var heavy: bool = step==3
	var duration: float = (0.31 if heavy else 0.20) if contact else (0.30 if heavy else 0.18+step*0.015)
	var count: int = int(duration*rate)
	var data := PackedByteArray()
	data.resize(count*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 51821+step*771+(111 if contact else 0)+(909 if stone else 0)
	var filtered: float = 0.0
	var phase: float = 0.0
	for i: int in range(count):
		var t: float = float(i)/rate
		var progress: float = t/duration
		var noise: float = rng.randf_range(-1,1)
		filtered = lerpf(filtered,noise,0.19 if contact else 0.08)
		var sample: float
		if contact:
			phase += TAU*lerpf(108.0-step*7.0,51.0,progress)/rate
			var body: float = sin(phase)*exp(-t*(20.0 if heavy else 34.0))*0.31
			var thock: float = filtered*exp(-t*42.0)*0.83
			var strike: float = (noise-filtered)*exp(-t*110.0)*0.20
			var metal: float = (sin(TAU*(1340.0+step*190.0)*t)+0.34*sin(TAU*2813.0*t))*exp(-t*(23.0 if stone else 70.0))*(0.10 if stone else 0.025)
			sample = body+thock+strike+metal
		else:
			var envelope: float = pow(sin(PI*progress),1.6)*(1.0-progress*0.35)
			var air: float = (noise-filtered)*0.13+filtered*0.32
			var whisper: float = sin(TAU*(740.0-step*90.0)*t)*0.014
			sample = (air+whisper)*envelope
		# A short fade avoids clicks even when a transient starts at sample zero.
		sample *= minf(1.0,t*1500.0)*clampf((duration-t)*180.0,0.0,1.0)
		data.encode_s16(i*2,int(clampf(sample,-0.8,0.8)*32767))
	return _pcm_stream(data,rate)

func _ground_impact() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.54
	var count: int = int(rate*duration)
	var data := PackedByteArray()
	data.resize(count*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 292514
	var low_noise: float = 0.0
	var phase: float = 0.0
	for i: int in range(count):
		var t: float = float(i)/rate
		var noise: float = rng.randf_range(-1,1)
		low_noise = lerpf(low_noise,noise,0.11)
		phase += TAU*lerpf(91.0,37.0,t/duration)/rate
		var body: float = sin(phase)*exp(-t*11.0)*0.40
		var gravel: float = low_noise*exp(-t*15.0)*0.75
		var flame: float = (noise-low_noise)*exp(-t*8.0)*0.08
		var sample: float = (body+gravel+flame)*minf(1.0,t*1800.0)*clampf((duration-t)*100.0,0.0,1.0)
		data.encode_s16(i*2,int(clampf(sample,-0.85,0.85)*32767))
	return _pcm_stream(data,rate)

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
	_play_stream(clips[key])
	_diagnostic_note("audio_sfx_play",{"category":key})

func play_cut_swing(step: int) -> void:
	if not _combat_swings.is_empty():
		_play_stream(_combat_swings[clampi(step-1,0,3)],-3.0)

func play_cut_hit(step: int,stone: bool = false,critical: bool = false) -> void:
	var sounds: Array[AudioStreamWAV] = _stone_hits if stone else _combat_hits
	if not sounds.is_empty():
		_play_stream(sounds[clampi(step-1,0,3)],-1.8 if critical else -3.0)

func play_fire_impact() -> void:
	if _fire_impact != null:
		_play_stream(_fire_impact,-3.0)

func _play_stream(stream: AudioStream,volume: float = -4.0) -> void:
	if not enabled or _exiting or stream == null or _sfx_voices.size()>=MAX_SFX_VOICES:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	_sfx_voices.append(player)
	player.finished.connect(func() -> void:
		_sfx_voices.erase(player)
		player.queue_free()
	)
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
	if not enabled:
		for player: AudioStreamPlayer in _sfx_voices:
			if is_instance_valid(player):
				player.stop()
				player.queue_free()
		_sfx_voices.clear()

func _exit_tree() -> void:
	# Release the loop before AudioServer shuts down, including headless runs.
	_exiting = true
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
	clips.clear()
	_sfx_voices.clear()
	_combat_swings.clear()
	_combat_hits.clear()
	_stone_hits.clear()
	_fire_impact = null

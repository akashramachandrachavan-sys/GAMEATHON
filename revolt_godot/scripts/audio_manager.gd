extends Node

# Procedural Sound Generator for REVOLT 2150
# Generates punchy retro-futuristic combat sound effects on the fly

var shoot_stream: AudioStreamWAV
var emp_stream: AudioStreamWAV
var hit_stream: AudioStreamWAV
var explosion_stream: AudioStreamWAV
var reprogram_stream: AudioStreamWAV
var dash_stream: AudioStreamWAV
var step_stream: AudioStreamWAV
var alert_stream: AudioStreamWAV

func _ready() -> void:
	shoot_stream = _create_shoot_sound()
	emp_stream = _create_emp_sound()
	hit_stream = _create_hit_sound()
	explosion_stream = _create_explosion_sound()
	reprogram_stream = _create_reprogram_sound()
	dash_stream = _create_dash_sound()
	step_stream = _create_step_sound()
	alert_stream = _create_alert_sound()

func play_sound(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_shoot(pitch: float = 1.0) -> void:
	play_sound(shoot_stream, -4.0, pitch)

func play_emp() -> void:
	play_sound(emp_stream, 2.0, 1.0)

func play_hit() -> void:
	play_sound(hit_stream, -6.0, randf_range(0.85, 1.2))

func play_explosion() -> void:
	play_sound(explosion_stream, 3.0, randf_range(0.8, 1.1))

func play_reprogram() -> void:
	play_sound(reprogram_stream, 2.0, 1.0)

func play_dash() -> void:
	play_sound(dash_stream, 0.0, 1.0)

func play_step() -> void:
	play_sound(step_stream, -10.0, randf_range(0.9, 1.1))

func play_alert() -> void:
	play_sound(alert_stream, 0.0, 1.0)

# Sound Generators (Sample rate: 22050 Hz, 8-bit / 16-bit PCM)
func _create_shoot_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.15
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 28.0)
		var freq = 320.0 * (1.0 - t / duration) + 80.0
		var tone = sin(t * freq * TAU)
		var noise = (randf() * 2.0 - 1.0) * 0.4
		var sample = (tone * 0.7 + noise * 0.3) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_emp_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.6
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 4.0)
		var freq = 120.0 + sin(t * 45.0) * 80.0 + t * 400.0
		var tone = sin(t * freq * TAU)
		var zap = sin(t * 1800.0 * TAU) * 0.3
		var sample = (tone * 0.7 + zap) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_hit_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.12
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 35.0)
		var tone = sin(t * 600.0 * TAU)
		var metal = sin(t * 1450.0 * TAU) * 0.5
		var sample = (tone * 0.5 + metal * 0.5) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_explosion_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.8
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 5.0)
		var noise = (randf() * 2.0 - 1.0)
		var rumble = sin(t * 65.0 * TAU) * 0.8
		var sample = (noise * 0.6 + rumble * 0.4) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_reprogram_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.5
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = min(t * 15.0, 1.0) * exp(-t * 3.5)
		# Ascending arpeggio
		var freq = 440.0
		if t > 0.1: freq = 554.37
		if t > 0.2: freq = 659.25
		if t > 0.3: freq = 880.0
		var tone = sin(t * freq * TAU)
		var sample = tone * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_dash_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.3
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 9.0)
		var freq = 200.0 * exp(-t * 5.0) + 40.0
		var sample = ((randf() * 2.0 - 1.0) * 0.5 + sin(t * freq * TAU) * 0.5) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_step_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.1
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 40.0)
		var sample = sin(t * 85.0 * TAU) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_alert_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.25
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 10.0)
		var tone = sin(t * 900.0 * TAU)
		var sample = tone * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

extends Node

# Procedural Sound Generator for REVOLT 2150
# Generates punchy retro-futuristic combat sound effects on the fly

var shoot_stream: AudioStreamWAV
var shotgun_stream: AudioStreamWAV
var railgun_stream: AudioStreamWAV
var emp_stream: AudioStreamWAV
var hit_stream: AudioStreamWAV
var explosion_stream: AudioStreamWAV
var reprogram_stream: AudioStreamWAV
var dash_stream: AudioStreamWAV
var step_stream: AudioStreamWAV
var alert_stream: AudioStreamWAV
var switch_stream: AudioStreamWAV
var shield_break_stream: AudioStreamWAV
var stim_stream: AudioStreamWAV
var overclock_stream: AudioStreamWAV

func _ready() -> void:
	shoot_stream = _create_shoot_sound()
	shotgun_stream = _create_shotgun_sound()
	railgun_stream = _create_railgun_sound()
	emp_stream = _create_emp_sound()
	hit_stream = _create_hit_sound()
	explosion_stream = _create_explosion_sound()
	reprogram_stream = _create_reprogram_sound()
	dash_stream = _create_dash_sound()
	step_stream = _create_step_sound()
	alert_stream = _create_alert_sound()
	switch_stream = _create_switch_sound()
	shield_break_stream = _create_shield_break_sound()
	stim_stream = _create_stim_sound()
	overclock_stream = _create_overclock_sound()

func play_sound(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_shoot(pitch: float = 1.0) -> void:
	play_sound(shoot_stream, -3.0, pitch)

func play_shotgun() -> void:
	play_sound(shotgun_stream, 1.0, randf_range(0.9, 1.1))

func play_railgun() -> void:
	play_sound(railgun_stream, 2.5, randf_range(0.95, 1.05))

func play_weapon_switch() -> void:
	play_sound(switch_stream, -2.0, 1.0)

func play_shield_break() -> void:
	play_sound(shield_break_stream, 2.0, 1.0)

func play_stim() -> void:
	play_sound(stim_stream, 1.0, 1.0)

func play_overclock() -> void:
	play_sound(overclock_stream, 2.5, 1.0)

func play_emp() -> void:
	play_sound(emp_stream, 2.0, 1.0)

func play_hit() -> void:
	play_sound(hit_stream, -5.0, randf_range(0.85, 1.2))

func play_explosion() -> void:
	play_sound(explosion_stream, 3.5, randf_range(0.8, 1.1))

func play_reprogram() -> void:
	play_sound(reprogram_stream, 2.0, 1.0)

func play_dash() -> void:
	play_sound(dash_stream, 0.0, 1.0)

func play_step() -> void:
	play_sound(step_stream, -10.0, randf_range(0.9, 1.1))

func play_alert() -> void:
	play_sound(alert_stream, 0.0, 1.0)

# Sound Generators (Sample rate: 22050 Hz, 16-bit PCM)
func _create_shoot_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.15
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 28.0)
		var freq = 340.0 * (1.0 - t / duration) + 90.0
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

func _create_shotgun_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 14.0)
		var bass = sin(t * 70.0 * TAU) * exp(-t * 8.0)
		var noise = (randf() * 2.0 - 1.0) * exp(-t * 18.0)
		var sample = (bass * 0.6 + noise * 0.6) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_railgun_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.55
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 8.0)
		var zap = sin(t * 1400.0 * TAU * (1.0 - t * 1.2)) * 0.5
		var boom = sin(t * 65.0 * TAU) * exp(-t * 6.0) * 0.6
		var sample = (zap + boom) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_switch_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.08
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 45.0)
		var sample = sin(t * 1200.0 * TAU) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_shield_break_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.4
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 9.0)
		var glass = sin(t * 2200.0 * TAU) * 0.4 + sin(t * 1600.0 * TAU) * 0.4
		var sample = glass * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_stim_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.3
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 12.0)
		var tone = sin(t * 600.0 * TAU) * 0.5 + sin(t * 950.0 * TAU) * 0.5
		var sample = tone * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_overclock_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.7
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 3.5)
		var riser = sin(t * (200.0 + t * 900.0) * TAU) * 0.7
		var sample = riser * env
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
		var sample = (sin(t * 160.0 * TAU) * 0.6 + (randf() * 2.0 - 1.0) * 0.4) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_explosion_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 1.2
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 2.8)
		var bass = sin(t * 45.0 * TAU) * exp(-t * 2.0)
		var rumble = (randf() * 2.0 - 1.0) * 0.6
		var sample = (bass * 0.7 + rumble * 0.4) * env
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
		var env = exp(-t * 3.5)
		var tone1 = sin(t * 440.0 * TAU)
		var tone2 = sin(t * 880.0 * TAU)
		var chirp = sin(t * (1200.0 + sin(t * 80.0) * 400.0) * TAU) * 0.4
		var sample = (tone1 * 0.4 + tone2 * 0.3 + chirp) * env
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_dash_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.22
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

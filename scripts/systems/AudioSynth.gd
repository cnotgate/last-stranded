class_name AudioSynth
extends RefCounted

static func generate_beep(freq: float = 880.0, duration: float = 0.15) -> AudioStreamWAV:
	var sample_rate = 44100
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var time = i / float(sample_rate)
		# Sine wave
		var wave = sin(time * freq * TAU)
		# Sharp attack, fast decay envelope (like a digital click/beep)
		var envelope = exp(-time * 25.0) 
		
		var sample = int(wave * envelope * 24000.0) # slightly reduced volume
		sample = clamp(sample, -32768, 32767)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream

static func generate_breath(duration: float = 5.0) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var last_val = 0.0
	for i in range(total_samples):
		var time = i / float(sample_rate)
		var phase = time / duration
		
		# White noise base
		var noise = randf_range(-1.0, 1.0)
		
		var envelope = 0.0
		var filter_alpha = 0.05 # How muffled the noise is (lower = more muffled)
		var mech_whine = 0.0
		
		if phase < 0.35:
			# INHALE: Smooth natural build-up, smooth release
			var p = phase / 0.35
			# Smooth sine curve for organic inhale
			envelope = pow(sin(p * PI), 1.2)
			envelope *= 0.8
			filter_alpha = 0.3 # Hissy air noise
			
			# Gentle mechanical hum scaled by envelope so it doesn't click
			mech_whine = sin(time * 180.0 * TAU) * 0.03 * envelope
			
		elif phase > 0.45 and phase < 0.90:
			# EXHALE: Muffled, moderate start, slow fading end
			var p = (phase - 0.45) / 0.45
			# Reaches peak smoothly over first 20%, then slowly fades out
			envelope = min(p * 5.0, 1.0) * pow(1.0 - p, 1.5)
			envelope *= 0.65
			filter_alpha = 0.06 # Very muffled (breathing into mask)
			
			# Deeper hum during exhale, also scaled by envelope
			mech_whine = sin(time * 140.0 * TAU) * 0.02 * envelope
			
		# Apply low-pass filter
		var filtered = last_val + filter_alpha * (noise - last_val)
		last_val = filtered
		
		# Combine noise and mechanical hum, envelope is already applied to whine, apply to filtered
		var final_signal = (filtered * envelope) + mech_whine
		
		var sample = int(final_signal * 32767.0 * 2.2)
		sample = clamp(sample, -32768, 32767)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	return stream

static func generate_heartbeat(duration: float = 1.0) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var current_phase = 0.0
	
	for i in range(total_samples):
		var time = i / float(sample_rate)
		
		var envelope = 0.0
		var freq = 0.0
		
		# Heartbeat consists of two pulses: lub (0.0 to 0.15) and dub (0.25 to 0.40)
		if time < 0.15:
			# Lub (first dug)
			var p = time / 0.15
			envelope = sin(p * PI) * exp(-p * 3.0)
			# Rapid pitch drop from 120Hz down to 30Hz (Kick drum synthesis)
			freq = lerp(120.0, 30.0, pow(p, 0.4))
		elif time > 0.25 and time < 0.40:
			# Dub (second dug)
			var p = (time - 0.25) / 0.15
			envelope = sin(p * PI) * exp(-p * 4.0) * 0.7
			freq = lerp(150.0, 35.0, pow(p, 0.4))
			
		# Integrate frequency for proper pitch sweep
		current_phase += freq / sample_rate
		var wave = sin(current_phase * TAU)
		
		# Mild saturation/clipping for extra "thump" warmth
		var sig = wave * envelope * 1.5
		sig = clamp(sig, -1.0, 1.0)
		
		var sample = int(sig * 32767.0 * 0.8) # 0.8 to prevent max peaking
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	return stream

static func generate_warning(duration: float = 1.0) -> AudioStreamWAV:
	var sample_rate = 44100
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var time = i / float(sample_rate)
		
		var envelope = 0.0
		# Two quick urgent beeps
		if time < 0.1:
			envelope = 1.0
		elif time > 0.15 and time < 0.25:
			envelope = 1.0
			
		# Dissonant dual-frequency tone for an alarm effect
		var freq1 = 1200.0
		var freq2 = 1240.0
		var wave = (sin(time * freq1 * TAU) + sin(time * freq2 * TAU)) * 0.5
		
		# Apply a slight square wave clipping for harsher electronic sound
		wave = sign(wave) * pow(abs(wave), 0.5)
		
		var sig = wave * envelope * 0.35 # Volume control
		var sample = int(sig * 32767.0)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	return stream

static func generate_rescue_alarm(duration: float = 1.0) -> AudioStreamWAV:
	var sample_rate = 44100
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var time = i / float(sample_rate)
		
		var envelope = 0.0
		# Long, steady pulse (0.4s on, 0.6s off)
		if time < 0.4:
			envelope = 1.0
			
		# Low, serious frequency
		var freq = 350.0
		var wave = sin(time * freq * TAU)
		
		# Square wave for industrial/robotic feel
		wave = sign(wave)
		
		var sig = wave * envelope * 0.15 # Lower volume since square wave is loud
		var sample = int(sig * 32767.0)
		
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	return stream

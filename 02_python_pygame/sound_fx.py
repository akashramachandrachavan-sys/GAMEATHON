"""
Procedural 8-bit Sound Generator for Pygame.
Generates sound waves programmatically with zero external .wav files!
"""
import pygame
import math
import array
import random

SAMPLE_RATE = 22050

def generate_tone(freq, duration, wave_type='square', decay=True):
    n_samples = int(duration * SAMPLE_RATE)
    buf = array.array('h')
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        factor = (1.0 - (i / n_samples)) if decay else 1.0
        
        if wave_type == 'square':
            val = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        elif wave_type == 'sawtooth':
            val = 2.0 * ((freq * t) % 1.0) - 1.0
        elif wave_type == 'sine':
            val = math.sin(2 * math.pi * freq * t)
        elif wave_type == 'noise':
            val = random.uniform(-1.0, 1.0)
        else:
            val = 0.0

        sample = int(val * factor * 14000)
        buf.append(sample)
    return pygame.mixer.Sound(buffer=buf)

def generate_laser():
    # Frequency sweep downwards
    duration = 0.12
    n_samples = int(duration * SAMPLE_RATE)
    buf = array.array('h')
    for i in range(n_samples):
        t = i / n_samples
        freq = 800 * (1.0 - t) + 120
        phase = 2 * math.pi * freq * (i / SAMPLE_RATE)
        val = 1.0 if math.sin(phase) > 0 else -1.0
        factor = 1.0 - t
        buf.append(int(val * factor * 12000))
    return pygame.mixer.Sound(buffer=buf)

def generate_explosion():
    # Filtered noise burst
    duration = 0.28
    n_samples = int(duration * SAMPLE_RATE)
    buf = array.array('h')
    for i in range(n_samples):
        t = i / n_samples
        factor = (1.0 - t) ** 1.8
        val = random.uniform(-1.0, 1.0)
        buf.append(int(val * factor * 14000))
    return pygame.mixer.Sound(buffer=buf)

def generate_pickup():
    # Two-tone ascending chime
    duration = 0.15
    n_samples = int(duration * SAMPLE_RATE)
    half = n_samples // 2
    buf = array.array('h')
    for i in range(n_samples):
        freq = 523 if i < half else 784 # C5 to G5
        t = i / SAMPLE_RATE
        val = math.sin(2 * math.pi * freq * t)
        factor = 1.0 - (i % half) / half
        buf.append(int(val * factor * 14000))
    return pygame.mixer.Sound(buffer=buf)

def generate_hit():
    # Low thud with noise
    duration = 0.1
    n_samples = int(duration * SAMPLE_RATE)
    buf = array.array('h')
    for i in range(n_samples):
        t = i / n_samples
        freq = 180 * (1.0 - t) + 40
        val = math.sin(2 * math.pi * freq * (i / SAMPLE_RATE)) * 0.7 + random.uniform(-0.3, 0.3)
        factor = 1.0 - t
        buf.append(int(val * factor * 15000))
    return pygame.mixer.Sound(buffer=buf)

class SoundManager:
    def __init__(self):
        self.enabled = True
        try:
            pygame.mixer.init(frequency=SAMPLE_RATE, size=-16, channels=1)
            self.laser = generate_laser()
            self.explosion = generate_explosion()
            self.pickup = generate_pickup()
            self.hit = generate_hit()
        except Exception as e:
            print("Sound initialization failed:", e)
            self.enabled = False

    def play_laser(self):
        if self.enabled: self.laser.play()

    def play_explosion(self):
        if self.enabled: self.explosion.play()

    def play_pickup(self):
        if self.enabled: self.pickup.play()

    def play_hit(self):
        if self.enabled: self.hit.play()

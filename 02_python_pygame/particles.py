import pygame
import random
import math

class Particle:
    def __init__(self, x, y, color, size=4, max_speed=120):
        self.x = x
        self.y = y
        self.color = color
        self.size = size
        angle = random.uniform(0, math.pi * 2)
        speed = random.uniform(20, max_speed)
        self.vx = math.cos(angle) * speed
        self.vy = math.sin(angle) * speed
        self.life = random.uniform(0.3, 0.6)
        self.max_life = self.life

    def update(self, dt):
        self.x += self.vx * dt
        self.y += self.vy * dt
        self.vx *= 0.92
        self.vy *= 0.92
        self.life -= dt

    def draw(self, surface):
        if self.life > 0:
            alpha = max(0, self.life / self.max_life)
            current_size = max(1, int(self.size * alpha))
            rect = pygame.Rect(int(self.x - current_size / 2), int(self.y - current_size / 2), current_size, current_size)
            pygame.draw.rect(surface, self.color, rect)

class FloatingText:
    def __init__(self, x, y, text, color=(255, 255, 255), size=18):
        self.x = x
        self.y = y
        self.text = text
        self.color = color
        self.size = size
        self.life = 0.8
        self.font = pygame.font.SysFont("Helvetica", size, bold=True)

    def update(self, dt):
        self.y -= 40 * dt
        self.life -= dt

    def draw(self, surface):
        if self.life > 0:
            rendered = self.font.render(self.text, True, self.color)
            surface.blit(rendered, (int(self.x - rendered.get_width() / 2), int(self.y)))

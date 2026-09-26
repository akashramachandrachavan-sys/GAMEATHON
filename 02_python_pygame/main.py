"""
CYBER STRIKE - Pygame 4-Hour Gameathon Engine
Controls:
  - WASD / Arrows : Move
  - Mouse Aim & Left-Click : Shoot
  - P / Esc : Pause
  - F1 : Judge God Mode (Invincible toggle)
  - Space : Restart on Game Over
"""
import sys
import math
import random
import os
import pygame

from sound_fx import SoundManager
from particles import Particle, FloatingText

# ==========================================
# CONFIGURATION & THEME
# ==========================================
SCREEN_WIDTH = 960
SCREEN_HEIGHT = 640
FPS = 60

COLOR_BG = (10, 14, 22)
COLOR_GRID = (20, 30, 48)
COLOR_PLAYER = (0, 240, 255)
COLOR_BULLET = (255, 230, 0)
COLOR_ENEMY_BASIC = (255, 0, 100)
COLOR_ENEMY_TANK = (255, 120, 0)
COLOR_ENEMY_FAST = (180, 0, 255)
COLOR_TEXT = (240, 245, 250)

class Bullet:
    def __init__(self, x, y, angle, speed=600, damage=25):
        self.x = x
        self.y = y
        self.vx = math.cos(angle) * speed
        self.vy = math.sin(angle) * speed
        self.radius = 4
        self.damage = damage
        self.alive = True

    def update(self, dt):
        self.x += self.vx * dt
        self.y += self.vy * dt
        if self.x < -10 or self.x > SCREEN_WIDTH + 10 or self.y < -10 or self.y > SCREEN_HEIGHT + 10:
            self.alive = False

    def draw(self, surface):
        pygame.draw.circle(surface, COLOR_BULLET, (int(self.x), int(self.y)), self.radius)

class Enemy:
    def __init__(self, x, y, enemy_type='basic'):
        self.x = x
        self.y = y
        self.enemy_type = enemy_type
        if enemy_type == 'basic':
            self.radius = 14
            self.speed = 120
            self.hp = 30
            self.max_hp = 30
            self.color = COLOR_ENEMY_BASIC
            self.score_val = 50
        elif enemy_type == 'tank':
            self.radius = 22
            self.speed = 65
            self.hp = 100
            self.max_hp = 100
            self.color = COLOR_ENEMY_TANK
            self.score_val = 150
        elif enemy_type == 'fast':
            self.radius = 10
            self.speed = 190
            self.hp = 20
            self.max_hp = 20
            self.color = COLOR_ENEMY_FAST
            self.score_val = 80
        self.alive = True

    def update(self, dt, player_x, player_y):
        angle = math.atan2(player_y - self.y, player_x - self.x)
        self.x += math.cos(angle) * self.speed * dt
        self.y += math.sin(angle) * self.speed * dt

    def take_damage(self, amount):
        self.hp -= amount
        if self.hp <= 0:
            self.alive = False
            return True
        return False

    def draw(self, surface):
        pos = (int(self.x), int(self.y))
        pygame.draw.circle(surface, self.color, pos, self.radius)
        # Draw HP bar if damaged
        if self.hp < self.max_hp:
            bar_w = self.radius * 2
            bar_h = 4
            pct = max(0, self.hp / self.max_hp)
            pygame.draw.rect(surface, (50, 50, 50), (int(self.x - bar_w/2), int(self.y - self.radius - 8), bar_w, bar_h))
            pygame.draw.rect(surface, (0, 255, 100), (int(self.x - bar_w/2), int(self.y - self.radius - 8), int(bar_w * pct), bar_h))

class Player:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.radius = 16
        self.speed = 280
        self.hp = 100
        self.max_hp = 100
        self.angle = 0
        self.fire_rate = 0.16
        self.fire_timer = 0
        self.god_mode = False
        self.invulnerable_timer = 0
        self.weapon_level = 1

    def update(self, dt, keys, mouse_pos, mouse_click, bullets, sounds):
        # Movement
        dx, dy = 0, 0
        if keys[pygame.K_w] or keys[pygame.K_UP]: dy -= 1
        if keys[pygame.K_s] or keys[pygame.K_DOWN]: dy += 1
        if keys[pygame.K_a] or keys[pygame.K_LEFT]: dx -= 1
        if keys[pygame.K_d] or keys[pygame.K_RIGHT]: dx += 1

        if dx != 0 and dy != 0:
            dx *= 0.7071
            dy *= 0.7071

        self.x += dx * self.speed * dt
        self.y += dy * self.speed * dt

        # Boundaries
        self.x = max(self.radius + 10, min(SCREEN_WIDTH - self.radius - 10, self.x))
        self.y = max(self.radius + 10, min(SCREEN_HEIGHT - self.radius - 10, self.y))

        # Aim towards mouse
        self.angle = math.atan2(mouse_pos[1] - self.y, mouse_pos[0] - self.x)

        # Timers
        if self.fire_timer > 0: self.fire_timer -= dt
        if self.invulnerable_timer > 0: self.invulnerable_timer -= dt

        # Fire
        if mouse_click and self.fire_timer <= 0:
            sounds.play_laser()
            if self.weapon_level == 1:
                bullets.append(Bullet(self.x, self.y, self.angle))
            elif self.weapon_level >= 2:
                bullets.append(Bullet(self.x, self.y, self.angle - 0.15))
                bullets.append(Bullet(self.x, self.y, self.angle + 0.15))
            self.fire_timer = self.fire_rate

    def take_damage(self, amount, sounds):
        if self.god_mode or self.invulnerable_timer > 0:
            return False
        self.hp -= amount
        self.invulnerable_timer = 0.4
        sounds.play_hit()
        return self.hp <= 0

    def draw(self, surface):
        # Draw pointing triangle
        tip_x = self.x + math.cos(self.angle) * 20
        tip_y = self.y + math.sin(self.angle) * 20
        left_x = self.x + math.cos(self.angle + 2.5) * 16
        left_y = self.y + math.sin(self.angle + 2.5) * 16
        right_x = self.x + math.cos(self.angle - 2.5) * 16
        right_y = self.y + math.sin(self.angle - 2.5) * 16

        color = (255, 255, 0) if self.god_mode else COLOR_PLAYER
        pygame.draw.polygon(surface, color, [(tip_x, tip_y), (left_x, left_y), (self.x, self.y), (right_x, right_y)])

class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("IEEE GAMEATHON - Cyber Strike")
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        self.clock = pygame.time.Clock()
        self.font = pygame.font.SysFont("Helvetica", 16, bold=True)
        self.title_font = pygame.font.SysFont("Helvetica", 42, bold=True)
        self.sounds = SoundManager()

        self.state = "MENU" # MENU, PLAYING, PAUSED, GAMEOVER
        self.score = 0
        self.high_score = 0
        self.wave = 1
        self.load_high_score()
        self.reset_game()

    def load_high_score(self):
        try:
            if os.path.exists("highscore.txt"):
                with open("highscore.txt", "r") as f:
                    self.high_score = int(f.read().strip())
        except Exception:
            self.high_score = 0

    def save_high_score(self):
        if self.score > self.high_score:
            self.high_score = self.score
            try:
                with open("highscore.txt", "w") as f:
                    f.write(str(self.high_score))
            except Exception:
                pass

    def reset_game(self):
        self.player = Player(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2)
        self.bullets = []
        self.enemies = []
        self.particles = []
        self.floating_texts = []
        self.score = 0
        self.wave = 1
        self.enemies_spawned = 0
        self.total_enemies_in_wave = 10
        self.spawn_timer = 0
        self.shake_amount = 0

    def spawn_enemy(self):
        # Random edge
        if random.random() < 0.5:
            x = random.choice([-20, SCREEN_WIDTH + 20])
            y = random.uniform(0, SCREEN_HEIGHT)
        else:
            x = random.uniform(0, SCREEN_WIDTH)
            y = random.choice([-20, SCREEN_HEIGHT + 20])

        rand = random.random()
        etype = 'basic'
        if self.wave >= 2 and rand < 0.3:
            etype = 'fast'
        elif self.wave >= 3 and rand > 0.7:
            etype = 'tank'

        self.enemies.append(Enemy(x, y, etype))
        self.enemies_spawned += 1

    def run(self):
        running = True
        while running:
            dt = self.clock.tick(FPS) / 1000.0
            dt = min(dt, 0.1)

            # Event handling
            mouse_click = False
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE or event.key == pygame.K_p:
                        if self.state == "PLAYING": self.state = "PAUSED"
                        elif self.state == "PAUSED": self.state = "PLAYING"
                    elif event.key == pygame.K_F1:
                        self.player.god_mode = not self.player.god_mode
                        self.floating_texts.append(FloatingText(self.player.x, self.player.y - 30, f"GOD MODE: {self.player.god_mode}", (255, 230, 0)))
                    elif event.key == pygame.K_SPACE:
                        if self.state == "MENU" or self.state == "GAMEOVER":
                            self.reset_game()
                            self.state = "PLAYING"
                elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    mouse_click = True

            keys = pygame.key.get_pressed()
            mouse_pos = pygame.mouse.get_pos()
            mouse_down = pygame.mouse.get_pressed()[0]

            if self.state == "PLAYING":
                self.update_playing(dt, keys, mouse_pos, mouse_down or mouse_click)

            self.draw()

        self.save_high_score()
        pygame.quit()
        sys.exit()

    def update_playing(self, dt, keys, mouse_pos, mouse_down):
        # Update shake
        if self.shake_amount > 0:
            self.shake_amount -= dt * 20
            if self.shake_amount < 0: self.shake_amount = 0

        # Update player
        self.player.update(dt, keys, mouse_pos, mouse_down, self.bullets, self.sounds)

        # Spawning
        if self.enemies_spawned < self.total_enemies_in_wave:
            self.spawn_timer -= dt
            if self.spawn_timer <= 0:
                self.spawn_enemy()
                self.spawn_timer = max(0.4, 1.8 - self.wave * 0.1)
        elif len(self.enemies) == 0:
            # Wave clear
            self.wave += 1
            self.enemies_spawned = 0
            self.total_enemies_in_wave = 10 + self.wave * 4
            self.player.hp = min(self.player.max_hp, self.player.hp + 25)
            if self.wave >= 3: self.player.weapon_level = 2
            self.floating_texts.append(FloatingText(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2, f"WAVE {self.wave}!", (0, 255, 255), 28))
            self.sounds.play_pickup()

        # Update bullets
        for b in self.bullets[:]:
            b.update(dt)
            if not b.alive:
                self.bullets.remove(b)
                continue
            for e in self.enemies[:]:
                dist = math.hypot(b.x - e.x, b.y - e.y)
                if dist < b.radius + e.radius:
                    self.bullets.remove(b)
                    killed = e.take_damage(b.damage)
                    # Spawn hit particles
                    for _ in range(4):
                        self.particles.append(Particle(e.x, e.y, e.color, size=3, max_speed=80))
                    if killed:
                        self.enemies.remove(e)
                        self.score += e.score_val
                        self.sounds.play_explosion()
                        self.shake_amount = 6
                        self.floating_texts.append(FloatingText(e.x, e.y, f"+{e.score_val}", (255, 230, 0)))
                        for _ in range(12):
                            self.particles.append(Particle(e.x, e.y, e.color, size=5, max_speed=160))
                    break

        # Update enemies
        for e in self.enemies[:]:
            e.update(dt, self.player.x, self.player.y)
            dist = math.hypot(e.x - self.player.x, e.y - self.player.y)
            if dist < e.radius + self.player.radius:
                dead = self.player.take_damage(15, self.sounds)
                self.shake_amount = 12
                for _ in range(8):
                    self.particles.append(Particle(self.player.x, self.player.y, (255, 0, 50), size=4))
                if dead:
                    self.state = "GAMEOVER"
                    self.save_high_score()

        # Particles & text
        for p in self.particles[:]:
            p.update(dt)
            if p.life <= 0: self.particles.remove(p)

        for ft in self.floating_texts[:]:
            ft.update(dt)
            if ft.life <= 0: self.floating_texts.remove(ft)

    def draw(self):
        # Shake offset
        shake_x = random.uniform(-self.shake_amount, self.shake_amount) if self.shake_amount > 0 else 0
        shake_y = random.uniform(-self.shake_amount, self.shake_amount) if self.shake_amount > 0 else 0

        canvas = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT))
        canvas.fill(COLOR_BG)

        # Draw grid
        for x in range(0, SCREEN_WIDTH, 40):
            pygame.draw.line(canvas, COLOR_GRID, (x, 0), (x, SCREEN_HEIGHT))
        for y in range(0, SCREEN_HEIGHT, 40):
            pygame.draw.line(canvas, COLOR_GRID, (0, y), (SCREEN_WIDTH, y))

        # Draw entities
        for p in self.particles: p.draw(canvas)
        for b in self.bullets: b.draw(canvas)
        for e in self.enemies: e.draw(canvas)
        if self.state in ["PLAYING", "PAUSED"]:
            self.player.draw(canvas)
        for ft in self.floating_texts: ft.draw(canvas)

        # HUD
        score_text = self.font.render(f"SCORE: {self.score}   WAVE: {self.wave}   HIGH: {self.high_score}", True, COLOR_TEXT)
        canvas.blit(score_text, (20, 20))

        hp_pct = max(0, self.player.hp / self.player.max_hp)
        pygame.draw.rect(canvas, (40, 40, 40), (20, SCREEN_HEIGHT - 35, 180, 16))
        pygame.draw.rect(canvas, (0, 255, 100), (20, SCREEN_HEIGHT - 35, int(180 * hp_pct), 16))
        hp_text = self.font.render(f"HP: {int(self.player.hp)}", True, (255, 255, 255))
        canvas.blit(hp_text, (210, SCREEN_HEIGHT - 37))

        if self.player.god_mode:
            god_lbl = self.font.render("[F1: GOD MODE ACTIVE]", True, (255, 230, 0))
            canvas.blit(god_lbl, (SCREEN_WIDTH - 220, 20))

        # Screen Overlays
        if self.state == "MENU":
            self.draw_overlay(canvas, "CYBER STRIKE", "PRESS SPACE TO START", "WASD to Move | Mouse to Shoot | F1 for Demo God Mode")
        elif self.state == "PAUSED":
            self.draw_overlay(canvas, "PAUSED", "PRESS P TO RESUME", "")
        elif self.state == "GAMEOVER":
            self.draw_overlay(canvas, "GAME OVER", f"FINAL SCORE: {self.score}", "PRESS SPACE TO RETRY")

        self.screen.blit(canvas, (shake_x, shake_y))
        pygame.display.flip()

    def draw_overlay(self, canvas, title, sub, extra):
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
        overlay.fill((5, 8, 15, 210))
        canvas.blit(overlay, (0, 0))

        t = self.title_font.render(title, True, (0, 240, 255))
        s = self.font.render(sub, True, (255, 255, 255))
        canvas.blit(t, (SCREEN_WIDTH // 2 - t.get_width() // 2, SCREEN_HEIGHT // 2 - 60))
        canvas.blit(s, (SCREEN_WIDTH // 2 - s.get_width() // 2, SCREEN_HEIGHT // 2 + 10))
        if extra:
            e = self.font.render(extra, True, (160, 175, 195))
            canvas.blit(e, (SCREEN_WIDTH // 2 - e.get_width() // 2, SCREEN_HEIGHT // 2 + 50))

if __name__ == "__main__":
    game = Game()
    game.run()

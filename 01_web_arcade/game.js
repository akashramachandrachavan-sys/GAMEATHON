/**
 * CYBER SURVIVOR - 4-Hour Gameathon Canvas Engine
 * Built for rapid reskinning, instant browser play, and maximum visual juice!
 */

// ==========================================
// 1. CONFIGURATION & EDITABLE THEME CONSTANTS
// (Modify these values to match your hackathon theme!)
// ==========================================
const CONFIG = {
  CANVAS_WIDTH: 960,
  CANVAS_HEIGHT: 640,
  PLAYER_SPEED: 280,
  PLAYER_MAX_HP: 100,
  DASH_SPEED: 650,
  DASH_DURATION: 0.18, // seconds
  DASH_COOLDOWN: 1.2, // seconds
  COLORS: {
    background: '#090b10',
    gridLines: 'rgba(0, 240, 255, 0.05)',
    player: '#00f0ff',
    playerTrail: 'rgba(0, 240, 255, 0.3)',
    bullet: '#ffe600',
    drone: '#ff007f',
    brute: '#ff5500',
    shooter: '#a000ff',
    boss: '#ff0033',
    pickupHp: '#00ff66',
    pickupWeapon: '#ffe600'
  }
};

// ==========================================
// 2. PARTICLES & FLOATING TEXT (JUICE SYSTEM)
// ==========================================
class Particle {
  constructor(x, y, vx, vy, color, size, life) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.color = color;
    this.size = size;
    this.maxLife = life;
    this.life = life;
  }

  update(dt) {
    this.x += this.vx * dt;
    this.y += this.vy * dt;
    this.vx *= 0.94; // friction
    this.vy *= 0.94;
    this.life -= dt;
  }

  draw(ctx) {
    const alpha = Math.max(0, this.life / this.maxLife);
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.fillStyle = this.color;
    ctx.shadowColor = this.color;
    ctx.shadowBlur = 8;
    ctx.fillRect(this.x - this.size / 2, this.y - this.size / 2, this.size, this.size);
    ctx.restore();
  }
}

class FloatingText {
  constructor(x, y, text, color = '#fff', size = 16) {
    this.x = x;
    this.y = y;
    this.text = text;
    this.color = color;
    this.size = size;
    this.life = 0.8;
    this.maxLife = 0.8;
  }

  update(dt) {
    this.y -= 45 * dt;
    this.life -= dt;
  }

  draw(ctx) {
    const alpha = Math.max(0, this.life / this.maxLife);
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.font = `bold ${this.size}px 'Press Start 2P', monospace`;
    ctx.fillStyle = this.color;
    ctx.shadowColor = this.color;
    ctx.shadowBlur = 10;
    ctx.textAlign = 'center';
    ctx.fillText(this.text, this.x, this.y);
    ctx.restore();
  }
}

// ==========================================
// 3. PROJECTILES & WEAPONS
// ==========================================
class Bullet {
  constructor(x, y, angle, speed, damage, isPlayer = true, color = CONFIG.COLORS.bullet) {
    this.x = x;
    this.y = y;
    this.vx = Math.cos(angle) * speed;
    this.vy = Math.sin(angle) * speed;
    this.damage = damage;
    this.isPlayer = isPlayer;
    this.color = color;
    this.radius = isPlayer ? 4 : 5;
    this.life = 2.0; // max seconds alive
  }

  update(dt) {
    this.x += this.vx * dt;
    this.y += this.vy * dt;
    this.life -= dt;
  }

  draw(ctx) {
    ctx.save();
    ctx.fillStyle = this.color;
    ctx.shadowColor = this.color;
    ctx.shadowBlur = 12;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
}

// ==========================================
// 4. ENTITIES: PLAYER & ENEMIES
// ==========================================
class Player {
  constructor(x, y) {
    this.x = x;
    this.y = y;
    this.radius = 16;
    this.angle = 0;
    this.hp = CONFIG.PLAYER_MAX_HP;
    this.maxHp = CONFIG.PLAYER_MAX_HP;

    // Movement & Dash
    this.dashTimer = 0;
    this.dashCooldownTimer = 0;
    this.isDashing = false;
    this.dashDirX = 0;
    this.dashDirY = 0;

    // Shooting
    this.fireTimer = 0;
    this.fireRate = 0.16; // seconds per shot
    this.weaponLevel = 1; // 1: Blaster, 2: Dual, 3: Triple Spread, 4: Plasma Rapid

    // Invulnerability
    this.invulnerableTimer = 0;
    this.godMode = false;
  }

  update(dt, input, game) {
    // Dash timers
    if (this.dashCooldownTimer > 0) this.dashCooldownTimer -= dt;
    if (this.invulnerableTimer > 0) this.invulnerableTimer -= dt;

    if (this.isDashing) {
      this.dashTimer -= dt;
      this.x += this.dashDirX * CONFIG.DASH_SPEED * dt;
      this.y += this.dashDirY * CONFIG.DASH_SPEED * dt;

      // Spawn dash particles
      if (Math.random() < 0.6) {
        game.spawnParticles(this.x, this.y, CONFIG.COLORS.playerTrail, 2, 60);
      }

      if (this.dashTimer <= 0) {
        this.isDashing = false;
      }
    } else {
      // Normal movement
      let dx = 0;
      let dy = 0;
      if (input.keys['KeyW'] || input.keys['ArrowUp']) dy -= 1;
      if (input.keys['KeyS'] || input.keys['ArrowDown']) dy += 1;
      if (input.keys['KeyA'] || input.keys['ArrowLeft']) dx -= 1;
      if (input.keys['KeyD'] || input.keys['ArrowRight']) dx += 1;

      if (dx !== 0 && dy !== 0) {
        const norm = Math.SQRT1_2;
        dx *= norm;
        dy *= norm;
      }

      this.x += dx * CONFIG.PLAYER_SPEED * dt;
      this.y += dy * CONFIG.PLAYER_SPEED * dt;

      // Trigger dash with Spacebar
      if (input.keys['Space'] && this.dashCooldownTimer <= 0 && (dx !== 0 || dy !== 0)) {
        this.isDashing = true;
        this.dashTimer = CONFIG.DASH_DURATION;
        this.dashCooldownTimer = CONFIG.DASH_COOLDOWN;
        this.dashDirX = dx;
        this.dashDirY = dy;
        this.invulnerableTimer = CONFIG.DASH_DURATION + 0.1;
        game.screenShake(6, 0.2);
        window.soundEngine.playDash();
      }
    }

    // Keep player in bounds
    this.x = Math.max(this.radius + 10, Math.min(CONFIG.CANVAS_WIDTH - this.radius - 10, this.x));
    this.y = Math.max(this.radius + 10, Math.min(CONFIG.CANVAS_HEIGHT - this.radius - 10, this.y));

    // Rotate towards mouse crosshair
    const mouseX = input.mouse.x;
    const mouseY = input.mouse.y;
    this.angle = Math.atan2(mouseY - this.y, mouseX - this.x);

    // Shooting
    this.fireTimer -= dt;
    if (input.mouse.down && this.fireTimer <= 0) {
      this.shoot(game);
      this.fireTimer = this.fireRate;
    }
  }

  shoot(game) {
    window.soundEngine.playShoot(this.weaponLevel >= 3 ? 'laser' : 'normal');
    game.screenShake(2, 0.08);

    const speed = 750;
    const dmg = 25;

    if (this.weaponLevel === 1) {
      // Single Blaster
      game.bullets.push(new Bullet(this.x, this.y, this.angle, speed, dmg, true));
    } else if (this.weaponLevel === 2) {
      // Dual Cannons
      const perpX = Math.cos(this.angle + Math.PI / 2) * 8;
      const perpY = Math.sin(this.angle + Math.PI / 2) * 8;
      game.bullets.push(new Bullet(this.x + perpX, this.y + perpY, this.angle, speed, dmg, true));
      game.bullets.push(new Bullet(this.x - perpX, this.y - perpY, this.angle, speed, dmg, true));
    } else if (this.weaponLevel >= 3) {
      // Triple Spread
      [-0.18, 0, 0.18].forEach(spread => {
        game.bullets.push(new Bullet(this.x, this.y, this.angle + spread, speed, dmg, true));
      });
    }
  }

  takeDamage(amount, game) {
    if (this.godMode || this.invulnerableTimer > 0) return;
    this.hp -= amount;
    this.invulnerableTimer = 0.4;
    game.screenShake(10, 0.3);
    window.soundEngine.playHit();
    game.spawnParticles(this.x, this.y, '#ff0055', 12, 160);

    if (this.hp <= 0) {
      this.hp = 0;
      game.gameOver();
    }
  }

  draw(ctx) {
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate(this.angle);

    // Invulnerability blink
    if (this.invulnerableTimer > 0 && Math.floor(Date.now() / 60) % 2 === 0) {
      ctx.globalAlpha = 0.4;
    }

    // Ship body
    ctx.fillStyle = CONFIG.COLORS.player;
    ctx.shadowColor = CONFIG.COLORS.player;
    ctx.shadowBlur = this.godMode ? 25 : 12;

    ctx.beginPath();
    ctx.moveTo(18, 0);
    ctx.lineTo(-14, -13);
    ctx.lineTo(-6, 0);
    ctx.lineTo(-14, 13);
    ctx.closePath();
    ctx.fill();

    // Thruster flame
    ctx.fillStyle = '#ffaa00';
    ctx.beginPath();
    ctx.moveTo(-7, -4);
    ctx.lineTo(-18 - Math.random() * 6, 0);
    ctx.lineTo(-7, 4);
    ctx.closePath();
    ctx.fill();

    ctx.restore();
  }
}

class Enemy {
  constructor(x, y, type = 'drone') {
    this.x = x;
    this.y = y;
    this.type = type;
    this.shootTimer = 1.5 + Math.random() * 2;

    if (type === 'drone') {
      this.radius = 12;
      this.hp = 30;
      this.maxHp = 30;
      this.speed = 150 + Math.random() * 40;
      this.color = CONFIG.COLORS.drone;
      this.scoreVal = 50;
      this.touchDamage = 15;
    } else if (type === 'brute') {
      this.radius = 24;
      this.hp = 140;
      this.maxHp = 140;
      this.speed = 70;
      this.color = CONFIG.COLORS.brute;
      this.scoreVal = 150;
      this.touchDamage = 35;
    } else if (type === 'shooter') {
      this.radius = 16;
      this.hp = 60;
      this.maxHp = 60;
      this.speed = 100;
      this.color = CONFIG.COLORS.shooter;
      this.scoreVal = 100;
      this.touchDamage = 15;
    } else if (type === 'boss') {
      this.radius = 42;
      this.hp = 900;
      this.maxHp = 900;
      this.speed = 50;
      this.color = CONFIG.COLORS.boss;
      this.scoreVal = 1500;
      this.touchDamage = 50;
    }
  }

  update(dt, player, game) {
    const angle = Math.atan2(player.y - this.y, player.x - this.x);

    // Drone & Brute rush the player
    if (this.type === 'drone' || this.type === 'brute' || this.type === 'boss') {
      this.x += Math.cos(angle) * this.speed * dt;
      this.y += Math.sin(angle) * this.speed * dt;
    } else if (this.type === 'shooter') {
      // Shooter keeps a distance
      const dist = Math.hypot(player.x - this.x, player.y - this.y);
      if (dist > 300) {
        this.x += Math.cos(angle) * this.speed * dt;
        this.y += Math.sin(angle) * this.speed * dt;
      } else if (dist < 180) {
        this.x -= Math.cos(angle) * this.speed * dt;
        this.y -= Math.sin(angle) * this.speed * dt;
      }

      // Shoot projectile
      this.shootTimer -= dt;
      if (this.shootTimer <= 0) {
        this.shootTimer = 2.2;
        game.bullets.push(new Bullet(this.x, this.y, angle, 240, 15, false, '#ff00aa'));
      }
    }

    // Boss attack patterns
    if (this.type === 'boss') {
      this.shootTimer -= dt;
      if (this.shootTimer <= 0) {
        this.shootTimer = 1.8;
        // 8-way burst
        for (let i = 0; i < 8; i++) {
          const bossAngle = (i / 8) * Math.PI * 2;
          game.bullets.push(new Bullet(this.x, this.y, bossAngle, 190, 20, false, '#ff0033'));
        }
      }
    }
  }

  takeDamage(dmg, game) {
    this.hp -= dmg;
    game.spawnParticles(this.x, this.y, this.color, 4, 80);
    if (this.hp <= 0) {
      this.hp = 0;
      return true; // killed
    }
    return false;
  }

  draw(ctx) {
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.fillStyle = this.color;
    ctx.shadowColor = this.color;
    ctx.shadowBlur = 12;

    if (this.type === 'drone') {
      // Diamond
      ctx.beginPath();
      ctx.moveTo(0, -this.radius);
      ctx.lineTo(this.radius, 0);
      ctx.lineTo(0, this.radius);
      ctx.lineTo(-this.radius, 0);
      ctx.closePath();
      ctx.fill();
    } else if (this.type === 'brute') {
      // Octagon / Sturdy box
      ctx.fillRect(-this.radius, -this.radius, this.radius * 2, this.radius * 2);
    } else if (this.type === 'shooter') {
      // Inverted Triangle
      ctx.beginPath();
      ctx.moveTo(-this.radius, -this.radius);
      ctx.lineTo(this.radius, -this.radius);
      ctx.lineTo(0, this.radius);
      ctx.closePath();
      ctx.fill();
    } else if (this.type === 'boss') {
      // Large spiky skull / mech
      ctx.beginPath();
      ctx.arc(0, 0, this.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = '#fff';
      ctx.fillRect(-15, -8, 8, 8);
      ctx.fillRect(7, -8, 8, 8);
    }

    // Health bar above enemy if damaged
    if (this.hp < this.maxHp) {
      const barW = this.radius * 2;
      const barH = 4;
      const pct = this.hp / this.maxHp;
      ctx.fillStyle = 'rgba(0,0,0,0.6)';
      ctx.fillRect(-barW / 2, -this.radius - 10, barW, barH);
      ctx.fillStyle = '#00ff66';
      ctx.fillRect(-barW / 2, -this.radius - 10, barW * pct, barH);
    }

    ctx.restore();
  }
}

class Pickup {
  constructor(x, y, type = 'hp') {
    this.x = x;
    this.y = y;
    this.type = type; // 'hp', 'weapon'
    this.radius = 10;
    this.life = 12; // disappears after 12s
    this.pulse = 0;
  }

  update(dt) {
    this.life -= dt;
    this.pulse += dt * 5;
  }

  draw(ctx) {
    ctx.save();
    const scale = 1 + Math.sin(this.pulse) * 0.15;
    ctx.translate(this.x, this.y);
    ctx.scale(scale, scale);

    const color = this.type === 'hp' ? CONFIG.COLORS.pickupHp : CONFIG.COLORS.pickupWeapon;
    ctx.fillStyle = color;
    ctx.shadowColor = color;
    ctx.shadowBlur = 10;

    ctx.beginPath();
    ctx.arc(0, 0, this.radius, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#000';
    ctx.font = 'bold 9px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(this.type === 'hp' ? '+' : 'W', 0, 0);

    ctx.restore();
  }
}

// ==========================================
// 5. MAIN GAME ENGINE
// ==========================================
class GameEngine {
  constructor() {
    this.canvas = document.getElementById('gameCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.state = 'MENU'; // 'MENU', 'PLAYING', 'PAUSED', 'UPGRADE', 'GAMEOVER'

    this.score = 0;
    this.highScore = parseInt(localStorage.getItem('ieee_gameathon_highscore') || '0', 10);
    this.wave = 1;
    this.kills = 0;

    // Entities
    this.player = new Player(CONFIG.CANVAS_WIDTH / 2, CONFIG.CANVAS_HEIGHT / 2);
    this.enemies = [];
    this.bullets = [];
    this.pickups = [];
    this.particles = [];
    this.floatingTexts = [];

    // Screen shake
    this.shakeIntensity = 0;
    this.shakeDuration = 0;

    // Waves & Spawning
    this.waveSpawnTimer = 0;
    this.enemiesSpawnedThisWave = 0;
    this.totalEnemiesInWave = 10;
    this.waveTransitionTimer = 0;

    // Input tracker
    this.input = {
      keys: {},
      mouse: { x: CONFIG.CANVAS_WIDTH / 2, y: CONFIG.CANVAS_HEIGHT / 2, down: false }
    };

    this.lastTime = performance.now();
    this.setupInputs();
    this.setupUI();
    this.updateHUD();
  }

  setupInputs() {
    window.addEventListener('keydown', (e) => {
      this.input.keys[e.code] = true;

      // Toggle Pause
      if (e.code === 'KeyP' || e.code === 'Escape') {
        if (this.state === 'PLAYING') this.pauseGame();
        else if (this.state === 'PAUSED') this.resumeGame();
      }

      // Hackathon Judge / Debug keys
      if (e.code === 'F1') {
        e.preventDefault();
        this.player.godMode = !this.player.godMode;
        this.addFloatingText(this.player.x, this.player.y - 30, `GOD MODE: ${this.player.godMode ? 'ON' : 'OFF'}`, '#ffe600', 14);
      }
      if (e.code === 'F2') {
        e.preventDefault();
        this.completeWave();
      }
      if (e.code === 'F3') {
        e.preventDefault();
        this.score += 5000;
        this.updateHUD();
      }

      // Restart on Space when in Game Over
      if (e.code === 'Space' && this.state === 'GAMEOVER') {
        this.startGame();
      }
    });

    window.addEventListener('keyup', (e) => {
      this.input.keys[e.code] = false;
    });

    const updateMousePos = (e) => {
      const rect = this.canvas.getBoundingClientRect();
      const scaleX = this.canvas.width / rect.width;
      const scaleY = this.canvas.height / rect.height;
      this.input.mouse.x = (e.clientX - rect.left) * scaleX;
      this.input.mouse.y = (e.clientY - rect.top) * scaleY;
    };

    this.canvas.addEventListener('mousemove', updateMousePos);
    this.canvas.addEventListener('mousedown', (e) => {
      this.input.mouse.down = true;
      updateMousePos(e);
      window.soundEngine.init();
    });
    window.addEventListener('mouseup', () => {
      this.input.mouse.down = false;
    });

    // Touch support for testing on tablets/phones
    this.canvas.addEventListener('touchmove', (e) => {
      e.preventDefault();
      const touch = e.touches[0];
      const rect = this.canvas.getBoundingClientRect();
      this.input.mouse.x = (touch.clientX - rect.left) * (this.canvas.width / rect.width);
      this.input.mouse.y = (touch.clientY - rect.top) * (this.canvas.height / rect.height);
      this.input.mouse.down = true;
    }, { passive: false });

    this.canvas.addEventListener('touchstart', (e) => {
      e.preventDefault();
      window.soundEngine.init();
      const touch = e.touches[0];
      const rect = this.canvas.getBoundingClientRect();
      this.input.mouse.x = (touch.clientX - rect.left) * (this.canvas.width / rect.width);
      this.input.mouse.y = (touch.clientY - rect.top) * (this.canvas.height / rect.height);
      this.input.mouse.down = true;
    }, { passive: false });

    this.canvas.addEventListener('touchend', () => {
      this.input.mouse.down = false;
    });
  }

  setupUI() {
    // Menu Start
    document.getElementById('btn-start').addEventListener('click', () => {
      window.soundEngine.init();
      this.startGame();
    });

    // Toggle sound
    const btnSound = document.getElementById('btn-toggle-sound');
    btnSound.addEventListener('click', () => {
      window.soundEngine.init();
      const isOn = window.soundEngine.toggle();
      btnSound.textContent = `SOUND: ${isOn ? 'ON' : 'OFF'}`;
    });

    // Pause Resume & Restart
    document.getElementById('btn-resume').addEventListener('click', () => this.resumeGame());
    document.getElementById('btn-restart-pause').addEventListener('click', () => this.startGame());

    // Game Over Retry
    document.getElementById('btn-retry').addEventListener('click', () => this.startGame());
  }

  startGame() {
    this.state = 'PLAYING';
    this.score = 0;
    this.wave = 1;
    this.kills = 0;
    this.enemies = [];
    this.bullets = [];
    this.pickups = [];
    this.particles = [];
    this.floatingTexts = [];
    this.player = new Player(CONFIG.CANVAS_WIDTH / 2, CONFIG.CANVAS_HEIGHT / 2);

    this.enemiesSpawnedThisWave = 0;
    this.totalEnemiesInWave = 12;
    this.waveSpawnTimer = 0;

    document.getElementById('menu-screen').classList.add('hidden');
    document.getElementById('gameover-screen').classList.add('hidden');
    document.getElementById('pause-screen').classList.add('hidden');
    document.getElementById('upgrade-screen').classList.add('hidden');
    document.getElementById('hud').classList.remove('hidden');

    this.updateHUD();
    window.soundEngine.startBGM();
    this.addFloatingText(CONFIG.CANVAS_WIDTH / 2, CONFIG.CANVAS_HEIGHT / 2 - 50, 'WAVE 1 START!', '#00f0ff', 24);
  }

  pauseGame() {
    this.state = 'PAUSED';
    document.getElementById('pause-screen').classList.remove('hidden');
    window.soundEngine.stopBGM();
  }

  resumeGame() {
    this.state = 'PLAYING';
    document.getElementById('pause-screen').classList.add('hidden');
    window.soundEngine.startBGM();
    this.lastTime = performance.now();
  }

  gameOver() {
    this.state = 'GAMEOVER';
    window.soundEngine.stopBGM();
    window.soundEngine.playGameOver();

    if (this.score > this.highScore) {
      this.highScore = this.score;
      localStorage.setItem('ieee_gameathon_highscore', this.highScore.toString());
    }

    document.getElementById('final-score').textContent = this.score;
    document.getElementById('final-wave').textContent = this.wave;
    document.getElementById('final-kills').textContent = this.kills;

    document.getElementById('hud').classList.add('hidden');
    document.getElementById('gameover-screen').classList.remove('hidden');
  }

  screenShake(intensity, duration) {
    this.shakeIntensity = Math.max(this.shakeIntensity, intensity);
    this.shakeDuration = Math.max(this.shakeDuration, duration);
  }

  spawnParticles(x, y, color, count = 8, maxSpeed = 100) {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = (Math.random() * 0.7 + 0.3) * maxSpeed;
      const vx = Math.cos(angle) * speed;
      const vy = Math.sin(angle) * speed;
      const size = Math.random() * 3 + 2;
      const life = Math.random() * 0.4 + 0.2;
      this.particles.push(new Particle(x, y, vx, vy, color, size, life));
    }
  }

  addFloatingText(x, y, text, color = '#fff', size = 14) {
    this.floatingTexts.push(new FloatingText(x, y, text, color, size));
  }

  updateHUD() {
    document.getElementById('score-display').textContent = this.score;
    document.getElementById('wave-display').textContent = this.wave;
    document.getElementById('high-score-display').textContent = this.highScore;

    const hpPct = Math.max(0, (this.player.hp / this.player.maxHp) * 100);
    const fill = document.getElementById('health-bar-fill');
    fill.style.width = `${hpPct}%`;
    document.getElementById('health-text').textContent = `${Math.ceil(this.player.hp)} / ${this.player.maxHp}`;

    const weapons = ['BLASTER', 'DUAL CANNONS', 'SPREAD-3', 'CYBER LASER'];
    document.getElementById('weapon-display').textContent = weapons[Math.min(this.player.weaponLevel - 1, weapons.length - 1)];
  }

  spawnEnemy() {
    // Spawn along perimeter
    let x, y;
    if (Math.random() < 0.5) {
      x = Math.random() < 0.5 ? -20 : CONFIG.CANVAS_WIDTH + 20;
      y = Math.random() * CONFIG.CANVAS_HEIGHT;
    } else {
      x = Math.random() * CONFIG.CANVAS_WIDTH;
      y = Math.random() < 0.5 ? -20 : CONFIG.CANVAS_HEIGHT + 20;
    }

    // Determine type by wave
    let type = 'drone';
    const rand = Math.random();

    if (this.wave >= 2 && rand < 0.3) {
      type = 'shooter';
    } else if (this.wave >= 3 && rand > 0.75) {
      type = 'brute';
    }

    this.enemies.push(new Enemy(x, y, type));
    this.enemiesSpawnedThisWave++;
  }

  completeWave() {
    this.wave++;
    this.enemiesSpawnedThisWave = 0;
    this.totalEnemiesInWave = 10 + this.wave * 4;

    window.soundEngine.playPowerup();
    this.addFloatingText(CONFIG.CANVAS_WIDTH / 2, CONFIG.CANVAS_HEIGHT / 2, `WAVE ${this.wave} INCOMING!`, '#ffe600', 22);

    // Offer upgrade modal every 2 waves
    if (this.wave % 2 === 0) {
      this.showUpgradeScreen();
    }

    // Spawn Boss every 5 waves
    if (this.wave % 5 === 0) {
      this.enemies.push(new Enemy(CONFIG.CANVAS_WIDTH / 2, -50, 'boss'));
      this.addFloatingText(CONFIG.CANVAS_WIDTH / 2, 100, '⚠️ BOSS DETECTED ⚠️', '#ff0033', 26);
      this.screenShake(12, 0.6);
    }

    this.updateHUD();
  }

  showUpgradeScreen() {
    this.state = 'UPGRADE';
    const container = document.getElementById('upgrade-cards-container');
    container.innerHTML = '';

    const upgradePool = [
      {
        id: 'weapon',
        icon: '⚡',
        title: 'WEAPON UPGRADE',
        desc: 'Upgrade cannon fire rate & bullet spreads.',
        action: () => {
          this.player.weaponLevel++;
          this.addFloatingText(this.player.x, this.player.y - 20, 'WEAPON UPGRADED!', '#ffe600');
        }
      },
      {
        id: 'heal',
        icon: '❤️',
        title: 'NANO REPAIR',
        desc: 'Restore 50 HP and increase max capacity.',
        action: () => {
          this.player.maxHp += 20;
          this.player.hp = Math.min(this.player.maxHp, this.player.hp + 50);
          this.addFloatingText(this.player.x, this.player.y - 20, '+50 HP!', '#00ff66');
        }
      },
      {
        id: 'speed',
        icon: '🚀',
        title: 'ION THRUSTERS',
        desc: 'Increase movement speed & dash recovery.',
        action: () => {
          CONFIG.PLAYER_SPEED += 35;
          CONFIG.DASH_COOLDOWN = Math.max(0.6, CONFIG.DASH_COOLDOWN - 0.2);
          this.addFloatingText(this.player.x, this.player.y - 20, 'SPEED BOOST!', '#00f0ff');
        }
      }
    ];

    upgradePool.forEach(upg => {
      const card = document.createElement('div');
      card.className = 'upgrade-card';
      card.innerHTML = `
        <div class="upgrade-icon">${upg.icon}</div>
        <div class="upgrade-title">${upg.title}</div>
        <div class="upgrade-desc">${upg.desc}</div>
      `;
      card.addEventListener('click', () => {
        upg.action();
        window.soundEngine.playPowerup();
        document.getElementById('upgrade-screen').classList.add('hidden');
        this.state = 'PLAYING';
        this.updateHUD();
        this.lastTime = performance.now();
      });
      container.appendChild(card);
    });

    document.getElementById('upgrade-screen').classList.remove('hidden');
  }

  update(dt) {
    if (this.state !== 'PLAYING') return;

    // Screen Shake decay
    if (this.shakeDuration > 0) {
      this.shakeDuration -= dt;
      if (this.shakeDuration <= 0) this.shakeIntensity = 0;
    }

    // Player update
    this.player.update(dt, this.input, this);

    // Wave spawning
    if (this.enemiesSpawnedThisWave < this.totalEnemiesInWave) {
      this.waveSpawnTimer -= dt;
      if (this.waveSpawnTimer <= 0) {
        this.spawnEnemy();
        this.waveSpawnTimer = Math.max(0.4, 1.8 - this.wave * 0.12);
      }
    } else if (this.enemies.length === 0) {
      this.completeWave();
    }

    // Bullets update & Bounds
    for (let i = this.bullets.length - 1; i >= 0; i--) {
      const b = this.bullets[i];
      b.update(dt);

      if (b.life <= 0 || b.x < -20 || b.x > CONFIG.CANVAS_WIDTH + 20 || b.y < -20 || b.y > CONFIG.CANVAS_HEIGHT + 20) {
        this.bullets.splice(i, 1);
        continue;
      }

      // Check collision with player
      if (!b.isPlayer) {
        const dist = Math.hypot(b.x - this.player.x, b.y - this.player.y);
        if (dist < b.radius + this.player.radius) {
          this.player.takeDamage(b.damage, this);
          this.bullets.splice(i, 1);
          continue;
        }
      } else {
        // Player bullet hitting enemies
        for (let j = this.enemies.length - 1; j >= 0; j--) {
          const e = this.enemies[j];
          const dist = Math.hypot(b.x - e.x, b.y - e.y);
          if (dist < b.radius + e.radius) {
            const killed = e.takeDamage(b.damage, this);
            this.bullets.splice(i, 1);

            if (killed) {
              this.score += e.scoreVal;
              this.kills++;
              this.addFloatingText(e.x, e.y, `+${e.scoreVal}`, '#ffe600', 12);
              this.spawnParticles(e.x, e.y, e.color, 16, 180);
              window.soundEngine.playExplosion(e.type === 'boss' ? 'large' : 'medium');
              this.screenShake(e.type === 'boss' ? 14 : 5, 0.2);

              // Chance to drop pickup
              const dropRand = Math.random();
              if (dropRand < 0.15) {
                this.pickups.push(new Pickup(e.x, e.y, 'hp'));
              } else if (dropRand < 0.22) {
                this.pickups.push(new Pickup(e.x, e.y, 'weapon'));
              }

              this.enemies.splice(j, 1);
            }
            break;
          }
        }
      }
    }

    // Enemies update & Player contact
    for (let i = this.enemies.length - 1; i >= 0; i--) {
      const e = this.enemies[i];
      e.update(dt, this.player, this);

      const dist = Math.hypot(e.x - this.player.x, e.y - this.player.y);
      if (dist < e.radius + this.player.radius) {
        this.player.takeDamage(e.touchDamage, this);
      }
    }

    // Pickups
    for (let i = this.pickups.length - 1; i >= 0; i--) {
      const p = this.pickups[i];
      p.update(dt);
      if (p.life <= 0) {
        this.pickups.splice(i, 1);
        continue;
      }
      const dist = Math.hypot(p.x - this.player.x, p.y - this.player.y);
      if (dist < p.radius + this.player.radius) {
        window.soundEngine.playPickup();
        if (p.type === 'hp') {
          this.player.hp = Math.min(this.player.maxHp, this.player.hp + 30);
          this.addFloatingText(p.x, p.y, '+30 HP', '#00ff66', 13);
        } else if (p.type === 'weapon') {
          this.player.weaponLevel = Math.min(4, this.player.weaponLevel + 1);
          this.addFloatingText(p.x, p.y, 'WEAPON UPGRADE!', '#ffe600', 13);
        }
        this.pickups.splice(i, 1);
      }
    }

    // Particles
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const pt = this.particles[i];
      pt.update(dt);
      if (pt.life <= 0) this.particles.splice(i, 1);
    }

    // Floating text
    for (let i = this.floatingTexts.length - 1; i >= 0; i--) {
      const ft = this.floatingTexts[i];
      ft.update(dt);
      if (ft.life <= 0) this.floatingTexts.splice(i, 1);
    }

    this.updateHUD();
  }

  draw() {
    this.ctx.save();

    // Apply Screen Shake
    if (this.shakeIntensity > 0) {
      const rx = (Math.random() - 0.5) * this.shakeIntensity;
      const ry = (Math.random() - 0.5) * this.shakeIntensity;
      this.ctx.translate(rx, ry);
    }

    // Background Clear
    this.ctx.fillStyle = CONFIG.COLORS.background;
    this.ctx.fillRect(0, 0, CONFIG.CANVAS_WIDTH, CONFIG.CANVAS_HEIGHT);

    // Draw Cyberpunk Grid
    this.ctx.strokeStyle = CONFIG.COLORS.gridLines;
    this.ctx.lineWidth = 1;
    const gridSize = 40;
    for (let x = 0; x < CONFIG.CANVAS_WIDTH; x += gridSize) {
      this.ctx.beginPath();
      this.ctx.moveTo(x, 0);
      this.ctx.lineTo(x, CONFIG.CANVAS_HEIGHT);
      this.ctx.stroke();
    }
    for (let y = 0; y < CONFIG.CANVAS_HEIGHT; y += gridSize) {
      this.ctx.beginPath();
      this.ctx.moveTo(0, y);
      this.ctx.lineTo(CONFIG.CANVAS_WIDTH, y);
      this.ctx.stroke();
    }

    // Draw Entities
    this.pickups.forEach(p => p.draw(this.ctx));
    this.particles.forEach(pt => pt.draw(this.ctx));
    this.bullets.forEach(b => b.draw(this.ctx));
    this.enemies.forEach(e => e.draw(this.ctx));
    if (this.state === 'PLAYING' || this.state === 'PAUSED' || this.state === 'UPGRADE') {
      this.player.draw(this.ctx);
    }
    this.floatingTexts.forEach(ft => ft.draw(this.ctx));

    // Crosshair cursor
    this.drawCrosshair();

    this.ctx.restore();
  }

  drawCrosshair() {
    const mx = this.input.mouse.x;
    const my = this.input.mouse.y;
    this.ctx.save();
    this.ctx.strokeStyle = '#00f0ff';
    this.ctx.lineWidth = 1.5;
    this.ctx.beginPath();
    this.ctx.arc(mx, my, 8, 0, Math.PI * 2);
    this.ctx.moveTo(mx - 12, my);
    this.ctx.lineTo(mx - 5, my);
    this.ctx.moveTo(mx + 5, my);
    this.ctx.lineTo(mx + 12, my);
    this.ctx.moveTo(mx, my - 12);
    this.ctx.lineTo(mx, my - 5);
    this.ctx.moveTo(mx, my + 5);
    this.ctx.lineTo(mx, my + 12);
    this.ctx.stroke();
    this.ctx.restore();
  }

  loop(currentTime) {
    const dt = Math.min((currentTime - this.lastTime) / 1000, 0.1);
    this.lastTime = currentTime;

    this.update(dt);
    this.draw();

    requestAnimationFrame((t) => this.loop(t));
  }
}

// Launch engine on DOM load
window.addEventListener('DOMContentLoaded', () => {
  window.gameEngine = new GameEngine();
  requestAnimationFrame((t) => window.gameEngine.loop(t));
});

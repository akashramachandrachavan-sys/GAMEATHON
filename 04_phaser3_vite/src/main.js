import Phaser from 'phaser';

class GameScene extends Phaser.Scene {
  constructor() {
    super('GameScene');
  }

  preload() {
    // Generate textures procedurally using Phaser graphics
    // No external image assets needed!
    const gfx = this.make.graphics({ x: 0, y: 0, add: false });

    // Player ship (Cyan Triangle)
    gfx.clear();
    gfx.fillStyle(0x00f0ff, 1);
    gfx.fillTriangle(0, 0, 32, 16, 0, 32);
    gfx.generateTexture('player_tex', 32, 32);

    // Bullet (Yellow Circle)
    gfx.clear();
    gfx.fillStyle(0xffe600, 1);
    gfx.fillCircle(6, 6, 6);
    gfx.generateTexture('bullet_tex', 12, 12);

    // Enemy Drone (Magenta Diamond)
    gfx.clear();
    gfx.fillStyle(0xff007f, 1);
    gfx.beginPath();
    gfx.moveTo(16, 0);
    gfx.lineTo(32, 16);
    gfx.lineTo(16, 32);
    gfx.lineTo(0, 16);
    gfx.closePath();
    gfx.fillPath();
    gfx.generateTexture('enemy_tex', 32, 32);

    // Particle spark
    gfx.clear();
    gfx.fillStyle(0x00f0ff, 1);
    gfx.fillRect(0, 0, 4, 4);
    gfx.generateTexture('particle_tex', 4, 4);
  }

  create() {
    this.score = 0;
    this.wave = 1;
    this.hp = 100;
    this.isGameOver = false;

    // Background Grid
    this.add.grid(480, 320, 960, 640, 40, 40, 0x090b10, 1, 0x141e30, 0.4);

    // Player
    this.player = this.physics.add.sprite(480, 320, 'player_tex');
    this.player.setCollideWorldBounds(true);
    this.player.setDrag(600);

    // Groups
    this.bullets = this.physics.add.group();
    this.enemies = this.physics.add.group();

    // Controls
    this.cursors = this.input.keyboard.addKeys({
      up: Phaser.Input.Keyboard.KeyCodes.W,
      down: Phaser.Input.Keyboard.KeyCodes.S,
      left: Phaser.Input.Keyboard.KeyCodes.A,
      right: Phaser.Input.Keyboard.KeyCodes.D,
      space: Phaser.Input.Keyboard.KeyCodes.SPACE
    });

    // Shooting on mouse click
    this.input.on('pointerdown', (pointer) => {
      if (this.isGameOver) {
        this.scene.restart();
        return;
      }
      this.shoot(pointer);
    });

    // Enemy Spawning Timer
    this.spawnTimer = this.time.addEvent({
      delay: 1200,
      callback: this.spawnEnemy,
      callbackScope: this,
      loop: true
    });

    // HUD
    this.hudText = this.add.text(20, 20, 'SCORE: 0  HP: 100', {
      fontFamily: 'monospace',
      fontSize: '20px',
      color: '#00f0ff'
    });

    // Collisions
    this.physics.add.overlap(this.bullets, this.enemies, (bullet, enemy) => {
      bullet.destroy();
      enemy.destroy();
      this.score += 50;
      this.hudText.setText(`SCORE: ${this.score}  HP: ${this.hp}`);
      this.cameras.main.shake(100, 0.008);
    });

    this.physics.add.overlap(this.player, this.enemies, (player, enemy) => {
      enemy.destroy();
      this.hp -= 20;
      this.cameras.main.shake(200, 0.02);
      this.hudText.setText(`SCORE: ${this.score}  HP: ${this.hp}`);
      if (this.hp <= 0 && !this.isGameOver) {
        this.gameOver();
      }
    });
  }

  shoot(pointer) {
    const bullet = this.bullets.create(this.player.x, this.player.y, 'bullet_tex');
    const angle = Phaser.Math.Angle.Between(this.player.x, this.player.y, pointer.x, pointer.y);
    const speed = 600;
    bullet.setVelocity(Math.cos(angle) * speed, Math.sin(angle) * speed);
    this.cameras.main.shake(50, 0.003);
  }

  spawnEnemy() {
    if (this.isGameOver) return;
    const x = Phaser.Math.Between(0, 1) === 0 ? 0 : 960;
    const y = Phaser.Math.Between(0, 640);
    const enemy = this.enemies.create(x, y, 'enemy_tex');
    this.physics.moveToObject(enemy, this.player, 110 + this.wave * 10);
  }

  gameOver() {
    this.isGameOver = true;
    this.player.setTint(0xff0000);
    this.add.text(480, 320, 'GAME OVER\nClick to Restart', {
      fontFamily: 'monospace',
      fontSize: '36px',
      color: '#ff007f',
      align: 'center'
    }).setOrigin(0.5);
  }

  update() {
    if (this.isGameOver) return;

    // Movement
    const speed = 260;
    let vx = 0;
    let vy = 0;
    if (this.cursors.left.isDown) vx -= speed;
    if (this.cursors.right.isDown) vx += speed;
    if (this.cursors.up.isDown) vy -= speed;
    if (this.cursors.down.isDown) vy += speed;
    this.player.setVelocity(vx, vy);

    // Aim towards mouse
    const pointer = this.input.activePointer;
    this.player.rotation = Phaser.Math.Angle.Between(this.player.x, this.player.y, pointer.x, pointer.y);

    // Enemies track player
    this.enemies.getChildren().forEach(enemy => {
      this.physics.moveToObject(enemy, this.player, 120);
    });
  }
}

const config = {
  type: Phaser.AUTO,
  width: 960,
  height: 640,
  parent: 'game-container',
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { y: 0 },
      debug: false
    }
  },
  scene: [GameScene]
};

new Phaser.Game(config);

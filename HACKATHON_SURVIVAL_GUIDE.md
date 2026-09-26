# 🏆 4-Hour Gameathon Survival Guide & Playbook
*Specially crafted for the IEEE Gameathon*

---

## 💡 1. The 5-Minute Crash Course: "How Games Actually Work"

If you've never built a game before, don't worry! Games are not magic; they are simple loops that run 60 times every second.

### The Game Loop (The Heart of Every Game)
Every single game engine (Unity, Godot, Pygame, Canvas) executes this exact 4-step sequence 60 times a second:
```
           ┌───────────────────────┐
           │   1. READ INPUT       │  (Keyboard, Mouse, Touch)
           └───────────┬───────────┘
                       │
                       ▼
           ┌───────────────────────┐
           │   2. UPDATE LOGIC     │  (Move player: x += vx * dt)
           └───────────┬───────────┘  (Move enemies towards player)
                       │
                       ▼
           ┌───────────────────────┐
           │   3. CHECK COLLISIONS │  (Did bullet touch enemy?)
           └───────────┬───────────┘  (Did enemy touch player?)
                       │
                       ▼
           ┌───────────────────────┐
           │   4. RENDER / DRAW    │  (Draw background, entities, HUD)
           └───────────┬───────────┘
                       │
                       └───► Loop back to step 1 (60 FPS)
```

### Key Terms You Need to Know:
1. **Delta Time (`dt`)**: The time elapsed between the current frame and the previous frame (~0.016 seconds at 60 FPS).
   - *Why it matters*: Always multiply speeds by `dt` (e.g., `x += speed * dt`). This guarantees your game runs at the exact same speed on a 60Hz laptop or a 144Hz gaming screen!
2. **Game State**: Your game is always in one of 4 states:
   - `MENU`: Shows title, controls, "Press Start"
   - `PLAYING`: Active gameplay
   - `PAUSED`: Stops the update loop
   - `GAMEOVER`: Shows final score, waves survived, "Play Again"
3. **Collision Detection (AABB or Distance)**:
   - Circle collision formula: `distance = Math.hypot(x2 - x1, y2 - y1)`. If `distance < radius1 + radius2`, they collided!
4. **"Game Juice" (The Secret Hack to Win Hackathons)**:
   - A boring game: A square shoots another square and it disappears.
   - A winning game: When you shoot, the screen shakes slightly, a retro laser bleep plays, the enemy explodes into 16 glowing particles, and a floating `+100` pops up on the screen!
   - *All templates in this workspace have Game Juice built in!*

---

## ⏱️ 2. The 4-Hour Master Schedule

In a 4-hour hackathon, **scope creep is your #1 enemy**. Never try to build an open-world RPG, a story-heavy platformer with 10 levels, or networked multiplayer.

| Time Window | Phase | Goal |
|---|---|---|
| **00:00 - 00:30** | **Theme & Concept** | Theme is announced. Pick **ONE** core mechanic. Write it down in 1 sentence. |
| **00:30 - 02:00** | **Core Gameplay** | Movement, 1 objective, 1 hazard/enemy, win/lose condition. |
| **02:00 - 03:00** | **Progression & Variety** | Add 2 enemy types, wave scaling, simple powerups/upgrades. |
| **03:00 - 03:40** | **Juice & Audio** | Add sound effects, screen shake, particles, color polish. (Judges LOVE this!) |
| **03:40 - 04:00** | **Code Freeze & Pitch** | **STOP CODING.** Test restart loop. Prepare 60-second pitch. |

> [!IMPORTANT]
> **Rule of Thumb:** A small, completed, juice-filled game with 1 level and a restart screen will ALWAYS score higher than a grand, half-finished game that crashes when judges click!

---

## 🎭 3. Theme Decoder: How to Fit ANY Surprise Theme in 5 Minutes

Hackathons announce a surprise theme at the start. Here is how to adapt your ready templates (`01_web_arcade` or `02_python_pygame`) to the most common hackathon themes:

| Likely Theme | How to Adapt Your Game | Quick Implementation |
|---|---|---|
| **"Time / Rewind"** | Time moves only when you move (SUPERHOT), or a "Chrono Dash" that slows enemies by 75% for 3 seconds. | Add `timeScale = 0.25` during dash! |
| **"Chain Reaction"** | Killing an enemy triggers a blast radius that ignites nearby enemies. | In `onEnemyKilled()`, find enemies within 80px and deal damage. |
| **"Duality / Two Sides"** | Switch between Light and Dark mode (`Q` key). Light bullets destroy Light enemies; Dark bullets destroy Dark enemies. | Add `player.mode = 'light'/'dark'` and check matching colors. |
| **"One / Limited"** | You have ONLY ONE bullet that ricochets and must be picked back up, OR your Health is your Ammo! | Set `ammo = 1` or shooting costs 2 HP. |
| **"Evolution / Growth"** | Every 5 kills, your ship mutates (grows larger, gets dual cannons, but becomes easier to hit). | Scale radius up by 1.1x and weapon level up. |
| **"Glitch / Chaos"** | Every 30 seconds, a random glitch event happens (inverted controls, low gravity, speed surge). | Timer that triggers random modifier for 5 seconds. |

---

## 🎤 4. The 2-Minute Judge Pitch (Guaranteed High Score)

When the judges walk up to your desk, follow this script:

1. **The Hook (15s)**:
   > *"Hello judges! For the theme [THEME], we created [GAME NAME], a fast-paced survival arcade game where [1-sentence unique twist]."*
2. **The Demo (45s)**:
   > Hand them the mouse/keyboard or let them play.
   > *Pro Tip: If you want to show higher wave content without risking dying during the pitch, press **F1** to turn on God Mode!*
3. **The Polish Highlights (30s)**:
   > *"We focused heavily on game feel—everything from the procedural 8-bit sound synthesis, screen shake, and dynamic particle bursts to the escalating wave AI."*
4. **The Tech Stack (15s)**:
   > Mention your stack (Pure HTML5 Canvas / Web Audio API or Pygame-CE / Godot) and highlight that it runs at a rock-solid 60 FPS without external asset dependencies.
5. **Ask for Questions (15s)**:
   > *"Would you like to try beating the high score?"*

---

## 🛠️ 5. Cheat Keys Embedded in Your Templates

Both the Web and Pygame templates include hidden developer hotkeys for demos:
- `F1`: **God Mode** (Toggle Invincibility — never die in front of judges!)
- `F2`: **Next Wave** (Instantly jump to wave 2, 3, or Boss fight)
- `F3`: **Add +5000 Score** (Quickly show high score animations)
- `P` / `Esc`: **Pause / Resume**

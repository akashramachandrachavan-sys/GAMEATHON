# 🐍 Template 2: Cyber Strike (Python + Pygame-CE)

A complete, self-contained 2D arcade game built with Pygame Community Edition.

## Key Features:
- **Zero Audio Dependency**: Procedural 8-bit sound generator in `sound_fx.py` creates square wave lasers, noise explosion bursts, and pickup sounds programmatically.
- **Visual Juice**: Screen shake on explosions, particle trails and bursts, floating score damage text.
- **Judge Demo Mode**: Press **F1** anytime during gameplay to activate God Mode (invincibility), ensuring you never die while demonstrating the game to judges.
- **High Score Persistence**: Automatically saved to `highscore.txt`.

## How to Run:
```bash
./run.sh
```
or
```bash
../.venv/bin/python3 main.py
```

## How to Reskin for Hackathon Themes:
Open `main.py` and modify the top configuration:
- Change `COLOR_PLAYER`, `COLOR_ENEMY_BASIC`, `COLOR_ENEMY_TANK`.
- Modify titles and speeds.
- Add new enemy types or boss logic in `Enemy` class.

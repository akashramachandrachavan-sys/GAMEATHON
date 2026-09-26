import os
from PIL import Image, ImageDraw, ImageFont

assets_dir = "/Users/akash/GAMEATHON/revolt_godot/assets"
os.makedirs(assets_dir, exist_ok=True)

font_bold_path = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
font_large = ImageFont.truetype(font_bold_path, 46)
font_medium = ImageFont.truetype(font_bold_path, 28)
font_small = ImageFont.truetype(font_bold_path, 20)

# 1. Cyber Skyscraper Facade (1024x1024)
facade1 = Image.new("RGB", (1024, 1024), (16, 20, 28))
fdraw1 = ImageDraw.Draw(facade1)

for x in range(0, 1024, 128):
    fdraw1.rectangle([x, 0, x + 24, 1024], fill=(28, 34, 46), outline=(12, 16, 22), width=2)
    fdraw1.line([x + 12, 0, x + 12, 1024], fill=(0, 180, 220), width=2)

for y in range(0, 1024, 64):
    fdraw1.line([0, y, 1024, y], fill=(10, 14, 20), width=4)
    for x in range(0, 1024, 128):
        for w_idx in range(3):
            wx = x + 32 + w_idx * 28
            wy = y + 10
            seed = (wx * 17 + wy * 31) % 100
            if seed < 35:
                fdraw1.rectangle([wx, wy, wx + 20, wy + 42], fill=(245, 210, 120), outline=(60, 50, 25), width=2)
            elif seed < 65:
                fdraw1.rectangle([wx, wy, wx + 20, wy + 42], fill=(120, 225, 255), outline=(30, 65, 80), width=2)
            else:
                fdraw1.rectangle([wx, wy, wx + 20, wy + 42], fill=(22, 28, 38), outline=(14, 18, 26), width=1)

facade1.save(os.path.join(assets_dir, "building_facade_1.png"))

# 2. Industrial Factory / Citadel Facade (1024x1024)
facade2 = Image.new("RGB", (1024, 1024), (24, 28, 36))
fdraw2 = ImageDraw.Draw(facade2)

for y in range(0, 1024, 128):
    fdraw2.rectangle([0, y, 1024, y + 124], fill=(30, 36, 48), outline=(14, 18, 24), width=3)
    for x in range(16, 1024, 64):
        fdraw2.ellipse([x - 3, y + 8 - 3, x + 3, y + 8 + 3], fill=(80, 90, 105))
        fdraw2.ellipse([x - 3, y + 116 - 3, x + 3, y + 116 + 3], fill=(80, 90, 105))
    
    fdraw2.rectangle([80, y + 24, 440, y + 100], fill=(12, 14, 18), outline=(50, 60, 75), width=2)
    for ly in range(y + 30, y + 96, 10):
        fdraw2.line([84, ly, 436, ly], fill=(45, 52, 65), width=4)
        
    fdraw2.rectangle([580, y + 24, 940, y + 100], fill=(12, 14, 18), outline=(50, 60, 75), width=2)
    for ly in range(y + 30, y + 96, 10):
        fdraw2.line([584, ly, 936, ly], fill=(45, 52, 65), width=4)

hy = 480
for x in range(-512, 1536, 48):
    fdraw2.polygon([(x, hy), (x + 24, hy), (x - 32, hy + 64), (x - 56, hy + 64)], fill=(225, 180, 20))

facade2.save(os.path.join(assets_dir, "building_facade_2.png"))

# 3. Holographic Billboard 1: STERLING ROBOTICS // SECURING 2150 (1024x512)
holo1 = Image.new("RGBA", (1024, 512), (6, 14, 28, 255))
hdraw1 = ImageDraw.Draw(holo1)

# Outer cyber border with corner tech cutouts
hdraw1.rectangle([12, 12, 1011, 499], outline=(0, 240, 255), width=6)
hdraw1.rectangle([24, 24, 999, 487], outline=(0, 140, 200), width=2)

# Corner decorative brackets
for cx, cy in [(12, 12), (1011, 12), (12, 499), (1011, 499)]:
    sx = 1 if cx < 500 else -1
    sy = 1 if cy < 250 else -1
    hdraw1.line([cx, cy, cx + sx * 40, cy], fill=(0, 255, 230), width=10)
    hdraw1.line([cx, cy, cx, cy + sy * 40], fill=(0, 255, 230), width=10)

# Scanline raster pattern
for y in range(28, 484, 8):
    hdraw1.line([28, y, 995, y], fill=(10, 30, 55, 120), width=1)

# Corporate Emblem - Hexagonal Cyber Core
hdraw1.polygon([(110, 120), (160, 80), (210, 120), (210, 180), (160, 220), (110, 180)], outline=(0, 255, 240), width=8)
hdraw1.ellipse([140, 130, 180, 170], fill=(0, 255, 220))

# Typography
hdraw1.text((250, 80), "STERLING ROBOTICS", font=font_large, fill=(0, 255, 255))
hdraw1.text((254, 142), "AUTONOMOUS DEFENSE GRID // YEAR 2150", font=font_medium, fill=(180, 230, 255))

# Status Bar
hdraw1.rectangle([60, 250, 964, 320], fill=(12, 28, 56), outline=(0, 200, 240), width=2)
hdraw1.text((80, 268), "SECURITY LEVEL: TITAN-ACTIVE  |  SURVEILLANCE: 100%", font=font_medium, fill=(240, 200, 40))

# Bottom warning stripe
hdraw1.line([40, 380, 984, 380], fill=(0, 240, 255), width=4)
hdraw1.text((60, 410), "STERLING DEFENSE NETWORK: PROTECTING NEW BABYLON", font=font_medium, fill=(0, 220, 255))
hdraw1.text((60, 452), "UNAUTHORIZED CIVILIAN INTERFERENCE IS MET WITH LETHAL ENFORCEMENT", font=font_small, fill=(140, 180, 210))

holo1.save(os.path.join(assets_dir, "holo_billboard_1.png"))

# 4. Holographic Billboard 2: CRITICAL SYSTEM ALERT // OMEGA-ZERO (1024x512)
holo2 = Image.new("RGBA", (1024, 512), (32, 8, 14, 255))
hdraw2 = ImageDraw.Draw(holo2)

hdraw2.rectangle([12, 12, 1011, 499], outline=(255, 40, 60), width=6)
hdraw2.rectangle([24, 24, 999, 487], outline=(180, 25, 45), width=2)

for cx, cy in [(12, 12), (1011, 12), (12, 499), (1011, 499)]:
    sx = 1 if cx < 500 else -1
    sy = 1 if cy < 250 else -1
    hdraw2.line([cx, cy, cx + sx * 40, cy], fill=(255, 60, 80), width=10)
    hdraw2.line([cx, cy, cx, cy + sy * 40], fill=(255, 60, 80), width=10)

# Hazard Chevron Header
hy = 40
for x in range(30, 990, 48):
    hdraw2.polygon([(x, hy), (x + 24, hy), (x + 12, hy + 24), (x - 12, hy + 24)], fill=(255, 190, 20))

# Warning Triangle
hdraw2.polygon([(150, 120), (220, 240), (80, 240)], outline=(255, 200, 30), width=8)
hdraw2.line([150, 155, 150, 205], fill=(255, 200, 30), width=8)
hdraw2.ellipse([145, 218, 155, 228], fill=(255, 200, 30))

hdraw2.text((250, 125), "[ CRITICAL SYSTEM ALERT ]", font=font_large, fill=(255, 50, 70))
hdraw2.text((254, 185), "SECTOR 04 CONTAINMENT BREACH", font=font_medium, fill=(255, 220, 230))

# Alert Box
hdraw2.rectangle([60, 280, 964, 350], fill=(60, 12, 22), outline=(255, 60, 80), width=3)
hdraw2.text((80, 296), "TARGET: OMEGA-ZERO TITAN PROTOCOL INITIATED", font=font_medium, fill=(255, 210, 40))

# Evacuate Footer
hdraw2.line([40, 400, 984, 400], fill=(255, 50, 70), width=4)
hdraw2.text((60, 420), "ALL UNITS: ENGAGE FULL RETALIATION PROTOCOL", font=font_medium, fill=(255, 80, 100))
hdraw2.text((60, 460), "EVACUATE COMBAT ZONE IMMEDIATELY // NON-COMPLIANCE IS FATAL", font=font_small, fill=(240, 160, 170))

holo2.save(os.path.join(assets_dir, "holo_billboard_2.png"))

print("High-definition city and billboard textures generated successfully!")

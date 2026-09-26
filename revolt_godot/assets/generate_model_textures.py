import os
from PIL import Image, ImageDraw

assets_dir = "/Users/akash/GAMEATHON/revolt_godot/assets"
os.makedirs(assets_dir, exist_ok=True)

# 1. Kai Hero Cyber-Suit & Armor Texture (512x512)
kai_tex = Image.new("RGB", (512, 512), (28, 34, 44))
kdraw = ImageDraw.Draw(kai_tex)

# Hexagonal carbon-fiber weave pattern
for y in range(0, 512, 32):
    for x in range(0, 512, 32):
        kdraw.rectangle([x, y, x + 28, y + 28], fill=(34, 42, 54), outline=(20, 24, 32), width=1)
        kdraw.polygon([(x + 14, y + 4), (x + 24, y + 10), (x + 24, y + 20), (x + 14, y + 26), (x + 4, y + 20), (x + 4, y + 10)], outline=(44, 56, 72), width=1)

# Cyan glowing circuit traces down the suit
for x in [64, 192, 320, 448]:
    kdraw.line([x, 0, x, 512], fill=(0, 200, 240), width=3)
    for y in range(40, 512, 96):
        kdraw.line([x, y, x + 24, y + 24], fill=(0, 220, 255), width=2)
        kdraw.rectangle([x + 22, y + 22, x + 28, y + 28], fill=(0, 240, 255))

kai_tex.save(os.path.join(assets_dir, "kai_suit_pattern.png"))

# 2. Heavy Mech Titan Plate (1024x1024) - Industrial titanium armor with hazard chevrons and heat exhaust
mech_tex = Image.new("RGB", (1024, 1024), (32, 36, 44))
mdraw = ImageDraw.Draw(mech_tex)

# Armor plating segments
for y in range(0, 1024, 256):
    mdraw.line([0, y, 1024, y], fill=(14, 16, 20), width=6)
    for x in range(0, 1024, 256):
        mdraw.line([x, 0, x, 1024], fill=(14, 16, 20), width=6)
        mdraw.rectangle([x + 8, y + 8, x + 248, y + 248], fill=(40, 46, 56), outline=(60, 70, 84), width=3)
        # Industrial rivets around plate corners
        for rx, ry in [(x + 20, y + 20), (x + 236, y + 20), (x + 20, y + 236), (x + 236, y + 236)]:
            mdraw.ellipse([rx - 5, ry - 5, rx + 5, ry + 5], fill=(110, 125, 145), outline=(20, 24, 30), width=1)

# Prominent hazard diagonal bands
for hy in [160, 672]:
    for x in range(-512, 1536, 64):
        mdraw.polygon([(x, hy), (x + 32, hy), (x - 32, hy + 64), (x - 64, hy + 64)], fill=(235, 190, 25))

# Heat exhaust mesh
for y in [384, 896]:
    mdraw.rectangle([128, y, 896, y + 96], fill=(16, 18, 22), outline=(80, 90, 105), width=3)
    for lx in range(140, 884, 16):
        mdraw.line([lx, y + 6, lx, y + 90], fill=(50, 58, 70), width=4)

mech_tex.save(os.path.join(assets_dir, "mech_titan_plate.png"))

# 3. Scout Drone Stealth Carbon (512x512) - High-tech matte stealth with orange danger markings
scout_tex = Image.new("RGB", (512, 512), (22, 26, 32))
sdraw = ImageDraw.Draw(scout_tex)

for y in range(0, 512, 16):
    sdraw.line([0, y, 512, y], fill=(18, 21, 26), width=2)
for x in range(0, 512, 64):
    sdraw.line([x, 0, x, 512], fill=(16, 18, 22), width=3)

# Orange tactical stripes
sdraw.polygon([(0, 180), (120, 180), (240, 300), (120, 300)], fill=(255, 110, 20))
sdraw.polygon([(260, 180), (380, 180), (500, 300), (380, 300)], fill=(255, 110, 20))
sdraw.text((40, 420), "CAUTION // ACTIVE WEAPONS PLATFORM", fill=(255, 180, 50))

scout_tex.save(os.path.join(assets_dir, "scout_drone_camo.png"))

print("High-definition model textures created successfully!")

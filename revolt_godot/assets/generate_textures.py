import os
import math
from PIL import Image, ImageDraw, ImageFilter

assets_dir = "/Users/akash/GAMEATHON/revolt_godot/assets"
os.makedirs(assets_dir, exist_ok=True)

# 1. Floor Diamond Plate Albedo (1024x1024)
w, h = 1024, 1024
floor_img = Image.new("RGB", (w, h), (32, 35, 42))
draw = ImageDraw.Draw(floor_img)

# Steel tiles grid
tile_size = 64
for x in range(0, w, tile_size):
    for y in range(0, h, tile_size):
        # Base tile color variance
        v = int(28 + ((x * 13 + y * 7) % 15))
        draw.rectangle([x, y, x + tile_size - 1, y + tile_size - 1], fill=(v, v + 3, v + 7), outline=(18, 20, 25))
        # Diamond plate treads
        for i in range(4):
            dx = x + 16 + (i % 2) * 28
            dy = y + 16 + (i // 2) * 28
            draw.line([dx - 8, dy - 8, dx + 8, dy + 8], fill=(55, 60, 70), width=3)
            draw.line([dx + 8, dy - 8, dx - 8, dy + 8], fill=(22, 24, 28), width=2)
            
        # Corner rivets
        for rx, ry in [(x + 4, y + 4), (x + tile_size - 5, y + 4), (x + 4, y + tile_size - 5), (x + tile_size - 5, y + tile_size - 5)]:
            draw.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=(70, 75, 85), outline=(15, 17, 20))

# Center combat ring circle with cyan neon marker
cx, cy = w // 2, h // 2
draw.ellipse([cx - 220, cy - 220, cx + 220, cy + 220], outline=(0, 180, 240), width=6)
draw.ellipse([cx - 240, cy - 240, cx + 240, cy + 240], outline=(40, 50, 60), width=2)
# Center insignia
draw.line([cx - 40, cy, cx + 40, cy], fill=(0, 210, 255), width=4)
draw.line([cx, cy - 40, cx, cy + 40], fill=(0, 210, 255), width=4)
draw.ellipse([cx - 15, cy - 15, cx + 15, cy + 15], outline=(0, 210, 255), width=3)

# Outer Hazard Stripes (along perimeter)
stripe_w = 48
for i in range(-w, w * 2, 32):
    # Top border
    draw.polygon([(i, 0), (i + 16, 0), (i + 16 - stripe_w, stripe_w), (i - stripe_w, stripe_w)], fill=(210, 175, 15))
    # Bottom border
    draw.polygon([(i, h - stripe_w), (i + 16, h - stripe_w), (i + 16 - stripe_w, h), (i - stripe_w, h)], fill=(210, 175, 15))
    # Left border
    draw.polygon([(0, i), (0, i + 16), (stripe_w, i + 16 - stripe_w), (stripe_w, i - stripe_w)], fill=(210, 175, 15))
    # Right border
    draw.polygon([(w - stripe_w, i), (w - stripe_w, i + 16), (w, i + 16 - stripe_w), (w, i - stripe_w)], fill=(210, 175, 15))

floor_img.save(os.path.join(assets_dir, "floor_albedo.png"))

# 2. Floor Normal Map (1024x1024)
norm_img = Image.new("RGB", (w, h), (128, 128, 255))
norm_draw = ImageDraw.Draw(norm_img)
for x in range(0, w, tile_size):
    for y in range(0, h, tile_size):
        # Tile grooves
        norm_draw.line([x, y, x + tile_size, y], fill=(128, 90, 255), width=2)
        norm_draw.line([x, y, x, y + tile_size], fill=(90, 128, 255), width=2)
        # Diamond treads normal
        for i in range(4):
            dx = x + 16 + (i % 2) * 28
            dy = y + 16 + (i // 2) * 28
            norm_draw.line([dx - 8, dy - 8, dx + 8, dy + 8], fill=(160, 150, 240), width=3)
norm_img = norm_img.filter(ImageFilter.GaussianBlur(radius=1.0))
norm_img.save(os.path.join(assets_dir, "floor_normal.png"))

# 3. Mech Armor Plate Albedo & Normal (512x512)
mw, mh = 512, 512
armor_img = Image.new("RGB", (mw, mh), (65, 72, 82))
adraw = ImageDraw.Draw(armor_img)
for y in range(0, mh, 64):
    adraw.line([0, y, mw, y], fill=(45, 50, 58), width=3)
    for x in range(0, mw, 64):
        adraw.line([x, y, x, y + 64], fill=(45, 50, 58), width=3)
        # Panel rivets
        adraw.ellipse([x + 6, y + 6, x + 10, y + 10], fill=(90, 100, 115), outline=(30, 35, 42))
        adraw.ellipse([x + 54, y + 6, x + 58, y + 10], fill=(90, 100, 115), outline=(30, 35, 42))
armor_img.save(os.path.join(assets_dir, "armor_albedo.png"))

armor_norm = Image.new("RGB", (mw, mh), (128, 128, 255))
andraw = ImageDraw.Draw(armor_norm)
for y in range(0, mh, 64):
    andraw.line([0, y, mw, y], fill=(128, 100, 255), width=3)
    for x in range(0, mw, 64):
        andraw.line([x, y, x, y + 64], fill=(100, 128, 255), width=3)
armor_norm = armor_norm.filter(ImageFilter.GaussianBlur(radius=1.0))
armor_norm.save(os.path.join(assets_dir, "armor_normal.png"))

# 4. RoboCop Green Cockpit Visor Reticle (1024x1024 transparent RGBA)
hud_img = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
hdraw = ImageDraw.Draw(hud_img)

green = (0, 255, 140, 220)
green_dim = (0, 255, 140, 110)
green_glow = (0, 255, 140, 45)

hcx, hcy = 512, 512
# Tactical Visor Center Brackets
hdraw.line([hcx - 70, hcy - 40, hcx - 40, hcy - 40], fill=green, width=3)
hdraw.line([hcx - 70, hcy - 40, hcx - 70, hcy - 10], fill=green, width=3)

hdraw.line([hcx + 70, hcy - 40, hcx + 40, hcy - 40], fill=green, width=3)
hdraw.line([hcx + 70, hcy - 40, hcx + 70, hcy - 10], fill=green, width=3)

hdraw.line([hcx - 70, hcy + 40, hcx - 40, hcy + 40], fill=green, width=3)
hdraw.line([hcx - 70, hcy + 40, hcx - 70, hcy + 10], fill=green, width=3)

hdraw.line([hcx + 70, hcy + 40, hcx + 40, hcy + 40], fill=green, width=3)
hdraw.line([hcx + 70, hcy + 40, hcx + 70, hcy + 10], fill=green, width=3)

# Center cross pip
hdraw.line([hcx - 12, hcy, hcx - 4, hcy], fill=green, width=2)
hdraw.line([hcx + 4, hcy, hcx + 12, hcy], fill=green, width=2)
hdraw.line([hcx, hcy - 12, hcx, hcy - 4], fill=green, width=2)
hdraw.line([hcx, hcy + 4, hcx, hcy + 12], fill=green, width=2)

# Rangefinder tick marks
for r in [120, 180, 240]:
    hdraw.arc([hcx - r, hcy - r, hcx + r, hcy + r], start=210, end=230, fill=green_dim, width=2)
    hdraw.arc([hcx - r, hcy - r, hcx + r, hcy + r], start=310, end=330, fill=green_dim, width=2)
    hdraw.arc([hcx - r, hcy - r, hcx + r, hcy + r], start=30, end=50, fill=green_dim, width=2)
    hdraw.arc([hcx - r, hcy - r, hcx + r, hcy + r], start=130, end=150, fill=green_dim, width=2)

# Outer corner cockpit brackets (RoboCop HUD)
corner_len = 160
# Top-Left
hdraw.line([40, 40, 40 + corner_len, 40], fill=green, width=4)
hdraw.line([40, 40, 40, 40 + corner_len], fill=green, width=4)
# Top-Right
hdraw.line([w - 40, 40, w - 40 - corner_len, 40], fill=green, width=4)
hdraw.line([w - 40, 40, w - 40, 40 + corner_len], fill=green, width=4)
# Bottom-Left
hdraw.line([40, h - 40, 40 + corner_len, h - 40], fill=green, width=4)
hdraw.line([40, h - 40, 40, h - 40 - corner_len], fill=green, width=4)
# Bottom-Right
hdraw.line([w - 40, h - 40, w - 40 - corner_len, h - 40], fill=green, width=4)
hdraw.line([w - 40, h - 40, w - 40, h - 40 - corner_len], fill=green, width=4)

hud_img.save(os.path.join(assets_dir, "hud_reticle.png"))

# 5. Wireframe Mech Schematic (for Bottom-Left HUD, 256x256)
mech_icon = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
mdraw = ImageDraw.Draw(mech_icon)
mcx, mcy = 128, 128
# Head / Cockpit
mdraw.polygon([(mcx - 35, mcy - 50), (mcx + 35, mcy - 50), (mcx + 45, mcy - 20), (mcx - 45, mcy - 20)], outline=green, width=2)
# Visor slit
mdraw.line([mcx - 30, mcy - 35, mcx + 30, mcy - 35], fill=green, width=3)
# Torso
mdraw.rectangle([mcx - 40, mcy - 18, mcx + 40, mcy + 25], outline=green, width=2)
# Arms / Cannons
mdraw.rectangle([mcx - 65, mcy - 12, mcx - 45, mcy + 30], outline=green, width=2)
mdraw.rectangle([mcx + 45, mcy - 12, mcx + 65, mcy + 30], outline=green, width=2)
mdraw.line([mcx - 55, mcy + 30, mcx - 55, mcy + 55], fill=green, width=3)
mdraw.line([mcx + 55, mcy + 30, mcx + 55, mcy + 55], fill=green, width=3)
# Reverse Legs
mdraw.line([mcx - 25, mcy + 25, mcx - 38, mcy + 60], fill=green, width=3)
mdraw.line([mcx - 38, mcy + 60, mcx - 30, mcy + 95], fill=green, width=3)
mdraw.line([mcx - 45, mcy + 95, mcx - 15, mcy + 95], fill=green, width=4)

mdraw.line([mcx + 25, mcy + 25, mcx + 38, mcy + 60], fill=green, width=3)
mdraw.line([mcx + 38, mcy + 60, mcx + 30, mcy + 95], fill=green, width=3)
mdraw.line([mcx + 15, mcy + 95, mcx + 45, mcy + 95], fill=green, width=4)

mech_icon.save(os.path.join(assets_dir, "mech_schematic.png"))
print("All PBR and HUD textures generated successfully!")

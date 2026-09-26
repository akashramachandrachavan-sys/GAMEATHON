import os
from PIL import Image, ImageDraw, ImageFont

assets_dir = "/Users/akash/GAMEATHON/revolt_godot/assets"
os.makedirs(assets_dir, exist_ok=True)

# 1. Industrial Warning Sign: OMEGA ROBOTICS / SECTOR 01 (1024x256)
sign = Image.new("RGB", (1024, 256), (15, 18, 24))
draw = ImageDraw.Draw(sign)

# Border
draw.rectangle([6, 6, 1017, 249], outline=(220, 160, 20), width=6)
# Caution stripes on corners
for x in range(12, 160, 20):
    draw.polygon([(x, 12), (x + 10, 12), (x - 20, 80), (x - 30, 80)], fill=(220, 160, 20))
    draw.polygon([(1024 - x, 12), (1024 - x - 10, 12), (1024 - x + 20, 80), (1024 - x + 30, 80)], fill=(220, 160, 20))

# Sign text
draw.text((220, 45), "OMEGA ROBOTICS AUTOMATION", fill=(240, 245, 255))
draw.text((220, 110), "RESTRICTED COMBAT TESTING SECTOR // DR. STERLING", fill=(0, 210, 255))
draw.text((220, 175), "CRITICAL ALERT: ROGUE PROTOTYPE OMEGA-ZERO ACTIVE", fill=(255, 60, 60))

sign.save(os.path.join(assets_dir, "sign_omega.png"))

# 2. Brighter, Richer PBR Diamond Plate Floor (1024x1024)
w, h = 1024, 1024
floor_img = Image.new("RGB", (w, h), (48, 54, 64))
draw = ImageDraw.Draw(floor_img)

tile_size = 64
for x in range(0, w, tile_size):
    for y in range(0, h, tile_size):
        # Base tile color variance
        v = int(45 + ((x * 17 + y * 11) % 18))
        draw.rectangle([x, y, x + tile_size - 1, y + tile_size - 1], fill=(v, v + 4, v + 9), outline=(28, 32, 40))
        # Bright diamond treads
        for i in range(4):
            dx = x + 16 + (i % 2) * 28
            dy = y + 16 + (i // 2) * 28
            draw.line([dx - 8, dy - 8, dx + 8, dy + 8], fill=(95, 105, 120), width=4)
            draw.line([dx + 8, dy - 8, dx - 8, dy + 8], fill=(30, 35, 42), width=2)
            
        # Corner rivets
        for rx, ry in [(x + 4, y + 4), (x + tile_size - 5, y + 4), (x + 4, y + tile_size - 5), (x + tile_size - 5, y + tile_size - 5)]:
            draw.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=(120, 130, 145), outline=(20, 24, 30))

# Center combat ring circle with vibrant cyan & yellow markings
cx, cy = w // 2, h // 2
draw.ellipse([cx - 240, cy - 240, cx + 240, cy + 240], outline=(0, 200, 255), width=8)
draw.ellipse([cx - 260, cy - 260, cx + 260, cy + 260], outline=(230, 180, 20), width=4)

# Crosshairs & inner circle
draw.line([cx - 60, cy, cx + 60, cy], fill=(0, 220, 255), width=5)
draw.line([cx, cy - 60, cx, cy + 60], fill=(0, 220, 255), width=5)
draw.ellipse([cx - 25, cy - 25, cx + 25, cy + 25], outline=(0, 220, 255), width=4)

# Outer Hazard Stripes (thick and bright along all 4 perimeter edges)
stripe_w = 56
for i in range(-w, w * 2, 36):
    draw.polygon([(i, 0), (i + 18, 0), (i + 18 - stripe_w, stripe_w), (i - stripe_w, stripe_w)], fill=(240, 195, 20))
    draw.polygon([(i, h - stripe_w), (i + 18, h - stripe_w), (i + 18 - stripe_w, h), (i - stripe_w, h)], fill=(240, 195, 20))
    draw.polygon([(0, i), (0, i + 18), (stripe_w, i + 18 - stripe_w), (stripe_w, i - stripe_w)], fill=(240, 195, 20))
    draw.polygon([(w - stripe_w, i), (w - stripe_w, i + 18), (w, i + 18 - stripe_w), (w, i - stripe_w)], fill=(240, 195, 20))

floor_img.save(os.path.join(assets_dir, "floor_albedo.png"))
print("Enhanced floor and sign generated!")

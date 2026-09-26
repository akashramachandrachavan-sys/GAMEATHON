import os
from PIL import Image, ImageDraw, ImageFilter

assets_dir = "/Users/akash/GAMEATHON/revolt_godot/assets"
os.makedirs(assets_dir, exist_ok=True)

# 1. High-Tech Cyber Proving Ground (1024x1024)
ground = Image.new("RGB", (1024, 1024), (32, 35, 42))
gdraw = ImageDraw.Draw(ground)

# Concrete slabs with textured variance
slab = 128
for x in range(0, 1024, slab):
    for y in range(0, 1024, slab):
        v = int(34 + ((x * 17 + y * 29) % 16))
        gdraw.rectangle([x, y, x + slab - 1, y + slab - 1], fill=(v, v + 2, v + 5), outline=(18, 20, 24), width=3)
        # Metallic drainage grates on corner intersections
        if (x // slab + y // slab) % 3 == 0:
            gdraw.rectangle([x + 10, y + 10, x + slab - 10, y + slab - 10], fill=(22, 24, 28), outline=(50, 55, 65), width=2)
            for gy in range(y + 16, y + slab - 12, 12):
                gdraw.line([x + 16, gy, x + slab - 16, gy], fill=(12, 14, 16), width=3)

# Glowing Cyan Runway Light Strips
for gx in [256, 768]:
    gdraw.rectangle([gx - 6, 0, gx + 6, 1024], fill=(0, 210, 255))
    gdraw.rectangle([gx - 14, 0, gx + 14, 1024], outline=(0, 140, 180), width=2)

# Central Combat Helipad / Sector Circle
cx, cy = 512, 512
gdraw.ellipse([cx - 320, cy - 320, cx + 320, cy + 320], outline=(230, 180, 20), width=8)
gdraw.ellipse([cx - 290, cy - 290, cx + 290, cy + 290], outline=(0, 220, 255), width=4)
gdraw.ellipse([cx - 160, cy - 160, cx + 160, cy + 160], outline=(230, 180, 20), width=4)

# Giant Helipad 'H'
gdraw.line([cx - 90, cy - 80, cx - 90, cy + 80], fill=(230, 180, 20), width=20)
gdraw.line([cx + 90, cy - 80, cx + 90, cy + 80], fill=(230, 180, 20), width=20)
gdraw.line([cx - 90, cy, cx + 90, cy], fill=(230, 180, 20), width=20)

# Perimeter Hazard Chevrons (Yellow & Black)
for i in range(-1024, 2048, 48):
    gdraw.polygon([(i, 0), (i + 24, 0), (i - 48, 64), (i - 72, 64)], fill=(235, 185, 20))
    gdraw.polygon([(i, 1024 - 64), (i + 24, 1024 - 64), (i - 48, 1024), (i - 72, 1024)], fill=(235, 185, 20))
    gdraw.polygon([(0, i), (0, i + 24), (64, i - 48), (64, i - 72)], fill=(235, 185, 20))
    gdraw.polygon([(1024 - 64, i), (1024 - 64, i + 24), (1024, i - 48), (1024, i - 72)], fill=(235, 185, 20))

ground.save(os.path.join(assets_dir, "cyber_ground.png"))

# 2. Military Blast Barrier Wall (512x512)
wall = Image.new("RGB", (512, 512), (38, 42, 48))
wdraw = ImageDraw.Draw(wall)
# Steel plates
for y in range(0, 512, 128):
    wdraw.line([0, y, 512, y], fill=(18, 20, 24), width=4)
    for x in range(0, 512, 128):
        wdraw.line([x, y, x, y + 128], fill=(18, 20, 24), width=3)
        # Rivets
        for rx, ry in [(x + 12, y + 12), (x + 116, y + 12), (x + 12, y + 116), (x + 116, y + 116)]:
            wdraw.ellipse([rx - 4, ry - 4, rx + 4, ry + 4], fill=(85, 95, 110), outline=(20, 22, 26))

# Center Warning Stencil & Stripes
wdraw.rectangle([0, 220, 512, 292], fill=(25, 28, 34), outline=(230, 180, 20), width=3)
for x in range(-512, 1024, 32):
    wdraw.polygon([(x, 220), (x + 16, 220), (x - 16, 292), (x - 32, 292)], fill=(230, 180, 20))

wall.save(os.path.join(assets_dir, "blast_wall.png"))

# 3. Mech Titan Armor Plating (512x512)
mech_tex = Image.new("RGB", (512, 512), (48, 52, 58))
mdraw = ImageDraw.Draw(mech_tex)
# Hexagonal composite weave
hex_w, hex_h = 48, 28
for hx in range(-48, 560, hex_w):
    for hy in range(-28, 560, hex_h):
        off = (hex_w // 2) if (hy // hex_h) % 2 == 1 else 0
        mdraw.rectangle([hx + off, hy, hx + off + hex_w - 4, hy + hex_h - 4], fill=(42, 45, 52), outline=(28, 30, 35), width=2)

# Hazard stripes on edge
for x in range(0, 512, 36):
    mdraw.polygon([(x, 440), (x + 18, 440), (x - 18, 512), (x - 36, 512)], fill=(230, 180, 20))

mech_tex.save(os.path.join(assets_dir, "mech_armor_camo.png"))

# 4. Kai Styled Face & Cyber Visor Avatar (256x256)
avatar = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
adraw = ImageDraw.Draw(avatar)
acx, acy = 128, 128

# Anime swept spiky hair (back layer)
adraw.polygon([(acx - 45, acy - 40), (acx - 65, acy - 85), (acx - 25, acy - 80), (acx, acy - 110), (acx + 30, acy - 85), (acx + 65, acy - 80), (acx + 45, acy - 40)], fill=(30, 32, 38))
# Human Face
adraw.polygon([(acx - 34, acy - 50), (acx + 34, acy - 50), (acx + 28, acy + 10), (acx, acy + 35), (acx - 28, acy + 10)], fill=(240, 195, 165), outline=(20, 25, 30), width=2)
# Glowing Cyan Wrap-Around Visor
adraw.polygon([(acx - 36, acy - 25), (acx + 36, acy - 25), (acx + 32, acy - 5), (acx - 32, acy - 5)], fill=(0, 230, 255), outline=(0, 160, 200), width=2)
adraw.line([acx - 28, acy - 15, acx + 28, acy - 15], fill=(255, 255, 255), width=2)
# Anime Fringe / Bangs (front hair layer)
adraw.polygon([(acx - 36, acy - 45), (acx - 18, acy - 15), (acx - 5, acy - 40), (acx + 12, acy - 10), (acx + 32, acy - 35), (acx + 10, acy - 65), (acx - 20, acy - 65)], fill=(38, 42, 50))
# Headset & Mic
adraw.rectangle([acx - 40, acy - 20, acx - 34, acy + 5], fill=(20, 25, 30))
adraw.line([acx - 36, acy - 5, acx - 12, acy + 15], fill=(0, 230, 255), width=3)
# Tactical Jacket / Collar
adraw.polygon([(acx - 20, acy + 30), (acx + 20, acy + 30), (acx + 55, acy + 115), (acx - 55, acy + 115)], fill=(28, 38, 52), outline=(0, 230, 255), width=2)
adraw.polygon([(acx - 16, acy + 40), (acx + 16, acy + 40), (acx + 22, acy + 95), (acx - 22, acy + 95)], fill=(45, 55, 70), outline=(0, 200, 160), width=2)

avatar.save(os.path.join(assets_dir, "kai_avatar.png"))
print("Enhanced cyber proving ground, blast wall, mech armor, and Kai avatar generated successfully!")

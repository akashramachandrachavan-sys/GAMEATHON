import os
from PIL import Image, ImageDraw

assets_dir = "/Users/akash/GAMEATHON/revolt_godot/assets"
os.makedirs(assets_dir, exist_ok=True)

# 1. Open Ground Runway / Concrete Testing Grounds (1024x1024 seamless)
ground = Image.new("RGB", (1024, 1024), (42, 45, 52))
gdraw = ImageDraw.Draw(ground)

# Concrete slab grid (128x128 slabs)
slab = 128
for x in range(0, 1024, slab):
    for y in range(0, 1024, slab):
        v = int(38 + ((x * 19 + y * 23) % 14))
        gdraw.rectangle([x, y, x + slab - 1, y + slab - 1], fill=(v, v + 3, v + 6), outline=(24, 26, 32), width=2)
        # Expansion joints
        gdraw.line([x, y, x + slab, y], fill=(20, 22, 28), width=3)
        gdraw.line([x, y, x, y + slab], fill=(20, 22, 28), width=3)

# Painted tactical runway lines & center landing circle
cx, cy = 512, 512
gdraw.ellipse([cx - 280, cy - 280, cx + 280, cy + 280], outline=(220, 180, 20), width=6)
gdraw.ellipse([cx - 260, cy - 260, cx + 260, cy + 260], outline=(0, 190, 240), width=3)
# Helipad H
gdraw.line([cx - 100, cy - 90, cx - 100, cy + 90], fill=(220, 180, 20), width=16)
gdraw.line([cx + 100, cy - 90, cx + 100, cy + 90], fill=(220, 180, 20), width=16)
gdraw.line([cx - 100, cy, cx + 100, cy], fill=(220, 180, 20), width=16)

# Outer boundary caution stripes
for i in range(-1024, 2048, 48):
    gdraw.polygon([(i, 0), (i + 24, 0), (i - 40, 64), (i - 64, 64)], fill=(220, 175, 20))
    gdraw.polygon([(i, 1024 - 64), (i + 24, 1024 - 64), (i - 40, 1024), (i - 64, 1024)], fill=(220, 175, 20))
    gdraw.polygon([(0, i), (0, i + 24), (64, i - 40), (64, i - 64)], fill=(220, 175, 20))
    gdraw.polygon([(1024 - 64, i), (1024 - 64, i + 24), (1024, i - 40), (1024, i - 64)], fill=(220, 175, 20))

ground.save(os.path.join(assets_dir, "open_ground.png"))

# 2. Sci-Fi Cargo Container Texture (512x512)
crate = Image.new("RGB", (512, 512), (30, 48, 64))
cdraw = ImageDraw.Draw(crate)
# Corrugated ridges
for x in range(0, 512, 32):
    cdraw.rectangle([x + 4, 10, x + 28, 502], fill=(40, 62, 82), outline=(18, 30, 42), width=2)
# Stencils
cdraw.rectangle([60, 200, 452, 312], fill=(20, 32, 44), outline=(220, 180, 20), width=3)
cdraw.text((90, 225), "STERLING ROBOTICS // SEC-9", fill=(240, 245, 255))
cdraw.text((90, 265), "HAZARD: EMP MUNITIONS INSIDE", fill=(220, 180, 20))

crate.save(os.path.join(assets_dir, "crate_albedo.png"))

# 3. Kai Character Avatar (for HUD bottom-left)
avatar = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
adraw = ImageDraw.Draw(avatar)
acx, acy = 128, 128
# Head
adraw.ellipse([acx - 30, acy - 65, acx + 30, acy - 5], fill=(235, 190, 155), outline=(0, 255, 140), width=2)
# Cyber Hair (anime spiky hair)
adraw.polygon([(acx - 32, acy - 55), (acx - 45, acy - 80), (acx - 15, acy - 75), (acx, acy - 95), (acx + 20, acy - 75), (acx + 45, acy - 80), (acx + 32, acy - 55)], fill=(45, 45, 55))
# Cyber visor across eyes
adraw.line([acx - 25, acy - 38, acx + 25, acy - 38], fill=(0, 255, 200), width=5)
# Neck
adraw.rectangle([acx - 12, acy - 5, acx + 12, acy + 12], fill=(220, 175, 140))
# Tactical Vest / Jacket
adraw.polygon([(acx - 45, acy + 12), (acx + 45, acy + 12), (acx + 55, acy + 90), (acx - 55, acy + 90)], fill=(32, 45, 60), outline=(0, 255, 140), width=2)
# Chest armor neon stripes
adraw.line([acx - 30, acy + 35, acx + 30, acy + 35], fill=(0, 255, 160), width=3)
adraw.line([acx, acy + 35, acx, acy + 75], fill=(0, 255, 160), width=3)

avatar.save(os.path.join(assets_dir, "kai_avatar.png"))
print("Open ground, crate, and Kai avatar generated!")

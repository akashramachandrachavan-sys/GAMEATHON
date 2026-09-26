import os
import subprocess

audio_dir = "/Users/akash/GAMEATHON/revolt_godot/assets/audio"
os.makedirs(audio_dir, exist_ok=True)

voice_lines = [
    # Maya Tactical Operator (Samantha - US English female tactical comms)
    ("maya_wave1.wav", "Samantha", "Kai! Recon scouts infiltrating the sector! Switch between your Pulse Rifle and Shotgun to shred their armor!"),
    ("maya_wave2.wav", "Samantha", "Two Combat Enforcers inbound! They pack heavy Gatling cannons—use your EMP to stun and reprogram!"),
    ("maya_wave3.wav", "Samantha", "Heavy Siege Titans entering the arena! Pierce their reinforced plating with the Ion Railgun!"),
    ("maya_wave4.wav", "Samantha", "Emergency alert! Apex Titan Omega-Zero has deployed! Stand your ground, unleash all weapons, and save the city!"),
    ("maya_shield_low.wav", "Samantha", "Shields down! Take cover immediately!"),
    ("maya_reprogrammed.wav", "Samantha", "Override successful! War machine reprogrammed to our side!"),

    # Robot War Machine Voices (Zarvox - Sinister robotic vocoder)
    ("bot_target.wav", "Zarvox", "Target acquired. Commencing extermination."),
    ("bot_fire.wav", "Zarvox", "Hostile human locked. Eradicate."),
    ("bot_damage.wav", "Zarvox", "Hull integrity compromised."),
    ("bot_boss_intro.wav", "Zarvox", "I am Omega-Zero. Human resistance is futile."),

    # Kai Hero Combat Callouts (Fred / Ralph - Punchy combat lines)
    ("kai_kill.wav", "Fred", "Scratch one bot!"),
    ("kai_overclock.wav", "Fred", "Overclock engaged!"),
    ("kai_emp.wav", "Fred", "EMP shockwave unleashed!")
]

for filename, voice, text in voice_lines:
    out_path = os.path.join(audio_dir, filename)
    cmd = ["say", "-v", voice, text, "-o", out_path, "--data-format=LEI16@22050"]
    print(f"Generating {filename} with voice {voice}...")
    subprocess.run(cmd, check=True)

print("All voice audio files generated successfully!")

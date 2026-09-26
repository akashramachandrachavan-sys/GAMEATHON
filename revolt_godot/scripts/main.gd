extends Node3D

# Main Game Controller for REVOLT 2150: SQUAD ALLIANCE
# Linear Wave Progression: Small Scouts -> Medium Enforcers -> Heavy Titans -> Flagship Boss OMEGA-ZERO

var current_wave: int = 1
var score: int = 0
var max_allies: int = 3
var active_allies: int = 0
var enemies_remaining: int = 0
var total_wave_enemies: int = 0
var game_active: bool = false

# References
var player: CharacterBody3D
var hud: CanvasLayer
var world_env: WorldEnvironment

func _ready() -> void:
	_setup_environment()
	_setup_arena()
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if all_args.has("--fast-start"):
		_start_gameplay()
	else:
		_show_story_intro()
		
	if all_args.has("--capture-screenshot"):
		var delay = 2.0
		for a in all_args:
			if a.begins_with("--delay="):
				delay = float(a.split("=")[1])
		get_tree().create_timer(delay).timeout.connect(func():
			var img = get_viewport().get_texture().get_image()
			img.save_png("res://screenshot_verified.png")
			get_tree().quit()
		)

func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		if event is InputEventKey and event.pressed:
			if event.keycode in [KEY_R, KEY_ENTER, KEY_SPACE]:
				get_tree().reload_current_scene()

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	# Rich Cyberpunk Twilight Sky
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.08, 0.12, 0.22)
	sky_mat.sky_horizon_color = Color(0.22, 0.32, 0.50)
	sky_mat.ground_bottom_color = Color(0.04, 0.06, 0.09)
	sky_mat.ground_horizon_color = Color(0.14, 0.18, 0.28)
	sky_mat.sun_angle_max = 45.0
	sky.sky_material = sky_mat
	env.sky = sky
	
	# PBR Ambient Lighting & Sky Reflections
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.40, 0.48, 0.62)
	env.ambient_light_sky_contribution = 0.85
	env.ambient_light_energy = 1.5
	
	# Clean Soft Bloom
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.glow_bloom = 0.08
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	
	# ACES Filmic Tonemapping
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.35
	
	# Screen-space Ambient Occlusion (SSAO)
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 2.4
	
	# Light atmospheric haze
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.16, 0.25)
	env.fog_density = 0.0012
	
	world_env.environment = env
	add_child(world_env)
	
	# Key Light with Shadows
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(0.88, 0.94, 1.0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.shadow_blur = 1.2
	sun.rotation_degrees = Vector3(-48, 38, 0)
	add_child(sun)

func _setup_arena() -> void:
	var arena_script = load("res://scripts/arena.gd")
	var arena = Node3D.new()
	arena.set_script(arena_script)
	add_child(arena)

func _show_story_intro() -> void:
	var intro_scene = load("res://scenes/StoryIntro.tscn")
	var intro = intro_scene.instantiate()
	intro.intro_completed.connect(_start_gameplay)
	add_child(intro)

func _start_gameplay() -> void:
	game_active = true
	
	# Setup HUD
	var hud_scene = load("res://scenes/HUD.tscn")
	hud = hud_scene.instantiate()
	hud.add_to_group("hud")
	add_child(hud)
	
	# Spawn Teen Hero Kai in the open testing plaza
	var player_script = load("res://scripts/player_mech.gd")
	player = CharacterBody3D.new()
	player.set_script(player_script)
	player.add_to_group("player")
	add_child(player)
	player.global_position = Vector3(0, 0.5, 36.0)
	
	# Connect Player Signals to HUD
	player.health_changed.connect(_on_player_health_changed)
	player.shield_changed.connect(hud.update_shield)
	player.stim_changed.connect(hud.update_stims)
	player.weapon_changed.connect(hud.update_weapon)
	player.heat_updated.connect(hud.update_heat)
	player.emp_cooldown_updated.connect(hud.update_emp)
	player.overclock_updated.connect(hud.update_overclock)
	player.reprogram_progress_updated.connect(hud.update_reprogram_progress)
	
	hud.update_allies(active_allies, max_allies)
	hud.update_score(score)
	
	# Start Wave (Defaults to 1, or can be set via --wave=N)
	var start_w = 1
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for a in all_args:
		if a.begins_with("--wave="):
			start_w = int(a.split("=")[1])
	_start_wave(start_w)

func _on_player_health_changed(current: float, max_hp: float) -> void:
	if is_instance_valid(hud):
		hud.update_health(current, max_hp)
	if current <= 0.0 and game_active:
		game_over(false)

func _start_wave(wave_num: int) -> void:
	current_wave = wave_num
	var subtitle = ""
	var comms_msg = ""
	var objective = ""
	
	match wave_num:
		1:
			subtitle = "RECON SCOUT INFILTRATION // 2 LIGHT UNITS DETECTED"
			objective = "OBJECTIVE: ELIMINATE RECON SCOUTS [ 2 REMAINING ]"
			comms_msg = "Kai! Sterling Labs recon scouts are infiltrating the testing grounds! They're fast and agile—switch between your [1] Pulse Rifle and [2] Shotgun to shred their plating!"
			hud.set_wave(1, "SECTOR ALERT // WAVE 1", subtitle, objective)
			hud.show_comms("MAYA // TACTICAL OVERRIDE", comms_msg, 7.5)
			AudioManager.play_voice_maya(1)
			# Wave 1: 2 Agile Scout Mechs (Linear start, 1-2 robots at a time)
			_spawn_wave_enemies(2, 0, 0, false)
		2:
			subtitle = "MEDIUM ASSAULT PATROL // 2 ENFORCERS INBOUND"
			objective = "OBJECTIVE: PURGE OR REPROGRAM ENFORCERS [ 2 REMAINING ]"
			comms_msg = "Two 4-meter Combat Enforcers are entering the plaza! They pack heavy Gatling guns—use your [Q] EMP Shockwave to stun one, then hold [E] to reprogram it!"
			hud.set_wave(2, "SECTOR ALERT // WAVE 2", subtitle, objective)
			hud.show_comms("MAYA // TACTICAL OVERRIDE", comms_msg, 7.5)
			AudioManager.play_voice_maya(2)
			# Wave 2: 2 Medium Enforcers
			_spawn_wave_enemies(0, 2, 0, false)
		3:
			subtitle = "HEAVY SIEGE BATTALION // 2 HEAVY TITANS INBOUND"
			objective = "OBJECTIVE: DESTROY OR REPROGRAM SIEGE TITANS [ 2 REMAINING ]"
			comms_msg = "Heavy 7-meter Siege Titans deployed with reinforced armor! Pierce their hull with the [3] Ion Railgun and pop Overclock [F] for bullet-time evasion!"
			hud.set_wave(3, "SECTOR ALERT // WAVE 3", subtitle, objective)
			hud.show_comms("JAX // HEAVY MUNITIONS", comms_msg, 7.5)
			AudioManager.play_voice_maya(3)
			# Wave 3: 2 Heavy Siege Titans
			_spawn_wave_enemies(0, 0, 2, false)
		4:
			subtitle = "CRITICAL THREAT // TITAN OMEGA-ZERO (11-METER APEX COLOSSUS)"
			objective = "OBJECTIVE: TERMINATE APEX TITAN OMEGA-ZERO"
			comms_msg = "CRITICAL ALERT! The Flagship Colossus OMEGA-ZERO has entered the arena! Stand your ground, unleash all firepower, and save the city!"
			hud.set_wave(4, "CRITICAL ALERT // WAVE 4", subtitle, objective)
			hud.show_comms("MAYA & JAX // EMERGENCY", comms_msg, 8.5)
			AudioManager.play_voice_maya(4)
			# Wave 4: Colossal Flagship Apex Boss
			_spawn_wave_enemies(0, 0, 0, true)

func _spawn_wave_enemies(scouts: int, grunts: int, bruisers: int, has_boss: bool) -> void:
	enemies_remaining = scouts + grunts + bruisers + (1 if has_boss else 0)
	total_wave_enemies = enemies_remaining
	var enemy_script = load("res://scripts/enemy_mech.gd")
	
	# Spawn points in open combat lanes with clear line-of-sight to the player
	var spawn_points = [
		Vector3(-10, 0.5, 2.0),
		Vector3(10, 0.5, 2.0),
		Vector3(-14, 0.5, -6.0),
		Vector3(14, 0.5, -6.0),
		Vector3(0, 0.5, -10.0)
	]
	
	var sp_idx = 0
	for i in range(scouts):
		var bot = CharacterBody3D.new()
		bot.set_script(enemy_script)
		bot.bot_type = "scout"
		add_child(bot)
		bot.global_position = spawn_points[sp_idx % spawn_points.size()]
		sp_idx += 1
		
	for i in range(grunts):
		var bot = CharacterBody3D.new()
		bot.set_script(enemy_script)
		bot.bot_type = "grunt"
		add_child(bot)
		bot.global_position = spawn_points[sp_idx % spawn_points.size()]
		sp_idx += 1
		
	for i in range(bruisers):
		var bot = CharacterBody3D.new()
		bot.set_script(enemy_script)
		bot.bot_type = "bruiser"
		add_child(bot)
		bot.global_position = spawn_points[sp_idx % spawn_points.size()]
		sp_idx += 1
		
	if has_boss:
		var boss = CharacterBody3D.new()
		boss.set_script(enemy_script)
		boss.bot_type = "boss"
		add_child(boss)
		boss.global_position = Vector3(0, 0.5, -14.0)
		AudioManager.play_voice_boss_intro()

func on_enemy_destroyed(bot_type: String) -> void:
	enemies_remaining = max(0, enemies_remaining - 1)
	match bot_type:
		"scout": score += 150
		"grunt": score += 350
		"bruiser": score += 650
		"boss": score += 3000
		
	hud.update_score(score)
	_update_hud_objective()
	_check_wave_cleared()

func on_bot_reprogrammed() -> void:
	enemies_remaining = max(0, enemies_remaining - 1)
	active_allies = min(max_allies, active_allies + 1)
	score += 450
	hud.update_score(score)
	hud.update_allies(active_allies, max_allies)
	hud.show_comms("MAYA // TACTICAL OVERRIDE", "Unit reprogrammed! Combat alliance updated.", 4.0)
	_update_hud_objective()
	_check_wave_cleared()

func on_ally_destroyed() -> void:
	active_allies = max(0, active_allies - 1)
	hud.update_allies(active_allies, max_allies)
	hud.show_comms("JAX // MUNITIONS", "Allied unit lost! Reprogram another if you need backup.", 4.0)

func _update_hud_objective() -> void:
	if not is_instance_valid(hud): return
	if current_wave == 4:
		hud.update_objective("OBJECTIVE: TERMINATE APEX TITAN OMEGA-ZERO")
	else:
		hud.update_objective("OBJECTIVE: ELIMINATE HOSTILES [ %d REMAINING ]" % enemies_remaining)

func _check_wave_cleared() -> void:
	if enemies_remaining <= 0 and game_active:
		if current_wave < 4:
			# Reward Kai with full shield and extra stim pack
			if is_instance_valid(player) and player.has_method("reward_wave_completion"):
				player.reward_wave_completion()
				
			hud.show_wave_cleared(current_wave, "+500 CREDITS | REPAIRING NANO-VEST (+100 SHIELD, +1 STIM)")
			hud.show_comms("MAYA // TACTICAL OVERRIDE", "Sector secured! Next threat deploying in 3 seconds.", 4.5)
			
			get_tree().create_timer(3.5).timeout.connect(func():
				if game_active:
					_start_wave(current_wave + 1)
			)
		else:
			game_over(true)

func game_over(victory: bool) -> void:
	game_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var end_layer = CanvasLayer.new()
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.08, 0.94)
	bg.add_theme_stylebox_override("panel", style)
	end_layer.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300
	vbox.offset_right = 300
	vbox.offset_top = -160
	vbox.offset_bottom = 160
	vbox.add_theme_constant_override("separation", 16)
	bg.add_child(vbox)
	
	var title = Label.new()
	title.text = "VICTORY // OMEGA-ZERO PURGED!" if victory else "MISSION FAILED // KAI OVERWHELMED"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0, 1, 0.75) if victory else Color(1, 0.25, 0.25))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var desc = Label.new()
	if victory:
		desc.text = "Kai, Maya, and Jax saved Sterling City!\nThe rogue machine fleet has been completely deactivated.\nPROVING GROUNDS LIBERATED — ALL 4 WAVES CLEARED."
	else:
		desc.text = "Omega-Zero's rogue armada overran the testing grounds.\nRe-calibrate your weapon systems and fight again!"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.8, 0.9, 0.95))
	vbox.add_child(desc)
	
	var score_lbl = Label.new()
	score_lbl.text = "FINAL SCORE: %05d   //   WAVES SURVIVED: %d / 4" % [score, current_wave if victory else (current_wave - 1)]
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 16)
	score_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0))
	vbox.add_child(score_lbl)
	
	var restart_btn = Button.new()
	restart_btn.text = "REPLAY MISSION [R / ENTER]"
	restart_btn.custom_minimum_size = Vector2(260, 52)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0.75, 0.9)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	restart_btn.add_theme_stylebox_override("normal", btn_style)
	restart_btn.pressed.connect(func():
		get_tree().reload_current_scene()
	)
	vbox.add_child(restart_btn)
	
	add_child(end_layer)

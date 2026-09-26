extends Node3D

# Main Game Controller for REVOLT 2150: SQUAD ALLIANCE

var current_wave: int = 1
var score: int = 0
var max_allies: int = 3
var active_allies: int = 0
var enemies_remaining: int = 0
var game_active: bool = false

# References
var player: CharacterBody3D
var hud: CanvasLayer
var world_env: WorldEnvironment

func _ready() -> void:
	_setup_environment()
	_setup_arena()
	if OS.get_cmdline_user_args().has("--fast-start"):
		_start_gameplay()
	else:
		_show_story_intro()

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	# Realistic Cyberpunk Sky / Warehouse Dome
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.12, 0.16, 0.24)
	sky_mat.sky_horizon_color = Color(0.24, 0.3, 0.42)
	sky_mat.ground_bottom_color = Color(0.08, 0.1, 0.14)
	sky_mat.ground_horizon_color = Color(0.18, 0.22, 0.3)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky
	
	# PBR Ambient Lighting & Sky Reflections (Gives metallic armor natural reflections)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.35, 0.42, 0.55)
	env.ambient_light_sky_contribution = 0.9
	env.ambient_light_energy = 1.8
	
	# Soft bloom / glow (No blinding additive blowouts!)
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	
	# Filmic / ACES Tonemapping
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.25
	
	# Screen-space Ambient Occlusion (SSAO) for grounded contact shadows
	env.ssao_enabled = true
	env.ssao_radius = 1.8
	env.ssao_intensity = 2.2
	
	# Subtle atmospheric depth haze (Light and clean)
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.14, 0.2)
	env.fog_density = 0.001
	
	world_env.environment = env
	add_child(world_env)

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
	add_child(hud)
	
	# Spawn Teen Hero Kai in the open testing plaza
	var player_script = load("res://scripts/player_mech.gd")
	player = CharacterBody3D.new()
	player.set_script(player_script)
	player.add_to_group("player")
	add_child(player)
	player.global_position = Vector3(0, 0.5, 22.0)
	
	# Connect Player Signals to HUD
	player.health_changed.connect(hud.update_health)
	player.heat_updated.connect(hud.update_heat)
	player.emp_cooldown_updated.connect(hud.update_emp)
	player.reprogram_progress_updated.connect(hud.update_reprogram_progress)
	
	hud.update_allies(active_allies, max_allies)
	hud.update_score(score)
	
	# Start Wave 1
	_start_wave(1)

func _start_wave(wave_num: int) -> void:
	current_wave = wave_num
	var subtitle = ""
	var comms_msg = ""
	
	match wave_num:
		1:
			subtitle = "ROGUE BATTLE DROIDS // PURGE OR REPROGRAM"
			comms_msg = "Kai! Malfunctioning robots have overrun the open testing grounds! Stun them with your EMP [Q] and hold [E] to reprogram!"
			hud.set_wave(1, "OPEN SECTOR // WAVE 1", subtitle)
			hud.show_comms("MAYA // TACTICAL OVERRIDE", comms_msg, 7.0)
			_spawn_wave_enemies(4, 0, false)
		2:
			subtitle = "HEAVY BRUISER ENFORCERS // REPROGRAM FOR FIRE SUPPORT"
			comms_msg = "Heavy bruiser mechs inbound across the courtyard! Use cargo containers for cover and recruit an ally squad!"
			hud.set_wave(2, "OPEN SECTOR // WAVE 2", subtitle)
			hud.show_comms("JAX // HEAVY MUNITIONS", comms_msg, 7.0)
			_spawn_wave_enemies(4, 2, false)
		3:
			subtitle = "TITAN OMEGA-ZERO // MASSIVE THREAT DETECTED!"
			comms_msg = "CRITICAL ALERT! Omega-Zero has breached the open sector! Coordinate fire with your allied robot squad!"
			hud.set_wave(3, "CRITICAL ALERT // WAVE 3", subtitle)
			hud.show_comms("MAYA // EMERGENCY", comms_msg, 8.0)
			_spawn_wave_enemies(3, 2, true)

func _spawn_wave_enemies(grunts: int, bruisers: int, has_boss: bool) -> void:
	enemies_remaining = grunts + bruisers + (1 if has_boss else 0)
	var enemy_script = load("res://scripts/enemy_mech.gd")
	
	var spawn_points = [
		Vector3(-25, 0.5, -25),
		Vector3(25, 0.5, -25),
		Vector3(0, 0.5, -30),
		Vector3(-28, 0.5, 0),
		Vector3(28, 0.5, 0),
		Vector3(-18, 0.5, -15),
		Vector3(18, 0.5, -15),
		Vector3(-10, 0.5, -22),
		Vector3(10, 0.5, -22)
	]
	spawn_points.shuffle()
	
	var sp_idx = 0
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
		boss.global_position = Vector3(0, 0.5, -12)

func on_enemy_destroyed(bot_type: String) -> void:
	enemies_remaining = max(0, enemies_remaining - 1)
	match bot_type:
		"grunt": score += 100
		"bruiser": score += 250
		"boss": score += 1500
		
	hud.update_score(score)
	_check_wave_cleared()

func on_bot_reprogrammed() -> void:
	enemies_remaining = max(0, enemies_remaining - 1)
	active_allies = min(max_allies, active_allies + 1)
	score += 350
	hud.update_score(score)
	hud.update_allies(active_allies, max_allies)
	hud.show_comms("MAYA // TACTICAL OVERRIDE", "Unit reprogrammed! Combat alliance updated.", 4.0)
	_check_wave_cleared()

func on_ally_destroyed() -> void:
	active_allies = max(0, active_allies - 1)
	hud.update_allies(active_allies, max_allies)
	hud.show_comms("JAX // MUNITIONS", "Allied unit lost! Reprogram another if you need backup.", 4.0)

func _check_wave_cleared() -> void:
	if enemies_remaining <= 0 and game_active:
		if current_wave < 3:
			hud.show_comms("MAYA // TACTICAL OVERRIDE", "Sector secured! Next wave deploying immediately.", 5.0)
			get_tree().create_timer(3.5).timeout.connect(func():
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
	style.bg_color = Color(0.02, 0.04, 0.08, 0.92)
	bg.add_theme_stylebox_override("panel", style)
	end_layer.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250
	vbox.offset_right = 250
	vbox.offset_top = -140
	vbox.offset_bottom = 140
	vbox.add_theme_constant_override("separation", 18)
	bg.add_child(vbox)
	
	var title = Label.new()
	title.text = "VICTORY // OMEGA-ZERO PURGED!" if victory else "MISSION FAILED // KAI OVERWHELMED"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0, 1, 0.7) if victory else Color(1, 0.2, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var desc = Label.new()
	if victory:
		desc.text = "Kai, Maya and Jax successfully stopped the robot rebellion!\nThe city is saved thanks to your Squad Alliance."
	else:
		desc.text = "Omega-Zero's rogue army conquered the sector.\nRepair your Vanguard Walker and fight back!"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	var score_lbl = Label.new()
	score_lbl.text = "FINAL SCORE: %d" % score
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_lbl)
	
	var restart_btn = Button.new()
	restart_btn.text = "PLAY AGAIN [ENTER]"
	restart_btn.custom_minimum_size = Vector2(220, 50)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0.7, 0.9)
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

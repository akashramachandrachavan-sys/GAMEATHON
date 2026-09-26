extends CharacterBody3D

# Rogue War Machine AI for REVOLT 2150 (Godot 4.7)
# Dynamic combatant: active rhythmic shooting, feeler navigation around containers,
# unique high-detail 3D robot models for each class, articulated hydraulics, voice lines,
# and spectacular cinematic death explosions.

@export var bot_type: String = "scout" # "scout", "grunt", "bruiser", "boss"

var max_health: float = 160.0
var health: float = 160.0
var speed: float = 7.5
var damage_per_shot: float = 7.0
var attack_range: float = 110.0 # Full-arena engagement
var preferred_dist: float = 16.0
var team: String = "enemy"

# Firing State Machine
enum FiringState { IDLE, SPINUP, FIRING, COOLDOWN }
var firing_state: FiringState = FiringState.IDLE
var burst_count: int = 0
var max_burst: int = 4
var spinup_timer: float = 0.0
var shot_interval: float = 0.14
var shot_timer: float = 0.0
var cooldown_timer: float = 0.0
var has_played_target_voice: bool = false

# State & AI
var is_stunned: bool = false
var stun_timer: float = 0.0
var target: Node3D = null
var walk_cycle: float = 0.0
var step_interval: float = 0.32
var step_timer: float = 0.0
var flank_angle_offset: float = 0.0
var strafe_direction: float = 1.0
var strafe_timer: float = 0.0
var is_dying: bool = false

# Node References
var torso: Node3D
var head_pivot: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_shin: Node3D
var right_shin: Node3D
var left_piston: Node3D
var right_piston: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_gatling_barrels: Node3D
var right_gatling_barrels: Node3D
var visor_mesh: MeshInstance3D
var visor_mat: StandardMaterial3D
var searchlight: SpotLight3D
var stun_sparks: CPUParticles3D
var prompt_label: Label3D
var health_label: Label3D
var reactor_mat: StandardMaterial3D
var thruster_particles: CPUParticles3D

func _ready() -> void:
	add_to_group("enemies")
	flank_angle_offset = sin(float(get_instance_id() % 13)) * 0.45
	_configure_stats()
	_build_mech_model()
	_setup_collision()
	
	if bot_type == "boss":
		var hud = get_tree().get_first_node_in_group("hud")
		if is_instance_valid(hud) and hud.has_method("update_boss_health"):
			hud.update_boss_health(health, max_health)

func _configure_stats() -> void:
	match bot_type:
		"scout":
			# Wave 1: Fast agile scout runner (~2.8m tall)
			max_health = 160.0
			speed = 7.5
			damage_per_shot = 6.0
			scale = Vector3(1.8, 1.8, 1.8)
			attack_range = 110.0
			preferred_dist = 14.0
			max_burst = 4
			shot_interval = 0.14
			step_interval = 0.30
		"grunt":
			# Wave 2: Medium combat enforcer (~4.5m tall)
			max_health = 420.0
			speed = 5.2
			damage_per_shot = 9.0
			scale = Vector3(2.8, 2.8, 2.8)
			attack_range = 120.0
			preferred_dist = 18.0
			max_burst = 6
			shot_interval = 0.12
			step_interval = 0.45
		"bruiser":
			# Wave 3: Heavy siege titan (~7m tall)
			max_health = 850.0
			speed = 3.6
			damage_per_shot = 15.0
			scale = Vector3(4.2, 4.2, 4.2)
			attack_range = 130.0
			preferred_dist = 22.0
			max_burst = 8
			shot_interval = 0.10
			step_interval = 0.65
		"boss":
			# Wave 4: Flagship Colossus Titan OMEGA-ZERO (~11m tall)
			max_health = 2600.0
			speed = 4.0
			damage_per_shot = 20.0
			scale = Vector3(6.5, 6.5, 6.5)
			attack_range = 150.0
			preferred_dist = 26.0
			max_burst = 14
			shot_interval = 0.08
			step_interval = 0.85
	health = max_health

func _physics_process(delta: float) -> void:
	if is_dying: return
	
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	else:
		velocity.y = 0.0

	# Process EMP Stun State
	if is_stunned:
		stun_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		
		if stun_sparks: stun_sparks.emitting = true
		if prompt_label: prompt_label.visible = true
		
		if visor_mat:
			var flicker = sin(Time.get_ticks_msec() * 0.04) > 0.0
			visor_mat.emission_energy_multiplier = 3.5 if flicker else 0.4
			
		if stun_timer <= 0.0:
			_recover_from_stun()
		return
		
	# Combat Navigation AI
	_find_target()
	
	if is_instance_valid(target):
		var target_pos = target.global_position
		var diff = target_pos - global_position
		diff.y = 0
		var dist = diff.length()
		
		# Turn chassis to face target
		if diff.length() > 0.1:
			var target_rot = atan2(diff.x, diff.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 5.5 * delta)
			
		# Head tracking: Head pivot swivels independently to lock gaze on Kai
		if head_pivot:
			var head_target_rot = atan2(diff.x, diff.z) - rotation.y
			head_pivot.rotation.y = lerp_angle(head_pivot.rotation.y, head_target_rot, 8.0 * delta)
			
		# Tactical Strafing Timer
		strafe_timer += delta
		if strafe_timer >= 2.0:
			strafe_timer = 0.0
			strafe_direction = -strafe_direction if randf() > 0.3 else strafe_direction
			
		var move_dir = _calculate_smart_movement(diff, dist, delta)
		var target_vel = move_dir * speed
		velocity.x = lerp(velocity.x, target_vel.x, 6.0 * delta)
		velocity.z = lerp(velocity.z, target_vel.z, 6.0 * delta)
		
		# Realistic Articulated Mechanical Walk Cycle
		if move_dir.length() > 0.1:
			walk_cycle += delta * (9.0 if bot_type == "scout" else 6.0)
			var l_rot = sin(walk_cycle) * (26.0 if bot_type == "scout" else 30.0)
			var r_rot = -sin(walk_cycle) * (26.0 if bot_type == "scout" else 30.0)
			left_leg.rotation_degrees.x = l_rot
			right_leg.rotation_degrees.x = r_rot
			
			if left_shin: left_shin.rotation_degrees.x = max(0.0, -l_rot * 0.75)
			if right_shin: right_shin.rotation_degrees.x = max(0.0, -r_rot * 0.75)
			
			# Hydraulic pistons visibly compress and extend
			if left_piston: left_piston.position.y = -0.55 + sin(walk_cycle) * 0.12
			if right_piston: right_piston.position.y = -0.55 - sin(walk_cycle) * 0.12
			
			# Chassis swaying & stomping
			torso.position.y = 1.35 + abs(sin(walk_cycle * 2.0)) * (0.08 if bot_type == "scout" else 0.14)
			torso.rotation_degrees.z = sin(walk_cycle) * 3.5
			
			step_timer += delta
			if step_timer >= step_interval:
				step_timer = 0.0
				AudioManager.play_step()
				if bot_type in ["bruiser", "boss"]:
					_spawn_footstep_shockwave()
					
			if thruster_particles: thruster_particles.emitting = true
		else:
			left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 6.0 * delta)
			right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 6.0 * delta)
			if left_shin: left_shin.rotation_degrees.x = lerp(left_shin.rotation_degrees.x, 0.0, 6.0 * delta)
			if right_shin: right_shin.rotation_degrees.x = lerp(right_shin.rotation_degrees.x, 0.0, 6.0 * delta)
			torso.position.y = lerp(torso.position.y, 1.35, 6.0 * delta)
			torso.rotation_degrees.z = lerp(torso.rotation_degrees.z, 0.0, 6.0 * delta)
			if thruster_particles: thruster_particles.emitting = false
			
		# Arm & Cannon Pitch Tracking (tilt weapons up/down to track Kai)
		var y_diff = (target.global_position.y + 1.0) - (global_position.y + 1.25 * scale.y)
		var horiz_dist = max(1.0, diff.length())
		var aim_pitch_deg = rad_to_deg(atan2(y_diff, horiz_dist))
		if left_arm: left_arm.rotation_degrees.x = clamp(aim_pitch_deg, -35.0, 35.0)
		if right_arm: right_arm.rotation_degrees.x = clamp(aim_pitch_deg, -35.0, 35.0)

		# Active Combat Shooting across the full battlefield
		if dist <= attack_range:
			_process_firing_cycle(delta)
		elif firing_state != FiringState.COOLDOWN:
			firing_state = FiringState.IDLE
	else:
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
		
	move_and_slide()

# Feeler Pathfinding: Smoothly routes around cargo containers and blast walls
func _calculate_smart_movement(target_diff: Vector3, dist: float, _delta: float) -> Vector3:
	var base_dir = Vector3.ZERO
	var norm_diff = target_diff.normalized()
	var strafe_vec = Vector3(-norm_diff.z, 0, norm_diff.x).normalized()
	
	if dist > preferred_dist + 3.0:
		base_dir = (norm_diff + strafe_vec * flank_angle_offset).normalized()
	elif dist < preferred_dist - 3.0:
		base_dir = (-norm_diff + strafe_vec * flank_angle_offset).normalized()
	else:
		base_dir = (strafe_vec * strafe_direction + norm_diff * 0.3).normalized()
		
	# Raycast Feeler Check
	var space_state = get_world_3d().direct_space_state
	var start_pos = global_position + Vector3(0, 1.2 * scale.y, 0)
	var feeler_dist = 5.0 * scale.y
	
	var forward_query = PhysicsRayQueryParameters3D.create(start_pos, start_pos + base_dir * feeler_dist)
	forward_query.exclude = [self]
	var forward_hit = space_state.intersect_ray(forward_query)
	
	if forward_hit and not forward_hit.collider.is_in_group("player") and not forward_hit.collider.is_in_group("allies"):
		var right_dir = base_dir.rotated(Vector3.UP, deg_to_rad(-45)).normalized()
		var left_dir = base_dir.rotated(Vector3.UP, deg_to_rad(45)).normalized()
		
		var right_query = PhysicsRayQueryParameters3D.create(start_pos, start_pos + right_dir * feeler_dist)
		right_query.exclude = [self]
		var right_hit = space_state.intersect_ray(right_query)
		
		var left_query = PhysicsRayQueryParameters3D.create(start_pos, start_pos + left_dir * feeler_dist)
		left_query.exclude = [self]
		var left_hit = space_state.intersect_ray(left_query)
		
		if not right_hit:
			base_dir = right_dir
		elif not left_hit:
			base_dir = left_dir
		else:
			base_dir = base_dir.rotated(Vector3.UP, deg_to_rad(90)).normalized()
			
	return base_dir

func _process_firing_cycle(delta: float) -> void:
	match firing_state:
		FiringState.IDLE:
			# Begin attack telegraph / spin-up
			firing_state = FiringState.SPINUP
			spinup_timer = 0.12 if bot_type == "scout" else 0.25
			if visor_mat:
				visor_mat.emission_energy_multiplier = 4.2
			if not has_played_target_voice:
				has_played_target_voice = true
				AudioManager.play_voice_bot_target()
				
		FiringState.SPINUP:
			spinup_timer -= delta
			var spin_speed = 1400.0 * delta
			if left_gatling_barrels: left_gatling_barrels.rotation_degrees.z += spin_speed
			if right_gatling_barrels: right_gatling_barrels.rotation_degrees.z += spin_speed
			
			if spinup_timer <= 0.0:
				firing_state = FiringState.FIRING
				burst_count = 0
				shot_timer = 0.0 # First shot fires immediately!
				
		FiringState.FIRING:
			var spin_speed = 2200.0 * delta
			if left_gatling_barrels: left_gatling_barrels.rotation_degrees.z += spin_speed
			if right_gatling_barrels: right_gatling_barrels.rotation_degrees.z += spin_speed
			
			shot_timer -= delta
			if shot_timer <= 0.0:
				shot_timer = shot_interval
				burst_count += 1
				_fire_single_shot()
				
				if burst_count >= max_burst:
					burst_count = 0
					firing_state = FiringState.COOLDOWN
					cooldown_timer = randf_range(0.7, 1.2) if bot_type == "scout" else randf_range(1.0, 1.6)
					if visor_mat:
						visor_mat.emission_energy_multiplier = 1.6
						
		FiringState.COOLDOWN:
			cooldown_timer -= delta
			if cooldown_timer <= 0.0:
				firing_state = FiringState.IDLE

func _fire_single_shot() -> void:
	if not is_instance_valid(target): return
	
	var is_left = (burst_count % 2 == 1)
	var forward_dir = global_transform.basis.z # Front of robot model is +basis.z
	var right_dir = global_transform.basis.x
	
	# Clean forward spawn position in front of weapon barrel
	var spawn_pos = global_position + Vector3(0, 1.25 * scale.y, 0) + forward_dir * (1.6 * scale.y)
	spawn_pos += (right_dir * -0.65 * scale.y) if is_left else (right_dir * 0.65 * scale.y)
	
	var aim_dir = (target.global_position + Vector3(0, 1.0, 0) - spawn_pos).normalized()
	var spread_amt = 0.025 if bot_type == "scout" else 0.015
	aim_dir += Vector3(randf_range(-spread_amt, spread_amt), randf_range(-spread_amt, spread_amt), randf_range(-spread_amt, spread_amt))
	aim_dir = aim_dir.normalized()
	
	var pitch = 1.30 if bot_type == "scout" else (0.85 if bot_type == "grunt" else 0.60)
	AudioManager.play_shoot(pitch)
	
	# Voice Callout (Chance to trigger menacing robot voice during attack)
	if burst_count == 1 and randf() < 0.25:
		AudioManager.play_voice_bot_fire()
		
	# Arm recoil kick
	var active_arm = left_arm if is_left else right_arm
	if active_arm:
		active_arm.position.z -= 0.14 * scale.y
		var tween = create_tween()
		tween.tween_property(active_arm, "position:z", 0.0, 0.08)
		
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.initialize_projectile(spawn_pos, aim_dir, team, "enemy", damage_per_shot)
	
	var target_parent = get_parent() if is_instance_valid(get_parent()) else get_tree().current_scene
	if target_parent:
		target_parent.add_child(bullet)
	else:
		get_tree().root.add_child(bullet)
	bullet.global_position = spawn_pos
	
	# High-Intensity Orange Plasma Muzzle Flash
	var m_light = OmniLight3D.new()
	m_light.light_color = Color(1.0, 0.45, 0.05)
	m_light.light_energy = 5.0
	m_light.omni_range = 6.5
	if target_parent:
		target_parent.add_child(m_light)
	else:
		get_tree().root.add_child(m_light)
	m_light.global_position = spawn_pos
	get_tree().create_timer(0.08).timeout.connect(func(): if is_instance_valid(m_light): m_light.queue_free())

func _spawn_footstep_shockwave() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var p_dist = global_position.distance_to(player.global_position)
		if p_dist < 40.0 and player.get("camera_shake") != null:
			player.camera_shake = max(player.camera_shake, 0.35 * (1.0 - p_dist / 40.0))

func _find_target() -> void:
	var potential_targets = []
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		potential_targets.append(player)
		
	var allies = get_tree().get_nodes_in_group("allies")
	for ally in allies:
		if is_instance_valid(ally):
			potential_targets.append(ally)
			
	var closest: Node3D = null
	var min_d = 999.0
	for t in potential_targets:
		var d = global_position.distance_to(t.global_position)
		if d < min_d:
			min_d = d
			closest = t
	target = closest

func apply_emp_stun(duration: float) -> void:
	if bot_type == "boss":
		duration *= 0.50
		
	is_stunned = true
	stun_timer = duration
	if stun_sparks: stun_sparks.emitting = true
	if prompt_label: prompt_label.visible = true

func _recover_from_stun() -> void:
	is_stunned = false
	if stun_sparks: stun_sparks.emitting = false
	if prompt_label and (health / max_health) > 0.35:
		prompt_label.visible = false
	if visor_mat:
		var red = Color(1.0, 0.1, 0.1) if bot_type != "scout" else Color(1.0, 0.55, 0.0)
		visor_mat.emission = red
		visor_mat.emission_energy_multiplier = 1.6

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	if is_dying: return
	
	if is_stunned:
		amount *= 1.45
		
	health = max(0.0, health - amount)
	_update_health_display()
	
	if bot_type == "boss":
		var hud = get_tree().get_first_node_in_group("hud")
		if is_instance_valid(hud) and hud.has_method("update_boss_health"):
			hud.update_boss_health(health, max_health)
			
	# Voice callout on damage (20% chance)
	if randf() < 0.20:
		AudioManager.play_voice_bot_damage()
		
	if visor_mat:
		visor_mat.emission_energy_multiplier = 4.5
		var t = get_tree().create_tween()
		t.tween_property(visor_mat, "emission_energy_multiplier", 1.6, 0.08)
		
	# Spark and show hack prompt when damaged below 35% HP
	if health > 0 and (health / max_health) <= 0.35:
		if prompt_label: prompt_label.visible = true
		if stun_sparks: stun_sparks.emitting = true
		
	if health <= 0.0:
		_die()

func _update_health_display() -> void:
	if health_label:
		var pct = int((health / max_health) * 100.0)
		health_label.text = "[ %s: %d%% ]" % [bot_type.to_upper(), pct]
		if pct < 35:
			health_label.modulate = Color(1.0, 0.2, 0.2)

func _die() -> void:
	if is_dying: return
	is_dying = true
	
	visible = false
	set_physics_process(false)
	var col = get_node_or_null("CollisionShape3D")
	if col: col.set_deferred("disabled", true)
	
	AudioManager.play_explosion()
	if randf() < 0.35:
		AudioManager.play_voice_kai_kill()
		
	_spawn_massive_cinematic_explosion()
	
	var main_node = get_parent()
	if main_node.has_method("on_enemy_destroyed"):
		main_node.on_enemy_destroyed(bot_type)
		
	queue_free()

func _spawn_massive_cinematic_explosion() -> void:
	var root = get_parent() if is_instance_valid(get_parent()) else get_tree().current_scene
	if not is_instance_valid(root): return
	var spawn_pos = global_position + Vector3(0, 1.2 * scale.y, 0)
	
	# Expanding Fireball
	var fireball = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 1.0 * scale.y
	f_sph.height = 2.0 * scale.y
	fireball.mesh = f_sph
	
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.95)
	f_mat.emission_enabled = true
	f_mat.emission = Color(1.0, 0.65, 0.15)
	f_mat.emission_energy_multiplier = 4.5
	fireball.material_override = f_mat
	
	root.add_child(fireball)
	fireball.global_position = spawn_pos
	
	var ft = fireball.create_tween()
	ft.tween_property(fireball, "scale", Vector3(2.5, 2.5, 2.5), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.parallel().tween_property(f_mat, "albedo_color:a", 0.0, 0.32)
	ft.tween_callback(fireball.queue_free)
	get_tree().create_timer(0.38).timeout.connect(func(): if is_instance_valid(fireball): fireball.queue_free())
	
	# Debris Particles
	var debris = CPUParticles3D.new()
	debris.emitting = true
	debris.one_shot = true
	debris.explosiveness = 1.0
	debris.amount = 45
	debris.lifetime = 0.75
	debris.spread = 180.0
	debris.initial_velocity_min = 10.0
	debris.initial_velocity_max = 24.0
	debris.gravity = Vector3(0, -18.0, 0)
	debris.color = Color(1.0, 0.45, 0.1)
	root.add_child(debris)
	debris.global_position = spawn_pos
	get_tree().create_timer(0.85).timeout.connect(func(): if is_instance_valid(debris): debris.queue_free())

	# Ground Shockwave
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.3
	ring.mesh = torus
	ring.rotation_degrees.x = 90
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(1.0, 0.8, 0.2)
	r_mat.emission_enabled = true
	r_mat.emission = Color(1.0, 0.8, 0.2)
	r_mat.emission_energy_multiplier = 3.5
	ring.material_override = r_mat
	root.add_child(ring)
	ring.global_position = global_position + Vector3(0, 0.2, 0)
	
	var rt = ring.create_tween()
	rt.tween_property(ring, "scale", Vector3(10.0 * scale.y, 1.0, 10.0 * scale.y), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.parallel().tween_property(r_mat, "albedo_color:a", 0.0, 0.32)
	rt.tween_callback(ring.queue_free)
	get_tree().create_timer(0.38).timeout.connect(func(): if is_instance_valid(ring): ring.queue_free())

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.85
	cap.height = 2.6
	col.shape = cap
	col.position.y = 1.3
	add_child(col)

# ==============================================================================
# 3D MODEL ARCHITECTURE: DISTINCT HIGH-DETAIL MECHA CHASSIS PER CLASS
# ==============================================================================
func _build_mech_model() -> void:
	torso = Node3D.new()
	torso.position.y = 1.35
	add_child(torso)
	
	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0, 0.35, 0)
	torso.add_child(head_pivot)
	
	# PBR Materials
	var titan_armor = StandardMaterial3D.new()
	titan_armor.albedo_texture = load("res://assets/mech_titan_plate.png")
	titan_armor.metallic = 0.95
	titan_armor.roughness = 0.22
	
	var scout_armor = StandardMaterial3D.new()
	scout_armor.albedo_texture = load("res://assets/scout_drone_camo.png")
	scout_armor.metallic = 0.85
	scout_armor.roughness = 0.30
	
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.18, 0.20, 0.24)
	steel_mat.metallic = 0.98
	steel_mat.roughness = 0.18
	
	var chrome_mat = StandardMaterial3D.new()
	chrome_mat.albedo_color = Color(0.70, 0.75, 0.80)
	chrome_mat.metallic = 0.98
	chrome_mat.roughness = 0.12
	
	# Optical Visor Material
	visor_mat = StandardMaterial3D.new()
	var eye_color = Color(1.0, 0.55, 0.0) if bot_type == "scout" else (Color(1.0, 0.35, 0.05) if bot_type == "grunt" else (Color(1.0, 0.05, 0.05) if bot_type == "bruiser" else Color(1.0, 0.0, 0.35)))
	visor_mat.albedo_color = eye_color
	visor_mat.emission_enabled = true
	visor_mat.emission = eye_color
	visor_mat.emission_energy_multiplier = 2.4
	
	reactor_mat = StandardMaterial3D.new()
	reactor_mat.albedo_color = eye_color
	reactor_mat.emission_enabled = true
	reactor_mat.emission = eye_color
	reactor_mat.emission_energy_multiplier = 3.2
	
	match bot_type:
		"scout":
			_build_scout_chassis(scout_armor, steel_mat, chrome_mat, eye_color)
		"grunt":
			_build_grunt_chassis(titan_armor, steel_mat, chrome_mat, eye_color)
		"bruiser":
			_build_bruiser_chassis(titan_armor, steel_mat, chrome_mat, eye_color)
		"boss":
			_build_boss_chassis(titan_armor, steel_mat, chrome_mat, eye_color)
			
	# Overhead Health Label
	health_label = Label3D.new()
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.text = "[ %s: 100%% ]" % bot_type.to_upper()
	health_label.modulate = Color(0.9, 0.95, 1.0)
	health_label.font_size = 28
	health_label.position = Vector3(0, 1.8, 0)
	add_child(health_label)
	
	# Reprogram Prompt Hologram
	prompt_label = Label3D.new()
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.text = "[ HOLD E ] REPROGRAM AI CORE"
	prompt_label.modulate = Color(0.0, 1.0, 0.8)
	prompt_label.font_size = 32
	prompt_label.position = Vector3(0, 2.2, 0)
	prompt_label.visible = false
	add_child(prompt_label)
	
	# 3D Stun Sparks
	stun_sparks = CPUParticles3D.new()
	stun_sparks.emitting = false
	stun_sparks.amount = 28
	stun_sparks.lifetime = 0.4
	stun_sparks.spread = 180.0
	stun_sparks.initial_velocity_min = 3.0
	stun_sparks.initial_velocity_max = 7.0
	stun_sparks.color = Color(0.2, 0.9, 1.0)
	torso.add_child(stun_sparks)

# 1. SCOUT DRONE: Aerodynamic high-speed runner with insectoid sensor head
func _build_scout_chassis(armor_mat: Material, steel_mat: Material, chrome_mat: Material, eye_col: Color) -> void:
	# Sleek Main Chassis
	var hull = MeshInstance3D.new()
	var h_prism = PrismMesh.new()
	h_prism.size = Vector3(0.9, 0.65, 1.1)
	hull.mesh = h_prism
	hull.rotation_degrees.x = -90
	hull.material_override = armor_mat
	torso.add_child(hull)
	
	# Insectoid Head Sensor Pod
	var head = MeshInstance3D.new()
	var hd_box = BoxMesh.new()
	hd_box.size = Vector3(0.65, 0.35, 0.6)
	head.mesh = hd_box
	head.position = Vector3(0, 0.1, 0.45)
	head.material_override = armor_mat
	head_pivot.add_child(head)
	
	# Dual Angled Ocular Sensors
	for sx in [-0.2, 0.2]:
		var eye = MeshInstance3D.new()
		var e_cyl = CylinderMesh.new()
		e_cyl.top_radius = 0.08
		e_cyl.bottom_radius = 0.08
		e_cyl.height = 0.15
		eye.mesh = e_cyl
		eye.rotation_degrees.x = 90
		eye.position = Vector3(sx, 0.1, 0.72)
		eye.material_override = visor_mat
		head_pivot.add_child(eye)
		
	# Dual Communication Antennae
	for sx in [-0.25, 0.25]:
		var ant = MeshInstance3D.new()
		var a_cyl = CylinderMesh.new()
		a_cyl.top_radius = 0.015
		a_cyl.bottom_radius = 0.03
		a_cyl.height = 0.75
		ant.mesh = a_cyl
		ant.rotation_degrees.x = -25
		ant.position = Vector3(sx, 0.45, 0.2)
		ant.material_override = steel_mat
		head_pivot.add_child(ant)
		
	# Rear Jet Thruster Exhaust
	var thruster = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.15
	t_cyl.bottom_radius = 0.22
	t_cyl.height = 0.35
	thruster.mesh = t_cyl
	thruster.rotation_degrees.x = 90
	thruster.position = Vector3(0, 0.05, -0.6)
	thruster.material_override = steel_mat
	torso.add_child(thruster)
	
	thruster_particles = CPUParticles3D.new()
	thruster_particles.emitting = false
	thruster_particles.amount = 18
	thruster_particles.lifetime = 0.25
	thruster_particles.spread = 25.0
	thruster_particles.initial_velocity_min = 4.0
	thruster_particles.initial_velocity_max = 8.0
	thruster_particles.gravity = Vector3.ZERO
	thruster_particles.color = Color(1.0, 0.5, 0.1)
	thruster_particles.position = Vector3(0, 0.05, -0.8)
	torso.add_child(thruster_particles)
	
	# Dual Micro-Blasters
	for side in [-1, 1]:
		var arm = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.2, 0.22, 0.65)
		arm.mesh = a_box
		arm.position = Vector3(side * 0.55, -0.05, 0.2)
		arm.material_override = steel_mat
		torso.add_child(arm)
		if side == -1: left_arm = arm
		else: right_arm = arm
		
		var barrel = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.04
		b_cyl.bottom_radius = 0.04
		b_cyl.height = 0.45
		barrel.mesh = b_cyl
		barrel.rotation_degrees.x = 90
		barrel.position = Vector3(0, 0, 0.45)
		barrel.material_override = chrome_mat
		arm.add_child(barrel)
		
	# Articulated Digitigrade Legs
	_build_reverse_joint_legs(armor_mat, steel_mat, 0.45, 0.65)

# 2. COMBAT ENFORCER: Heavy bipedal humanoid mech with Gatling cannons & searchlight
func _build_grunt_chassis(armor_mat: Material, steel_mat: Material, chrome_mat: Material, eye_col: Color) -> void:
	# Heavy Armored Cockpit
	var hull = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(1.3, 0.9, 1.1)
	hull.mesh = h_box
	hull.material_override = armor_mat
	torso.add_child(hull)
	
	# Armored Sloped Brow
	var brow = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.2, 0.3, 0.45)
	brow.mesh = b_box
	brow.position = Vector3(0, 0.35, 0.5)
	brow.material_override = armor_mat
	head_pivot.add_child(brow)
	
	# Horizontal Scanning Visor Slit
	visor_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(1.05, 0.16, 0.2)
	visor_mesh.mesh = v_box
	visor_mesh.position = Vector3(0, 0.14, 0.58)
	visor_mesh.material_override = visor_mat
	head_pivot.add_child(visor_mesh)
	
	# High-Power Searchlight
	searchlight = SpotLight3D.new()
	searchlight.light_color = eye_col
	searchlight.light_energy = 9.0
	searchlight.spot_range = 45.0
	searchlight.spot_angle = 35.0
	searchlight.position = Vector3(0, 0.18, 0.7)
	searchlight.rotation_degrees.x = -18.0
	head_pivot.add_child(searchlight)
	
	# Shoulder Blast Armor
	for side in [-1, 1]:
		var sh = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.45, 0.4, 0.7)
		sh.mesh = s_box
		sh.position = Vector3(side * 0.9, 0.35, 0)
		sh.rotation_degrees.z = side * -18.0
		sh.material_override = armor_mat
		torso.add_child(sh)
		
	# Armored Dual Gatling Cannons
	for side in [-1, 1]:
		var arm = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.38, 0.42, 0.85)
		arm.mesh = a_box
		arm.position = Vector3(side * 0.95, -0.15, 0.15)
		arm.material_override = steel_mat
		torso.add_child(arm)
		if side == -1: left_arm = arm
		else: right_arm = arm
		
		var gatling = Node3D.new()
		gatling.position = Vector3(0, -0.05, 0.55)
		arm.add_child(gatling)
		if side == -1: left_gatling_barrels = gatling
		else: right_gatling_barrels = gatling
		
		# 4 Rotating Barrels
		for b_i in range(4):
			var bm = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.04
			cyl.bottom_radius = 0.04
			cyl.height = 0.85
			bm.mesh = cyl
			bm.rotation_degrees.x = 90
			var ang = b_i * (PI / 2.0)
			bm.position = Vector3(cos(ang) * 0.10, sin(ang) * 0.10, 0.4)
			bm.material_override = chrome_mat
			gatling.add_child(bm)
			
	# Rear Reactor Core Cylinder
	var rc = MeshInstance3D.new()
	var rc_cyl = CylinderMesh.new()
	rc_cyl.top_radius = 0.22
	rc_cyl.bottom_radius = 0.22
	rc_cyl.height = 0.65
	rc.mesh = rc_cyl
	rc.rotation_degrees.z = 90
	rc.position = Vector3(0, 0.15, -0.65)
	rc.material_override = reactor_mat
	torso.add_child(rc)
	
	_build_reverse_joint_legs(armor_mat, steel_mat, 0.55, 0.85)

# 3. SIEGE TITAN: Walking fortress with shoulder missile pods & autocannons
func _build_bruiser_chassis(armor_mat: Material, steel_mat: Material, chrome_mat: Material, eye_col: Color) -> void:
	# Heavy Sloped Hull
	var hull = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(1.5, 1.1, 1.3)
	hull.mesh = h_box
	hull.material_override = armor_mat
	torso.add_child(hull)
	
	# Reinforced Skull Visor
	var head = MeshInstance3D.new()
	var hd_box = BoxMesh.new()
	hd_box.size = Vector3(0.9, 0.4, 0.6)
	head.mesh = hd_box
	head.position = Vector3(0, 0.25, 0.6)
	head.material_override = armor_mat
	head_pivot.add_child(head)
	
	visor_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.8, 0.18, 0.22)
	visor_mesh.mesh = v_box
	visor_mesh.position = Vector3(0, 0.22, 0.72)
	visor_mesh.material_override = visor_mat
	head_pivot.add_child(visor_mesh)
	
	# Dual Shoulder 6-Cell Missile Pods
	for side in [-1, 1]:
		var pod = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.55, 0.45, 0.8)
		pod.mesh = p_box
		pod.position = Vector3(side * 1.1, 0.55, 0)
		pod.material_override = steel_mat
		torso.add_child(pod)
		
		# 6 Missile Tubes with glowing warheads
		for mx in [-0.14, 0.14]:
			for my in [-0.12, 0.0, 0.12]:
				var tube = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.05
				cyl.bottom_radius = 0.05
				cyl.height = 0.15
				tube.mesh = cyl
				tube.rotation_degrees.x = 90
				tube.position = Vector3(mx, my, 0.42)
				tube.material_override = reactor_mat
				pod.add_child(tube)
				
	# Heavy Dual Autocannons
	for side in [-1, 1]:
		var arm = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.42, 0.48, 1.0)
		arm.mesh = a_box
		arm.position = Vector3(side * 1.15, -0.2, 0.2)
		arm.material_override = steel_mat
		torso.add_child(arm)
		if side == -1: left_arm = arm
		else: right_arm = arm
		
		var barrel = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.09
		b_cyl.bottom_radius = 0.09
		b_cyl.height = 1.2
		barrel.mesh = b_cyl
		barrel.rotation_degrees.x = 90
		barrel.position = Vector3(0, -0.05, 0.9)
		barrel.material_override = chrome_mat
		arm.add_child(barrel)
		
	# Dual Nuclear Reactor Exhaust Manifolds
	for side in [-0.3, 0.3]:
		var stack = MeshInstance3D.new()
		var s_cyl = CylinderMesh.new()
		s_cyl.top_radius = 0.12
		s_cyl.bottom_radius = 0.18
		s_cyl.height = 0.6
		stack.mesh = s_cyl
		stack.position = Vector3(side, 0.7, -0.55)
		stack.material_override = reactor_mat
		torso.add_child(stack)
		
	_build_reverse_joint_legs(armor_mat, steel_mat, 0.70, 1.1)

# 4. APEX TITAN OMEGA-ZERO: 11-Meter colossal flagship boss
func _build_boss_chassis(armor_mat: Material, steel_mat: Material, chrome_mat: Material, eye_col: Color) -> void:
	# Massive Multi-Tiered Armored Hull
	var hull = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(1.8, 1.4, 1.5)
	hull.mesh = h_box
	hull.material_override = armor_mat
	torso.add_child(hull)
	
	# Menacing Cyber-Demon Skull Visor
	var skull = MeshInstance3D.new()
	var s_prism = PrismMesh.new()
	s_prism.size = Vector3(1.2, 0.8, 0.8)
	skull.mesh = s_prism
	skull.rotation_degrees.x = -90
	skull.position = Vector3(0, 0.45, 0.7)
	skull.material_override = armor_mat
	head_pivot.add_child(skull)
	
	# Tri-Optic Crimson Visor Cluster
	for pos in [Vector3(0, 0.5, 0.95), Vector3(-0.35, 0.35, 0.92), Vector3(0.35, 0.35, 0.92)]:
		var eye = MeshInstance3D.new()
		var e_sph = SphereMesh.new()
		e_sph.radius = 0.12
		e_sph.height = 0.24
		eye.mesh = e_sph
		eye.position = pos
		eye.material_override = visor_mat
		head_pivot.add_child(eye)
		
	# Radar Scanner Dish
	var dish = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.1
	cyl.height = 0.18
	dish.mesh = cyl
	dish.rotation_degrees.x = 35
	dish.position = Vector3(0, 1.1, -0.3)
	dish.material_override = steel_mat
	torso.add_child(dish)
	
	# Colossal Hyper-Plasma Rail Cannons
	for side in [-1, 1]:
		var arm = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.55, 0.65, 1.4)
		arm.mesh = a_box
		arm.position = Vector3(side * 1.35, -0.2, 0.3)
		arm.material_override = steel_mat
		torso.add_child(arm)
		if side == -1: left_arm = arm
		else: right_arm = arm
		
		# Dual Rail Barrel
		for by in [-0.12, 0.12]:
			var rail = MeshInstance3D.new()
			var r_box = BoxMesh.new()
			r_box.size = Vector3(0.18, 0.18, 1.8)
			rail.mesh = r_box
			rail.position = Vector3(0, by, 1.1)
			rail.material_override = chrome_mat
			arm.add_child(rail)
			
		# Energy Acceleration Coils
		for cz in [0.4, 0.8, 1.2]:
			var coil = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = 0.22
			torus.outer_radius = 0.28
			coil.mesh = torus
			coil.rotation_degrees.x = 90
			coil.position = Vector3(0, 0, cz)
			coil.material_override = reactor_mat
			arm.add_child(coil)
			
	# Ground-Shaking Reinforced Quad-Piston Legs
	_build_reverse_joint_legs(armor_mat, steel_mat, 0.85, 1.3)

func _build_reverse_joint_legs(armor_mat: Material, steel_mat: Material, x_offset: float, leg_height: float) -> void:
	left_leg = Node3D.new()
	left_leg.position = Vector3(-x_offset, 0.85, 0)
	add_child(left_leg)
	
	right_leg = Node3D.new()
	right_leg.position = Vector3(x_offset, 0.85, 0)
	add_child(right_leg)
	
	var leg_nodes = [left_leg, right_leg]
	for idx in range(2):
		var leg = leg_nodes[idx]
		
		# Thigh segment
		var thigh = MeshInstance3D.new()
		var t_box = BoxMesh.new()
		t_box.size = Vector3(0.28, leg_height * 0.55, 0.38)
		thigh.mesh = t_box
		thigh.position = Vector3(0, -leg_height * 0.25, 0.1)
		thigh.rotation_degrees.x = -24.0
		thigh.material_override = armor_mat
		leg.add_child(thigh)
		
		# Knee Joint Cylinder
		var knee = MeshInstance3D.new()
		var k_cyl = CylinderMesh.new()
		k_cyl.top_radius = 0.16
		k_cyl.bottom_radius = 0.16
		k_cyl.height = 0.34
		knee.mesh = k_cyl
		knee.rotation_degrees.z = 90
		knee.position = Vector3(0, -leg_height * 0.48, 0.18)
		knee.material_override = steel_mat
		leg.add_child(knee)
		
		# Shin segment
		var shin = Node3D.new()
		shin.position = knee.position
		leg.add_child(shin)
		if idx == 0: left_shin = shin
		else: right_shin = shin
		
		var s_mesh = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.24, leg_height * 0.55, 0.32)
		s_mesh.mesh = s_box
		s_mesh.position = Vector3(0, -leg_height * 0.25, -0.1)
		s_mesh.rotation_degrees.x = 28.0
		s_mesh.material_override = steel_mat
		shin.add_child(s_mesh)
		
		# Foot pad with hydraulic shock absorber
		var foot = MeshInstance3D.new()
		var f_box = BoxMesh.new()
		f_box.size = Vector3(0.40, 0.16, 0.70)
		foot.mesh = f_box
		foot.position = Vector3(0, -leg_height * 0.52, 0.05)
		foot.material_override = armor_mat
		shin.add_child(foot)
		
		# Hydraulic Piston Tube
		var piston = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.05
		p_cyl.bottom_radius = 0.05
		p_cyl.height = leg_height * 0.5
		piston.mesh = p_cyl
		piston.position = Vector3(0, -leg_height * 0.35, -0.05)
		piston.material_override = steel_mat
		leg.add_child(piston)
		if idx == 0: left_piston = piston
		else: right_piston = piston

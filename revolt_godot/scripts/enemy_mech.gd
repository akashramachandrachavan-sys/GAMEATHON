extends CharacterBody3D

# Rogue War Machine AI for REVOLT 2150 (Godot 4.7)
# Linear Progression:
# 1. "scout": Agile 1.9m reconnaissance droid (nimble, flanking, 3-round rapid blaster)
# 2. "grunt": Medium 4.2m combat enforcer (heavy Gatlings, suppressive fire)
# 3. "bruiser": Heavy 6.8m siege titan (heavy cannons, rocket pods, ground stomps)
# 4. "boss": Colossal 11.5m Flagship Apex Titan OMEGA-ZERO (quad Gatlings, rocket volleys, boss health bar)

@export var bot_type: String = "scout" # "scout", "grunt", "bruiser", "boss"

var max_health: float = 85.0
var health: float = 85.0
var speed: float = 7.2
var fire_rate: float = 0.12
var burst_count: int = 0
var max_burst: int = 3
var burst_pause: float = 0.0
var is_spinning_up: bool = false
var spinup_timer: float = 0.0
var damage_per_shot: float = 6.0
var attack_range: float = 35.0
var preferred_dist: float = 12.0
var team: String = "enemy"

# State & AI
var is_stunned: bool = false
var stun_timer: float = 0.0
var target: Node3D = null
var walk_cycle: float = 0.0
var step_interval: float = 0.38
var step_timer: float = 0.0
var flank_angle_offset: float = 0.0
var strafe_direction: float = 1.0
var strafe_timer: float = 0.0

# Node References
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_piston: Node3D
var right_piston: Node3D
var left_muzzle: Marker3D
var right_muzzle: Marker3D
var left_muzzle_light: OmniLight3D
var right_muzzle_light: OmniLight3D
var left_gatling_barrels: Node3D
var right_gatling_barrels: Node3D
var visor_mesh: MeshInstance3D
var visor_mat: StandardMaterial3D
var searchlight: SpotLight3D
var stun_sparks: CPUParticles3D
var prompt_label: Label3D
var health_label: Label3D
var reactor_mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemies")
	flank_angle_offset = sin(float(get_instance_id() % 13)) * 0.55
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
			# Wave 1: Fast agile 1.9m reconnaissance droid
			max_health = 85.0
			speed = 7.2
			damage_per_shot = 6.0
			scale = Vector3(1.15, 1.15, 1.15)
			attack_range = 34.0
			preferred_dist = 12.0
			max_burst = 3
			step_interval = 0.36
		"grunt":
			# Wave 2: Medium 4.2m combat enforcer
			max_health = 260.0
			speed = 4.8
			damage_per_shot = 9.0
			scale = Vector3(2.3, 2.3, 2.3)
			attack_range = 44.0
			preferred_dist = 17.0
			max_burst = 6
			step_interval = 0.55
		"bruiser":
			# Wave 3: Heavy 6.8m siege titan
			max_health = 520.0
			speed = 3.6
			damage_per_shot = 15.0
			scale = Vector3(3.8, 3.8, 3.8)
			attack_range = 50.0
			preferred_dist = 21.0
			max_burst = 8
			step_interval = 0.72
		"boss":
			# Wave 4: Colossal 11.5m Flagship Apex Titan OMEGA-ZERO
			max_health = 1600.0
			speed = 4.0
			damage_per_shot = 18.0
			scale = Vector3(6.0, 6.0, 6.0)
			attack_range = 65.0
			preferred_dist = 24.0
			max_burst = 12
			step_interval = 0.85
	health = max_health

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	else:
		velocity.y = 0.0

	# Process Stun State
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
		
		# Aim smoothly at target
		if diff.length() > 0.1:
			var target_rot = atan2(diff.x, diff.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 4.0 * delta)
			
		# Smart Obstacle Avoidance Movement
		strafe_timer += delta
		if strafe_timer >= 2.0:
			strafe_timer = 0.0
			strafe_direction = -strafe_direction if randf() > 0.3 else strafe_direction
			
		var move_dir = _calculate_smart_movement(diff, dist, delta)
		var target_vel = move_dir * speed
		velocity.x = lerp(velocity.x, target_vel.x, 6.0 * delta)
		velocity.z = lerp(velocity.z, target_vel.z, 6.0 * delta)
		
		# Hydraulic / Mechanical Walk Cycle
		if move_dir.length() > 0.1:
			walk_cycle += delta * (8.5 if bot_type == "scout" else 6.5)
			var l_rot = sin(walk_cycle) * (20.0 if bot_type == "scout" else 26.0)
			var r_rot = -sin(walk_cycle) * (20.0 if bot_type == "scout" else 26.0)
			left_leg.rotation_degrees.x = l_rot
			right_leg.rotation_degrees.x = r_rot
			
			if left_piston: left_piston.position.y = -0.65 + sin(walk_cycle) * 0.08
			if right_piston: right_piston.position.y = -0.65 - sin(walk_cycle) * 0.08
			torso.position.y = 1.35 + abs(sin(walk_cycle * 2.0)) * 0.09
			
			step_timer += delta
			if step_timer >= step_interval:
				step_timer = 0.0
				AudioManager.play_step()
				if bot_type in ["bruiser", "boss"]:
					_spawn_footstep_shockwave()
		else:
			left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 6.0 * delta)
			right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 6.0 * delta)
			torso.position.y = lerp(torso.position.y, 1.35, 6.0 * delta)
			
		# Telegraphed Attack Sequence
		if burst_pause > 0.0:
			burst_pause -= delta
		elif dist <= attack_range:
			_process_telegraphed_attack(delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
		
	move_and_slide()

# Raycast Feeler Smart Navigation: Never gets stuck on containers or walls
func _calculate_smart_movement(target_diff: Vector3, dist: float, _delta: float) -> Vector3:
	var base_dir = Vector3.ZERO
	var norm_diff = target_diff.normalized()
	var strafe_vec = Vector3(-norm_diff.z, 0, norm_diff.x).normalized()
	
	if dist > preferred_dist + 2.5:
		base_dir = (norm_diff + strafe_vec * flank_angle_offset).normalized()
	elif dist < preferred_dist - 2.5:
		base_dir = (-norm_diff + strafe_vec * flank_angle_offset).normalized()
	else:
		base_dir = (strafe_vec * strafe_direction + norm_diff * 0.2).normalized()
		
	# Raycast Feeler Obstacle Check
	var space_state = get_world_3d().direct_space_state
	var start_pos = global_position + Vector3(0, 1.2 * scale.y, 0)
	var feeler_dist = 4.0 * scale.y
	
	var forward_query = PhysicsRayQueryParameters3D.create(start_pos, start_pos + base_dir * feeler_dist)
	forward_query.exclude = [self]
	var forward_hit = space_state.intersect_ray(forward_query)
	
	if forward_hit and not forward_hit.collider.is_in_group("player") and not forward_hit.collider.is_in_group("allies"):
		# Blocked by obstacle (e.g. cargo container). Test 45-degree alternate paths
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
			# If both blocked, steer sharp 90-degree around corner
			base_dir = base_dir.rotated(Vector3.UP, deg_to_rad(90)).normalized()
			
	return base_dir

func _process_telegraphed_attack(delta: float) -> void:
	# Spin-Up Telegraph: Barrels spin and eye glows before firing
	var spinup_time = 0.25 if bot_type == "scout" else 0.45
	if not is_spinning_up and burst_count == 0:
		is_spinning_up = true
		spinup_timer = spinup_time
		if visor_mat: visor_mat.emission_energy_multiplier = 3.2
		
	if is_spinning_up:
		spinup_timer -= delta
		if left_gatling_barrels: left_gatling_barrels.rotation_degrees.z += 800.0 * delta
		if right_gatling_barrels: right_gatling_barrels.rotation_degrees.z += 800.0 * delta
		if spinup_timer <= 0.0:
			is_spinning_up = false
		return
		
	# Active Burst Firing
	if left_gatling_barrels: left_gatling_barrels.rotation_degrees.z += 1400.0 * delta
	if right_gatling_barrels: right_gatling_barrels.rotation_degrees.z += 1400.0 * delta
	
	burst_count += 1
	var pitch = 1.35 if bot_type == "scout" else (0.85 if bot_type == "grunt" else 0.60)
	AudioManager.play_shoot(pitch)
	
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "enemy"
	bullet.weapon_type = "enemy"
	bullet.damage = damage_per_shot
	
	var is_left = (burst_count % 2 == 0)
	var muzzle = left_muzzle if is_left else right_muzzle
	var muzzle_light = left_muzzle_light if is_left else right_muzzle_light
	var spawn_pos = muzzle.global_position if is_instance_valid(muzzle) else (global_position + Vector3(0, 1.5, 0))
	
	if muzzle_light:
		muzzle_light.light_energy = 5.0
		var lt = create_tween()
		lt.tween_property(muzzle_light, "light_energy", 0.0, 0.08)
	
	# Slight aim spread allows dodging
	var aim_dir = (target.global_position + Vector3(0, 1.1, 0) - spawn_pos).normalized()
	aim_dir += Vector3(randf_range(-0.05, 0.05), randf_range(-0.03, 0.03), randf_range(-0.05, 0.05))
	aim_dir = aim_dir.normalized()
	
	bullet.direction = aim_dir
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	# Heavy Bruiser & Boss: Extra Rocket Volley
	if bot_type in ["bruiser", "boss"] and randf() > 0.40:
		var rocket = Area3D.new()
		rocket.set_script(bullet_script)
		rocket.team = "enemy"
		rocket.weapon_type = "enemy"
		rocket.damage = damage_per_shot * 1.4
		rocket.direction = (aim_dir + Vector3(randf_range(-0.08, 0.08), 0.05, 0)).normalized()
		get_parent().add_child(rocket)
		rocket.global_position = right_muzzle.global_position if is_instance_valid(right_muzzle) else spawn_pos
		
	if burst_count >= max_burst:
		burst_count = 0
		burst_pause = randf_range(1.4, 2.2) if bot_type == "scout" else randf_range(1.8, 2.6)
		if visor_mat: visor_mat.emission_energy_multiplier = 1.4

func _spawn_footstep_shockwave() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var p_dist = global_position.distance_to(player.global_position)
		if p_dist < 32.0 and player.get("camera_shake") != null:
			player.camera_shake = max(player.camera_shake, 0.28 * (1.0 - p_dist / 32.0))
			
	var dust = CPUParticles3D.new()
	dust.emitting = true
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.amount = 16
	dust.lifetime = 0.55
	dust.direction = Vector3.UP
	dust.spread = 90.0
	dust.initial_velocity_min = 2.5
	dust.initial_velocity_max = 6.0
	dust.gravity = Vector3(0, -6.0, 0)
	dust.color = Color(0.35, 0.4, 0.45, 0.6)
	get_parent().add_child(dust)
	dust.global_position = global_position + Vector3(0, 0.1, 0)
	get_tree().create_timer(0.65).timeout.connect(dust.queue_free)

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
		duration *= 0.55
		
	is_stunned = true
	stun_timer = duration
	if stun_sparks: stun_sparks.emitting = true
	if prompt_label: prompt_label.visible = true

func _recover_from_stun() -> void:
	is_stunned = false
	if stun_sparks: stun_sparks.emitting = false
	if prompt_label: prompt_label.visible = false
	if visor_mat:
		var red = Color(1.0, 0.1, 0.1) if bot_type != "scout" else Color(1.0, 0.5, 0.0)
		visor_mat.emission = red
		visor_mat.emission_energy_multiplier = 1.4

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	if is_stunned:
		amount *= 1.45
		
	health = max(0.0, health - amount)
	_update_health_display()
	
	if bot_type == "boss":
		var hud = get_tree().get_first_node_in_group("hud")
		if is_instance_valid(hud) and hud.has_method("update_boss_health"):
			hud.update_boss_health(health, max_health)
			
	if visor_mat:
		visor_mat.emission_energy_multiplier = 4.2
		var t = create_tween()
		t.tween_property(visor_mat, "emission_energy_multiplier", 1.4, 0.08)
		
	# Automatic Stun Vulnerability when HP < 35%
	if health > 0 and (health / max_health) <= 0.35 and not is_stunned:
		apply_emp_stun(4.5)
		
	if health <= 0.0:
		_die()

func _update_health_display() -> void:
	if health_label:
		var pct = int((health / max_health) * 100.0)
		health_label.text = "[ %s: %d%% ]" % [bot_type.to_upper(), pct]
		if pct < 35:
			health_label.modulate = Color(1.0, 0.2, 0.2)

func _die() -> void:
	AudioManager.play_explosion()
	_spawn_massive_cinematic_explosion()
	
	var main_node = get_parent()
	if main_node.has_method("on_enemy_destroyed"):
		main_node.on_enemy_destroyed(bot_type)
		
	queue_free()

func _spawn_massive_cinematic_explosion() -> void:
	# 1. Fireball
	var fireball = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 1.5 * scale.y * 0.5
	f_sph.height = 3.0 * scale.y * 0.5
	fireball.mesh = f_sph
	
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(1.0, 0.6, 0.1)
	f_mat.emission_enabled = true
	f_mat.emission = Color(1.0, 0.7, 0.15)
	f_mat.emission_energy_multiplier = 5.0
	fireball.material_override = f_mat
	
	get_parent().add_child(fireball)
	fireball.global_position = global_position + Vector3(0, 1.5 * scale.y, 0)
	
	var ft = create_tween()
	ft.tween_property(fireball, "scale", Vector3(3.5, 3.5, 3.5), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.parallel().tween_property(f_mat, "albedo_color:a", 0.0, 0.55)
	ft.tween_callback(fireball.queue_free)
	
	# 2. Debris Particles
	var debris = CPUParticles3D.new()
	debris.emitting = true
	debris.one_shot = true
	debris.explosiveness = 1.0
	debris.amount = 40
	debris.lifetime = 1.2
	debris.spread = 180.0
	debris.initial_velocity_min = 12.0
	debris.initial_velocity_max = 26.0
	debris.gravity = Vector3(0, -18.0, 0)
	debris.color = Color(1.0, 0.45, 0.1)
	get_parent().add_child(debris)
	debris.global_position = global_position + Vector3(0, 1.5 * scale.y, 0)
	get_tree().create_timer(2.0).timeout.connect(debris.queue_free)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.9
	cap.height = 2.8
	col.shape = cap
	col.position.y = 1.4
	add_child(col)

func _build_mech_model() -> void:
	torso = Node3D.new()
	torso.position.y = 1.35
	add_child(torso)
	
	# PBR Armor Materials
	var armor_mat = StandardMaterial3D.new()
	armor_mat.albedo_texture = load("res://assets/mech_armor_camo.png")
	armor_mat.metallic = 0.94
	armor_mat.roughness = 0.26
	
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.18, 0.20, 0.24)
	steel_mat.metallic = 0.96
	steel_mat.roughness = 0.20
	
	var hazard_mat = StandardMaterial3D.new()
	hazard_mat.albedo_color = Color(0.9, 0.75, 0.1)
	hazard_mat.metallic = 0.8
	hazard_mat.roughness = 0.3
	
	# Optical Visor Material
	visor_mat = StandardMaterial3D.new()
	var eye_color = Color(1.0, 0.55, 0.0) if bot_type == "scout" else (Color(1.0, 0.35, 0.05) if bot_type == "grunt" else (Color(1.0, 0.05, 0.05) if bot_type == "bruiser" else Color(1.0, 0.0, 0.35)))
	visor_mat.albedo_color = eye_color
	visor_mat.emission_enabled = true
	visor_mat.emission = eye_color
	visor_mat.emission_energy_multiplier = 1.8
	
	# Reactor Core Material
	reactor_mat = StandardMaterial3D.new()
	reactor_mat.albedo_color = eye_color
	reactor_mat.emission_enabled = true
	reactor_mat.emission = eye_color
	reactor_mat.emission_energy_multiplier = 2.8
	
	# 1. Main Pod Cockpit Hull
	var hull = MeshInstance3D.new()
	var hull_box = BoxMesh.new()
	hull_box.size = Vector3(1.4, 0.95, 1.2) if bot_type != "scout" else Vector3(1.0, 0.7, 0.9)
	hull.mesh = hull_box
	hull.material_override = armor_mat
	torso.add_child(hull)
	
	# Brow Armor
	var brow = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.3, 0.3, 0.4)
	brow.mesh = b_box
	brow.position = Vector3(0, 0.35, 0.55)
	brow.material_override = armor_mat
	torso.add_child(brow)
	
	# Horizontal Scanner Visor
	visor_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(1.1, 0.16, 0.2)
	visor_mesh.mesh = v_box
	visor_mesh.position = Vector3(0, 0.15, 0.62)
	visor_mesh.material_override = visor_mat
	torso.add_child(visor_mesh)
	
	# Targeting Spotlight
	searchlight = SpotLight3D.new()
	searchlight.light_color = eye_color
	searchlight.light_energy = 8.0 if bot_type != "boss" else 16.0
	searchlight.spot_range = 40.0
	searchlight.spot_angle = 32.0
	searchlight.position = Vector3(0, 0.2, 0.8)
	searchlight.rotation_degrees.x = -22.0
	torso.add_child(searchlight)
	
	# Rear Reactor Core
	var reactor = MeshInstance3D.new()
	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.2
	r_cyl.bottom_radius = 0.2
	r_cyl.height = 0.6
	reactor.mesh = r_cyl
	reactor.rotation_degrees.z = 90
	reactor.position = Vector3(0, 0.1, -0.65)
	reactor.material_override = reactor_mat
	torso.add_child(reactor)
	
	# Weapons: Dual Blasters / Gatling Barrels
	var left_arm = MeshInstance3D.new()
	var la_box = BoxMesh.new()
	la_box.size = Vector3(0.35, 0.4, 0.8)
	left_arm.mesh = la_box
	left_arm.position = Vector3(-0.95, -0.15, 0.15)
	left_arm.material_override = steel_mat
	torso.add_child(left_arm)
	
	var right_arm = MeshInstance3D.new()
	var ra_box = BoxMesh.new()
	ra_box.size = Vector3(0.35, 0.4, 0.8)
	right_arm.mesh = ra_box
	right_arm.position = Vector3(0.95, -0.15, 0.15)
	right_arm.material_override = steel_mat
	torso.add_child(right_arm)
	
	left_gatling_barrels = Node3D.new()
	left_gatling_barrels.position = Vector3(0, -0.05, 0.5)
	left_arm.add_child(left_gatling_barrels)
	
	right_gatling_barrels = Node3D.new()
	right_gatling_barrels.position = Vector3(0, -0.05, 0.5)
	right_arm.add_child(right_gatling_barrels)
	
	# Barrels
	for g in [left_gatling_barrels, right_gatling_barrels]:
		for b_i in range(4):
			var b_mesh = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.035
			cyl.bottom_radius = 0.035
			cyl.height = 0.75
			b_mesh.mesh = cyl
			b_mesh.rotation_degrees.x = 90
			var ang = b_i * (PI / 2.0)
			b_mesh.position = Vector3(cos(ang) * 0.08, sin(ang) * 0.08, 0.35)
			b_mesh.material_override = steel_mat
			g.add_child(b_mesh)
			
	# Muzzle Markers
	left_muzzle = Marker3D.new()
	left_muzzle.position = Vector3(0, 0, 0.75)
	left_gatling_barrels.add_child(left_muzzle)
	
	right_muzzle = Marker3D.new()
	right_muzzle.position = Vector3(0, 0, 0.75)
	right_gatling_barrels.add_child(right_muzzle)
	
	left_muzzle_light = OmniLight3D.new()
	left_muzzle_light.light_color = eye_color
	left_muzzle_light.light_energy = 0.0
	left_muzzle.add_child(left_muzzle_light)
	
	right_muzzle_light = OmniLight3D.new()
	right_muzzle_light.light_color = eye_color
	right_muzzle_light.light_energy = 0.0
	right_muzzle.add_child(right_muzzle_light)
	
	# Reverse-Joint Bipedal Legs
	left_leg = Node3D.new()
	left_leg.position = Vector3(-0.55, 0.85, 0)
	add_child(left_leg)
	
	right_leg = Node3D.new()
	right_leg.position = Vector3(0.55, 0.85, 0)
	add_child(right_leg)
	
	for leg in [left_leg, right_leg]:
		var thigh = MeshInstance3D.new()
		var t_box = BoxMesh.new()
		t_box.size = Vector3(0.25, 0.65, 0.35)
		thigh.mesh = t_box
		thigh.position = Vector3(0, -0.3, 0.1)
		thigh.rotation_degrees.x = -22.0
		thigh.material_override = armor_mat
		leg.add_child(thigh)
		
		var shin = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.22, 0.65, 0.3)
		shin.mesh = s_box
		shin.position = Vector3(0, -0.7, -0.1)
		shin.rotation_degrees.x = 28.0
		shin.material_override = steel_mat
		leg.add_child(shin)
		
		var foot = MeshInstance3D.new()
		var f_box = BoxMesh.new()
		f_box.size = Vector3(0.35, 0.14, 0.65)
		foot.mesh = f_box
		foot.position = Vector3(0, -1.0, 0.05)
		foot.material_override = armor_mat
		leg.add_child(foot)

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
	
	# Reprogram Prompt Hologram
	prompt_label = Label3D.new()
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.text = "[ HOLD E ] REPROGRAM AI CORE"
	prompt_label.modulate = Color(0.0, 1.0, 0.8)
	prompt_label.font_size = 32
	prompt_label.position = Vector3(0, 1.8, 0)
	prompt_label.visible = false
	add_child(prompt_label)
	
	# Overhead Health Label
	health_label = Label3D.new()
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.text = "[ %s: 100%% ]" % bot_type.to_upper()
	health_label.modulate = Color(0.9, 0.95, 1.0)
	health_label.font_size = 26
	health_label.position = Vector3(0, 1.5, 0)
	add_child(health_label)

extends CharacterBody3D

# Rogue War Machine AI for REVOLT 2150 (Godot 4.7)
# Dynamic combatant: active rhythmic shooting, feeler navigation around containers,
# and spectacular cinematic death explosions with 100% clean object destruction.

@export var bot_type: String = "scout" # "scout", "grunt", "bruiser", "boss"

var max_health: float = 160.0
var health: float = 160.0
var speed: float = 7.0
var damage_per_shot: float = 7.0
var attack_range: float = 48.0
var preferred_dist: float = 14.0
var team: String = "enemy"

# Firing Cycle
var burst_count: int = 0
var max_burst: int = 3
var burst_pause: float = 0.5 # Fast initial engagement
var shot_interval: float = 0.16
var shot_timer: float = 0.0
var is_spinning_up: bool = false
var spinup_timer: float = 0.0

# State & AI
var is_stunned: bool = false
var stun_timer: float = 0.0
var target: Node3D = null
var walk_cycle: float = 0.0
var step_interval: float = 0.36
var step_timer: float = 0.0
var flank_angle_offset: float = 0.0
var strafe_direction: float = 1.0
var strafe_timer: float = 0.0
var is_dying: bool = false

# Node References
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
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
			# Wave 1: Agile reconnaissance runner
			max_health = 160.0
			speed = 7.2
			damage_per_shot = 7.0
			scale = Vector3(1.15, 1.15, 1.15)
			attack_range = 48.0
			preferred_dist = 13.0
			max_burst = 3
			shot_interval = 0.16
			step_interval = 0.35
		"grunt":
			# Wave 2: Medium combat enforcer
			max_health = 380.0
			speed = 5.0
			damage_per_shot = 10.0
			scale = Vector3(2.3, 2.3, 2.3)
			attack_range = 52.0
			preferred_dist = 17.0
			max_burst = 6
			shot_interval = 0.13
			step_interval = 0.52
		"bruiser":
			# Wave 3: Heavy siege titan
			max_health = 750.0
			speed = 3.6
			damage_per_shot = 16.0
			scale = Vector3(3.8, 3.8, 3.8)
			attack_range = 58.0
			preferred_dist = 20.0
			max_burst = 8
			shot_interval = 0.12
			step_interval = 0.70
		"boss":
			# Wave 4: Colossal Flagship Apex Titan OMEGA-ZERO
			max_health = 2200.0
			speed = 4.2
			damage_per_shot = 20.0
			scale = Vector3(6.0, 6.0, 6.0)
			attack_range = 75.0
			preferred_dist = 22.0
			max_burst = 14
			shot_interval = 0.09
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
		
		# Turn to face target
		if diff.length() > 0.1:
			var target_rot = atan2(diff.x, diff.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 5.0 * delta)
			
		# Tactical Strafing Timer
		strafe_timer += delta
		if strafe_timer >= 2.2:
			strafe_timer = 0.0
			strafe_direction = -strafe_direction if randf() > 0.25 else strafe_direction
			
		var move_dir = _calculate_smart_movement(diff, dist, delta)
		var target_vel = move_dir * speed
		velocity.x = lerp(velocity.x, target_vel.x, 6.0 * delta)
		velocity.z = lerp(velocity.z, target_vel.z, 6.0 * delta)
		
		# Mechanical Walk Cycle
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
			
		# Active Combat Shooting
		if burst_pause > 0.0:
			burst_pause -= delta
		elif dist <= attack_range:
			_process_firing_cycle(delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
		
	move_and_slide()

# Feeler Pathfinding: Smoothly routes around cargo containers and walls
func _calculate_smart_movement(target_diff: Vector3, dist: float, _delta: float) -> Vector3:
	var base_dir = Vector3.ZERO
	var norm_diff = target_diff.normalized()
	var strafe_vec = Vector3(-norm_diff.z, 0, norm_diff.x).normalized()
	
	if dist > preferred_dist + 2.5:
		base_dir = (norm_diff + strafe_vec * flank_angle_offset).normalized()
	elif dist < preferred_dist - 2.5:
		base_dir = (-norm_diff + strafe_vec * flank_angle_offset).normalized()
	else:
		base_dir = (strafe_vec * strafe_direction + norm_diff * 0.25).normalized()
		
	# Raycast Feeler Check
	var space_state = get_world_3d().direct_space_state
	var start_pos = global_position + Vector3(0, 1.0 * scale.y, 0)
	var feeler_dist = 4.5 * scale.y
	
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
	# 1. Telegraph Spin-up
	var spinup_time = 0.22 if bot_type == "scout" else 0.40
	if not is_spinning_up and burst_count == 0:
		is_spinning_up = true
		spinup_timer = spinup_time
		if visor_mat: visor_mat.emission_energy_multiplier = 3.5
		
	if is_spinning_up:
		spinup_timer -= delta
		if left_gatling_barrels: left_gatling_barrels.rotation_degrees.z += 900.0 * delta
		if right_gatling_barrels: right_gatling_barrels.rotation_degrees.z += 900.0 * delta
		if spinup_timer <= 0.0:
			is_spinning_up = false
			shot_timer = 0.0 # Fire immediately upon spin-up completion
		return
		
	# 2. Paced Burst Firing (Shot by shot with proper delay)
	if left_gatling_barrels: left_gatling_barrels.rotation_degrees.z += 1500.0 * delta
	if right_gatling_barrels: right_gatling_barrels.rotation_degrees.z += 1500.0 * delta
	
	shot_timer -= delta
	if shot_timer <= 0.0:
		shot_timer = shot_interval
		burst_count += 1
		_fire_single_shot()
		
		if burst_count >= max_burst:
			burst_count = 0
			burst_pause = randf_range(1.2, 1.8) if bot_type == "scout" else randf_range(1.6, 2.4)
			if visor_mat: visor_mat.emission_energy_multiplier = 1.4

func _fire_single_shot() -> void:
	if not is_instance_valid(target): return
	
	var is_left = (burst_count % 2 == 1)
	var forward_dir = -global_transform.basis.z
	var right_dir = global_transform.basis.x
	
	# Spawn bullet safely outside own collision capsule
	var spawn_pos = global_position + Vector3(0, 1.2 * scale.y, 0) + forward_dir * (1.6 * scale.y)
	spawn_pos += (right_dir * -0.7 * scale.y) if is_left else (right_dir * 0.7 * scale.y)
	
	var aim_dir = (target.global_position + Vector3(0, 1.0, 0) - spawn_pos).normalized()
	aim_dir += Vector3(randf_range(-0.04, 0.04), randf_range(-0.03, 0.03), randf_range(-0.04, 0.04))
	aim_dir = aim_dir.normalized()
	
	var pitch = 1.30 if bot_type == "scout" else (0.85 if bot_type == "grunt" else 0.60)
	AudioManager.play_shoot(pitch)
	
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "enemy"
	bullet.weapon_type = "enemy"
	bullet.damage = damage_per_shot
	bullet.direction = aim_dir
	
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_pos
	
	# Muzzle flash
	var m_light = OmniLight3D.new()
	m_light.light_color = Color(1.0, 0.5, 0.1)
	m_light.light_energy = 4.0
	m_light.omni_range = 6.0
	get_tree().current_scene.add_child(m_light)
	m_light.global_position = spawn_pos
	get_tree().create_timer(0.08).timeout.connect(func(): if is_instance_valid(m_light): m_light.queue_free())

func _spawn_footstep_shockwave() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var p_dist = global_position.distance_to(player.global_position)
		if p_dist < 32.0 and player.get("camera_shake") != null:
			player.camera_shake = max(player.camera_shake, 0.28 * (1.0 - p_dist / 32.0))

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
		var red = Color(1.0, 0.1, 0.1) if bot_type != "scout" else Color(1.0, 0.5, 0.0)
		visor_mat.emission = red
		visor_mat.emission_energy_multiplier = 1.4

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
			
	if visor_mat:
		visor_mat.emission_energy_multiplier = 4.0
		var t = get_tree().create_tween()
		t.tween_property(visor_mat, "emission_energy_multiplier", 1.4, 0.08)
		
	# Spark and show hack prompt when damaged below 35% HP (without freezing)
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
	
	# Instantly hide robot and disable collisions
	visible = false
	set_physics_process(false)
	var col = get_node_or_null("CollisionShape3D")
	if col: col.set_deferred("disabled", true)
	
	AudioManager.play_explosion()
	_spawn_massive_cinematic_explosion()
	
	var main_node = get_parent()
	if main_node.has_method("on_enemy_destroyed"):
		main_node.on_enemy_destroyed(bot_type)
		
	queue_free()

func _spawn_massive_cinematic_explosion() -> void:
	var root = get_tree().current_scene
	if not is_instance_valid(root): return
	var spawn_pos = global_position + Vector3(0, 1.2 * scale.y, 0)
	
	# 1. Expanding Fireball (bound to fireball itself, guaranteed deletion)
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
	ft.tween_property(fireball, "scale", Vector3(2.4, 2.4, 2.4), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.parallel().tween_property(f_mat, "albedo_color:a", 0.0, 0.32)
	ft.tween_callback(fireball.queue_free)
	get_tree().create_timer(0.38).timeout.connect(func(): if is_instance_valid(fireball): fireball.queue_free())
	
	# 2. Debris Particles
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

	# 3. Shockwave ground ring
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
	
	# 4. Screen Shake for player
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.get("camera_shake") != null:
		player.camera_shake = max(player.camera_shake, 0.50)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.85
	cap.height = 2.6
	col.shape = cap
	col.position.y = 1.3
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
	left_arm = MeshInstance3D.new()
	var la_box = BoxMesh.new()
	la_box.size = Vector3(0.35, 0.4, 0.8)
	left_arm.mesh = la_box
	left_arm.position = Vector3(-0.95, -0.15, 0.15)
	left_arm.material_override = steel_mat
	torso.add_child(left_arm)
	
	right_arm = MeshInstance3D.new()
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

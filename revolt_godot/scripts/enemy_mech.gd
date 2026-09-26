extends CharacterBody3D

# Giant Rogue War Machine AI (Godot 4.7)
# Inspired by ED-209, Armored Core, and Titanfall Colossi.
# Stands 6.8m to 11.0m tall with rotating Gatling cannons, hydraulic reverse-joint legs,
# ground-shaking footstep stomps, red targeting searchlight, and telegraphed attacks.

@export var bot_type: String = "grunt" # "grunt", "bruiser", "boss"

var max_health: float = 380.0
var health: float = 380.0
var speed: float = 4.2
var fire_rate: float = 0.16
var burst_count: int = 0
var max_burst: int = 7
var burst_pause: float = 0.0
var is_spinning_up: bool = false
var spinup_timer: float = 0.0
var damage_per_shot: float = 10.0 # Balanced with Kai's 200 Shield + 300 HP
var attack_range: float = 42.0
var preferred_dist: float = 18.0
var team: String = "enemy"

# State
var is_stunned: bool = false
var stun_timer: float = 0.0
var target: Node3D = null
var walk_cycle: float = 0.0
var step_interval: float = 0.72
var step_timer: float = 0.0

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
	_configure_stats()
	_build_giant_mech_model()
	_setup_collision()

func _configure_stats() -> void:
	match bot_type:
		"grunt":
			# Giant 6.8m Goliath Enforcer Titan
			max_health = 380.0
			speed = 4.4
			damage_per_shot = 9.0
			scale = Vector3(3.4, 3.4, 3.4)
		"bruiser":
			# Colossal 8.0m Heavy Siege Titan
			max_health = 560.0
			speed = 3.8
			damage_per_shot = 14.0
			scale = Vector3(4.0, 4.0, 4.0)
		"boss":
			# Monolithic 11.0m Titan Colossus OMEGA-ZERO
			max_health = 1300.0
			speed = 4.0
			damage_per_shot = 20.0
			scale = Vector3(5.5, 5.5, 5.5)
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
			visor_mat.emission_energy_multiplier = 3.0 if flicker else 0.3
			
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
			rotation.y = lerp_angle(rotation.y, target_rot, 3.0 * delta)
			
		var move_dir = Vector3.ZERO
		if dist > preferred_dist + 2.5:
			move_dir = diff.normalized()
		elif dist < preferred_dist - 2.5:
			move_dir = -diff.normalized()
		else:
			var strafe = Vector3(-diff.z, 0, diff.x).normalized()
			move_dir = strafe * (1.0 if sin(Time.get_ticks_msec() * 0.0006) > 0 else -1.0) * 0.35
			
		var target_vel = move_dir * speed
		velocity.x = lerp(velocity.x, target_vel.x, 5.0 * delta)
		velocity.z = lerp(velocity.z, target_vel.z, 5.0 * delta)
		
		# Heavy Hydraulic Walk Cycle
		if move_dir.length() > 0.1:
			walk_cycle += delta * 7.5
			var l_rot = sin(walk_cycle) * 24.0
			var r_rot = -sin(walk_cycle) * 24.0
			left_leg.rotation_degrees.x = l_rot
			right_leg.rotation_degrees.x = r_rot
			
			# Piston extension/compression
			if left_piston: left_piston.position.y = -0.65 + sin(walk_cycle) * 0.08
			if right_piston: right_piston.position.y = -0.65 - sin(walk_cycle) * 0.08
			torso.position.y = 1.35 + abs(sin(walk_cycle * 2.0)) * 0.10
			
			step_timer += delta
			if step_timer >= step_interval:
				step_timer = 0.0
				AudioManager.play_step()
				_spawn_footstep_shockwave()
		else:
			left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 6.0 * delta)
			right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 6.0 * delta)
			torso.position.y = lerp(torso.position.y, 1.35, 6.0 * delta)
			
		# Telegraphed Gatling Firing Cycle
		if burst_pause > 0.0:
			burst_pause -= delta
		elif dist <= attack_range:
			_process_telegraphed_attack(delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 4.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 4.0 * delta)
		
	move_and_slide()

func _process_telegraphed_attack(delta: float) -> void:
	# 0.45s Spin-Up Telegraph: Barrels spin, eye brightens before bullets start flying
	if not is_spinning_up and burst_count == 0:
		is_spinning_up = true
		spinup_timer = 0.45
		if visor_mat: visor_mat.emission_energy_multiplier = 3.0
		
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
	AudioManager.play_shoot(0.70 if bot_type != "boss" else 0.50)
	
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "enemy"
	bullet.weapon_type = "enemy"
	bullet.damage = damage_per_shot
	
	var is_left = (burst_count % 2 == 0)
	var muzzle = left_muzzle if is_left else right_muzzle
	var muzzle_light = left_muzzle_light if is_left else right_muzzle_light
	var spawn_pos = muzzle.global_position
	
	if muzzle_light:
		muzzle_light.light_energy = 5.0
		var lt = create_tween()
		lt.tween_property(muzzle_light, "light_energy", 0.0, 0.08)
	
	# Slight spread allows Kai to dodge and sprint for cover
	var aim_dir = (target.global_position + Vector3(0, 1.2, 0) - spawn_pos).normalized()
	aim_dir += Vector3(randf_range(-0.06, 0.06), randf_range(-0.04, 0.04), randf_range(-0.06, 0.06))
	aim_dir = aim_dir.normalized()
	
	bullet.direction = aim_dir
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	# Boss extra rocket volley
	if bot_type == "boss" and randf() > 0.45:
		var b2 = Area3D.new()
		b2.set_script(bullet_script)
		b2.team = "enemy"
		b2.weapon_type = "enemy"
		b2.damage = damage_per_shot * 1.5
		b2.direction = (aim_dir + Vector3(randf_range(-0.08, 0.08), 0.06, 0)).normalized()
		get_parent().add_child(b2)
		b2.global_position = right_muzzle.global_position
		
	if burst_count >= max_burst:
		burst_count = 0
		burst_pause = randf_range(1.8, 2.6) # Tactical window for Kai to counter-attack!
		if visor_mat: visor_mat.emission_energy_multiplier = 1.4

func _spawn_footstep_shockwave() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var p_dist = global_position.distance_to(player.global_position)
		if p_dist < 30.0 and player.get("camera_shake") != null:
			player.camera_shake = max(player.camera_shake, 0.24 * (1.0 - p_dist / 30.0))
			
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
		visor_mat.emission = Color(1.0, 0.1, 0.1)
		visor_mat.emission_energy_multiplier = 1.4

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	if is_stunned:
		amount *= 1.45
		
	health = max(0.0, health - amount)
	_update_health_display()
	
	if visor_mat:
		visor_mat.emission_energy_multiplier = 4.2
		var t = create_tween()
		t.tween_property(visor_mat, "emission_energy_multiplier", 1.4, 0.08)
		
	if health <= 0.0:
		_die()

func _update_health_display() -> void:
	if health_label:
		var pct = int((health / max_health) * 100.0)
		health_label.text = "[ %s TITAN: %d%% ]" % [bot_type.to_upper(), pct]
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
	# 1. Blinding White-Hot Expanding Fireball Dome
	var fireball = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 2.4
	f_sph.height = 4.8
	fireball.mesh = f_sph
	
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(1.0, 0.6, 0.1)
	f_mat.emission_enabled = true
	f_mat.emission = Color(1.0, 0.7, 0.15)
	f_mat.emission_energy_multiplier = 5.0
	fireball.material_override = f_mat
	
	get_parent().add_child(fireball)
	fireball.global_position = global_position + Vector3(0, 3.5, 0)
	
	var ft = create_tween()
	ft.tween_property(fireball, "scale", Vector3(4.5, 4.5, 4.5), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.parallel().tween_property(f_mat, "albedo_color:a", 0.0, 0.55)
	ft.tween_callback(fireball.queue_free)
	
	# 2. 60+ Flaming Shrapnel & Debris Chunks with Gravity
	var debris = CPUParticles3D.new()
	debris.emitting = true
	debris.one_shot = true
	debris.explosiveness = 1.0
	debris.amount = 60
	debris.lifetime = 1.4
	debris.spread = 180.0
	debris.initial_velocity_min = 14.0
	debris.initial_velocity_max = 32.0
	debris.gravity = Vector3(0, -20.0, 0)
	debris.color = Color(1.0, 0.45, 0.1)
	get_parent().add_child(debris)
	debris.global_position = global_position + Vector3(0, 3.0, 0)
	
	# 3. Rising Dark Industrial Smoke Mushroom Plume
	var smoke = CPUParticles3D.new()
	smoke.emitting = true
	smoke.one_shot = true
	smoke.amount = 45
	smoke.lifetime = 2.2
	smoke.spread = 65.0
	smoke.direction = Vector3.UP
	smoke.initial_velocity_min = 6.0
	smoke.initial_velocity_max = 14.0
	smoke.gravity = Vector3(0, 2.0, 0)
	smoke.color = Color(0.12, 0.13, 0.16, 0.9)
	get_parent().add_child(smoke)
	smoke.global_position = global_position + Vector3(0, 3.0, 0)
	
	# 4. Shockwave Blast Ring along ground
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.6
	ring.mesh = torus
	ring.rotation_degrees.x = 90
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(1.0, 0.85, 0.3)
	r_mat.emission_enabled = true
	r_mat.emission = Color(1.0, 0.85, 0.3)
	r_mat.emission_energy_multiplier = 4.0
	ring.material_override = r_mat
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector3(0, 0.2, 0)
	
	var rt = create_tween()
	rt.tween_property(ring, "scale", Vector3(18.0, 1.0, 18.0), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.parallel().tween_property(r_mat, "albedo_color:a", 0.0, 0.55)
	rt.tween_callback(ring.queue_free)
	
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.get("camera_shake") != null:
		player.camera_shake = 0.8
		
	get_tree().create_timer(2.5).timeout.connect(debris.queue_free)
	get_tree().create_timer(2.5).timeout.connect(smoke.queue_free)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 1.1
	cap.height = 3.2
	col.shape = cap
	col.position.y = 1.6
	add_child(col)

func _build_giant_mech_model() -> void:
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
	
	var piston_mat = StandardMaterial3D.new()
	piston_mat.albedo_color = Color(0.85, 0.72, 0.3)
	piston_mat.metallic = 0.98
	piston_mat.roughness = 0.12
	
	var hazard_mat = StandardMaterial3D.new()
	hazard_mat.albedo_color = Color(0.9, 0.75, 0.1)
	hazard_mat.metallic = 0.8
	hazard_mat.roughness = 0.3
	
	# Crimson Optical Visor
	visor_mat = StandardMaterial3D.new()
	var red = Color(1.0, 0.1, 0.1) if bot_type != "boss" else Color(1.0, 0.0, 0.28)
	visor_mat.albedo_color = red
	visor_mat.emission_enabled = true
	visor_mat.emission = red
	visor_mat.emission_energy_multiplier = 1.6
	
	# Glowing Orange Nuclear Reactor Core
	reactor_mat = StandardMaterial3D.new()
	var orange = Color(1.0, 0.5, 0.05)
	reactor_mat.albedo_color = orange
	reactor_mat.emission_enabled = true
	reactor_mat.emission = orange
	reactor_mat.emission_energy_multiplier = 2.8
	
	# 1. Main Armored Pod Cockpit
	var hull = MeshInstance3D.new()
	var hull_box = BoxMesh.new()
	hull_box.size = Vector3(1.6, 1.1, 1.4)
	hull.mesh = hull_box
	hull.material_override = armor_mat
	torso.add_child(hull)
	
	# Brow Armor Shield
	var brow = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.5, 0.35, 0.45)
	brow.mesh = b_box
	brow.position = Vector3(0, 0.42, 0.65)
	brow.material_override = armor_mat
	torso.add_child(brow)
	
	# Horizontal Scanner Visor
	visor_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(1.25, 0.16, 0.2)
	visor_mesh.mesh = v_box
	visor_mesh.position = Vector3(0, 0.18, 0.72)
	visor_mesh.material_override = visor_mat
	torso.add_child(visor_mesh)
	
	# Red Volumetric Targeting Searchlight (Angled downward onto concrete)
	searchlight = SpotLight3D.new()
	searchlight.light_color = red
	searchlight.light_energy = 8.0
	searchlight.spot_range = 45.0
	searchlight.spot_angle = 32.0
	searchlight.position = Vector3(0, 0.25, 0.9)
	searchlight.rotation_degrees.x = -24.0
	torso.add_child(searchlight)
	
	# Rear Reactor Core Cylinder
	var reactor = MeshInstance3D.new()
	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.22
	r_cyl.bottom_radius = 0.22
	r_cyl.height = 0.7
	reactor.mesh = r_cyl
	reactor.rotation_degrees.z = 90
	reactor.position = Vector3(0, 0.1, -0.75)
	reactor.material_override = reactor_mat
	torso.add_child(reactor)
	
	# Hazard Stripe Decals on Shoulders
	for side in [-1, 1]:
		var hz = MeshInstance3D.new()
		var hz_box = BoxMesh.new()
		hz_box.size = Vector3(0.35, 0.08, 0.5)
		hz.mesh = hz_box
		hz.position = Vector3(side * 0.9, 0.55, 0.1)
		hz.material_override = hazard_mat
		torso.add_child(hz)
	
	# Exhaust Stacks with Continuous Dark Smoke Particles
	for x_off in [-0.5, 0.5]:
		var stack = MeshInstance3D.new()
		var s_cyl = CylinderMesh.new()
		s_cyl.top_radius = 0.1
		s_cyl.bottom_radius = 0.12
		s_cyl.height = 0.6
		stack.mesh = s_cyl
		stack.position = Vector3(x_off, 0.7, -0.5)
		stack.material_override = steel_mat
		torso.add_child(stack)
		
		var smoke = CPUParticles3D.new()
		smoke.emitting = true
		smoke.amount = 14
		smoke.lifetime = 1.0
		smoke.spread = 25.0
		smoke.direction = Vector3.UP
		smoke.initial_velocity_min = 2.0
		smoke.initial_velocity_max = 4.5
		smoke.gravity = Vector3(0, 1.0, 0)
		smoke.color = Color(0.15, 0.16, 0.18, 0.65)
		smoke.position = Vector3(x_off, 1.0, -0.5)
		torso.add_child(smoke)
		
	# 2. Dual Gatling Sponsons
	var left_arm = MeshInstance3D.new()
	var la_box = BoxMesh.new()
	la_box.size = Vector3(0.45, 0.5, 0.9)
	left_arm.mesh = la_box
	left_arm.position = Vector3(-1.15, 0.05, 0.2)
	left_arm.material_override = armor_mat
	torso.add_child(left_arm)
	
	left_gatling_barrels = Node3D.new()
	left_gatling_barrels.position = Vector3(-1.15, 0.05, 0.8)
	torso.add_child(left_gatling_barrels)
	
	for i in range(6):
		var angle = (float(i) / 6.0) * TAU
		var b = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.04
		b_cyl.bottom_radius = 0.04
		b_cyl.height = 1.0
		b.mesh = b_cyl
		b.rotation_degrees.x = 90
		b.position = Vector3(cos(angle) * 0.12, sin(angle) * 0.12, 0.3)
		b.material_override = steel_mat
		left_gatling_barrels.add_child(b)
		
	left_muzzle = Marker3D.new()
	left_muzzle.position = Vector3(-1.15, 0.05, 1.45)
	torso.add_child(left_muzzle)
	
	left_muzzle_light = OmniLight3D.new()
	left_muzzle_light.light_color = Color(1.0, 0.5, 0.1)
	left_muzzle_light.light_energy = 0.0
	left_muzzle_light.omni_range = 8.0
	left_muzzle.add_child(left_muzzle_light)
	
	var right_arm = MeshInstance3D.new()
	right_arm.mesh = la_box
	right_arm.position = Vector3(1.15, 0.05, 0.2)
	right_arm.material_override = armor_mat
	torso.add_child(right_arm)
	
	right_gatling_barrels = Node3D.new()
	right_gatling_barrels.position = Vector3(1.15, 0.05, 0.8)
	torso.add_child(right_gatling_barrels)
	
	for i in range(6):
		var angle = (float(i) / 6.0) * TAU
		var b = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.04
		b_cyl.bottom_radius = 0.04
		b_cyl.height = 1.0
		b.mesh = b_cyl
		b.rotation_degrees.x = 90
		b.position = Vector3(cos(angle) * 0.12, sin(angle) * 0.12, 0.3)
		b.material_override = steel_mat
		right_gatling_barrels.add_child(b)
		
	right_muzzle = Marker3D.new()
	right_muzzle.position = Vector3(1.15, 0.05, 1.45)
	torso.add_child(right_muzzle)
	
	right_muzzle_light = OmniLight3D.new()
	right_muzzle_light.light_color = Color(1.0, 0.5, 0.1)
	right_muzzle_light.light_energy = 0.0
	right_muzzle_light.omni_range = 8.0
	right_muzzle.add_child(right_muzzle_light)
	
	# Shoulder Missile Pod Racks (4 warheads)
	var pod_l = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.65, 0.45, 0.8)
	pod_l.mesh = p_box
	pod_l.position = Vector3(-0.95, 0.75, 0.1)
	pod_l.material_override = steel_mat
	torso.add_child(pod_l)
	
	var pod_r = MeshInstance3D.new()
	pod_r.mesh = p_box
	pod_r.position = Vector3(0.95, 0.75, 0.1)
	pod_r.material_override = steel_mat
	torso.add_child(pod_r)
	
	# Boss Crown
	if bot_type == "boss":
		var crown = MeshInstance3D.new()
		var cr_box = BoxMesh.new()
		cr_box.size = Vector3(2.4, 0.55, 0.85)
		crown.mesh = cr_box
		crown.position = Vector3(0, 0.95, 0)
		crown.material_override = armor_mat
		torso.add_child(crown)

	# 3. Massive Reverse-Joint Hydraulic Legs
	var leg_left_data = _create_heavy_leg(Vector3(-0.65, 1.0, 0), armor_mat, steel_mat, piston_mat)
	left_leg = leg_left_data[0]
	left_piston = leg_left_data[1]
	add_child(left_leg)
	
	var leg_right_data = _create_heavy_leg(Vector3(0.65, 1.0, 0), armor_mat, steel_mat, piston_mat)
	right_leg = leg_right_data[0]
	right_piston = leg_right_data[1]
	add_child(right_leg)
	
	# EMP Stun Sparks
	stun_sparks = CPUParticles3D.new()
	stun_sparks.emitting = false
	stun_sparks.amount = 35
	stun_sparks.lifetime = 0.4
	stun_sparks.spread = 180.0
	stun_sparks.initial_velocity_min = 4.0
	stun_sparks.initial_velocity_max = 9.0
	stun_sparks.gravity = Vector3(0, 2.5, 0)
	stun_sparks.color = Color(0.0, 0.95, 1.0)
	torso.add_child(stun_sparks)
	
	# 3D In-World Health & Type Label
	health_label = Label3D.new()
	health_label.text = "[ %s TITAN: 100%% ]" % bot_type.to_upper()
	health_label.modulate = Color(1.0, 0.75, 0.2)
	health_label.outline_modulate = Color(0.1, 0.05, 0.0)
	health_label.outline_size = 8
	health_label.font_size = 38
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.position = Vector3(0, 3.8, 0)
	add_child(health_label)
	
	# 3D Reprogram Prompt
	prompt_label = Label3D.new()
	prompt_label.text = "⚡ HOLD [E] // REPROGRAM SQUAD ALLIANCE"
	prompt_label.modulate = Color(0.0, 1.0, 0.6)
	prompt_label.outline_modulate = Color(0.0, 0.2, 0.1)
	prompt_label.outline_size = 8
	prompt_label.font_size = 36
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.position = Vector3(0, 4.4, 0)
	prompt_label.visible = false
	add_child(prompt_label)

func _create_heavy_leg(pos: Vector3, armor_mat: Material, steel_mat: Material, piston_mat: Material) -> Array:
	var leg_root = Node3D.new()
	leg_root.position = pos
	
	# Hip Joint Ball
	var hip = MeshInstance3D.new()
	var hip_sph = SphereMesh.new()
	hip_sph.radius = 0.28
	hip_sph.height = 0.56
	hip.mesh = hip_sph
	hip.material_override = steel_mat
	leg_root.add_child(hip)
	
	# Upper Thigh Armor
	var thigh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.38, 0.65, 0.42)
	thigh.mesh = t_box
	thigh.position = Vector3(0, -0.35, 0.05)
	thigh.material_override = armor_mat
	leg_root.add_child(thigh)
	
	# Hydraulic Reverse Knee Piston
	var piston = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.09
	p_cyl.bottom_radius = 0.09
	p_cyl.height = 0.55
	piston.mesh = p_cyl
	piston.position = Vector3(0, -0.65, -0.15)
	piston.material_override = piston_mat
	leg_root.add_child(piston)
	
	# Lower Shin Armor
	var shin = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.34, 0.65, 0.38)
	shin.mesh = s_box
	shin.position = Vector3(0, -0.95, -0.05)
	shin.material_override = armor_mat
	leg_root.add_child(shin)
	
	# 3-Toed Steel Foot Clad
	var foot = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.55, 0.22, 0.85)
	foot.mesh = f_box
	foot.position = Vector3(0, -1.25, 0.15)
	foot.material_override = steel_mat
	leg_root.add_child(foot)
	
	return [leg_root, piston]

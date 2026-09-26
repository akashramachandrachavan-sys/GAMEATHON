extends CharacterBody3D

# Giant Allied Reprogrammed Titan (Godot 4.7)
# Stands 6.8m tall, protects Kai, flanks rogue titans, and unleashes heavy Gatling fire.

var max_health: float = 400.0
var health: float = 400.0
var speed: float = 5.2
var fire_rate: float = 0.16
var burst_count: int = 0
var max_burst: int = 8
var burst_pause: float = 0.0
var damage_per_shot: float = 16.0
var team: String = "ally"

var target: Node3D = null
var walk_cycle: float = 0.0
var step_interval: float = 0.7
var step_timer: float = 0.0
var formation_offset: Vector3 = Vector3.ZERO

# Node references
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_muzzle: Marker3D
var right_muzzle: Marker3D
var left_gatling_barrels: Node3D
var right_gatling_barrels: Node3D
var visor_mat: StandardMaterial3D
var health_label: Label3D

func _ready() -> void:
	add_to_group("allies")
	scale = Vector3(3.4, 3.4, 3.4) # Matches towering enemy titan scale!
	_build_giant_ally_mesh()
	_setup_collision()
	
	# Flank offset around Kai
	var angle = randf() * TAU
	formation_offset = Vector3(cos(angle), 0, sin(angle)) * randf_range(6.0, 9.0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	else:
		velocity.y = 0.0

	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		move_and_slide()
		return
		
	# Target acquisition: prioritize rogue enemy titans
	_find_enemy_target()
	
	# Movement behavior: if enemy in sight, maintain combat distance; else follow Kai
	var destination = player.global_position + formation_offset
	if is_instance_valid(target):
		var e_pos = target.global_position
		var diff_to_enemy = e_pos - global_position
		diff_to_enemy.y = 0
		if diff_to_enemy.length() < 14.0:
			destination = global_position - diff_to_enemy.normalized() * 4.0
		elif diff_to_enemy.length() > 22.0:
			destination = e_pos - diff_to_enemy.normalized() * 16.0
			
	var diff = destination - global_position
	diff.y = 0
	var dist = diff.length()
	
	var move_dir = Vector3.ZERO
	if dist > 2.0:
		move_dir = diff.normalized()
		var target_vel = move_dir * speed
		velocity.x = lerp(velocity.x, target_vel.x, 6.0 * delta)
		velocity.z = lerp(velocity.z, target_vel.z, 6.0 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 6.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 6.0 * delta)

	# Face towards enemy if in combat, otherwise face movement direction
	if is_instance_valid(target):
		var e_diff = target.global_position - global_position
		e_diff.y = 0
		if e_diff.length() > 0.1:
			var target_rot = atan2(e_diff.x, e_diff.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 5.0 * delta)
	elif move_dir.length() > 0.1:
		var target_rot = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 5.0 * delta)

	# Heavy Hydraulic Walk Animation
	if velocity.length() > 0.4:
		walk_cycle += delta * 7.5
		left_leg.rotation_degrees.x = sin(walk_cycle) * 22.0
		right_leg.rotation_degrees.x = -sin(walk_cycle) * 22.0
		torso.position.y = 1.35 + abs(sin(walk_cycle * 2.0)) * 0.08
		
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			AudioManager.play_step()
	else:
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 6.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 6.0 * delta)
		torso.position.y = lerp(torso.position.y, 1.35, 6.0 * delta)

	move_and_slide()
	
	# Rapid Gatling Fire at rogue robots
	if burst_pause > 0.0:
		burst_pause -= delta
	elif is_instance_valid(target):
		var e_dist = global_position.distance_to(target.global_position)
		if e_dist <= 38.0:
			_process_burst_firing(delta)

func _process_burst_firing(delta: float) -> void:
	if left_gatling_barrels: left_gatling_barrels.rotation_degrees.z += 1200.0 * delta
	if right_gatling_barrels: right_gatling_barrels.rotation_degrees.z += 1200.0 * delta
	
	burst_count += 1
	AudioManager.play_shoot(0.85)
	
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "ally"
	bullet.damage = damage_per_shot
	
	var muzzle = left_muzzle if (burst_count % 2 == 0) else right_muzzle
	var spawn_pos = muzzle.global_position
	var aim_dir = (target.global_position + Vector3(0, 1.5, 0) - spawn_pos).normalized()
	aim_dir += Vector3(randf_range(-0.04, 0.04), randf_range(-0.02, 0.02), randf_range(-0.04, 0.04))
	
	bullet.direction = aim_dir.normalized()
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	if burst_count >= max_burst:
		burst_count = 0
		burst_pause = randf_range(1.4, 2.0)

func _find_enemy_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node3D = null
	var min_d = 999.0
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_stunned"):
			var d = global_position.distance_to(e.global_position)
			if d < min_d:
				min_d = d
				closest = e
	target = closest

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	health = max(0.0, health - amount)
	if health_label:
		var pct = int((health / max_health) * 100.0)
		health_label.text = "[ ALLIED TITAN: %d%% ]" % pct
		
	if health <= 0.0:
		AudioManager.play_explosion()
		var main_node = get_parent()
		if main_node.has_method("on_ally_destroyed"):
			main_node.on_ally_destroyed()
		queue_free()

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 1.1
	cap.height = 3.2
	col.shape = cap
	col.position.y = 1.6
	add_child(col)

func _build_giant_ally_mesh() -> void:
	torso = Node3D.new()
	torso.position.y = 1.35
	add_child(torso)
	
	# Cyan/Steel Resistance Alloy Materials
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.20, 0.28, 0.35)
	body_mat.metallic = 0.94
	body_mat.roughness = 0.28
	
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.18, 0.20, 0.24)
	steel_mat.metallic = 0.96
	steel_mat.roughness = 0.20
	
	var piston_mat = StandardMaterial3D.new()
	piston_mat.albedo_color = Color(0.85, 0.72, 0.3)
	piston_mat.metallic = 0.98
	piston_mat.roughness = 0.12
	
	# Friendly Emerald / Cyan Visor
	visor_mat = StandardMaterial3D.new()
	var glow = Color(0.0, 1.0, 0.65)
	visor_mat.albedo_color = glow
	visor_mat.emission_enabled = true
	visor_mat.emission = glow
	visor_mat.emission_energy_multiplier = 2.4
	
	# 1. Main Cockpit Hull
	var hull = MeshInstance3D.new()
	var hull_box = BoxMesh.new()
	hull_box.size = Vector3(1.6, 1.1, 1.4)
	hull.mesh = hull_box
	hull.material_override = body_mat
	torso.add_child(hull)
	
	# Horizontal Scanner Visor
	var visor_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(1.25, 0.16, 0.2)
	visor_mesh.mesh = v_box
	visor_mesh.position = Vector3(0, 0.18, 0.72)
	visor_mesh.material_override = visor_mat
	torso.add_child(visor_mesh)
	
	# Friendly Green Searchlight
	var searchlight = SpotLight3D.new()
	searchlight.light_color = glow
	searchlight.light_energy = 4.0
	searchlight.spot_range = 32.0
	searchlight.spot_angle = 24.0
	searchlight.position = Vector3(0, 0.18, 0.8)
	searchlight.rotation_degrees.x = -15.0
	torso.add_child(searchlight)
	
	# 2. Dual Gatling Sponsons
	var left_arm = MeshInstance3D.new()
	var la_box = BoxMesh.new()
	la_box.size = Vector3(0.45, 0.5, 0.9)
	left_arm.mesh = la_box
	left_arm.position = Vector3(-1.15, 0.05, 0.2)
	left_arm.material_override = body_mat
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
	
	var right_arm = MeshInstance3D.new()
	right_arm.mesh = la_box
	right_arm.position = Vector3(1.15, 0.05, 0.2)
	right_arm.material_override = body_mat
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

	# 3. Massive Reverse-Joint Legs
	left_leg = _create_heavy_leg(Vector3(-0.65, 1.0, 0), body_mat, steel_mat, piston_mat)
	right_leg = _create_heavy_leg(Vector3(0.65, 1.0, 0), body_mat, steel_mat, piston_mat)
	add_child(left_leg)
	add_child(right_leg)
	
	# 3D Alliance Billboard Tag
	health_label = Label3D.new()
	health_label.text = "[ ALLIED TITAN // DEFENDING KAI ]"
	health_label.modulate = glow
	health_label.outline_modulate = Color(0.0, 0.2, 0.1)
	health_label.outline_size = 6
	health_label.font_size = 28
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.position = Vector3(0, 3.2, 0)
	add_child(health_label)

func _create_heavy_leg(pos: Vector3, armor_mat: Material, steel_mat: Material, piston_mat: Material) -> Node3D:
	var leg_root = Node3D.new()
	leg_root.position = pos
	
	var hip = MeshInstance3D.new()
	var hip_sph = SphereMesh.new()
	hip_sph.radius = 0.28
	hip_sph.height = 0.56
	hip.mesh = hip_sph
	hip.material_override = steel_mat
	leg_root.add_child(hip)
	
	var thigh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.38, 0.65, 0.42)
	thigh.mesh = t_box
	thigh.position = Vector3(0, -0.35, 0.05)
	thigh.material_override = armor_mat
	leg_root.add_child(thigh)
	
	var piston = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.09
	p_cyl.bottom_radius = 0.09
	p_cyl.height = 0.55
	piston.mesh = p_cyl
	piston.position = Vector3(0, -0.65, -0.15)
	piston.material_override = piston_mat
	leg_root.add_child(piston)
	
	var shin = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.34, 0.65, 0.38)
	shin.mesh = s_box
	shin.position = Vector3(0, -0.95, -0.05)
	shin.material_override = armor_mat
	leg_root.add_child(shin)
	
	var foot = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.55, 0.22, 0.85)
	foot.mesh = f_box
	foot.position = Vector3(0, -1.25, 0.15)
	foot.material_override = steel_mat
	leg_root.add_child(foot)
	
	return leg_root

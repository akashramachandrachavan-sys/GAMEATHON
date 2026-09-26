extends CharacterBody3D

# Malfunctioning Rogue Battle Mech AI (Godot 4.7 PBR)
# Supports Grunt, Bruiser, and Boss "Omega-Zero" configurations.
# Features PBR armored chassis, floating 3D health bar, EMP stun state, and hacking prompt.

@export var bot_type: String = "grunt" # "grunt", "bruiser", "boss"

var max_health: float = 50.0
var health: float = 50.0
var speed: float = 5.5
var fire_rate: float = 1.4
var damage_per_shot: float = 10.0
var attack_range: float = 20.0
var preferred_dist: float = 8.0
var team: String = "enemy"

# State
var is_stunned: bool = false
var stun_timer: float = 0.0
var fire_timer: float = 0.0
var target: Node3D = null

# Visual & Node References
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_muzzle: Marker3D
var right_muzzle: Marker3D
var visor_mesh: MeshInstance3D
var visor_mat: StandardMaterial3D
var stun_sparks: CPUParticles3D
var prompt_label: Label3D
var health_label: Label3D
var walk_cycle: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_configure_stats()
	_build_mech_mesh()
	_setup_collision()
	fire_timer = randf_range(0.3, fire_rate)

func _configure_stats() -> void:
	match bot_type:
		"grunt":
			max_health = 45.0
			speed = 5.8
			fire_rate = 1.2
			damage_per_shot = 8.0
			scale = Vector3(0.95, 0.95, 0.95)
		"bruiser":
			max_health = 110.0
			speed = 3.8
			fire_rate = 0.8
			damage_per_shot = 14.0
			scale = Vector3(1.35, 1.35, 1.35)
		"boss":
			max_health = 450.0
			speed = 4.2
			fire_rate = 0.5
			damage_per_shot = 20.0
			scale = Vector3(2.2, 2.2, 2.2)
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
		
		# Visor malfunction flicker
		if visor_mat:
			var flicker = sin(Time.get_ticks_msec() * 0.02) > 0.0
			visor_mat.emission_energy_multiplier = 2.0 if flicker else 0.2
			
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
		
		if diff.length() > 0.1:
			var target_rot = atan2(diff.x, diff.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 4.0 * delta)
			
		var move_dir = Vector3.ZERO
		if dist > preferred_dist + 1.5:
			move_dir = diff.normalized()
		elif dist < preferred_dist - 1.5:
			move_dir = -diff.normalized()
		else:
			var strafe = Vector3(-diff.z, 0, diff.x).normalized()
			move_dir = strafe * (1.0 if sin(Time.get_ticks_msec() * 0.001) > 0 else -1.0) * 0.45
			
		var target_vel = move_dir * speed
		velocity.x = lerp(velocity.x, target_vel.x, 8.0 * delta)
		velocity.z = lerp(velocity.z, target_vel.z, 8.0 * delta)
		
		if move_dir.length() > 0.1:
			walk_cycle += delta * 12.0
			left_leg.rotation_degrees.x = sin(walk_cycle) * 22.0
			right_leg.rotation_degrees.x = -sin(walk_cycle) * 22.0
		else:
			left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 8.0 * delta)
			right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 8.0 * delta)
			
		fire_timer -= delta
		if fire_timer <= 0.0 and dist <= attack_range:
			_shoot()
	else:
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
		
	move_and_slide()

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

func _shoot() -> void:
	fire_timer = fire_rate
	AudioManager.play_shoot(0.85 if bot_type != "boss" else 0.65)
	
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "enemy"
	bullet.damage = damage_per_shot
	
	var muzzle = left_muzzle if randf() > 0.5 else right_muzzle
	var spawn_pos = muzzle.global_position
	
	var aim_dir = (target.global_position + Vector3(0, 1.2, 0) - spawn_pos).normalized()
	aim_dir += Vector3(randf_range(-0.05, 0.05), randf_range(-0.03, 0.03), randf_range(-0.05, 0.05))
	aim_dir = aim_dir.normalized()
	
	bullet.direction = aim_dir
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	if bot_type == "boss" and randf() > 0.35:
		var b2 = Area3D.new()
		b2.set_script(bullet_script)
		b2.team = "enemy"
		b2.damage = damage_per_shot
		b2.direction = (aim_dir + Vector3(0.06, 0, 0)).normalized()
		get_parent().add_child(b2)
		b2.global_position = right_muzzle.global_position

func apply_emp_stun(duration: float) -> void:
	if bot_type == "boss":
		duration *= 0.5
		
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
		visor_mat.emission_energy_multiplier = 1.3

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	if is_stunned:
		amount *= 1.4
		
	health = max(0.0, health - amount)
	_update_health_display()
	
	# Brief damage flash
	if visor_mat:
		visor_mat.emission_energy_multiplier = 3.0
		var t = create_tween()
		t.tween_property(visor_mat, "emission_energy_multiplier", 1.3, 0.1)
		
	if health <= 0.0:
		_die()

func _update_health_display() -> void:
	if health_label:
		var pct = int((health / max_health) * 100.0)
		health_label.text = "[ %s: %d%% ]" % [bot_type.to_upper(), pct]
		if pct < 35:
			health_label.modulate = Color(1.0, 0.3, 0.3)

func _die() -> void:
	AudioManager.play_explosion()
	_spawn_destruction_debris()
	
	var main_node = get_parent()
	if main_node.has_method("on_enemy_destroyed"):
		main_node.on_enemy_destroyed(bot_type)
		
	queue_free()

func _spawn_destruction_debris() -> void:
	var p = CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 25
	p.lifetime = 0.7
	p.spread = 180.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.gravity = Vector3(0, -9.8, 0)
	p.color = Color(1.0, 0.4, 0.05)
	get_parent().add_child(p)
	p.global_position = global_position + Vector3(0, 1.2, 0)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.8
	cap.height = 2.4
	col.shape = cap
	col.position.y = 1.2
	add_child(col)

func _build_mech_mesh() -> void:
	torso = Node3D.new()
	torso.position.y = 1.35
	add_child(torso)
	
	# PBR Armor Plate Material (Crimson tinted military steel)
	var armor_mat = StandardMaterial3D.new()
	var armor_tex = load("res://assets/armor_albedo.png")
	var armor_norm = load("res://assets/armor_normal.png")
	armor_mat.albedo_texture = armor_tex
	armor_mat.normal_enabled = true
	armor_mat.normal_texture = armor_norm
	armor_mat.albedo_color = Color(0.85, 0.55, 0.55) if bot_type != "boss" else Color(0.25, 0.15, 0.15)
	armor_mat.metallic = 0.9
	armor_mat.roughness = 0.32
	
	# Dark Steel Framework Material
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.18, 0.2, 0.24)
	steel_mat.metallic = 0.95
	steel_mat.roughness = 0.25
	
	# Menacing Red Optical Scanner Visor
	visor_mat = StandardMaterial3D.new()
	var red = Color(1.0, 0.1, 0.1)
	visor_mat.albedo_color = red
	visor_mat.emission_enabled = true
	visor_mat.emission = red
	visor_mat.emission_energy_multiplier = 1.3 # Crisp red bar, not blown-out
	
	# Main Armored Chassis
	var hull = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.3, 0.9, 1.2)
	hull.mesh = box
	hull.material_override = armor_mat
	torso.add_child(hull)
	
	# Red Visor Slit
	visor_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(1.05, 0.16, 0.2)
	visor_mesh.mesh = v_box
	visor_mesh.position = Vector3(0, 0.15, 0.62)
	visor_mesh.material_override = visor_mat
	torso.add_child(visor_mesh)
	
	# Heavy Dual Weapon Arms
	for side in [-1, 1]:
		var arm = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.35, 0.4, 0.75)
		arm.mesh = a_box
		arm.position = Vector3(side * 0.9, 0.0, 0.2)
		arm.material_override = armor_mat
		torso.add_child(arm)
		
		var barrel = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.12
		cyl.height = 1.0
		barrel.mesh = cyl
		barrel.rotation_degrees.x = 90
		barrel.position = Vector3(side * 0.9, 0.0, 0.7)
		barrel.material_override = steel_mat
		torso.add_child(barrel)
		
		var m = Marker3D.new()
		m.position = Vector3(side * 0.9, 0.0, 1.25)
		torso.add_child(m)
		if side == -1: left_muzzle = m
		else: right_muzzle = m

	# Boss Heavy Shoulder Pods
	if bot_type == "boss":
		var pod = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(1.8, 0.6, 0.8)
		pod.mesh = p_box
		pod.position = Vector3(0, 0.85, 0)
		pod.material_override = armor_mat
		torso.add_child(pod)

	# Bipedal Heavy Legs
	left_leg = _create_leg(Vector3(-0.55, 1.0, 0), armor_mat, steel_mat)
	right_leg = _create_leg(Vector3(0.55, 1.0, 0), armor_mat, steel_mat)
	add_child(left_leg)
	add_child(right_leg)
	
	# Sparks for Stun State
	stun_sparks = CPUParticles3D.new()
	stun_sparks.emitting = false
	stun_sparks.amount = 16
	stun_sparks.lifetime = 0.3
	stun_sparks.spread = 180.0
	stun_sparks.initial_velocity_min = 2.0
	stun_sparks.initial_velocity_max = 4.5
	stun_sparks.gravity = Vector3(0, 2.0, 0)
	stun_sparks.color = Color(0.1, 0.85, 1.0)
	torso.add_child(stun_sparks)
	
	# In-World 3D Health Bar
	health_label = Label3D.new()
	health_label.text = "[ %s: 100%% ]" % bot_type.to_upper()
	health_label.modulate = Color(1.0, 0.7, 0.2)
	health_label.outline_modulate = Color(0.1, 0.05, 0.0)
	health_label.outline_size = 5
	health_label.font_size = 22
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.position = Vector3(0, 2.5, 0)
	add_child(health_label)
	
	# In-World Reprogram Prompt
	prompt_label = Label3D.new()
	prompt_label.text = "⚡ HOLD [E] TO REPROGRAM ALLIANCE"
	prompt_label.modulate = Color(0.0, 1.0, 0.6)
	prompt_label.outline_modulate = Color(0.0, 0.2, 0.1)
	prompt_label.outline_size = 6
	prompt_label.font_size = 24
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.position = Vector3(0, 2.9, 0)
	prompt_label.visible = false
	add_child(prompt_label)

func _create_leg(pos: Vector3, armor_mat: Material, steel_mat: Material) -> Node3D:
	var leg_root = Node3D.new()
	leg_root.position = pos
	
	var thigh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.3, 0.6, 0.35)
	thigh.mesh = t_box
	thigh.position = Vector3(0, -0.35, 0.05)
	thigh.material_override = armor_mat
	leg_root.add_child(thigh)
	
	var shin = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.28, 0.6, 0.3)
	shin.mesh = s_box
	shin.position = Vector3(0, -0.9, -0.05)
	shin.material_override = armor_mat
	leg_root.add_child(shin)
	
	var foot = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.45, 0.18, 0.65)
	foot.mesh = f_box
	foot.position = Vector3(0, -1.2, 0.1)
	foot.material_override = steel_mat
	leg_root.add_child(foot)
	
	return leg_root

extends CharacterBody3D

# Allied Reprogrammed Squad Mech
# Protects Kai, follows formation, and attacks hostile rogue robots.

var max_health: float = 80.0
var health: float = 80.0
var speed: float = 6.5
var fire_rate: float = 0.9
var damage_per_shot: float = 14.0
var team: String = "ally"

var target: Node3D = null
var fire_timer: float = 0.0
var walk_cycle: float = 0.0
var formation_offset: Vector3 = Vector3.ZERO

# Node references
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_muzzle: Marker3D
var right_muzzle: Marker3D
var visor_mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("allies")
	_build_mech_mesh()
	_setup_collision()
	
	# Pick random flank offset around player
	var angle = randf() * TAU
	formation_offset = Vector3(cos(angle), 0, sin(angle)) * randf_range(3.5, 6.0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	else:
		velocity.y = 0.0

	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		move_and_slide()
		return
		
	# Target acquisition: prioritize closest enemy
	_find_enemy_target()
	
	# Formation following Kai
	var target_pos = player.global_position + formation_offset
	var diff = target_pos - global_position
	diff.y = 0
	var dist = diff.length()
	
	var move_dir = Vector3.ZERO
	if dist > 1.5:
		move_dir = diff.normalized()
		var target_vel = move_dir * speed
		velocity.x = lerp(velocity.x, target_vel.x, 8.0 * delta)
		velocity.z = lerp(velocity.z, target_vel.z, 8.0 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 6.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 6.0 * delta)

	# Rotate towards enemy if available, otherwise look where moving
	if is_instance_valid(target):
		var e_diff = target.global_position - global_position
		e_diff.y = 0
		if e_diff.length() > 0.1:
			var target_rot = atan2(e_diff.x, e_diff.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 6.0 * delta)
	elif move_dir.length() > 0.1:
		var target_rot = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 5.0 * delta)

	# Walk animation
	if velocity.length() > 0.5:
		walk_cycle += delta * 14.0
		left_leg.rotation_degrees.x = sin(walk_cycle) * 20.0
		right_leg.rotation_degrees.x = -sin(walk_cycle) * 20.0
	else:
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 8.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 8.0 * delta)

	move_and_slide()
	
	# Attack enemies
	fire_timer -= delta
	if fire_timer <= 0.0 and is_instance_valid(target):
		var e_dist = global_position.distance_to(target.global_position)
		if e_dist <= 22.0:
			_shoot()

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

func _shoot() -> void:
	fire_timer = fire_rate
	AudioManager.play_shoot(1.15)
	
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "ally"
	bullet.damage = damage_per_shot
	
	var muzzle = left_muzzle if randf() > 0.5 else right_muzzle
	var spawn_pos = muzzle.global_position
	var aim_dir = (target.global_position + Vector3(0, 1.2, 0) - spawn_pos).normalized()
	
	bullet.direction = aim_dir
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	health = max(0.0, health - amount)
	if health <= 0.0:
		AudioManager.play_explosion()
		var main_node = get_parent()
		if main_node.has_method("on_ally_destroyed"):
			main_node.on_ally_destroyed()
		queue_free()

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.7
	cap.height = 2.2
	col.shape = cap
	col.position.y = 1.1
	add_child(col)

func _build_mech_mesh() -> void:
	torso = Node3D.new()
	torso.position.y = 1.3
	add_child(torso)
	
	# Gunmetal armor with Cyan/Emerald Alliance Badging
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.18, 0.24, 0.28)
	body_mat.metallic = 0.9
	body_mat.roughness = 0.35
	
	visor_mat = StandardMaterial3D.new()
	var glow = Color(0.0, 1.0, 0.75)
	visor_mat.albedo_color = glow
	visor_mat.emission_enabled = true
	visor_mat.emission = glow
	visor_mat.emission_energy_multiplier = 5.0
	
	# Torso Hull
	var hull = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 0.85, 1.1)
	hull.mesh = box
	hull.material_override = body_mat
	torso.add_child(hull)
	
	# Friendly Cyan Visor
	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.95, 0.18, 0.25)
	visor.mesh = v_box
	visor.position = Vector3(0, 0.15, 0.55)
	visor.material_override = visor_mat
	torso.add_child(visor)
	
	# Alliance Chevron Hologram Badge above Mech
	var badge = Label3D.new()
	badge.text = "[ALLIED UNIT]"
	badge.modulate = Color(0.0, 1.0, 0.75)
	badge.font_size = 20
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.position = Vector3(0, 2.2, 0)
	add_child(badge)
	
	# Arms
	for side in [-1, 1]:
		var arm = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.28, 0.3, 0.6)
		arm.mesh = a_box
		arm.position = Vector3(side * 0.75, 0.0, 0.2)
		arm.material_override = body_mat
		torso.add_child(arm)
		
		var m = Marker3D.new()
		m.position = Vector3(side * 0.75, 0.0, 0.9)
		torso.add_child(m)
		if side == -1: left_muzzle = m
		else: right_muzzle = m

	# Legs
	left_leg = _create_leg(Vector3(-0.45, 0.9, 0), body_mat)
	right_leg = _create_leg(Vector3(0.45, 0.9, 0), body_mat)
	add_child(left_leg)
	add_child(right_leg)

func _create_leg(pos: Vector3, mat: Material) -> Node3D:
	var leg_root = Node3D.new()
	leg_root.position = pos
	
	var thigh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.25, 0.5, 0.25)
	thigh.mesh = t_box
	thigh.position = Vector3(0, -0.3, 0.05)
	thigh.material_override = mat
	leg_root.add_child(thigh)
	
	var shin = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.22, 0.5, 0.22)
	shin.mesh = s_box
	shin.position = Vector3(0, -0.75, -0.05)
	shin.material_override = mat
	leg_root.add_child(shin)
	
	var foot = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.35, 0.14, 0.5)
	foot.mesh = f_box
	foot.position = Vector3(0, -1.05, 0.1)
	foot.material_override = mat
	leg_root.add_child(foot)
	
	return leg_root

extends CharacterBody3D

signal health_changed(current_hp, max_hp)
signal emp_cooldown_updated(current, max_time)
signal heat_updated(current_heat, max_heat)
signal alliance_count_updated(current_count, max_count)
signal reprogram_progress_updated(progress)

const SPEED = 8.5
const ACCEL = 14.0
const ROT_SPEED = 8.0
const MOUSE_SENSITIVITY = 0.0025

var max_health: float = 100.0
var health: float = 100.0
var team: String = "player"

# EMP Ability
var emp_max_cooldown: float = 8.0
var emp_cooldown: float = 0.0
var emp_radius: float = 14.0

# Weapons & Heat
var max_heat: float = 100.0
var current_heat: float = 0.0
var is_overheated: bool = false
var fire_rate: float = 0.12
var fire_timer: float = 0.0
var current_barrel: int = 0 # 0 = Left, 1 = Right

# Dash Thrusters
var dash_cooldown: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0

# Procedural Walk Cycle
var walk_cycle: float = 0.0
var step_interval: float = 0.4
var step_timer: float = 0.0

# Camera & Aiming
var camera_pitch: float = -12.0
var camera_yaw: float = 0.0
var camera_shake: float = 0.0

# Node references
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_gun: Node3D
var right_gun: Node3D
var left_muzzle: Marker3D
var right_muzzle: Marker3D
var left_barrel_mesh: MeshInstance3D
var right_barrel_mesh: MeshInstance3D

# Reprogram target
var nearby_stunned_enemy: Node3D = null
var reprogram_timer: float = 0.0
var reprogram_duration: float = 1.2

func _ready() -> void:
	_build_mech_mesh()
	_setup_camera()
	_setup_collision()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, max_health)
	emp_cooldown_updated.emit(0.0, emp_max_cooldown)
	heat_updated.emit(current_heat, max_heat)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY * 45.0
		camera_pitch = clamp(camera_pitch, -45.0, 20.0)
		
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Cooldowns
	if emp_cooldown > 0.0:
		emp_cooldown = max(0.0, emp_cooldown - delta)
		emp_cooldown_updated.emit(emp_cooldown, emp_max_cooldown)
		
	if dash_cooldown > 0.0:
		dash_cooldown = max(0.0, dash_cooldown - delta)
		
	# Weapon heat cooling
	if current_heat > 0.0:
		var cooling_speed = 35.0 if is_overheated else 50.0
		current_heat = max(0.0, current_heat - cooling_speed * delta)
		if is_overheated and current_heat <= 10.0:
			is_overheated = false
		heat_updated.emit(current_heat, max_heat)

	# Movement Input
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y += 1.0
	if Input.is_action_pressed("move_backward"): input_dir.y -= 1.0
	if Input.is_action_pressed("move_left"): input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"): input_dir.x += 1.0
	input_dir = input_dir.normalized()
	
	# Dash processing
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and input_dir != Vector2.ZERO:
		is_dashing = true
		dash_timer = 0.22
		dash_cooldown = 2.0
		AudioManager.play_dash()
		camera_shake = 0.35
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	# Calculate World Direction based on camera yaw
	var cam_forward = Vector3(-sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
	var cam_right = Vector3(cos(camera_yaw), 0, -sin(camera_yaw)).normalized()
	var move_vec = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
	
	var target_speed = SPEED
	if is_dashing:
		target_speed = SPEED * 2.8
		
	var target_vel = move_vec * target_speed
	velocity.x = lerp(velocity.x, target_vel.x, ACCEL * delta)
	velocity.z = lerp(velocity.z, target_vel.z, ACCEL * delta)
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	else:
		velocity.y = 0.0
		
	move_and_slide()
	
	# Mech Torso and Leg Rotation
	if move_vec.length() > 0.1:
		var target_rot_y = atan2(move_vec.x, move_vec.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, ROT_SPEED * delta)
		
		# Procedural walk cycle animation
		walk_cycle += delta * (14.0 if not is_dashing else 25.0)
		left_leg.rotation_degrees.x = sin(walk_cycle) * 25.0
		right_leg.rotation_degrees.x = -sin(walk_cycle) * 25.0
		torso.position.y = 1.35 + abs(sin(walk_cycle * 2.0)) * 0.08
		
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			AudioManager.play_step()
	else:
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 10.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 10.0 * delta)
		torso.position.y = lerp(torso.position.y, 1.35, 10.0 * delta)
	
	# Update Camera Position & Shake
	_update_camera(delta)
	
	# Combat Actions
	fire_timer -= delta
	if Input.is_action_pressed("fire") and fire_timer <= 0.0 and not is_overheated:
		_shoot_cannon()
		
	if Input.is_action_just_pressed("fire_emp") and emp_cooldown <= 0.0:
		_trigger_emp()
		
	_process_reprogram(delta)

func _shoot_cannon() -> void:
	fire_timer = fire_rate
	current_heat += 4.5
	if current_heat >= max_heat:
		is_overheated = true
		AudioManager.play_alert()
	heat_updated.emit(current_heat, max_heat)
	
	AudioManager.play_shoot(1.0 if current_barrel == 0 else 1.08)
	camera_shake = max(camera_shake, 0.12)
	
	# Spawn Bullet
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "player"
	bullet.damage = 22.0
	
	var muzzle = left_muzzle if current_barrel == 0 else right_muzzle
	var barrel = left_barrel_mesh if current_barrel == 0 else right_barrel_mesh
	
	# Recoil kick on barrel
	barrel.position.z = 0.35
	var tween = create_tween()
	tween.tween_property(barrel, "position:z", 0.0, 0.1)
	
	# Direction towards crosshair center
	var aim_target = _get_aim_target()
	var spawn_pos = muzzle.global_position
	var aim_dir = (aim_target - spawn_pos).normalized()
	
	bullet.direction = aim_dir
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	
	current_barrel = 1 - current_barrel

func _get_aim_target() -> Vector3:
	var ray_length = 100.0
	var from = camera.global_position
	var forward = -camera.global_transform.basis.z
	var to = from + forward * ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
	return to

func _trigger_emp() -> void:
	emp_cooldown = emp_max_cooldown
	emp_cooldown_updated.emit(emp_cooldown, emp_max_cooldown)
	AudioManager.play_emp()
	camera_shake = 0.5
	
	# Spawn expanding visual EMP blast wave
	var blast_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.6
	blast_mesh.mesh = torus
	blast_mesh.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.9, 1.0)
	mat.emission_energy_multiplier = 8.0
	blast_mesh.material_override = mat
	
	get_parent().add_child(blast_mesh)
	blast_mesh.global_position = global_position + Vector3(0, 0.5, 0)
	
	# Blast tween scale & fade
	var tween = create_tween()
	tween.tween_property(blast_mesh, "scale", Vector3(emp_radius, 1.0, emp_radius), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.55)
	tween.tween_callback(blast_mesh.queue_free)
	
	# Stun all enemy bots within radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("apply_emp_stun"):
			var d = global_position.distance_to(enemy.global_position)
			if d <= emp_radius:
				enemy.apply_emp_stun(6.5)

func _process_reprogram(delta: float) -> void:
	# Find closest stunned enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_stunned: Node3D = null
	var min_dist = 4.2
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.get("is_stunned") == true:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_stunned = enemy
				
	nearby_stunned_enemy = closest_stunned
	
	if nearby_stunned_enemy and Input.is_action_pressed("reprogram"):
		reprogram_timer += delta
		var prog = clamp(reprogram_timer / reprogram_duration, 0.0, 1.0)
		reprogram_progress_updated.emit(prog)
		
		if reprogram_timer >= reprogram_duration:
			reprogram_timer = 0.0
			reprogram_progress_updated.emit(0.0)
			_convert_enemy_to_ally(nearby_stunned_enemy)
	else:
		if reprogram_timer > 0.0:
			reprogram_timer = 0.0
			reprogram_progress_updated.emit(0.0)

func _convert_enemy_to_ally(enemy: Node3D) -> void:
	AudioManager.play_reprogram()
	var spawn_pos = enemy.global_position
	enemy.queue_free()
	
	# Spawn Ally
	var ally_scene = load("res://scripts/ally_mech.gd")
	var ally = CharacterBody3D.new()
	ally.set_script(ally_scene)
	get_parent().add_child(ally)
	ally.global_position = spawn_pos
	
	var main_node = get_parent()
	if main_node.has_method("on_bot_reprogrammed"):
		main_node.on_bot_reprogrammed()

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	health = max(0.0, health - amount)
	health_changed.emit(health, max_health)
	camera_shake = max(camera_shake, 0.45)
	
	if health <= 0.0:
		AudioManager.play_explosion()
		var main_node = get_parent()
		if main_node.has_method("game_over"):
			main_node.game_over(false)

func _update_camera(delta: float) -> void:
	camera_pivot.global_position = global_position + Vector3(0, 1.8, 0)
	camera_pivot.rotation.y = camera_yaw
	spring_arm.rotation_degrees.x = camera_pitch
	
	# Camera shake
	if camera_shake > 0.0:
		camera_shake = max(0.0, camera_shake - delta * 2.0)
		var shake_offset = Vector3(
			randf_range(-camera_shake, camera_shake) * 0.25,
			randf_range(-camera_shake, camera_shake) * 0.25,
			0
		)
		camera.position = shake_offset
	else:
		camera.position = Vector3.ZERO

func _setup_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	get_parent().call_deferred("add_child", camera_pivot)
	
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 5.2
	spring_arm.margin = 0.2
	camera_pivot.add_child(spring_arm)
	
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 75.0
	spring_arm.add_child(camera)
	
	# Camera offset for over-the-shoulder view
	spring_arm.position = Vector3(0.9, 0.8, 0)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.8
	cap.height = 2.4
	col.shape = cap
	col.position.y = 1.2
	add_child(col)

func _build_mech_mesh() -> void:
	# Base root for torso and head
	torso = Node3D.new()
	torso.position.y = 1.35
	add_child(torso)
	
	# Heavy Armored Chassis (Dark Titanium Steel)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.2, 0.22, 0.26)
	body_mat.metallic = 0.92
	body_mat.roughness = 0.32
	
	var neon_mat = StandardMaterial3D.new()
	neon_mat.albedo_color = Color(0.0, 0.85, 1.0)
	neon_mat.emission_enabled = true
	neon_mat.emission = Color(0.0, 0.85, 1.0)
	neon_mat.emission_energy_multiplier = 4.5
	
	# Main Torso Hull
	var hull = MeshInstance3D.new()
	var hull_box = BoxMesh.new()
	hull_box.size = Vector3(1.4, 1.0, 1.3)
	hull.mesh = hull_box
	hull.material_override = body_mat
	torso.add_child(hull)
	
	# Cockpit / Visor (ED-209 style glowing cyan visor)
	var visor = MeshInstance3D.new()
	var visor_box = BoxMesh.new()
	visor_box.size = Vector3(1.1, 0.22, 0.3)
	visor.mesh = visor_box
	visor.position = Vector3(0, 0.2, 0.65)
	visor.material_override = neon_mat
	torso.add_child(visor)
	
	# Top Armored Dome
	var dome = MeshInstance3D.new()
	var dome_cyl = CylinderMesh.new()
	dome_cyl.top_radius = 0.6
	dome_cyl.bottom_radius = 0.72
	dome_cyl.height = 0.4
	dome.mesh = dome_cyl
	dome.position = Vector3(0, 0.65, 0)
	dome.material_override = body_mat
	torso.add_child(dome)
	
	# Rear Exhaust Boosters
	for x_off in [-0.4, 0.4]:
		var thruster = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.16
		cyl.bottom_radius = 0.22
		cyl.height = 0.45
		thruster.mesh = cyl
		thruster.rotation_degrees.x = 90
		thruster.position = Vector3(x_off, 0.2, -0.7)
		thruster.material_override = neon_mat
		torso.add_child(thruster)
		
	# Left Weapon Arm (Heavy Rotary Autocannon)
	left_gun = Node3D.new()
	left_gun.position = Vector3(-0.95, 0.05, 0.2)
	torso.add_child(left_gun)
	
	var l_shroud = MeshInstance3D.new()
	var l_sbox = BoxMesh.new()
	l_sbox.size = Vector3(0.35, 0.4, 0.8)
	l_shroud.mesh = l_sbox
	l_shroud.material_override = body_mat
	left_gun.add_child(l_shroud)
	
	left_barrel_mesh = MeshInstance3D.new()
	var l_bcyl = CylinderMesh.new()
	l_bcyl.top_radius = 0.12
	l_bcyl.bottom_radius = 0.12
	l_bcyl.height = 1.0
	left_barrel_mesh.mesh = l_bcyl
	left_barrel_mesh.rotation_degrees.x = 90
	left_barrel_mesh.position = Vector3(0, 0, 0.7)
	left_barrel_mesh.material_override = body_mat
	left_gun.add_child(left_barrel_mesh)
	
	left_muzzle = Marker3D.new()
	left_muzzle.position = Vector3(0, 0, 1.25)
	left_gun.add_child(left_muzzle)
	
	# Right Weapon Arm (Autocannon / EMP Shock Cannon)
	right_gun = Node3D.new()
	right_gun.position = Vector3(0.95, 0.05, 0.2)
	torso.add_child(right_gun)
	
	var r_shroud = MeshInstance3D.new()
	var r_sbox = BoxMesh.new()
	r_sbox.size = Vector3(0.35, 0.4, 0.8)
	r_shroud.mesh = r_sbox
	r_shroud.material_override = body_mat
	right_gun.add_child(r_shroud)
	
	right_barrel_mesh = MeshInstance3D.new()
	var r_bcyl = CylinderMesh.new()
	r_bcyl.top_radius = 0.12
	r_bcyl.bottom_radius = 0.12
	r_bcyl.height = 1.0
	right_barrel_mesh.mesh = r_bcyl
	right_barrel_mesh.rotation_degrees.x = 90
	right_barrel_mesh.position = Vector3(0, 0, 0.7)
	right_barrel_mesh.material_override = body_mat
	right_gun.add_child(right_barrel_mesh)
	
	right_muzzle = Marker3D.new()
	right_muzzle.position = Vector3(0, 0, 1.25)
	right_gun.add_child(right_muzzle)
	
	# Bipedal Legs (ED-209 Reverse-Joint Walkers)
	left_leg = _create_leg(Vector3(-0.6, 1.0, 0), body_mat)
	right_leg = _create_leg(Vector3(0.6, 1.0, 0), body_mat)
	add_child(left_leg)
	add_child(right_leg)

func _create_leg(pos: Vector3, mat: Material) -> Node3D:
	var leg_root = Node3D.new()
	leg_root.position = pos
	
	# Hip joint
	var hip = MeshInstance3D.new()
	var hip_sph = SphereMesh.new()
	hip_sph.radius = 0.25
	hip_sph.height = 0.5
	hip.mesh = hip_sph
	hip.material_override = mat
	leg_root.add_child(hip)
	
	# Thigh
	var thigh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.3, 0.6, 0.35)
	thigh.mesh = t_box
	thigh.position = Vector3(0, -0.35, 0.05)
	thigh.material_override = mat
	leg_root.add_child(thigh)
	
	# Hydraulic Reverse Knee
	var knee = MeshInstance3D.new()
	var k_cyl = CylinderMesh.new()
	k_cyl.top_radius = 0.18
	k_cyl.bottom_radius = 0.18
	k_cyl.height = 0.35
	knee.mesh = k_cyl
	knee.rotation_degrees.z = 90
	knee.position = Vector3(0, -0.65, -0.1)
	knee.material_override = mat
	leg_root.add_child(knee)
	
	# Shin
	var shin = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.28, 0.6, 0.3)
	shin.mesh = s_box
	shin.position = Vector3(0, -0.95, -0.05)
	shin.material_override = mat
	leg_root.add_child(shin)
	
	# Armored Footpad (Three-toed stabilizer)
	var foot = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.45, 0.18, 0.7)
	foot.mesh = f_box
	foot.position = Vector3(0, -1.25, 0.15)
	foot.material_override = mat
	leg_root.add_child(foot)
	
	return leg_root

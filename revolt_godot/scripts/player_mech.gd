extends CharacterBody3D

# Teen Resistance Hero: KAI (Human Cyberpunk Operative 3D Model & Combat Controller)
# Equipped with Bullpup EMP Pulse Rifle, Cybernetic Hacking Gauntlet, and Tactical Jet Slide.

signal health_changed(current_hp, max_hp)
signal emp_cooldown_updated(current, max_time)
signal heat_updated(current_heat, max_heat)
signal alliance_count_updated(current_count, max_count)
signal reprogram_progress_updated(progress)

const SPEED = 8.5
const SPRINT_SPEED = 14.5
const ACCEL = 18.0
const ROT_SPEED = 14.0
const MOUSE_SENSITIVITY = 0.0025

var max_health: float = 100.0
var health: float = 100.0
var team: String = "player"

# EMP Disruptor
var emp_max_cooldown: float = 6.0
var emp_cooldown: float = 0.0
var emp_radius: float = 20.0

# Pulse Rifle & Overheat
var max_heat: float = 100.0
var current_heat: float = 0.0
var is_overheated: bool = false
var fire_rate: float = 0.11
var fire_timer: float = 0.0

# Tactical Slide / Dash
var dash_cooldown: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0

# Procedural Locomotion
var run_cycle: float = 0.0
var step_interval: float = 0.28
var step_timer: float = 0.0

# Camera
var camera_pitch: float = -12.0
var camera_yaw: float = 0.0
var camera_shake: float = 0.0

# Node References
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var body_root: Node3D
var torso: Node3D
var head: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_shin: Node3D
var right_shin: Node3D
var left_arm: Node3D
var right_arm: Node3D
var rifle: Node3D
var muzzle: Marker3D
var muzzle_light: OmniLight3D
var muzzle_smoke: CPUParticles3D
var dash_particles: CPUParticles3D
var backpack_reactor_mat: StandardMaterial3D

# Reprogram target
var nearby_stunned_enemy: Node3D = null
var reprogram_timer: float = 0.0
var reprogram_duration: float = 1.0

func _ready() -> void:
	_build_detailed_human_kai()
	_setup_camera()
	_setup_collision()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, max_health)
	emp_cooldown_updated.emit(0.0, emp_max_cooldown)
	heat_updated.emit(current_heat, max_heat)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY * 40.0
		camera_pitch = clamp(camera_pitch, -55.0, 30.0)
		
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
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
		
	if current_heat > 0.0:
		var cooling_speed = 50.0 if is_overheated else 75.0
		current_heat = max(0.0, current_heat - cooling_speed * delta)
		if is_overheated and current_heat <= 10.0:
			is_overheated = false
		heat_updated.emit(current_heat, max_heat)

	# Backpack reactor visual pulsation
	if backpack_reactor_mat:
		var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
		backpack_reactor_mat.emission_energy_multiplier = 2.2 if emp_cooldown <= 0.0 else (0.5 + pulse * 0.5)

	# 100% Robust Hardware-Level WASD + Arrow Key Input Detection
	var input_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("move_forward"):
		input_dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("move_backward"):
		input_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()
	
	# Tactical Jet Slide / Dash (Spacebar)
	var dash_pressed = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("dash")
	if dash_pressed and dash_cooldown <= 0.0 and input_dir != Vector2.ZERO:
		is_dashing = true
		dash_timer = 0.32
		dash_cooldown = 1.4
		AudioManager.play_dash()
		camera_shake = 0.4
		if dash_particles: dash_particles.emitting = true
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			if dash_particles: dash_particles.emitting = false

	# Calculate World Direction based on camera yaw
	# Camera forward vector is (-sin(yaw), 0, -cos(yaw))
	var cam_forward = Vector3(-sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
	var cam_right = Vector3(cos(camera_yaw), 0, -sin(camera_yaw)).normalized()
	var move_vec = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
	
	var target_speed = SPEED
	if is_dashing:
		target_speed = SPRINT_SPEED * 1.55
		
	var target_vel = move_vec * target_speed
	velocity.x = lerp(velocity.x, target_vel.x, ACCEL * delta)
	velocity.z = lerp(velocity.z, target_vel.z, ACCEL * delta)
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	else:
		velocity.y = 0.0
		
	move_and_slide()
	
	# Kai faces crosshair aiming direction smoothly
	rotation.y = lerp_angle(rotation.y, camera_yaw, ROT_SPEED * delta)
	
	# Procedural Locomotion Animations
	if move_vec.length() > 0.1:
		run_cycle += delta * (16.0 if not is_dashing else 26.0)
		var leg_angle = sin(run_cycle) * (34.0 if not is_dashing else 48.0)
		left_leg.rotation_degrees.x = leg_angle
		right_leg.rotation_degrees.x = -leg_angle
		
		# Knee joint flexion
		if left_shin: left_shin.rotation_degrees.x = max(0.0, -leg_angle * 0.8)
		if right_shin: right_shin.rotation_degrees.x = max(0.0, leg_angle * 0.8)
		
		# Torso dynamic bounce, tilt, and banking
		torso.position.y = 0.95 + abs(sin(run_cycle * 2.0)) * 0.06
		torso.rotation_degrees.z = -input_dir.x * 6.0 # Bank into turns
		torso.rotation_degrees.x = -4.0 if not is_dashing else -14.0 # Lean forward into run
		
		# Arm natural counter-swing
		left_arm.rotation_degrees.x = -sin(run_cycle) * 18.0
		
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			AudioManager.play_step()
	else:
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 14.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 14.0 * delta)
		if left_shin: left_shin.rotation_degrees.x = lerp(left_shin.rotation_degrees.x, 0.0, 14.0 * delta)
		if right_shin: right_shin.rotation_degrees.x = lerp(right_shin.rotation_degrees.x, 0.0, 14.0 * delta)
		left_arm.rotation_degrees.x = lerp(left_arm.rotation_degrees.x, 0.0, 10.0 * delta)
		torso.position.y = lerp(torso.position.y, 0.95, 10.0 * delta)
		torso.rotation_degrees.z = lerp(torso.rotation_degrees.z, 0.0, 10.0 * delta)
		torso.rotation_degrees.x = lerp(torso.rotation_degrees.x, 0.0, 10.0 * delta)
	
	# Combat Actions
	fire_timer -= delta
	var fire_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("fire")
	if fire_pressed and fire_timer <= 0.0 and not is_overheated:
		_shoot()
		fire_timer = fire_rate
		
	# EMP Blast (Q / RMB)
	var emp_pressed = Input.is_physical_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_Q) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_action_just_pressed("fire_emp")
	if emp_pressed and emp_cooldown <= 0.0:
		_trigger_emp()
		
	# Reprogramming Hacking (Hold E)
	_process_reprogram(delta)
	
	# Update Camera Position & Shake
	_update_camera(delta)

func _shoot() -> void:
	current_heat = min(max_heat, current_heat + 10.5)
	if current_heat >= max_heat:
		is_overheated = true
		AudioManager.play_alert()
	heat_updated.emit(current_heat, max_heat)
	
	AudioManager.play_shoot(1.15)
	camera_shake = max(camera_shake, 0.16)
	
	# Rifle visual recoil kickback along +Z (towards player) and upward snap
	rifle.position.z = -0.18
	rifle.rotation_degrees.x = -6.0
	var tween = create_tween()
	tween.tween_property(rifle, "position:z", -0.26, 0.07)
	tween.parallel().tween_property(rifle, "rotation_degrees:x", 0.0, 0.09)
	
	# Dynamic Muzzle Flash Light
	if muzzle_light:
		muzzle_light.light_energy = 7.0
		var lt = create_tween()
		lt.tween_property(muzzle_light, "light_energy", 0.0, 0.07)
		
	if muzzle_smoke:
		muzzle_smoke.restart()
	
	# Spawn Bullet
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "player"
	bullet.damage = 32.0
	
	var aim_target = _get_aim_target()
	var spawn_pos = muzzle.global_position
	var aim_dir = (aim_target - spawn_pos).normalized()
	
	bullet.direction = aim_dir
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos

func _get_aim_target() -> Vector3:
	var ray_length = 200.0
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
	
	# Expanding brilliant cyan EMP shockwave ring along ground
	var blast_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.6
	blast_mesh.mesh = torus
	blast_mesh.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.95, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.95, 1.0)
	mat.emission_energy_multiplier = 3.5
	blast_mesh.material_override = mat
	
	get_parent().add_child(blast_mesh)
	blast_mesh.global_position = global_position + Vector3(0, 0.4, 0)
	
	var tween = create_tween()
	tween.tween_property(blast_mesh, "scale", Vector3(emp_radius, 1.0, emp_radius), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tween.tween_callback(blast_mesh.queue_free)
	
	# Stun all rogue enemy robots in 20m radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("apply_emp_stun"):
			var d = global_position.distance_to(enemy.global_position)
			if d <= emp_radius:
				enemy.apply_emp_stun(7.0)

func _process_reprogram(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_stunned: Node3D = null
	var min_dist = 8.5 # Generous hacking radius for giant robots
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.get("is_stunned") == true:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_stunned = enemy
				
	nearby_stunned_enemy = closest_stunned
	
	var reprogram_active = Input.is_physical_key_pressed(KEY_E) or Input.is_key_pressed(KEY_E) or Input.is_action_pressed("reprogram")
	if nearby_stunned_enemy and reprogram_active:
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
	camera_shake = max(camera_shake, 0.4)
	
	if health <= 0.0:
		AudioManager.play_explosion()
		var main_node = get_parent()
		if main_node.has_method("game_over"):
			main_node.game_over(false)

func _update_camera(delta: float) -> void:
	camera_pivot.global_position = global_position + Vector3(0, 1.5, 0)
	camera_pivot.rotation.y = camera_yaw
	spring_arm.rotation_degrees.x = camera_pitch
	
	if camera_shake > 0.0:
		camera_shake = max(0.0, camera_shake - delta * 2.2)
		var shake_offset = Vector3(
			randf_range(-camera_shake, camera_shake) * 0.16,
			randf_range(-camera_shake, camera_shake) * 0.16,
			0
		)
		camera.position = shake_offset
	else:
		camera.position = Vector3.ZERO

func _setup_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.top_level = true
	add_child(camera_pivot)
	
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 3.8 # Optimal OTS action view
	spring_arm.margin = 0.2
	camera_pivot.add_child(spring_arm)
	
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 74.0
	spring_arm.add_child(camera)
	
	# Over Kai's right shoulder for classic OTS shooter feel
	spring_arm.position = Vector3(0.85, 0.35, 0)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)

func _build_detailed_human_kai() -> void:
	# Human Kai faces forward along -Z (No 180 flip!)
	body_root = Node3D.new()
	add_child(body_root)
	
	# Materials
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.92, 0.76, 0.64)
	skin_mat.roughness = 0.65
	
	var hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.12, 0.14, 0.18)
	hair_mat.roughness = 0.5
	
	var suit_mat = StandardMaterial3D.new()
	suit_mat.albedo_color = Color(0.16, 0.20, 0.26)
	suit_mat.metallic = 0.6
	suit_mat.roughness = 0.4
	
	var vest_mat = StandardMaterial3D.new()
	vest_mat.albedo_color = Color(0.22, 0.27, 0.35)
	vest_mat.metallic = 0.88
	vest_mat.roughness = 0.28
	
	var cyan_neon_mat = StandardMaterial3D.new()
	var neon_col = Color(0.0, 0.95, 1.0)
	cyan_neon_mat.albedo_color = neon_col
	cyan_neon_mat.emission_enabled = true
	cyan_neon_mat.emission = neon_col
	cyan_neon_mat.emission_energy_multiplier = 2.0
	
	backpack_reactor_mat = StandardMaterial3D.new()
	backpack_reactor_mat.albedo_color = neon_col
	backpack_reactor_mat.emission_enabled = true
	backpack_reactor_mat.emission = neon_col
	backpack_reactor_mat.emission_energy_multiplier = 2.2
	
	var pants_mat = StandardMaterial3D.new()
	pants_mat.albedo_color = Color(0.13, 0.16, 0.20)
	pants_mat.roughness = 0.65
	
	var boots_mat = StandardMaterial3D.new()
	boots_mat.albedo_color = Color(0.06, 0.08, 0.10)
	boots_mat.metallic = 0.85
	boots_mat.roughness = 0.25
	
	var rifle_mat = StandardMaterial3D.new()
	rifle_mat.albedo_color = Color(0.18, 0.20, 0.24)
	rifle_mat.metallic = 0.96
	rifle_mat.roughness = 0.2

	# 1. Torso & Tactical Armor Vest
	torso = Node3D.new()
	torso.position.y = 0.95
	body_root.add_child(torso)
	
	# Combat compression jacket
	var chest = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.48, 0.52, 0.28)
	chest.mesh = c_box
	chest.material_override = suit_mat
	torso.add_child(chest)
	
	# Front: Segmented Ceramic Ballistic Chest Plates (facing -Z forward)
	var plate_upper = MeshInstance3D.new()
	var pu_box = BoxMesh.new()
	pu_box.size = Vector3(0.42, 0.22, 0.08)
	plate_upper.mesh = pu_box
	plate_upper.position = Vector3(0, 0.12, -0.15)
	plate_upper.material_override = vest_mat
	torso.add_child(plate_upper)
	
	var plate_lower = MeshInstance3D.new()
	var pl_box = BoxMesh.new()
	pl_box.size = Vector3(0.38, 0.18, 0.07)
	plate_lower.mesh = pl_box
	plate_lower.position = Vector3(0, -0.1, -0.15)
	plate_lower.material_override = vest_mat
	torso.add_child(plate_lower)
	
	# Glowing Cyan Tactical Power Line on chest
	var led_strip = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.32, 0.03, 0.02)
	led_strip.mesh = l_box
	led_strip.position = Vector3(0, 0.14, -0.19)
	led_strip.material_override = cyan_neon_mat
	torso.add_child(led_strip)
	
	# Shoulder Pauldrons / Armor Pads
	for side in [-1, 1]:
		var pad = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.16, 0.18, 0.24)
		pad.mesh = p_box
		pad.position = Vector3(side * 0.28, 0.22, 0)
		pad.material_override = vest_mat
		torso.add_child(pad)
		
	# Back (+Z): High-Tech EMP Reactor Backpack (Facing Third-Person Camera!)
	var pack = MeshInstance3D.new()
	var pack_box = BoxMesh.new()
	pack_box.size = Vector3(0.34, 0.42, 0.14)
	pack.mesh = pack_box
	pack.position = Vector3(0, 0.06, 0.18)
	pack.material_override = vest_mat
	torso.add_child(pack)
	
	# Glowing EMP Reactor Core Cylinder
	var reactor_core = MeshInstance3D.new()
	var rc_cyl = CylinderMesh.new()
	rc_cyl.top_radius = 0.07
	rc_cyl.bottom_radius = 0.07
	rc_cyl.height = 0.28
	reactor_core.mesh = rc_cyl
	reactor_core.rotation_degrees.z = 90
	reactor_core.position = Vector3(0, 0.06, 0.26)
	reactor_core.material_override = backpack_reactor_mat
	torso.add_child(reactor_core)
	
	# Backpack radiator cooling fins
	for y_off in [-0.08, 0.0, 0.08]:
		var fin = MeshInstance3D.new()
		var f_box = BoxMesh.new()
		f_box.size = Vector3(0.26, 0.02, 0.06)
		fin.mesh = f_box
		fin.position = Vector3(0, y_off, 0.25)
		fin.material_override = rifle_mat
		torso.add_child(fin)

	# 2. Head, Cyber Visor & Layered Hair
	head = Node3D.new()
	head.position = Vector3(0, 0.42, 0)
	torso.add_child(head)
	
	# Human Face & Head Base (facing -Z)
	var face = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 0.14
	f_sph.height = 0.30
	face.mesh = f_sph
	face.position = Vector3(0, 0, -0.02)
	face.material_override = skin_mat
	head.add_child(face)
	
	# Hair: Fully covers crown and back (+Z) of head
	var hair_back = MeshInstance3D.new()
	var hb_box = BoxMesh.new()
	hb_box.size = Vector3(0.34, 0.26, 0.22)
	hair_back.mesh = hb_box
	hair_back.position = Vector3(0, 0.04, 0.08)
	hair_back.material_override = hair_mat
	head.add_child(hair_back)
	
	var hair_top = MeshInstance3D.new()
	var ht_box = BoxMesh.new()
	ht_box.size = Vector3(0.32, 0.14, 0.32)
	hair_top.mesh = ht_box
	hair_top.position = Vector3(0, 0.15, -0.01)
	hair_top.material_override = hair_mat
	head.add_child(hair_top)
	
	# Stylish anime swept hair fringe at forehead (-Z)
	var hair_fringe = MeshInstance3D.new()
	var hf_box = BoxMesh.new()
	hf_box.size = Vector3(0.30, 0.12, 0.14)
	hair_fringe.mesh = hf_box
	hair_fringe.position = Vector3(0, 0.12, -0.14)
	hair_fringe.rotation_degrees.x = 22
	hair_fringe.material_override = hair_mat
	head.add_child(hair_fringe)
	
	# Glowing Tactical Cyber Visor (wrapped around temples facing -Z)
	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.28, 0.06, 0.14)
	visor.mesh = v_box
	visor.position = Vector3(0, 0.02, -0.14)
	visor.material_override = cyan_neon_mat
	head.add_child(visor)
	
	# Comms Headset with Boom Mic on left ear
	var headset = MeshInstance3D.new()
	var hs_box = BoxMesh.new()
	hs_box.size = Vector3(0.06, 0.10, 0.10)
	headset.mesh = hs_box
	headset.position = Vector3(-0.16, 0.02, -0.02)
	headset.material_override = boots_mat
	head.add_child(headset)

	# 3. Arms & Two-Handed Pulse Rifle Stance
	# Left Arm: Cybernetic Gauntlet angled across to support rifle foregrip
	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.24, 0.12, 0)
	torso.add_child(left_arm)
	
	var l_upper = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.065
	l_cyl.bottom_radius = 0.06
	l_cyl.height = 0.36
	l_upper.mesh = l_cyl
	l_upper.rotation_degrees.z = -30
	l_upper.rotation_degrees.x = 40
	l_upper.position = Vector3(0.10, -0.14, -0.12)
	l_upper.material_override = suit_mat
	left_arm.add_child(l_upper)
	
	var gauntlet = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(0.12, 0.14, 0.16)
	gauntlet.mesh = g_box
	gauntlet.position = Vector3(0.24, -0.20, -0.26)
	gauntlet.material_override = cyan_neon_mat
	left_arm.add_child(gauntlet)
	
	# Right Arm: Aiming rifle forward
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.30, 0.12, 0)
	torso.add_child(right_arm)
	
	var r_upper = MeshInstance3D.new()
	r_upper.mesh = l_cyl
	r_upper.rotation_degrees.z = 10
	r_upper.rotation_degrees.x = 20
	r_upper.position = Vector3(0.02, -0.14, -0.10)
	r_upper.material_override = suit_mat
	right_arm.add_child(r_upper)
	
	# 4. Heavy Bullpup EMP Pulse Rifle (Prominently mounted on right side of screen)
	rifle = Node3D.new()
	rifle.position = Vector3(0.34, -0.04, -0.26)
	torso.add_child(rifle)
	
	var r_body = MeshInstance3D.new()
	var rb_box = BoxMesh.new()
	rb_box.size = Vector3(0.10, 0.18, 0.65)
	r_body.mesh = rb_box
	r_body.position = Vector3(0, 0, -0.12)
	r_body.material_override = rifle_mat
	rifle.add_child(r_body)
	
	# Glowing Cyan Plasma Energy Cell (ammo battery)
	var r_cell = MeshInstance3D.new()
	var rc_box = BoxMesh.new()
	rc_box.size = Vector3(0.06, 0.14, 0.18)
	r_cell.mesh = rc_box
	r_cell.position = Vector3(0, -0.04, 0.05)
	r_cell.material_override = cyan_neon_mat
	rifle.add_child(r_cell)
	
	# Holographic Reflex Sight with glowing reticle
	var sight = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.06, 0.09, 0.18)
	sight.mesh = s_box
	sight.position = Vector3(0, 0.13, -0.18)
	sight.material_override = cyan_neon_mat
	rifle.add_child(sight)
	
	# Heavy Fluted Barrel extending forward (-Z)
	var barrel = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.035
	b_cyl.bottom_radius = 0.035
	b_cyl.height = 0.55
	barrel.mesh = b_cyl
	barrel.rotation_degrees.x = 90
	barrel.position = Vector3(0, 0.02, -0.52)
	barrel.material_override = rifle_mat
	rifle.add_child(barrel)
	
	# Underslung EMP Canister Tube
	var emp_canister = MeshInstance3D.new()
	var ec_cyl = CylinderMesh.new()
	ec_cyl.top_radius = 0.042
	ec_cyl.bottom_radius = 0.042
	ec_cyl.height = 0.35
	emp_canister.mesh = ec_cyl
	emp_canister.rotation_degrees.x = 90
	emp_canister.position = Vector3(0, -0.08, -0.38)
	emp_canister.material_override = cyan_neon_mat
	rifle.add_child(emp_canister)
	
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0, 0.02, -0.84)
	rifle.add_child(muzzle)
	
	# Muzzle Flash Dynamic Light
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(0.1, 0.95, 1.0)
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 9.0
	muzzle.add_child(muzzle_light)

	# 5. Articulated Legs & Combat Boots (Facing -Z Forward)
	var leg_data_left = _create_human_leg(Vector3(-0.16, 0.0, 0), pants_mat, boots_mat, vest_mat)
	left_leg = leg_data_left[0]
	left_shin = leg_data_left[1]
	body_root.add_child(left_leg)
	
	var leg_data_right = _create_human_leg(Vector3(0.16, 0.0, 0), pants_mat, boots_mat, vest_mat)
	right_leg = leg_data_right[0]
	right_shin = leg_data_right[1]
	body_root.add_child(right_leg)
	
	# Dash Boot Thruster Spark Particles
	dash_particles = CPUParticles3D.new()
	dash_particles.emitting = false
	dash_particles.amount = 22
	dash_particles.lifetime = 0.28
	dash_particles.spread = 120.0
	dash_particles.initial_velocity_min = 4.0
	dash_particles.initial_velocity_max = 8.0
	dash_particles.gravity = Vector3(0, 2.5, 0)
	dash_particles.color = Color(0.0, 0.95, 1.0)
	dash_particles.position = Vector3(0, 0.1, 0.15)
	body_root.add_child(dash_particles)

func _create_human_leg(pos: Vector3, pants_mat: Material, boots_mat: Material, armor_mat: Material) -> Array:
	var thigh_root = Node3D.new()
	thigh_root.position = pos + Vector3(0, 0.92, 0)
	
	# Thigh
	var thigh = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.09
	t_cyl.bottom_radius = 0.08
	t_cyl.height = 0.44
	thigh.mesh = t_cyl
	thigh.position.y = -0.22
	thigh.material_override = pants_mat
	thigh_root.add_child(thigh)
	
	# Knee Shin Joint
	var shin_root = Node3D.new()
	shin_root.position = Vector3(0, -0.44, 0)
	thigh_root.add_child(shin_root)
	
	# Knee Guard Armor Pad (facing -Z forward)
	var knee = MeshInstance3D.new()
	var k_box = BoxMesh.new()
	k_box.size = Vector3(0.14, 0.12, 0.08)
	knee.mesh = k_box
	knee.position = Vector3(0, 0, -0.08)
	knee.material_override = armor_mat
	shin_root.add_child(knee)
	
	# Shin
	var shin = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.075
	s_cyl.bottom_radius = 0.07
	s_cyl.height = 0.44
	shin.mesh = s_cyl
	shin.position.y = -0.22
	shin.material_override = pants_mat
	shin_root.add_child(shin)
	
	# Armored Combat Boot (pointing -Z forward)
	var boot = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.15, 0.14, 0.28)
	boot.mesh = b_box
	boot.position = Vector3(0, -0.42, -0.05)
	boot.material_override = boots_mat
	shin_root.add_child(boot)
	
	return [thigh_root, shin_root]
